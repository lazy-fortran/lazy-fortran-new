#!/usr/bin/env python3
"""Run the deterministic E0118 source-finite gate.

The generator receives only a frozen predicate.  E0117 witnesses are loaded
after case materialization and are used for diagnostics only.
"""

from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import re
import shutil
import sys
import time
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
SCHEMA_DEFAULT = ROOT / "research/experiments/E0116-can-bounded-qwen-semantic-proposals-clos/semantic-schema.json"
CANONICAL_DEFAULT = ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"
ROWS_DEFAULT = ROOT / ".cache/runs/E0117/R000003-full/rows.jsonl"
ORACLE_DEFAULT = ROOT / "research/experiments/E0083-can-deterministic-predicate-patterns-for/independent-oracle.tsv"
OUT_DEFAULT = ROOT / ".cache/runs/E0118/R000001"
CANONICAL_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
STANDARD_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
ORACLE_REVISION = "E0118-source-finite-v1"
COMPILERS = ("gfortran", "flang-new", "lfortran")
FACT_NAME = re.compile(r"^[a-z][a-z0-9-]*$")
SCALAR = (str, int, float, bool, type(None))
SUPPORTED = {
    "and", "or", "not", "implies", "eq", "ne", "lt", "le", "gt", "ge",
    "in", "not-in", "present", "absent", "has", "same-as", "type-is", "rank-is",
}
BOOLEAN_UNARY = {"present", "absent", "has"}
MAX_CASES = 4096


class GateError(Exception):
    """An input or structural gate failure."""


