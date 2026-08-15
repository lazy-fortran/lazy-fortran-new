#!/usr/bin/env python3
"""Adjudicate source-backed lexer and parser-behavior evidence.

This script only consumes already generated evidence.  It deliberately keeps
the generated-parser-runtime gate separate from the lexer module's tests.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(message)


def table(path: Path) -> dict[str, str]:
    rows = {}
    lines = path.read_text(encoding="utf-8").splitlines()
    if lines and lines[0].split("\t", 1)[0] in {"field", "oracle", "metric"}:
        lines = lines[1:]
    for line in lines:
        fields = line.split("\t")
        if len(fields) >= 2 and fields[0]:
            rows[fields[0]] = fields[1]
    return rows


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def contract(path: Path) -> tuple[dict, list[dict]]:
    rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip()]
    require(rows and rows[0].get("kind") == "lexer-contract-header",
            f"{path}: missing lexer contract header")
    require(rows[0].get("format") == 1 and rows[0].get("origin") == "MECHANICAL",
            f"{path}: invalid lexer contract header")
    tokens = rows[1:]
    require(tokens, f"{path}: no lexer-token rows")
    for row in tokens:
        require(row.get("kind") == "lexer-token", f"{path}: non-token row")
        require(row.get("origin") == "MECHANICAL", f"{path}: non-mechanical row")
        for field in ("token_name", "source_term", "lexical_class", "pattern",
                      "document", "clause", "rule", "page", "source_hash"):
            require(str(row.get(field, "")).strip() != "", f"{path}: missing {field}")
        require(re.fullmatch(r"[0-9a-f]{64}", row["source_hash"]) is not None,
                f"{path}: malformed source hash")
    return rows[0], tokens


def source_facts(path: Path) -> list[dict[str, str]]:
    facts = []
    for line in path.read_text(encoding="utf-8").splitlines():
        source_term = re.search(r"\(source-term (?:\"([^\"]*)\"|([^\s)]+))\)", line)
        if source_term is None:
            continue
        matches = {
            "target": re.search(r"\(target ([^\s)]+)\)", line),
            "lexical_class": re.search(r"\(class ([^\s)]+)\)", line),
            "rule": re.search(r"\(rule ([^\s)]+)\)", line),
            "page": re.search(r"\(page ([^\s)]+)\)", line),
            "source_hash": re.search(r"\(source-sha256 ([0-9a-f]{64})\)\)", line),
            "document": re.search(r"\(document ([^\s)]+)\)", line),
            "clause": re.search(r"\(clause ([^\s)]+)\)", line),
        }
        require(all(value is not None for value in matches.values()),
                f"{path}: incomplete lexical source fact")
        facts.append({
            "source_term": source_term.group(1) if source_term.group(1) is not None
            else source_term.group(2),
            **{key: value.group(1) for key, value in matches.items()},
        })
    require(facts, f"{path}: no lexical facts")
    return facts


def artifact_hash(path: Path) -> str:
    match = re.search(r'^sha256\s*=\s*"([0-9a-f]{64})"$',
                      path.read_text(encoding="utf-8"), re.MULTILINE)
    require(match is not None, f"{path}: missing artifact SHA-256")
    return match.group(1)


def projection_row(path: Path, format_name: str) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    header = lines[0].split("\t")
    for line in lines[1:]:
        fields = line.split("\t")
        if fields and fields[0] == format_name:
            return dict(zip(header, fields))
    fail(f"{path}: missing projection row {format_name}")


def check_projection(path: Path, label: str) -> dict[str, str]:
    values = table(path / "grammar-oracles.tsv")
    required = {
        "lexer-contract": "PASS",
        "antlr4": "PASS",
        "bison": "PASS",
        "tree-sitter": "PASS",
        "source-projection": "PASS",
        "overall": "PASS",
        "negative_control": "observed_failure",
        "undefined_symbol_diagnostics": "0",
    }
    for key, expected in required.items():
        require(values.get(key) == expected,
                f"{label}: {key}={values.get(key)!r}, expected {expected!r}")
    lexical = table(path / "lexical.tsv")
    require(lexical.get("format_gate_status") == "PASS",
            f"{label}: lexical format gate failed")
    require(lexical.get("negative_mutation") == "PASS",
            f"{label}: lexical negative mutation failed")
    return {
        "generator_smoke": "PASS",
        "lexical_gate": "PASS",
        "shift_reduce": values["bison_shift_reduce_conflicts"],
        "reduce_reduce": values["bison_reduce_reduce_conflicts"],
        "source_alternatives": projection_row(path / "source-projection.tsv", "ebnf")["expected"],
        "emitted_bodies": projection_row(path / "source-projection.tsv", "ebnf")["covered"],
        "omitted_bodies": projection_row(path / "source-projection.tsv", "ebnf")["skipped"],
        "omitted_declared_roots": values["omitted_declared_root_count"],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("lexical_facts", type=Path)
    parser.add_argument("artifact_manifest", type=Path)
    parser.add_argument("language_report", type=Path)
    parser.add_argument("external_summary", type=Path)
    parser.add_argument("fortfront_test_log", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--lexer-test-count", type=int, default=24)
    parser.add_argument("--runtime-test-log", type=Path)
    parser.add_argument("--runtime-test-count", type=int, default=0)
    args = parser.parse_args()

    baseline_header, baseline_tokens = contract(args.baseline / "lexer-contract.jsonl")
    candidate_header, candidate_tokens = contract(args.candidate / "lexer-contract.jsonl")
    require(baseline_header == candidate_header, "lexer contract headers differ")
    require(baseline_tokens == candidate_tokens, "baseline and candidate lexer contracts differ")
    source_terms = {row["source_term"] for row in baseline_tokens}
    token_names = {row["token_name"] for row in baseline_tokens}
    require(len(source_terms) == len(baseline_tokens), "duplicate source terms")
    require(len(token_names) == len(baseline_tokens), "duplicate token names")
    facts = source_facts(args.lexical_facts)
    expected_hash = artifact_hash(args.artifact_manifest)
    expected_by_term = {fact["source_term"]: fact for fact in facts}
    require(set(expected_by_term) == source_terms,
            "lexer contract source terms differ from lexical facts")
    for row in baseline_tokens:
        fact = expected_by_term[row["source_term"]]
        for field in ("document", "clause", "rule", "page", "source_hash"):
            require(row[field] == fact[field],
                    f"lexer contract {field} disagrees for {row['source_term']}")
        require(row["source_hash"] == expected_hash,
                f"lexer contract source hash is not the pinned artifact hash for {row['source_term']}")
        require(row["token_name"] == fact["target"] and
                row["lexical_class"] == fact["lexical_class"],
                f"lexer contract target/class disagrees for {row['source_term']}")

    baseline = check_projection(args.baseline, "baseline")
    candidate = check_projection(args.candidate, "candidate")

    language = json.loads(args.language_report.read_text(encoding="utf-8"))
    require(language.get("status") == "PASS", "bounded language gate failed")
    require(language.get("positive_cases") == 359 and language.get("negative_cases") == 636,
            "bounded language denominator changed")
    require(language.get("negative_candidate_acceptances") == 0,
            "bounded language candidate accepted a negative")

    external = table(args.external_summary)
    for key, expected in {
        "cases_declared": "10",
        "compiler_invocations": "30",
        "all_three_agree_cases": "10",
        "disagreement_cases": "0",
        "missing_results": "0",
        "diagnostic_files": "30",
    }.items():
        require(external.get(key) == expected,
                f"external corpus {key}={external.get(key)!r}, expected {expected!r}")

    test_log = args.fortfront_test_log.read_text(encoding="utf-8")
    match = re.search(r"(?:Tests|Summary):\s+(\d+) passed", test_log)
    require(match is not None and int(match.group(1)) == args.lexer_test_count,
            "fortfront-new lexer test count differs")
    runtime_tests = None
    if args.runtime_test_log is not None:
        runtime_log = args.runtime_test_log.read_text(encoding="utf-8")
        runtime_match = re.search(r"(?:Tests|Summary):\s+(\d+) passed", runtime_log)
        require(runtime_match is not None and int(runtime_match.group(1)) ==
                args.runtime_test_count,
                "fortfront-new parser-runtime test count differs")
        runtime_tests = f"{args.runtime_test_count}/{args.runtime_test_count}"
    runtime_line = (f"fortfront_generated_runtime_tests\t{runtime_tests}\n"
                    if runtime_tests is not None else "")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        "metric\tvalue\n"
        f"lexer_contract_rows\t{len(baseline_tokens)}\n"
        "lexer_contract_lineage\tPASS\n"
        "baseline_generator_smoke\tPASS\n"
        "candidate_generator_smoke\tPASS\n"
        f"baseline_source_alternatives\t{baseline['source_alternatives']}\n"
        f"baseline_emitted_bodies\t{baseline['emitted_bodies']}\n"
        f"baseline_omitted_bodies\t{baseline['omitted_bodies']}\n"
        f"baseline_omitted_declared_roots\t{baseline['omitted_declared_roots']}\n"
        f"candidate_source_alternatives\t{candidate['source_alternatives']}\n"
        f"candidate_emitted_bodies\t{candidate['emitted_bodies']}\n"
        f"candidate_omitted_bodies\t{candidate['omitted_bodies']}\n"
        f"candidate_omitted_declared_roots\t{candidate['omitted_declared_roots']}\n"
        "baseline_lexical_mutation\tPASS\n"
        "candidate_lexical_mutation\tPASS\n"
        f"baseline_bison_conflicts\t{baseline['shift_reduce']}/{baseline['reduce_reduce']}\n"
        f"candidate_bison_conflicts\t{candidate['shift_reduce']}/{candidate['reduce_reduce']}\n"
        f"fortfront_lexer_runtime_tests\t{args.lexer_test_count}/{args.lexer_test_count}\n"
        + runtime_line
        + "bounded_language_behavior\tPASS\n"
        "bounded_positive_cases\t359\n"
        "bounded_negative_cases\t636\n"
        "external_reference_behavior\t10/10-agree\n"
        "external_reference_diagnostics\t30\n"
        "generated_parser_runtime\tOPEN\n"
        "model_calls\t0\n"
        "status\tOPEN-GENERATED-PARSER-RUNTIME\n",
        encoding="utf-8",
    )
    print(args.output.read_text(encoding="utf-8"), end="")


if __name__ == "__main__":
    main()
