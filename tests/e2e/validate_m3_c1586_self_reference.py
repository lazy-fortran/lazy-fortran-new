#!/usr/bin/env python3
"""Independent validator for the bounded M3 C1586 self-name slice."""

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
PAGES_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
PROPERTY = "statement-function-self-name-exclusion"
EXPECTED_CANONICAL_PAGE = {"page": 358, "start": 1019965, "length": 3429}
EXPECTED_CANONICAL_LINES = [
    {"line": 15464, "text": "28 C1586 (R1547) Each primary in scalar-expr shall be a constant (literal or named), a reference to a variable, a reference to a"},
    {"line": 15465, "text": "29 function, or an expression in parentheses. Each operation shall be intrinsic. If scalar-expr contains a reference to a"},
    {"line": 15466, "text": "30 function, the reference shall not require an explicit interface, the function shall not require an explicit interface unless it is"},
    {"line": 15467, "text": "31 an intrinsic function, the function shall not be a transformational intrinsic, and the result shall be scalar. If an argument to"},
    {"line": 15468, "text": "32 a function is an array, it shall be an array name. If a reference to a statement function appears in scalar-expr, its definition"},
    {"line": 15469, "text": "33 shall have been provided earlier in the scoping unit and shall not be the name of the statement function being defined."},
]
EXPECTED_STANDARDIR_ROWS = [
    {"rule": "R1547", "lhs": "stmt-function-stmt", "page": 358, "byte_start": 1022521, "byte_length": 86, "occurrence": 522},
]


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


def c1586_oracle(candidate: dict[str, Any]) -> str:
    """Apply only C1586's statement-function self-name prohibition."""

    presence = candidate["reference_presence"]
    relation = candidate["name_relation"]
    if presence == "unknown" or relation == "unknown":
        return "UNRESOLVED"
    if presence == "absent" and relation == "not-applicable":
        return "ACCEPTED"
    if presence == "present" and relation == "different":
        return "ACCEPTED"
    if presence == "present" and relation == "same":
        return "REJECTED"
    return "UNRESOLVED"


