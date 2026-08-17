#!/usr/bin/env python3
"""Independent validator for the bounded M3 C726 semantic slice."""

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
VALUE_STATES = {"star", "explicit", "unknown"}
CONTEXT_STATES = {
    "dummy-argument",
    "named-constant",
    "allocate-assumed-length-character",
    "type-guard",
    "external-function-character-result",
    "other",
    "unknown",
}
ALLOWED_CONTEXTS = CONTEXT_STATES - {"other", "unknown"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PROPERTY = "type-param-value-star-context-legality"
SOURCE_SPAN = {"byte_start": 217828, "byte_length": 422, "page_start": 84, "page_end": 85}
EXPECTED_CANONICAL_LINES = [
    {"line": 3453, "text": "C726 (R721 R722 R723) A type-param-value of * shall be used only"},
    {"line": 3454, "text": "• to declare a dummy argument,"},
    {"line": 3455, "text": "• to declare a named constant,"},
    {"line": 3456, "text": "• in the type-spec of an ALLOCATE statement wherein each allocate-object is a dummy argument of"},
    {"line": 3457, "text": "type CHARACTER with an assumed character length,"},
    {"line": 3460, "text": "• in the type-spec or derived-type-spec of a type guard statement (11.1.11), or"},
    {"line": 3461, "text": "• in an external function, to declare the character length parameter of the function result."},
]
EXPECTED_PAGE_INDEX = {
    "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index",
    "sha256": PAGE_INDEX_SHA256,
    "pages": [
        {"page": 84, "start": 214997, "length": 3137},
        {"page": 85, "start": 218135, "length": 3925},
    ],
}
EXPECTED_STANDARDIR_ROWS = [
    {"rule": "R721", "lhs": "char-selector", "page": 84, "byte_start": 217200, "byte_length": 251, "occurrence": 71},
    {"rule": "R722", "lhs": "length-selector", "page": 84, "byte_start": 217452, "byte_length": 83, "occurrence": 72},
    {"rule": "R723", "lhs": "char-length", "page": 84, "byte_start": 217536, "byte_length": 70, "occurrence": 73},
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


def c726_oracle(candidate: dict[str, Any]) -> str:
    """Apply only C726's typed star-context relation."""

    value = candidate["type_param_value"]
    context = candidate["context"]
    if value == "explicit":
        return "ACCEPTED"
    if context in ALLOWED_CONTEXTS:
        return "ACCEPTED"
    if value == "star" and context == "other":
        return "REJECTED"
    return "UNRESOLVED"


def validate_candidate(case: dict[str, Any]) -> dict[str, Any]:
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case.get('id', '<missing>')}")
    require(isinstance(case["id"], str) and case["id"], "case id is invalid")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind is invalid")
    require(case["expected"] in OUTCOMES, f"case {case['id']} expected outcome is invalid")
    candidate = case["candidate"]
    require(isinstance(candidate, dict), f"case {case['id']} candidate is not an object")
    exact_keys(candidate, {"fact", "source_rule", "type_param_value", "context"}, f"case {case['id']} candidate")
    require(candidate["fact"] == PROPERTY, f"case {case['id']} candidate fact differs")
    require(candidate["source_rule"] == "C726", f"case {case['id']} source rule differs")
    require(candidate["type_param_value"] in VALUE_STATES, f"case {case['id']} value state is invalid")
    require(candidate["context"] in CONTEXT_STATES, f"case {case['id']} context state is invalid")
    computed = c726_oracle(candidate)
    require(computed == case["expected"], f"case {case['id']} expected outcome disagrees with oracle")
    return {
        "id": case["id"],
        "kind": case["kind"],
        "type_param_value": candidate["type_param_value"],
        "context": candidate["context"],
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
    require(standardir_spec["path"] == ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "StandardIR path differs")
    require(standardir_spec["sha256"] == STANDARDIR_SHA256, "fixture StandardIR hash differs")
    require(standardir_spec["source_hash"] == SOURCE_SHA256, "fixture StandardIR source hash differs")
    require(standardir_spec["rows"] == EXPECTED_STANDARDIR_ROWS, "StandardIR row identity differs")
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
    require(source["canonical_lines"] == EXPECTED_CANONICAL_LINES, "canonical source identity differs")
    lines = canonical_path.read_text(encoding="utf-8").split("\n")
    for item in source["canonical_lines"]:
        number = item["line"]
        require(1 <= number <= len(lines), f"canonical source line is out of range: {number}")
        actual = lines[number - 1].split(maxsplit=1)
        require(len(actual) == 2 and actual[0].isdigit(), f"canonical source line lacks line marker: {number}")
        require(actual[1] == item["text"], f"canonical source text differs at line {number}")


def validate_page_index(source: dict[str, Any], page_index_path: Path) -> None:
    require(digest(page_index_path) == PAGE_INDEX_SHA256, "page index hash differs")
    require(source["page_index"] == EXPECTED_PAGE_INDEX, "page index identity differs")
    text = page_index_path.read_text(encoding="utf-8")
    for page in EXPECTED_PAGE_INDEX["pages"]:
        fragment = f"page {page['page']} start {page['start']} length {page['length']}"
        require(fragment in text, f"page index span differs: {fragment}")
    require(source["source_span"]["page_start"] == 84 and source["source_span"]["page_end"] == 85, "source span page boundary differs")
    require(source["source_span"]["byte_start"] + source["source_span"]["byte_length"] == 218250, "source span endpoint differs")


def validate_semantic_item(doc: dict[str, Any], root: Path, semantic_input: Path) -> None:
    item = doc["semantic_item"]
    exact_keys(item, {"path", "sha256", "id", "subject", "document", "clause", "rule", "page", "source_hash", "origin", "resolution"}, "semantic item")
    expected_path = root / item["path"]
    require(semantic_input.resolve() == expected_path.resolve(), "semantic-items path differs")
    require(digest(expected_path) == item["sha256"], "semantic-items input hash differs")
    text = expected_path.read_text(encoding="utf-8").strip()
    for fragment in (
        f"(id {item['id']})",
        f"(subject {item['subject']})",
        f"(document {item['document']})",
        f"(clause {item['clause']})",
        f"(rule {item['rule']})",
        f"(page {item['page']})",
        f"(source-hash {item['source_hash']})",
        f"(origin {item['origin']})",
        f"(resolution {item['resolution']})",
    ):
        require(fragment in text, f"semantic-items input lacks {fragment}")


def validate_contract(doc: dict[str, Any], root: Path) -> None:
    schema = (root / doc["contract"]["schema"]).read_text(encoding="utf-8")
    for fragment in (
        "(enum outcome accepted rejected unresolved)",
        "(enum type-param-value-state star explicit unknown)",
        "(enum c726-context-state dummy-argument named-constant allocate-assumed-length-character type-guard external-function-character-result other unknown)",
        "(record type-param-star-use",
        "(record semantic-candidate",
    ):
        require(fragment in schema, f"contract schema lacks {fragment}")
    witness = (root / doc["contract"]["fixture"]).read_text(encoding="utf-8")
    for fragment in (
        "(contract m3-c726-type-param-star-context-oracle)",
        "(property type-param-value-star-context-legality)",
        "(document J3-24-007)",
        "(clause 7)",
        "(rule C726)",
        "(page 84)",
        "(byte-start 217828)",
        "(byte-length 422)",
        "(page-start 84)",
        "(page-end 85)",
        "(source-hash " + SOURCE_SHA256 + ")",
    ):
        require(fragment in witness, f"contract fixture lacks {fragment}")


def validate_source_binding(
    doc: dict[str, Any],
    root: Path,
    source_pdf: Path,
    canonical_path: Path,
    page_index_path: Path,
    standardir_path: Path,
    semantic_input: Path,
) -> None:
    exact_keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"}, "fixture")
    require(doc["schema_version"] == "m3-c726-source-backed-v0", "fixture schema version differs")
    require(doc["origin"] == "HUMAN", "fixture origin is not HUMAN")
    require(doc["property"] == PROPERTY, "fixture property differs")
    validate_contract(doc, root)
    source = doc["source"]
    require(source["document"] == "J3-24-007", "source document differs")
    require(source["clause"] == "7", "source clause differs")
    require(source["rule"] == "C726", "source rule differs")
    require(source["printed_page"] == 84, "source printed page differs")
    require(source["pdf_sha256"] == PDF_SHA256, "fixture PDF hash differs")
    require(source["canonical_text_sha256"] == SOURCE_SHA256, "fixture canonical hash differs")
    require(source["canonical_text"] == ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", "canonical path differs")
    require(canonical_path.resolve() == (root / source["canonical_text"]).resolve(), "canonical input path differs")
    require(page_index_path.resolve() == (root / source["page_index"]["path"]).resolve(), "page-index input path differs")
    require(source["source_span"] == SOURCE_SPAN, "source span differs")
    manifest = tomllib.loads((root / "artifacts/standards/j3-24-007.toml").read_text(encoding="utf-8"))
    require(manifest["sha256"] == PDF_SHA256, "standard manifest hash differs")
    require(manifest["bytes"] == source_pdf.stat().st_size, "standard manifest byte count differs")
    require(digest(source_pdf) == PDF_SHA256, "normative PDF hash differs")
    validate_canonical_lines(source, canonical_path)
    validate_page_index(source, page_index_path)
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


def validate_shape(doc: dict[str, Any]) -> None:
    require(isinstance(doc["cases"], list) and len(doc["cases"]) == 21, "fixture case count differs")
    results = [validate_candidate(case) for case in doc["cases"]]
    require({(item["type_param_value"], item["context"]) for item in results} == {(value, context) for value in VALUE_STATES for context in CONTEXT_STATES}, "C726 21-state table is incomplete")
    require({item["kind"] for item in results} == {"positive", "negative", "unresolved"}, "fixture witness kinds are incomplete")
    require(sum(item["kind"] == "negative" for item in results) == 1, "negative witness count differs")
    require(sum(item["kind"] == "unresolved" for item in results) == 3, "unresolved witness count differs")
    require(len(doc["mutations"]) == 12, "mutation control count differs")
    for mutation in doc["mutations"]:
        exact_keys(mutation, {"id", "path", "value"}, f"mutation {mutation.get('id', '<missing>')}")
        require(isinstance(mutation["path"], list) and mutation["path"], "mutation path is invalid")


def build_result(
    fixture_path: Path,
    fixture: dict[str, Any],
    root: Path,
    source_pdf: Path,
    canonical_path: Path,
    page_index_path: Path,
    standardir_path: Path,
    semantic_input: Path,
    semantic_output: Path,
    golden: Path,
    output: Path,
) -> dict[str, Any]:
    validate_shape(fixture)
    validate_source_binding(fixture, root, source_pdf, canonical_path, page_index_path, standardir_path, semantic_input)
    require(semantic_output.read_bytes() == semantic_input.read_bytes(), "canonical semantic-items output differs from input")
    require(semantic_output.read_bytes() == golden.read_bytes(), "canonical semantic-items output differs from golden")
    cases = [validate_candidate(case) for case in fixture["cases"]]
    mutations = []
    for mutation in fixture["mutations"]:
        mutated = copy.deepcopy(fixture)
        set_path(mutated, mutation["path"], mutation["value"])
        try:
            validate_source_binding(mutated, root, source_pdf, canonical_path, page_index_path, standardir_path, semantic_input)
        except (ContractError, OSError, KeyError, TypeError, ValueError):
            mutations.append({"id": mutation["id"], "result": "REJECTED"})
        else:
            raise ContractError(f"mutation control was accepted: {mutation['id']}")
    counts = {outcome: sum(case["computed"] == outcome for case in cases) for outcome in sorted(OUTCOMES)}
    result = {
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
            "page_index_sha256": digest(page_index_path),
            "standardir_sha256": digest(standardir_path),
            "canonical_lines": [item["line"] for item in fixture["source"]["canonical_lines"]],
            "source_span": fixture["source"]["source_span"],
            "page_index": fixture["source"]["page_index"],
            "standardir_rules": [row["rule"] for row in fixture["source"]["standardir"]["rows"]],
        },
        "semantic_items": {
            "input": fixture["semantic_item"]["path"],
            "input_sha256": digest(semantic_input),
            "canonical_output_sha256": digest(semantic_output),
            "canonical_output": "PASS",
        },
        "cases": cases,
        "outcome_counts": counts,
        "mutation_controls": mutations,
        "model_calls": 0,
        "semantic_promotions": 0,
        "candidate_promotion": "BOUNDED_ONLY",
        "full_m3": "OPEN",
        "origin": "MECHANICAL",
        "oracle": "tests/e2e/validate_m3_c726.py",
    }
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


def self_test() -> None:
    expected = {}
    for value in VALUE_STATES:
        for context in CONTEXT_STATES:
            candidate = {"type_param_value": value, "context": context}
            expected[(value, context)] = c726_oracle(candidate)
    require(len(expected) == 21, "self-test state count differs")
    require(expected[("star", "dummy-argument")] == "ACCEPTED", "allowed star state differs")
    require(expected[("star", "other")] == "REJECTED", "disallowed star state differs")
    require(expected[("star", "unknown")] == "UNRESOLVED", "unknown star state differs")
    require(expected[("explicit", "other")] == "ACCEPTED", "explicit state differs")
    require(expected[("unknown", "named-constant")] == "ACCEPTED", "allowed unknown state differs")
    require(expected[("unknown", "other")] == "UNRESOLVED", "unknown value state differs")
    print("M3 C726 oracle self-test: PASS")


def main(argv: list[str]) -> int:
    if argv[1:] == ["--self-test"]:
        self_test()
        return 0
    if len(argv) != 9:
        print("usage: validate_m3_c726.py FIXTURE SEMANTIC_OUTPUT STANDARDIR CANONICAL_TEXT PAGE_INDEX PDF GOLDEN RESULT_JSON", file=sys.stderr)
        return 2
    fixture_path, semantic_output, standardir, canonical, page_index, pdf, golden, result_path = map(Path, argv[1:])
    root = fixture_path.resolve().parents[2]
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        build_result(
            fixture_path.resolve(),
            fixture,
            root,
            pdf.resolve(),
            canonical.resolve(),
            page_index.resolve(),
            standardir.resolve(),
            root / fixture["semantic_item"]["path"],
            semantic_output.resolve(),
            golden.resolve(),
            result_path.resolve(),
        )
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"M3 C726 validator: FAIL: {error}", file=sys.stderr)
        return 1
    print("M3 C726 validator: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
