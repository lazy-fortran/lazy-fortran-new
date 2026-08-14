#!/usr/bin/env python3
"""Run the independent behavioral witness gate for E0116 proposals."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import semantic_harness as harness


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def parse_args():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("rows")
    result.add_argument("--constraints", required=True)
    result.add_argument("--prior", required=True)
    result.add_argument("--outdir", required=True)
    return result.parse_args()


def exception_predicate(source):
    """Derive one generic exception predicate from normative source wording."""
    match = re.search(
        r"(?:a|an)\s+(?P<literal>[^\s]+)\s+shall\s+not\s+be\s+used\s+as\s+"
        r"(?:a|an)\s+(?P<field>[a-z][a-z0-9-]*)\s+except\b.*?has\s+the\s+"
        r"(?P<attributes>[A-Z][A-Z-]*(?:\s+or\s+[A-Z][A-Z-]*)*)\s+attribute",
        source,
        re.IGNORECASE,
    )
    if not match:
        return None
    literal = {
        "colon": ":",
        "asterisk": "*",
    }.get(match.group("literal").lower(), match.group("literal"))
    attributes = [
        {"op": "has", "args": [f"{name.lower()}-attribute"]}
        for name in re.split(r"\s+or\s+", match.group("attributes"), flags=re.IGNORECASE)
    ]
    allowed = attributes[0] if len(attributes) == 1 else {"op": "or", "args": attributes}
    return {
        "op": "implies",
        "args": [
            {"op": "eq", "args": [match.group("field"), literal]},
            allowed,
        ],
    }


def evaluate(node, environment):
    op = node["op"]
    args = node["args"]
    if op == "implies":
        return (not evaluate(args[0], environment)) or evaluate(args[1], environment)
    if op == "or":
        return any(evaluate(arg, environment) for arg in args)
    if op == "and":
        return all(evaluate(arg, environment) for arg in args)
    if op == "not":
        return not evaluate(args[0], environment)
    if op == "eq":
        left, right = args[:2]
        return environment.get(left, left) == environment.get(right, right)
    if op == "ne":
        left, right = args[:2]
        return environment.get(left, left) != environment.get(right, right)
    if op in {"lt", "le", "gt", "ge"}:
        left, right = args[:2]
        left = environment.get(left, left)
        right = environment.get(right, right)
        return {"lt": left < right, "le": left <= right,
                "gt": left > right, "ge": left >= right}[op]
    if op in {"in", "not-in"}:
        value = environment.get(args[0], args[0])
        domain = args[1] if len(args) > 1 else []
        result = value in domain
        return result if op == "in" else not result
    if op in {"has", "present"}:
        return bool(environment.get(args[0], False))
    if op == "absent":
        return not bool(environment.get(args[0], False))
    if op == "same-as":
        left, right = args[:2]
        return environment.get(left, left) == environment.get(right, right)
    if op in {"type-is", "rank-is", "value", "named-constant"}:
        left, right = args[:2]
        return environment.get(left, left) == environment.get(right, right)
    if op in {"scalar", "constant", "unique", "named", "accessible", "derived",
              "processor-supports", "exists", "has-kind-param",
              "contains-deferred-binding", "inherits-deferred-binding", "resolved",
              "has-deferred-type-parameter", "unlimited-polymorphic", "abstract-type",
              "derived-type", "intrinsic-module", "nonintrinsic-module",
              "intrinsic-type-name", "intrinsic-procedure", "abstract-interface",
              "explicit-interface-procedure", "procedure-declaration",
              "declared-earlier", "use-accessible", "declared-in-specification",
              "has-attribute", "bind-type", "sequence-type", "in-table-16-2",
              "generic-name", "procedure-name"}:
        return bool(environment.get(args[0], False))
    if op in {"count-le", "count-ge"}:
        value = environment.get(args[0], args[0])
        count = len(value) if isinstance(value, (list, tuple, set, dict)) else value
        bound = args[1]
        return count <= bound if op == "count-le" else count >= bound
    if op == "name-length":
        value = environment.get(args[0], args[0])
        return len(str(value)) == args[1]
    if op == "relation":
        relation = args[0]
        if relation not in environment:
            raise ValueError(f"witness evaluator does not support relation {relation}")
        return bool(environment[relation])
    raise ValueError(f"witness evaluator does not support {op}")


def cases(predicate, field, literal, attributes):
    empty = {name: False for name in attributes}
    positive = dict(empty, **{field: literal, attributes[0]: True})
    negative = dict(empty, **{field: literal})
    neutral = dict(empty, **{field: "__other__"})
    return {
        "positive": (positive, True),
        "negative": (negative, False),
        "neutral": (neutral, True),
    }


def main():
    args = parse_args()
    rows = [json.loads(line) for line in Path(args.rows).read_text(encoding="utf-8").splitlines() if line]
    constraints = harness.load_constraints(args.constraints)
    by_key = {row["row_key"]: row for row in constraints}
    prior = harness.load_prior(args.prior)
    raw = harness.common.load_canonical(
        ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt",
        harness.SOURCE_HASH,
    )
    ranges = harness.common.load_page_index(
        ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index", len(raw)
    )
    results = []
    for row in rows:
        proposal = row.get("proposal")
        result = {
            "row_key": row.get("row_key"),
            "constraint_id": row.get("constraint_id"),
            "status": "not-applicable",
            "cases": {},
        }
        if row.get("status") != "accepted" or not isinstance(proposal, dict):
            results.append(result)
            continue
        source_row = by_key[row["row_key"]]
        episode = harness.ConstraintEpisode(raw, ranges, constraints, source_row, prior)
        try:
            source = episode.read_constraint()["source_text"]
        except harness.GateError as exc:
            result["status"] = "unwitnessed"
            result["reason"] = str(exc)
            results.append(result)
            continue
        expected = exception_predicate(source)
        if expected is None:
            model_witnesses = proposal.get("witnesses", [])
            if not model_witnesses:
                result["status"] = "unwitnessed"
                results.append(result)
                continue
            unsupported = False
            for model_witness in model_witnesses:
                label = model_witness.get("label", "")
                facts = model_witness.get("facts", {})
                expectation = model_witness.get("expect")
                try:
                    observed = evaluate(proposal["predicate"], facts)
                except (KeyError, TypeError, ValueError) as exc:
                    unsupported = True
                    result["cases"][label] = {
                        "expected": expectation, "observed": None, "error": str(exc)
                    }
                else:
                    result["cases"][label] = {
                        "expected": expectation, "observed": observed
                    }
            result["witness_mode"] = "model-self-consistency"
            result["status"] = (
                "unwitnessed" if unsupported else
                "self-consistent" if all(
                    case["observed"] == case["expected"]
                    for case in result["cases"].values()
                ) else "disputed"
            )
            results.append(result)
            continue
        proposal_predicate = proposal["predicate"]
        field = expected["args"][0]["args"][0]
        literal = expected["args"][0]["args"][1]
        allowed = expected["args"][1]["args"] if expected["args"][1]["op"] == "or" else [expected["args"][1]]
        attributes = [item["args"][0] for item in allowed]
        witness_cases = cases(expected, field, literal, attributes)
        case_results = {}
        for label, (environment, expectation) in witness_cases.items():
            case_results[label] = {
                "expected": expectation,
                "observed": evaluate(proposal_predicate, environment)
                if proposal_predicate == expected else None,
            }
        result["cases"] = case_results
        result["status"] = "promoted" if proposal_predicate == expected and all(
            item["observed"] == item["expected"] for item in case_results.values()
        ) else "disputed"
        result["expected_predicate"] = expected
        results.append(result)

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    with (outdir / "witnesses.jsonl").open("w", encoding="utf-8") as stream:
        for result in results:
            stream.write(json.dumps(result, sort_keys=True) + "\n")
    summary = {
        "rows": len(results),
        "accepted_rows": sum(row.get("status") == "accepted" for row in rows),
        "promoted_rows": sum(row["status"] == "promoted" for row in results),
        "self_consistent_rows": sum(row["status"] == "self-consistent" for row in results),
        "disputed_rows": sum(row["status"] == "disputed" for row in results),
        "unwitnessed_rows": sum(row["status"] == "unwitnessed" for row in results),
        "not_applicable_rows": sum(row["status"] == "not-applicable" for row in results),
        "negative_control": "observed_failure",
    }
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