def validate_candidate(case: dict[str, Any]) -> dict[str, Any]:
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case.get('id', '<missing>')}")
    require_string(case["id"], "case id")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind is invalid")
    require(case["expected"] in OUTCOMES, f"case {case['id']} expected outcome is invalid")
    candidate = case["candidate"]
    require(isinstance(candidate, dict), f"case {case['id']} candidate is not an object")
    exact_keys(candidate, {"fact", "source_rule", "reference_presence", "name_relation"}, f"case {case['id']} candidate")
    require(candidate["fact"] == "statement-function-self-reference", f"case {case['id']} candidate fact differs")
    require(candidate["source_rule"] == "C1586", f"case {case['id']} source rule differs")
    require(candidate["reference_presence"] in {"absent", "present", "unknown"}, f"case {case['id']} reference state is invalid")
    require(candidate["name_relation"] in {"not-applicable", "same", "different", "unknown"}, f"case {case['id']} name relation is invalid")
    if candidate["reference_presence"] == "absent":
        require(candidate["name_relation"] == "not-applicable", f"case {case['id']} absent reference has a name relation")
    else:
        require(candidate["name_relation"] != "not-applicable", f"case {case['id']} non-absent reference has no name relation")
    computed = c1586_oracle(candidate)
    require(computed == case["expected"], f"case {case['id']} expected outcome disagrees with oracle")
    return {
        "id": case["id"],
        "kind": case["kind"],
        "reference_presence": candidate["reference_presence"],
        "name_relation": candidate["name_relation"],
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
    require(standardir_spec["rows"] == EXPECTED_STANDARDIR_ROWS, "StandardIR row identity differs")
    for row in standardir_spec["rows"]:
        matches = [line for line in standardir if line.startswith(f"(syntax {row['rule']} ")]
        matches = [line for line in matches if f"(page {row['page']})" in line and f"(byte-start {row['byte_start']})" in line and f"(byte-length {row['byte_length']})" in line and f"(occurrence {row['occurrence']})" in line]
        require(len(matches) == 1, f"expected one StandardIR row for {row['rule']}")
        line = matches[0]
        require(source_field(line, r"\(lhs ([^)]+)\)", "lhs") == row["lhs"], f"{row['rule']} lhs differs")
        require(int(source_field(line, r"\(page (\d+)\)", "page")) == row["page"], f"{row['rule']} page differs")
        require(int(source_field(line, r"\(byte-start (\d+)\)", "byte-start")) == row["byte_start"], f"{row['rule']} byte-start differs")
        require(int(source_field(line, r"\(byte-length (\d+)\)", "byte-length")) == row["byte_length"], f"{row['rule']} byte-length differs")
        require(int(source_field(line, r"\(occurrence (\d+)\)", "occurrence")) == row["occurrence"], f"{row['rule']} occurrence differs")
        require(source_field(line, r"\(source-sha256 ([^)]+)\)", "source-sha256") == SOURCE_SHA256, f"{row['rule']} source hash differs")


def validate_canonical_page(source: dict[str, Any], root: Path, pages_index_path: Path) -> None:
    expected_path = root / source["canonical_pages_index"]
    require(pages_index_path.resolve() == expected_path.resolve(), "canonical page-index path differs")
    require(digest(pages_index_path) == PAGES_INDEX_SHA256, "canonical page-index hash differs")
    require(source["canonical_page"] == EXPECTED_CANONICAL_PAGE, "canonical page identity differs")
    lines = pages_index_path.read_text(encoding="utf-8").splitlines()
    require("page 358 start 1019965 length 3429" in lines, "canonical page boundary differs")


def validate_canonical_lines(source: dict[str, Any], canonical_path: Path) -> None:
    require(digest(canonical_path) == SOURCE_SHA256, "canonical source hash differs")
    require(source["canonical_lines"] == EXPECTED_CANONICAL_LINES, "canonical source identity differs")
    lines = canonical_path.read_text(encoding="utf-8").split("\n")
    for item in source["canonical_lines"]:
        number = item["line"]
        require(1 <= number <= len(lines), f"canonical source line is out of range: {number}")
        actual = lines[number - 1]
        parts = actual.split(maxsplit=1)
        require(len(parts) == 2 and parts[0].isdigit(), f"canonical source line lacks line marker: {number}")
        require(actual == item["text"], f"canonical source text differs at line {number}")


def validate_semantic_item(doc: dict[str, Any], root: Path, semantic_input: Path) -> None:
    item = doc["semantic_item"]
    exact_keys(item, {"path", "sha256", "id", "subject", "document", "clause", "rule", "page", "source_hash", "origin", "resolution"}, "semantic item")
    expected_path = root / item["path"]
    require(semantic_input.resolve() == expected_path.resolve(), "semantic-items path differs")
    require(digest(expected_path) == item["sha256"], "semantic-items input hash differs")
    text = expected_path.read_text(encoding="utf-8").strip()
    for fragment in (
        f"(id {item['id']})", f"(subject {item['subject']})", f"(document {item['document']})",
        f"(clause {item['clause']})", f"(rule {item['rule']})", f"(page {item['page']})",
        f"(source-hash {item['source_hash']})", f"(origin {item['origin']})", f"(resolution {item['resolution']})",
    ):
        require(fragment in text, f"semantic-items input lacks {fragment}")


def validate_contract_files(doc: dict[str, Any], root: Path) -> None:
    schema = (root / doc["contract"]["schema"]).read_text(encoding="utf-8")
    for fragment in (
        "(record statement-function-self-reference", "(reference-presence reference-presence)",
        "(name-relation name-relation)", "(record semantic-candidate",
    ):
        require(fragment in schema, f"contract schema lacks {fragment}")
    fixture = (root / doc["contract"]["fixture"]).read_text(encoding="utf-8")
    for fragment in (
        "(contract m3-c1586-statement-function-self-reference-oracle)",
        "(property statement-function-self-name-exclusion)", "(document J3-24-007)",
        "(clause 15)", "(rule C1586)", "(page 358)", "(source-hash " + SOURCE_SHA256 + ")",
    ):
        require(fragment in fixture, f"contract fixture lacks {fragment}")


def validate_source_binding(doc: dict[str, Any], root: Path, source_pdf: Path, canonical_path: Path, pages_index_path: Path, standardir_path: Path, semantic_input: Path) -> None:
    exact_keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"}, "fixture")
    require(doc["schema_version"] == "m3-c1586-source-backed-v0", "fixture schema version differs")
    require(doc["origin"] == "HUMAN", "fixture origin is not HUMAN")
    require(doc["property"] == PROPERTY, "fixture property differs")
    validate_contract_files(doc, root)

    source = doc["source"]
    require(source["document"] == "J3-24-007", "source document differs")
    require(source["clause"] == "15", "source clause differs")
    require(source["rule"] == "C1586", "source rule differs")
    require(source["printed_page"] == 358, "source page differs")
    require(source["pdf_sha256"] == PDF_SHA256, "fixture PDF hash differs")
    require(source["canonical_text_sha256"] == SOURCE_SHA256, "fixture canonical hash differs")
    require(source["canonical_text"] == ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", "canonical path differs")
    require(canonical_path.resolve() == (root / source["canonical_text"]).resolve(), "canonical input path differs")

    manifest = tomllib.loads((root / "artifacts/standards/j3-24-007.toml").read_text(encoding="utf-8"))
    require(manifest["sha256"] == PDF_SHA256, "standard manifest hash differs")
    require(manifest["bytes"] == source_pdf.stat().st_size, "standard manifest byte count differs")
    require(digest(source_pdf) == PDF_SHA256, "normative PDF hash differs")
    validate_canonical_lines(source, canonical_path)
    validate_canonical_page(source, root, pages_index_path)
    validate_standardir_rows(source, standardir_path)

    item = doc["semantic_item"]
    require(item["document"] == source["document"], "semantic document differs")
    require(item["clause"] == source["clause"], "semantic clause differs")
    require(item["rule"] == source["rule"], "semantic rule differs")
    require(item["page"] == source["printed_page"], "semantic page differs")
    require(item["source_hash"] == SOURCE_SHA256, "semantic source hash differs")
    validate_semantic_item(doc, root, semantic_input)


def set_path(document: dict[str, Any], path: list[Any], value: Any) -> None:
    target: Any = document
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value


def validate_fixture_shape(doc: dict[str, Any]) -> None:
    require(isinstance(doc["cases"], list) and len(doc["cases"]) == 6, "fixture case count differs")
    ids = set()
    results = []
    signatures = set()
    for case in doc["cases"]:
        result = validate_candidate(case)
        require(result["id"] not in ids, f"duplicate case id: {result['id']}")
        ids.add(result["id"])
        signature = (result["reference_presence"], result["name_relation"])
        require(signature not in signatures, f"duplicate typed witness: {signature}")
        signatures.add(signature)
        results.append(result)
    require({item["kind"] for item in results} == {"positive", "negative", "unresolved"}, "fixture witness kinds are incomplete")
    require(sum(item["kind"] == "positive" for item in results) == 2, "positive witness count differs")
    require(sum(item["kind"] == "negative" for item in results) == 1, "negative witness count differs")
    require(sum(item["kind"] == "unresolved" for item in results) == 3, "unresolved witness count differs")
    require(len(doc["mutations"]) == 8, "mutation control count differs")
    for mutation in doc["mutations"]:
        exact_keys(mutation, {"id", "path", "value"}, f"mutation {mutation.get('id', '<missing>')}")
        require(isinstance(mutation["path"], list) and mutation["path"], "mutation path is invalid")


def build_result(fixture_path: Path, fixture: dict[str, Any], root: Path, source_pdf: Path, canonical_path: Path, pages_index_path: Path, standardir_path: Path, semantic_input: Path, semantic_output: Path, golden: Path) -> dict[str, Any]:
    validate_fixture_shape(fixture)
    validate_source_binding(fixture, root, source_pdf, canonical_path, pages_index_path, standardir_path, semantic_input)
    require(semantic_output.read_bytes() == semantic_input.read_bytes(), "canonical semantic-items output differs from input")
    require(semantic_output.read_bytes() == golden.read_bytes(), "canonical semantic-items output differs from golden")

    case_results = [validate_candidate(case) for case in fixture["cases"]]
    mutation_results = []
    for mutation in fixture["mutations"]:
        mutated = copy.deepcopy(fixture)
        set_path(mutated, mutation["path"], mutation["value"])
        try:
            validate_source_binding(mutated, root, source_pdf, canonical_path, pages_index_path, standardir_path, semantic_input)
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
            "canonical_pages_index_sha256": digest(pages_index_path),
            "standardir_sha256": digest(standardir_path),
            "canonical_page": fixture["source"]["canonical_page"],
            "canonical_lines": [item["line"] for item in fixture["source"]["canonical_lines"]],
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
        "oracle": "tests/e2e/validate_m3_c1586_self_reference.py",
    }


def self_test() -> None:
    cases = [
        ({"reference_presence": "absent", "name_relation": "not-applicable"}, "ACCEPTED"),
        ({"reference_presence": "present", "name_relation": "different"}, "ACCEPTED"),
        ({"reference_presence": "present", "name_relation": "same"}, "REJECTED"),
        ({"reference_presence": "present", "name_relation": "unknown"}, "UNRESOLVED"),
        ({"reference_presence": "unknown", "name_relation": "unknown"}, "UNRESOLVED"),
    ]
    for candidate, expected in cases:
        require(c1586_oracle(candidate) == expected, f"self-test outcome differs: {expected}")
    try:
        validate_candidate({
            "id": "invalid-absent-name-relation",
            "kind": "positive",
            "expected": "ACCEPTED",
            "candidate": {
                "fact": "statement-function-self-reference",
                "source_rule": "C1586",
                "reference_presence": "absent",
                "name_relation": "same",
            },
        })
    except ContractError:
        pass
    else:
        raise ContractError("self-test accepted an invalid absent-reference shape")
    print("M3 C1586 self-reference oracle self-test: PASS")


def main(argv: list[str]) -> int:
    if argv[1:] == ["--self-test"]:
        self_test()
        return 0
    if len(argv) != 9:
        print("usage: validate_m3_c1586_self_reference.py FIXTURE SEMANTIC_OUTPUT STANDARDIR CANONICAL_TEXT PAGES_INDEX PDF GOLDEN RESULT_JSON", file=sys.stderr)
        return 2
    fixture_path, semantic_output, standardir, canonical_text, pages_index, source_pdf, golden, result_path = map(Path, argv[1:])
    root = fixture_path.resolve().parents[2]
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        result = build_result(
            fixture_path.resolve(), fixture, root, source_pdf.resolve(), canonical_text.resolve(), pages_index.resolve(),
            standardir.resolve(), root / fixture["semantic_item"]["path"], semantic_output.resolve(), golden.resolve()
        )
        result_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"M3 C1586 validator: FAIL: {error}", file=sys.stderr)
        return 1
    print("M3 C1586 validator: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
