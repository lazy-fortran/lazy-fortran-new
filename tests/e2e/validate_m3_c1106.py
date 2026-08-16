#!/usr/bin/env python3
"""Independent validator for the bounded M3 C1106 semantic slice."""

from __future__ import annotations

import copy
import hashlib
import json
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PROPERTY = "associate-construct-name-consistency"


class ContractError(Exception):
    """A source, schema, fact or oracle contract failure."""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    require(set(value) == expected, f"{label} keys differ")


def require_string(value: Any, label: str) -> None:
    require(isinstance(value, str) and value != "", f"{label} is not a nonempty string")


def fortran_name_identity(value: str) -> str:
    """Normalize ASCII Fortran letter equivalence without broad Unicode rules."""

    return "".join(chr(ord(char) + 32) if "A" <= char <= "Z" else char for char in value)


def validate_side(side: Any, label: str) -> None:
    require(isinstance(side, dict), f"{label} is not an object")
    exact_keys(side, {"known", "present", "value"}, label)
    require(type(side["known"]) is bool, f"{label}.known is not boolean")
    require(type(side["present"]) is bool, f"{label}.present is not boolean")
    require(side["value"] is None or isinstance(side["value"], str), f"{label}.value is not nullable string")
    if not side["known"]:
        require(not side["present"] and side["value"] is None, f"{label} unknown state is not closed")
    elif side["present"]:
        require_string(side["value"], f"{label}.value")
    else:
        require(side["value"] is None, f"{label} absent state has a value")


def c1106_oracle(candidate: dict[str, Any]) -> str:
    """The deliberately small decision procedure for C1106."""

    start = candidate["start"]
    end = candidate["end"]
    if not start["known"] or not end["known"]:
        return "UNRESOLVED"
    if start["present"] != end["present"]:
        return "REJECTED"
    if not start["present"]:
        return "ACCEPTED"
    return "ACCEPTED" if fortran_name_identity(start["value"]) == fortran_name_identity(end["value"]) else "REJECTED"


def validate_candidate(case: dict[str, Any]) -> dict[str, Any]:
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case.get('id', '<missing>')}")
    require_string(case["id"], "case id")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind is invalid")
    require(case["expected"] in OUTCOMES, f"case {case['id']} expected outcome is invalid")
    candidate = case["candidate"]
    require(isinstance(candidate, dict), f"case {case['id']} candidate is not an object")
    exact_keys(candidate, {"type", "source_rule", "start", "end"}, f"case {case['id']} candidate")
    require(candidate["type"] == "associate-construct-name-pair", f"case {case['id']} candidate type differs")
    require(candidate["source_rule"] == "C1106", f"case {case['id']} source rule differs")
    validate_side(candidate["start"], f"case {case['id']} start")
    validate_side(candidate["end"], f"case {case['id']} end")
    computed = c1106_oracle(candidate)
    require(computed == case["expected"], f"case {case['id']} expected label disagrees with oracle")
    return {
        "id": case["id"],
        "kind": case["kind"],
        "computed": computed,
        "expected": case["expected"],
    }


def source_field(line: str, pattern: str, label: str) -> str:
    match = re.search(pattern, line)
    if match is None:
        raise ContractError(f"StandardIR row has no {label}: {line}")
    return match.group(1)


def validate_standardir_rows(source: dict[str, Any], standardir_path: Path) -> None:
    standardir = standardir_path.read_text(encoding="utf-8").splitlines()
    require(digest(standardir_path) == STANDARDIR_SHA256, "StandardIR source hash differs")
    standardir_spec = source["standardir"]
    require(standardir_spec["sha256"] == STANDARDIR_SHA256, "fixture StandardIR hash differs")
    require(standardir_spec["source_hash"] == SOURCE_SHA256, "fixture StandardIR source hash differs")
    for row in standardir_spec["rows"]:
        matches = [line for line in standardir if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matches) == 1, f"expected one StandardIR row for {row['rule']}")
        line = matches[0]
        require(source_field(line, r"\(lhs ([^)]+)\)", "lhs") == row["lhs"], f"{row['rule']} lhs differs")
        require(int(source_field(line, r"\(page (\d+)\)", "page")) == row["page"], f"{row['rule']} page differs")
        require(int(source_field(line, r"\(byte-start (\d+)\)", "byte-start")) == row["byte_start"], f"{row['rule']} byte-start differs")
        require(int(source_field(line, r"\(byte-length (\d+)\)", "byte-length")) == row["byte_length"], f"{row['rule']} byte-length differs")
        require(int(source_field(line, r"\(occurrence (\d+)\)", "occurrence")) == row["occurrence"], f"{row['rule']} occurrence differs")
        require(source_field(line, r"\(source-sha256 ([^)]+)\)", "source-sha256") == SOURCE_SHA256, f"{row['rule']} source hash differs")