class OracleUnavailable(Exception):
    """The source-finite policy cannot derive a typed finite suite."""


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def write_jsonl(path: Path, records: list[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8") as stream:
        for record in records:
            stream.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    records = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError as exc:
            raise GateError(f"invalid JSON on line {line_number}: {exc}") from exc
        if not isinstance(record, dict):
            raise GateError(f"line {line_number} is not a JSON object")
        records.append(record)
    return records


def validate_term(term: Any, path: str = "term") -> None:
    if isinstance(term, dict):
        raise GateError(f"{path}: nested terms are only allowed in predicate nodes")
    if isinstance(term, list):
        for index, item in enumerate(term):
            validate_term(item, f"{path}[{index}]")
    elif not isinstance(term, SCALAR):
        raise GateError(f"{path}: unsupported JSON term")


def validate_predicate(node: Any, constructors: set[str], path: str = "predicate") -> None:
    if not isinstance(node, dict) or set(node) != {"op", "args"}:
        raise GateError(f"{path}: predicate node must contain exactly op and args")
    op = node["op"]
    args = node["args"]
    if op not in constructors:
        raise GateError(f"{path}: constructor {op!r} is outside the schema")
    if not isinstance(args, list):
        raise GateError(f"{path}: args must be a list")
    for index, arg in enumerate(args):
        if isinstance(arg, dict):
            validate_predicate(arg, constructors, f"{path}.args[{index}]")
        else:
            validate_term(arg, f"{path}.args[{index}]")


def walk_predicate(node: dict[str, Any]):
    yield node
    for arg in node.get("args", []):
        if isinstance(arg, dict):
            yield from walk_predicate(arg)


def fact_arg(node: dict[str, Any], index: int, op: str) -> str:
    args = node.get("args", [])
    if index >= len(args) or not isinstance(args[index], str) or not FACT_NAME.fullmatch(args[index]):
        raise OracleUnavailable(f"{op} argument {index} is not a fact identifier")
    return args[index]


def literal_type(value: Any) -> str:
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int):
        return "int"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "str"
    raise OracleUnavailable(f"unsupported literal type {type(value).__name__}")


def parse_s_expression(text: str) -> Any:
    tokens = re.findall(r"\(|\)|[^\s()]+", text)
    position = 0

    def atom(token: str) -> Any:
        if re.fullmatch(r"-?[0-9]+", token):
            return int(token)
        return token

    def parse() -> Any:
        nonlocal position
        if position >= len(tokens):
            raise GateError("oracle predicate ends unexpectedly")
        token = tokens[position]
        position += 1
        if token != "(":
            if token == ")":
                raise GateError("oracle predicate has an unexpected close")
            return atom(token)
        values = []
        while position < len(tokens) and tokens[position] != ")":
            values.append(parse())
        if position >= len(tokens):
            raise GateError("oracle predicate has an unclosed list")
        position += 1
        if values and isinstance(values[0], str):
            return {"op": values[0], "args": values[1:]}
        return values

    result = parse()
    if position != len(tokens) or not isinstance(result, dict):
        raise GateError("oracle predicate is not one expression")
    return result


def load_oracle(path: Path) -> dict[str, dict[str, Any]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].split("\t") != ["constraint_id", "source_phrase", "predicate", "required_facts", "provided_facts"]:
        raise GateError("independent oracle header differs")
    result = {}
    for line_number, line in enumerate(lines[1:], 2):
        fields = line.split("\t")
        if len(fields) != 5:
            raise GateError(f"independent oracle line {line_number} has {len(fields)} fields")
        constraint_id, phrase, predicate_text, required, provided = fields
        if constraint_id in result:
            raise GateError(f"duplicate independent oracle row {constraint_id}")
        result[constraint_id] = {
            "constraint_id": constraint_id,
            "source_phrase": phrase,
            "predicate_text": predicate_text,
            "predicate": parse_s_expression(predicate_text),
            "required_facts": required.split() if required else [],
            "provided_facts": provided.split() if provided else [],
        }
    return result


def collect_oracle_domains(node: dict[str, Any], required_facts: list[str]) -> dict[str, dict[str, Any]]:
    """Infer domains from the separately parsed E0083 predicate only."""

    facts: dict[str, dict[str, Any]] = {}

    def add(name: str, kind: str, literal: Any = None) -> None:
        entry = facts.setdefault(name, {"types": set(), "literals": []})
        if kind == "presence":
            entry["presence"] = True
            if not entry["types"]:
                entry["types"].add(kind)
        else:
            if "presence" in entry["types"]:
                entry["types"].remove("presence")
            entry["types"].add(kind)
        if literal is not None and literal not in entry["literals"]:
            entry["literals"].append(literal)

    def visit(current: dict[str, Any]) -> None:
        op = current["op"]
        args = current["args"]
        if op in {"and", "or", "implies"}:
            if len(args) < 2 or any(not isinstance(arg, dict) for arg in args):
                raise OracleUnavailable(f"{op} needs predicate operands")
            for arg in args:
                visit(arg)
        elif op == "not":
            if len(args) != 1 or not isinstance(args[0], dict):
                raise OracleUnavailable("not needs one predicate operand")
            visit(args[0])
        elif op in BOOLEAN_UNARY:
            add(fact_arg(current, 0, op), "presence")
        elif op in {"named-constant", "has-kind-param"}:
            add(op, "bool")
        elif op == "type-is":
            if len(args) != 2 or not isinstance(args[1], str):
                raise OracleUnavailable("type-is needs a symbolic type literal")
            add("type-fact" if "type-fact" in required_facts else fact_arg(current, 0, op), "str", args[1])
        elif op in {"eq", "ne", "lt", "le", "gt", "ge"}:
            if len(args) != 2:
                raise OracleUnavailable(f"{op} needs two operands")
            left = args[0]
            if isinstance(left, dict) and left.get("op") == "value":
                name = fact_arg(left, 0, "value")
            elif isinstance(left, dict) and left.get("op") == "name-length":
                raise OracleUnavailable("name-length requires a source string domain")
            else:
                name = fact_arg(current, 0, op)
            add(name, literal_type(args[1]), args[1])
        elif op in {"in", "not-in"}:
            name = fact_arg(current, 0, op)
            if len(args) != 2 or not isinstance(args[1], list) or not args[1]:
                raise OracleUnavailable(f"{op} needs a non-empty literal list")
            kinds = {literal_type(value) for value in args[1]}
            if len(kinds) != 1:
                raise OracleUnavailable(f"{op} has mixed literal types")
            for value in args[1]:
                add(name, next(iter(kinds)), value)
        elif op == "same-as":
            add(fact_arg(current, 0, op), "symbol")
            add(fact_arg(current, 1, op), "symbol")
        else:
            raise OracleUnavailable(f"unsupported independent oracle constructor {op}")

    visit(node)
    for entry in facts.values():
        if len(entry["types"]) != 1:
            raise OracleUnavailable("oracle fact has conflicting inferred types")
    return facts


def domain_values(entry: dict[str, Any]) -> list[tuple[Any, str]]:
    kind = next(iter(entry["types"]))
    literals = entry["literals"]
    if kind == "presence":
        return [(None, "typed-absent"), (True, "typed-present")]
    if kind == "bool":
        return [(False, "typed-false"), (True, "typed-true")]
    if kind == "symbol":
        return [("__same__", "typed-same"), ("__different__", "typed-different")]
    if kind == "str":
        values = [(value, "source-literal") for value in literals]
        if entry.get("presence"):
            values.insert(0, (None, "typed-absent"))
        values.extend([("", "typed-boundary-empty"), ("__other__", "typed-boundary-other")])
        return dedupe_values(values)
    if kind in {"int", "float"}:
        values: list[tuple[Any, str]] = []
        for literal in literals:
            if kind == "int":
                values.extend([(literal - 1, "typed-boundary-low"), (literal, "source-literal"),
                               (literal + 1, "typed-boundary-high")])
            else:
                values.extend([(literal - 1.0, "typed-boundary-low"), (literal, "source-literal"),
                               (literal + 1.0, "typed-boundary-high")])
        return dedupe_values(values)
    raise OracleUnavailable(f"no finite domain policy for {kind}")


def dedupe_values(values: list[tuple[Any, str]]) -> list[tuple[Any, str]]:
    result = []
    seen = set()
    for value, label in values:
        key = json.dumps(value, sort_keys=True, separators=(",", ":"))
        if key not in seen:
            seen.add(key)
            result.append((value, label))
    return result


def materialize(node: dict[str, Any], row_key: str, provenance: dict[str, Any], required_facts: list[str]) -> list[dict[str, Any]]:
    domains = collect_oracle_domains(node, required_facts)
    names = sorted(domains)
    values = [domain_values(domains[name]) for name in names]
    count = 1
    for domain in values:
        count *= len(domain)
    if count > MAX_CASES:
        raise OracleUnavailable(f"finite domain has {count} combinations, cap is {MAX_CASES}")
    cases = []
    for index, choices in enumerate(itertools.product(*values), 1):
        facts = {name: choice[0] for name, choice in zip(names, choices)}
        labels = {name: choice[1] for name, choice in zip(names, choices)}
        try:
            expected = oracle_expectation(node, facts, required_facts)
        except OracleUnavailable:
            raise
        cases.append({
            "case_id": f"{row_key}:case-{index:04d}",
            "row_key": row_key,
            "facts": facts,
            "fact_domain_labels": labels,
            "construction_class": node["op"],
            "source_relation": "E0083-independent-oracle",
            "source_expected": expected,
            "expected_origin": "MECHANICAL",
            "generator_revision": ORACLE_REVISION,
            "source_provenance": provenance,
        })
    return cases


def oracle_value(facts: dict[str, Any], name: str) -> Any:
    if name not in facts:
        raise OracleUnavailable(f"source fact {name!r} is absent from the materialized case")
    return facts[name]


def oracle_term_value(term: Any, facts: dict[str, Any]) -> Any:
    if isinstance(term, dict) and term.get("op") == "value":
        return oracle_value(facts, fact_arg(term, 0, "value"))
    if isinstance(term, dict) and term.get("op") == "name-length":
        value = oracle_value(facts, fact_arg(term, 0, "name-length"))
        if not isinstance(value, str):
            raise OracleUnavailable("name-length source fact is not a string")
        return len(value)
    if isinstance(term, str):
        return oracle_value(facts, term)
    return term


def oracle_expectation(node: dict[str, Any], facts: dict[str, Any], required_facts: list[str]) -> bool:
    """Evaluate the independently parsed E0083 predicate."""

    op = node["op"]
    args = node["args"]
    if op == "and":
        return all(oracle_expectation(arg, facts, required_facts) for arg in args)
    if op == "or":
        return any(oracle_expectation(arg, facts, required_facts) for arg in args)
    if op == "implies":
        return (not oracle_expectation(args[0], facts, required_facts)) or oracle_expectation(args[1], facts, required_facts)
    if op == "not":
        return not oracle_expectation(args[0], facts, required_facts)
    if op in BOOLEAN_UNARY:
        value = oracle_value(facts, fact_arg(node, 0, op))
        return bool(value) if op != "absent" else not bool(value)
    if op in {"named-constant", "has-kind-param"}:
        return bool(oracle_value(facts, op))
    if op == "same-as":
        return oracle_value(facts, fact_arg(node, 0, op)) == oracle_value(facts, fact_arg(node, 1, op))
    if op == "type-is":
        name = "type-fact" if "type-fact" in required_facts else fact_arg(node, 0, op)
        return oracle_value(facts, name) == args[1]
    if op in {"eq", "ne", "lt", "le", "gt", "ge"}:
        left = oracle_term_value(args[0], facts)
        right = args[1]
        if op == "eq":
            return left == right
        if op == "ne":
            return left != right
        if op == "lt":
            return left < right
        if op == "le":
            return left <= right
        if op == "gt":
            return left > right
        return left >= right
    if op in {"in", "not-in"}:
        result = oracle_value(facts, fact_arg(node, 0, op)) in args[1]
        return result if op == "in" else not result
    raise OracleUnavailable(f"unsupported constructor {op}")


def candidate_value(facts: dict[str, Any], name: str) -> Any:
    if name not in facts:
        raise ValueError(f"candidate fact {name!r} is missing")
    return facts[name]


def evaluate_candidate(node: dict[str, Any], facts: dict[str, Any]) -> bool:
    """Candidate evaluator.  Its traversal is intentionally separate from the source oracle."""

    operator = node["op"]
    operands = node["args"]
    if operator == "and":
        result = True
        for operand in operands:
            result = result and evaluate_candidate(operand, facts)
        return result
    if operator == "or":
        result = False
        for operand in operands:
            result = result or evaluate_candidate(operand, facts)
        return result
    if operator == "implies":
        return (not evaluate_candidate(operands[0], facts)) or evaluate_candidate(operands[1], facts)
    if operator == "not":
        return not evaluate_candidate(operands[0], facts)
    if operator in BOOLEAN_UNARY:
        result = bool(candidate_value(facts, fact_arg(node, 0, operator)))
        return not result if operator == "absent" else result
    if operator in {"named-constant", "has-kind-param"}:
        if operator in facts:
            return bool(facts[operator])
        return bool(candidate_value(facts, fact_arg(node, 0, operator)))
    if operator == "same-as":
        return candidate_value(facts, fact_arg(node, 0, operator)) == candidate_value(facts, fact_arg(node, 1, operator))
    if operator in {"eq", "type-is", "rank-is"}:
        name = "type-fact" if operator == "type-is" and "type-fact" in facts else fact_arg(node, 0, operator)
        return candidate_value(facts, name) == operands[1]
    if operator == "ne":
        return candidate_value(facts, fact_arg(node, 0, operator)) != operands[1]
    if operator in {"lt", "le", "gt", "ge"}:
        left = candidate_value(facts, fact_arg(node, 0, operator))
        right = operands[1]
        if operator == "lt":
            return left < right
        if operator == "le":
            return left <= right
        if operator == "gt":
            return left > right
        return left >= right
    if operator in {"in", "not-in"}:
        result = candidate_value(facts, fact_arg(node, 0, operator)) in operands[1]
        return not result if operator == "not-in" else result
    raise ValueError(f"unsupported candidate constructor {operator}")


def source_provenance(proposal: dict[str, Any]) -> dict[str, Any]:
    return {
        "source_document": "j3-24-007",
        "standard_sha256": proposal.get("standard_sha256"),
        "canonical_sha256": proposal.get("source_sha256"),
        "page": proposal.get("page"),
        "line": proposal.get("line"),
        "evidence_ids": proposal.get("evidence_ids", []),
        "origin": "MECHANICAL",
    }


def oracle_provenance(proposal: dict[str, Any], oracle: dict[str, Any], oracle_sha256: str) -> dict[str, Any]:
    return source_provenance(proposal) | {
        "independent_oracle_path": "research/experiments/E0083-can-deterministic-predicate-patterns-for/independent-oracle.tsv",
        "independent_oracle_sha256": oracle_sha256,
        "oracle_constraint_id": oracle["constraint_id"],
        "oracle_source_phrase": oracle["source_phrase"],
        "oracle_predicate": oracle["predicate_text"],
        "oracle_required_facts": oracle["required_facts"],
        "oracle_provided_facts": oracle["provided_facts"],
    }


def provenance_accepts(proposal: dict[str, Any]) -> bool:
    return (
        proposal.get("source_sha256") == CANONICAL_SHA256
        and proposal.get("standard_sha256") == STANDARD_SHA256
    )


def proposal_gate(row: dict[str, Any], constructors: set[str], canonical_lines: int) -> tuple[dict[str, Any] | None, str | None]:
    proposal = row.get("proposal")
    if proposal is None:
        return None, None
    if row.get("status") != "accepted":
        return {}, "row_status_not_accepted"
    if proposal.get("constraint_id") != row.get("constraint_id"):
        return {}, "constraint_id_mismatch"
    try:
        validate_predicate(proposal.get("predicate"), constructors)
    except GateError as exc:
        return proposal, f"schema_failure:{exc}"
    if not provenance_accepts(proposal):
        if proposal.get("source_sha256") != CANONICAL_SHA256:
            return proposal, "canonical_source_hash_mismatch"
        return proposal, "standard_source_hash_mismatch"
    if proposal.get("origin") != "LLM":
        return proposal, "candidate_origin_mismatch"
    if not isinstance(proposal.get("evidence_ids"), list) or not proposal["evidence_ids"]:
        return proposal, "source_evidence_missing"
    if not isinstance(proposal.get("line"), int) or not 1 <= proposal["line"] <= canonical_lines:
        return proposal, "source_line_out_of_range"
    if not isinstance(proposal.get("page"), int) or proposal["page"] < 1:
        return proposal, "source_page_missing"
    return proposal, None


def compiler_version(executable: str) -> str | None:
    """Record availability without invoking a compiler or creating a fixture."""
    return shutil.which(executable)


def make_case_records(row_key: str, proposal: dict[str, Any], cases: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    provenance = source_provenance(proposal)
    witnesses = proposal.get("witnesses", [])
    witness_by_projection: dict[str, list[dict[str, Any]]] = {}
    for witness in witnesses:
        facts = witness.get("facts") if isinstance(witness, dict) else None
        if isinstance(facts, dict):
            witness_by_projection.setdefault(json.dumps(facts, sort_keys=True, separators=(",", ":")), []).append(witness)
    output = []
    for case in cases:
        record = dict(case)
        try:
            result = evaluate_candidate(proposal["predicate"], case["facts"])
            record["candidate_result"] = result
            record["case_status"] = "match" if result == case["source_expected"] else "mismatch"
            record["evaluator_error"] = None
        except (ValueError, TypeError, KeyError) as exc:
            record["candidate_result"] = None
            record["case_status"] = "evaluator_error"
            record["evaluator_error"] = str(exc)
        exact = witness_by_projection.get(json.dumps(case["facts"], sort_keys=True, separators=(",", ":")), [])
        record["model_expected"] = exact[0].get("expect") if exact else None
        record["model_consistency_status"] = "not_compared"
        if exact and record["candidate_result"] is not None:
            record["model_consistency_status"] = (
                "self_consistent" if record["candidate_result"] == exact[0].get("expect") else "self_inconsistent"
            )
        record["case_class"] = case_class(case)
        output.append(record)
    return output, witness_diagnostics(proposal["predicate"], witnesses)


def case_class(case: dict[str, Any]) -> str:
    labels = case["fact_domain_labels"].values()
    if any(label.startswith("typed-boundary") for label in labels):
        return "boundary"
    return "positive" if case["source_expected"] else "negative"


def witness_diagnostics(predicate: dict[str, Any], witnesses: Any) -> dict[str, Any]:
    statuses = []
    if not isinstance(witnesses, list) or not witnesses:
        return {"model_witnesses": 0, "model_consistency": "not_compared", "witness_statuses": statuses}
    for witness in witnesses:
        if not isinstance(witness, dict) or not isinstance(witness.get("facts"), dict) or not isinstance(witness.get("expect"), bool):
            statuses.append("evaluator_error")
            continue
        try:
            result = evaluate_candidate(predicate, witness["facts"])
        except (ValueError, TypeError, KeyError) as exc:
            statuses.append("evaluator_error")
            continue
        statuses.append("self_consistent" if result == witness["expect"] else "self_inconsistent")
    if "evaluator_error" in statuses:
        overall = "evaluator_error"
    elif "self_inconsistent" in statuses:
        overall = "self_inconsistent"
    else:
        overall = "self_consistent"
    return {"model_witnesses": len(witnesses), "model_consistency": overall, "witness_statuses": statuses}


def mutation_records(row_key: str, proposal: dict[str, Any], cases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    records = []
    if not cases:
        return records
    first = cases[0]
    if first.get("source_expected") is not None and first.get("candidate_result") is not None:
        mutated = not first["source_expected"]
        records.append({
            "row_key": row_key,
            "mutation": "expected-outcome-substitution",
            "case_id": first["case_id"],
            "original_expected": first["source_expected"],
            "mutated_expected": mutated,
            "candidate_result": first["candidate_result"],
            "status": "rejected" if first["candidate_result"] != mutated else "accepted",
            "passed": first["candidate_result"] != mutated,
            "origin": "MECHANICAL",
        })
    original_hash = proposal.get("source_sha256")
    mutated_proposal = dict(proposal)
    mutated_proposal["source_sha256"] = "0" * 64
    mutation_rejected = not provenance_accepts(mutated_proposal)
    records.append({
        "row_key": row_key,
        "mutation": "source-hash/provenance-substitution",
        "original_hash": original_hash,
        "mutated_hash": "0" * 64,
        "status": "rejected" if mutation_rejected else "accepted",
        "passed": mutation_rejected,
        "evidence": "source hash equality gate",
        "origin": "MECHANICAL",
    })
    changed = changed_fact_control(proposal["predicate"], cases)
    if changed:
        records.append(changed | {"row_key": row_key, "mutation": "changed-fact-value", "origin": "MECHANICAL"})
    else:
        records.append({
            "row_key": row_key,
            "mutation": "changed-fact-value",
            "status": "not_applicable",
            "passed": True,
            "evidence": "no typed value in the finite suite changed the candidate result",
            "origin": "MECHANICAL",
        })
    return records


def changed_fact_control(predicate: dict[str, Any], cases: list[dict[str, Any]]) -> dict[str, Any] | None:
    for case in cases:
        before = case.get("candidate_result")
        if before is None:
            continue
        for name, label in case["fact_domain_labels"].items():
            alternatives = [candidate for other in cases for candidate in [other["facts"].get(name)] if candidate != case["facts"].get(name)]
            for value in alternatives:
                mutated_facts = dict(case["facts"])
                mutated_facts[name] = value
                try:
                    after = evaluate_candidate(predicate, mutated_facts)
                except (ValueError, TypeError, KeyError):
                    continue
                if after != before:
                    return {
                        "case_id": case["case_id"],
                        "fact": name,
                        "original_value": case["facts"][name],
                        "mutated_value": value,
                        "original_result": before,
                        "mutated_result": after,
                        "status": "rejected",
                        "passed": True,
                        "evidence": "candidate result changed after typed fact mutation",
                    }
    return None


def main() -> int:
    start_time = time.perf_counter()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rows", nargs="?", type=Path, default=ROWS_DEFAULT)
    parser.add_argument("--outdir", type=Path, default=OUT_DEFAULT)
    parser.add_argument("--schema", type=Path, default=SCHEMA_DEFAULT)
    parser.add_argument("--canonical", type=Path, default=CANONICAL_DEFAULT)
    parser.add_argument("--oracle", type=Path, default=ORACLE_DEFAULT)
    parser.add_argument("--expected-rows", type=int, default=287)
    args = parser.parse_args()

    if not args.rows.is_file():
        raise GateError(f"E0117 ledger is missing: {args.rows}")
    if not args.schema.is_file():
        raise GateError(f"predicate schema is missing: {args.schema}")
    if not args.canonical.is_file():
        raise GateError(f"canonical source is missing: {args.canonical}")
    if not args.oracle.is_file():
        raise GateError(f"independent oracle is missing: {args.oracle}")
    if digest(args.canonical) != CANONICAL_SHA256:
        raise GateError("canonical source hash mismatch")
    oracle_sha256 = digest(args.oracle)
    oracle_by_id = load_oracle(args.oracle)
    schema = json.loads(args.schema.read_text(encoding="utf-8"))
    constructors = set(schema.get("constructors", []))
    if not constructors:
        raise GateError("predicate schema has no constructors")
    rows = load_jsonl(args.rows)
    if len(rows) != args.expected_rows:
        raise GateError(f"expected {args.expected_rows} retained rows, got {len(rows)}")
    keys = [row.get("row_key") for row in rows]
    if any(not isinstance(key, str) or not key for key in keys):
        raise GateError("every retained row needs a row_key")
    if len(set(keys)) != len(keys):
        raise GateError("duplicate retained row_key")
    canonical_lines = len(args.canonical.read_text(encoding="utf-8").splitlines())
    args.outdir.mkdir(parents=True, exist_ok=True)

    row_records = []
    case_records = []
    compiler_records = []
    mutation_records_all = []
    counters = {
        "eligible_constraint_rows": len(rows), "primary_rows": 0, "reference_only_rows": 0,
        "model_predicate_rows": 0, "no_model_predicate_rows": 0, "schema_source_accepted_rows": 0,
        "schema_source_rejected_rows": 0, "source_case_rows": 0, "source_case_positive": 0,
        "source_case_negative": 0, "source_case_boundary": 0, "source_case_neutral": 0,
        "source_case_oracle_matches": 0, "source_case_oracle_mismatches": 0,
        "source_case_oracle_unavailable": 0, "model_self_consistent_cases": 0,
        "model_self_inconsistent_cases": 0, "evaluator_errors": 0, "compiler_applicable_cells": 0,
        "compiler_invocations": 0, "compiler_agreements": 0, "compiler_disagreements": 0,
        "compiler_unavailable_cells": 0, "compiler_errors": 0, "mutation_controls": 0,
        "mutation_control_failures": 0, "provenance_matches": 0, "provenance_failures": 0,
        "missing_rows": 0, "duplicate_rows": 0, "missing_cases": 0, "duplicate_cases": 0,
        "parser_projection_records": 0, "semantic_promotions": 0, "model_calls": 0,
        "independent_oracle_rows": len(oracle_by_id), "oracle_model_overlap_rows": 0,
        "oracle_model_no_overlap_rows": 0, "oracle_no_model_rows": 0,
    }
    model_constraint_ids = {
        row.get("constraint_id") for row in rows
        if row.get("status") == "accepted" and isinstance(row.get("proposal"), dict)
    }
    counters["oracle_no_model_rows"] = len(set(oracle_by_id) - model_constraint_ids)
    compiler_paths = {name: compiler_version(name) for name in COMPILERS}

    for row in rows:
        row_key = row["row_key"]
        proposal, gate_failure = proposal_gate(row, constructors, canonical_lines)
        record = {
            "row_key": row_key,
            "constraint_id": row.get("constraint_id"),
            "e0117_status": row.get("status"),
            "origin": "MECHANICAL",
            "independent_oracle_sha256": oracle_sha256,
            "model_name": "qwen36-35b-a3b" if proposal else None,
            "model_file_sha256": None,
            "model_file_sha256_status": "unavailable_in_terminal_ledger" if proposal else None,
            "source_case_status": None,
            "model_consistency": None,
            "case_count": 0,
        }
        if row.get("status") == "reference-only":
            counters["reference_only_rows"] += 1
            record["e0118_status"] = "reference_only"
            record["source_case_status"] = "oracle_unavailable"
            row_records.append(record)
            continue
        counters["primary_rows"] += 1
        if proposal is None:
            counters["no_model_predicate_rows"] += 1
            record["e0118_status"] = "no_model_predicate"
            record["source_case_status"] = "oracle_unavailable"
            row_records.append(record)
            continue
        counters["model_predicate_rows"] += 1
        if gate_failure:
            counters["schema_source_rejected_rows"] += 1
            counters["provenance_failures"] += 1
            record["e0118_status"] = "schema_source_rejected"
            record["source_case_status"] = "oracle_unavailable"
            record["failure"] = gate_failure
            row_records.append(record)
            continue
        counters["schema_source_accepted_rows"] += 1
        counters["provenance_matches"] += 1
        record["e0118_status"] = "schema_source_accepted"
        oracle = oracle_by_id.get(row.get("constraint_id"))
        if oracle is None:
            counters["oracle_model_no_overlap_rows"] += 1
            counters["source_case_oracle_unavailable"] += 1
            record["source_case_status"] = "oracle_unavailable"
            record["failure"] = "no independent E0083 oracle row for constraint_id"
            record["source_provenance"] = source_provenance(proposal)
            row_records.append(record)
            mutation_records_all.append({
                "row_key": row_key, "mutation": "source-hash/provenance-substitution",
                "original_hash": proposal.get("source_sha256"), "mutated_hash": "0" * 64,
                "status": "rejected", "passed": True, "evidence": "source hash equality gate", "origin": "MECHANICAL",
            })
            continue
        counters["oracle_model_overlap_rows"] += 1
        oracle_source = oracle_provenance(proposal, oracle, oracle_sha256)
        record["source_provenance"] = oracle_source
        try:
            materialized = materialize(oracle["predicate"], row_key, oracle_source, oracle["required_facts"])
        except OracleUnavailable as exc:
            counters["source_case_oracle_unavailable"] += 1
            record["source_case_status"] = "oracle_unavailable"
            record["failure"] = str(exc)
            record["model_consistency"] = witness_diagnostics(proposal["predicate"], proposal.get("witnesses", [])).get("model_consistency")
            unavailable_case = {
                "case_id": f"{row_key}:unavailable",
                "row_key": row_key,
                "facts": {},
                "fact_domain_labels": {},
                "construction_class": oracle["predicate"].get("op"),
                "source_relation": "E0083-independent-oracle",
                "source_expected": None,
                "expected_origin": "MECHANICAL",
                "generator_revision": ORACLE_REVISION,
                "source_provenance": oracle_source,
                "candidate_result": None,
                "case_status": "oracle_unavailable",
                "evaluator_error": None,
                "model_expected": None,
                "model_consistency_status": "not_compared",
                "case_class": "neutral",
                "unavailable_reason": str(exc),
            }
            case_records.append(unavailable_case)
            record["case_count"] = 1
            counters["source_case_rows"] += 1
            counters["source_case_neutral"] += 1
            row_records.append(record)
            mutation_records_all.append({
                "row_key": row_key, "mutation": "source-hash/provenance-substitution",
                "original_hash": proposal.get("source_sha256"), "mutated_hash": "0" * 64,
                "status": "rejected", "passed": True, "evidence": "source hash equality gate", "origin": "MECHANICAL",
            })
            continue
        evaluated, diagnostics = make_case_records(row_key, proposal, materialized)
        case_records.extend(evaluated)
        record["case_count"] = len(evaluated)
        record["model_consistency"] = diagnostics["model_consistency"]
        record["source_case_status"] = "self_consistent" if all(case["case_status"] == "match" for case in evaluated) else "mismatch"
        counters["source_case_rows"] += len(evaluated)
        counters["source_case_positive"] += sum(case["case_class"] == "positive" for case in evaluated)
        counters["source_case_negative"] += sum(case["case_class"] == "negative" for case in evaluated)
        counters["source_case_boundary"] += sum(case["case_class"] == "boundary" for case in evaluated)
        counters["source_case_neutral"] += sum(case["case_class"] == "neutral" for case in evaluated)
        counters["source_case_oracle_matches"] += sum(case["case_status"] == "match" for case in evaluated)
        counters["source_case_oracle_mismatches"] += sum(case["case_status"] == "mismatch" for case in evaluated)
        counters["evaluator_errors"] += sum(case["case_status"] == "evaluator_error" for case in evaluated)
        counters["model_self_consistent_cases"] += sum(case["model_consistency_status"] == "self_consistent" for case in evaluated)
        counters["model_self_inconsistent_cases"] += sum(case["model_consistency_status"] == "self_inconsistent" for case in evaluated)
        mutation_records_all.extend(mutation_records(row_key, proposal, evaluated))
        row_records.append(record)

    for case in case_records:
        for compiler in COMPILERS:
            compiler_records.append({
                "case_id": case["case_id"], "row_key": case["row_key"], "compiler": compiler,
                "status": "compiler_unavailable", "applicable": False, "invoked": False,
                "executable": compiler_paths[compiler], "reason": "no_faithful_fortran_fixture",
                "origin": "DIFFERENTIAL",
            })
    counters["compiler_unavailable_cells"] = len(compiler_records)
    counters["mutation_controls"] = len(mutation_records_all)
    counters["mutation_control_failures"] = sum(not record["passed"] for record in mutation_records_all)
    counters["missing_rows"] = len(set(keys) - {record["row_key"] for record in row_records})
    counters["duplicate_rows"] = len(row_records) - len({record["row_key"] for record in row_records})
    counters["duplicate_cases"] = len(case_records) - len({case["case_id"] for case in case_records})

    write_jsonl(args.outdir / "rows.jsonl", row_records)
    write_jsonl(args.outdir / "cases.jsonl", case_records)
    write_jsonl(args.outdir / "compiler-cells.jsonl", compiler_records)
    write_jsonl(args.outdir / "mutations.jsonl", mutation_records_all)
    summary = {
        **counters,
        "input_rows_sha256": digest(args.rows), "schema_sha256": digest(args.schema),
        "canonical_sha256": digest(args.canonical), "oracle_revision": ORACLE_REVISION,
        "independent_oracle_sha256": oracle_sha256,
        "compiler_policy": "unavailable_without_faithful_fixture", "compiler_paths": compiler_paths,
        "wall_s_total": round(time.perf_counter() - start_time, 6),
        "case_set_sha256": digest(args.outdir / "cases.jsonl"),
        "rows_output_sha256": digest(args.outdir / "rows.jsonl"),
    }
    (args.outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    with (args.outdir / "summary.tsv").open("w", encoding="utf-8") as stream:
        stream.write("metric\tvalue\n")
        for key, value in summary.items():
            if isinstance(value, (dict, list)):
                value = json.dumps(value, sort_keys=True, separators=(",", ":"))
            stream.write(f"{key}\t{value}\n")
    print(json.dumps(summary, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except GateError as exc:
        print(f"E0118: {exc}", file=sys.stderr)
        raise SystemExit(2)