def validate_canonical_lines(source: dict[str, Any], canonical_path: Path) -> None:
    require(digest(canonical_path) == SOURCE_SHA256, "canonical source hash differs")
    # The canonical extractor preserves PDF form-feed bytes.  `splitlines()`
    # would count those as extra lines and invalidate the physical line pins.
    lines = canonical_path.read_text(encoding="utf-8").split("\n")
    for item in source["canonical_lines"]:
        number = item["line"]
        require(1 <= number <= len(lines), f"canonical source line is out of range: {number}")
        actual = lines[number - 1]
        parts = actual.split(maxsplit=1)
        require(len(parts) == 2 and parts[0].isdigit(), f"canonical source line lacks line marker: {number}")
        require(parts[1] == item["text"], f"canonical source text differs at line {number}")
    for item in source["case_identity_lines"]:
        number = item["line"]
        require(1 <= number <= len(lines), f"case identity source line is out of range: {number}")
        actual = lines[number - 1]
        parts = actual.split(maxsplit=1)
        require(len(parts) == 2 and parts[0].isdigit(), f"case identity source line lacks line marker: {number}")
        require(parts[1] == item["text"], f"case identity source text differs at line {number}")


def validate_semantic_item(doc: dict[str, Any], root: Path, semantic_input: Path) -> None:
    item = doc["semantic_item"]
    exact_keys(
        item,
        {"path", "sha256", "id", "subject", "document", "clause", "rule", "page", "source_hash", "origin", "resolution"},
        "semantic item",
    )
    expected_path = root / item["path"]
    require(semantic_input.resolve() == expected_path.resolve(), "semantic-items path differs")
    require(digest(expected_path) == item["sha256"], "semantic-items input hash differs")
    text = expected_path.read_text(encoding="utf-8").strip()
    required = [
        f"(id {item['id']})",
        f"(subject {item['subject']})",
        f"(document {item['document']})",
        f"(clause {item['clause']})",
        f"(rule {item['rule']})",
        f"(page {item['page']})",
        f"(source-hash {item['source_hash']})",
        f"(origin {item['origin']})",
        f"(resolution {item['resolution']})",
    ]
    for fragment in required:
        require(fragment in text, f"semantic-items input lacks {fragment}")


def validate_source_binding(
    doc: dict[str, Any],
    root: Path,
    source_pdf: Path,
    canonical_path: Path,
    standardir_path: Path,
    semantic_input: Path,
) -> None:
    exact_keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"}, "fixture")
    require(doc["schema_version"] == "m3-c1106-source-backed-v0", "fixture schema version differs")
    require(doc["origin"] == "HUMAN", "fixture origin is not HUMAN")
    require(doc["property"] == PROPERTY, "fixture property differs")

    source = doc["source"]
    require(source["document"] == "J3-24-007", "source document differs")
    require(source["clause"] == "11", "source clause differs")
    require(source["rule"] == "C1106", "source rule differs")
    require(source["printed_page"] == 190, "source printed page differs")
    require(source["pdf_sha256"] == PDF_SHA256, "fixture PDF hash differs")
    require(source["canonical_text_sha256"] == SOURCE_SHA256, "fixture canonical hash differs")
    require(source["canonical_text"] == ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", "canonical path differs")
    require(canonical_path.resolve() == (root / source["canonical_text"]).resolve(), "canonical input path differs")

    manifest = tomllib.loads((root / "artifacts/standards/j3-24-007.toml").read_text(encoding="utf-8"))
    require(manifest["sha256"] == PDF_SHA256, "standard manifest hash differs")
    require(manifest["bytes"] == source_pdf.stat().st_size, "standard manifest byte count differs")
    require(digest(source_pdf) == PDF_SHA256, "normative PDF hash differs")
    validate_canonical_lines(source, canonical_path)
    validate_standardir_rows(source, standardir_path)

    item = doc["semantic_item"]
    require(item["document"] == source["document"], "semantic document differs")
    require(item["clause"] == source["clause"], "semantic clause differs")
    require(item["rule"] == source["rule"], "semantic rule differs")
    require(item["page"] == source["printed_page"], "semantic page differs")
    require(item["source_hash"] == SOURCE_SHA256, "semantic source hash differs")
    validate_semantic_item(doc, root, semantic_input)


def set_path(document: dict[str, Any], path: list[str], value: Any) -> None:
    target: Any = document
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value


def validate_fixture_shape(doc: dict[str, Any]) -> None:
    require(isinstance(doc["cases"], list) and len(doc["cases"]) == 6, "fixture case count differs")
    ids = set()
    results = []
    for case in doc["cases"]:
        result = validate_candidate(case)
        require(result["id"] not in ids, f"duplicate case id: {result['id']}")
        ids.add(result["id"])
        results.append(result)
    require({item["kind"] for item in results} == {"positive", "negative", "unresolved"}, "fixture witness kinds are incomplete")
    require(len(doc["mutations"]) == 3, "mutation control count differs")
    for mutation in doc["mutations"]:
        exact_keys(mutation, {"id", "path", "value"}, f"mutation {mutation.get('id', '<missing>')}")
        require(isinstance(mutation["path"], list) and mutation["path"], "mutation path is invalid")


def build_result(
    fixture_path: Path,
    fixture: dict[str, Any],
    root: Path,
    source_pdf: Path,
    canonical_path: Path,
    standardir_path: Path,
    semantic_input: Path,
    semantic_output: Path,
    golden: Path,
) -> dict[str, Any]:
    validate_fixture_shape(fixture)
    validate_source_binding(fixture, root, source_pdf, canonical_path, standardir_path, semantic_input)
    require(semantic_output.read_bytes() == semantic_input.read_bytes(), "canonical semantic-items output differs from input")
    require(semantic_output.read_bytes() == golden.read_bytes(), "canonical semantic-items output differs from golden")

    case_results = [validate_candidate(case) for case in fixture["cases"]]
    mutation_results = []
    for mutation in fixture["mutations"]:
        mutated = copy.deepcopy(fixture)
        set_path(mutated, mutation["path"], mutation["value"])
        try:
            validate_source_binding(mutated, root, source_pdf, canonical_path, standardir_path, semantic_input)
        except ContractError:
            mutation_results.append({"id": mutation["id"], "result": "REJECTED"})
        else:
            raise ContractError(f"mutation control was accepted: {mutation['id']}")

    counts = {outcome: sum(result["computed"] == outcome for result in case_results) for outcome in sorted(OUTCOMES)}
    return {
        "schema_version": fixture["schema_version"],
        "milestone": "M3",
        "property": PROPERTY,
        "fixture": str(fixture_path.relative_to(root)),
        "fixture_sha256": digest(fixture_path),
        "contract": {
            "schema": fixture["contract"]["schema"],
            "schema_sha256": digest(root / fixture["contract"]["schema"]),
            "fixture": fixture["contract"]["fixture"],
            "fixture_sha256": digest(root / fixture["contract"]["fixture"]),
            "version": fixture["contract"]["version"],
        },
        "source": {
            "document": fixture["source"]["document"],
            "clause": fixture["source"]["clause"],
            "rule": fixture["source"]["rule"],
            "printed_page": fixture["source"]["printed_page"],
            "pdf_sha256": digest(source_pdf),
            "canonical_text_sha256": digest(canonical_path),
            "standardir_sha256": digest(standardir_path),
            "canonical_lines": [item["line"] for item in fixture["source"]["canonical_lines"]],
            "case_identity_lines": [item["line"] for item in fixture["source"]["case_identity_lines"]],
            "standardir_rules": [row["rule"] for row in fixture["source"]["standardir"]["rows"]],
        },
        "semantic_items": {
            "input": fixture["semantic_item"]["path"],
            "input_sha256": digest(semantic_input),
            "canonical_output_sha256": digest(semantic_output),
            "canonical_output": "PASS",
        },
        "cases": case_results,
        "outcome_counts": counts,
        "mutation_controls": mutation_results,
        "model_calls": 0,
        "semantic_promotions": 0,
        "origin": "MECHANICAL",
        "oracle": "tests/e2e/validate_m3_c1106.py",
    }


def self_test() -> None:
    def side(known: bool, present: bool, value: str | None) -> dict[str, Any]:
        return {"known": known, "present": present, "value": value}

    cases = [
        (side(True, True, "a"), side(True, True, "a"), "ACCEPTED"),
        (side(True, False, None), side(True, False, None), "ACCEPTED"),
        (side(True, True, "a"), side(True, True, "b"), "REJECTED"),
        (side(True, True, "a"), side(True, False, None), "REJECTED"),
        (side(True, True, "FOO"), side(True, True, "foo"), "ACCEPTED"),
        (side(True, True, "a"), side(False, False, None), "UNRESOLVED"),
    ]
    for start, end, expected in cases:
        candidate = {"start": start, "end": end}
        require(c1106_oracle(candidate) == expected, f"self-test outcome differs: {expected}")
    print("M3 C1106 oracle self-test: PASS")


def main(argv: list[str]) -> int:
    if argv[1:] == ["--self-test"]:
        self_test()
        return 0
    if len(argv) != 8:
        print(
            "usage: validate_m3_c1106.py FIXTURE SEMANTIC_OUTPUT STANDARDIR "
            "CANONICAL_TEXT PDF GOLDEN RESULT_JSON",
            file=sys.stderr,
        )
        return 2

    fixture_path, semantic_output, standardir, canonical_text, source_pdf, golden, result_path = map(Path, argv[1:])
    root = fixture_path.resolve().parents[2]
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        result = build_result(
            fixture_path.resolve(),
            fixture,
            root,
            source_pdf.resolve(),
            canonical_text.resolve(),
            standardir.resolve(),
            root / fixture["semantic_item"]["path"],
            semantic_output.resolve(),
            golden.resolve(),
        )
        result_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"M3 C1106 validator: FAIL: {error}", file=sys.stderr)
        return 1
    print("M3 C1106 validator: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
