#!/usr/bin/env python3
"""Independent validator for the bounded M3 C754 semantic slice."""

from __future__ import annotations

import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
ATTRIBUTES = {"absent", "present", "unknown"}
SHAPES = {"explicit-shape-list", "deferred-shape-list", "unknown"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
EXPECTED_OUTCOMES_SHA256 = "2292e590eb65aa35bf46f64d6f953f6ca6fea1cae0c1abb55d9384ee00d321dc"
SOURCE_FIXTURE_SHA256 = "78a03ef7ef5189f9138134a7955b7703b10e08c07c05d237826c334591775f3c"
SEMANTIC_ITEM_SHA256 = "61f2f24b66964ac1bcef9c8ff03b0886cf6caaebb120bffb8af0e6fad918d5f1"
PROPERTY = "component-c754-array-spec"
SOURCE_SPAN = {"byte_start": 241715, "byte_length": 150, "page_start": 93, "page_end": 93}
PAGE_INDEX = [{"page": 93, "start": 239957, "length": 2451}]
CANONICAL_LINES = [
    {"line": 3847, "text": "C754 (R737) If neither the POINTER nor the ALLOCATABLE attribute is specified, each component-array-"},
    {"line": 3848, "text": "spec shall be an explicit-shape-spec-list."},
]
SOURCE_BYTES = (
    b"33 C754 (R737) If neither the POINTER nor the ALLOCATABLE attribute is specified, each component-array-\n"
    b"34 spec shall be an explicit-shape-spec-list.\n"
)
STANDARDIR_ROWS = [
    {"rule": "R737", "lhs": "data-component-def-stmt", "page": 93, "byte_start": 240182, "byte_length": 115, "occurrence": 87},
    {"rule": "R738", "lhs": "component-attr-spec", "page": 93, "byte_start": 240298, "byte_length": 179, "occurrence": 88},
    {"rule": "R739", "lhs": "component-decl", "page": 93, "byte_start": 240478, "byte_length": 157, "occurrence": 89},
    {"rule": "R740", "lhs": "component-array-spec", "page": 93, "byte_start": 240636, "byte_length": 87, "occurrence": 90},
]
CONTRACT = {"schema": "contracts/m3-c754-component-array-spec-v0.sxs", "fixture": "contracts/fixtures/m3-c754-component-array-spec-v0.sx", "version": 0}
SEMANTIC_ITEM = {"path": "tests/fixtures/m3-c754-semantic-items.sx", "id": "S-C754", "subject": PROPERTY, "document": "J3-24-007", "clause": "7", "rule": "C754", "page": 79, "source_hash": SOURCE_SHA256, "origin": "human", "resolution": "disputed"}
MUTATIONS = [
    ("source-rule", ("source", "rule"), "C753"),
    ("printed-page", ("source", "printed_page"), 80),
    ("pdf-hash", ("source", "pdf_sha256"), "0" * 64),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64),
    ("span-start", ("source", "source_span", "byte_start"), 241716),
    ("span-length", ("source", "source_span", "byte_length"), 151),
    ("canonical-line", ("source", "canonical_lines", 0, "text"), "C754 (R737) changed"),
    ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64),
    ("page-index-start", ("source", "page_index", "pages", 0, "start"), 239958),
    ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64),
    ("standardir-rule", ("source", "standardir", "rows", 1, "rule"), "R736"),
    ("semantic-item-hash", ("semantic_item", "source_hash"), "0" * 64),
    ("contract-version", ("contract", "version"), 1),
]


class ContractError(Exception):
    pass


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    require(set(value) == expected, f"{label} keys differ")


def oracle(candidate: dict[str, str]) -> str:
    pointer = candidate["pointer_attribute"]
    allocatable = candidate["allocatable_attribute"]
    shape = candidate["component_array_spec"]
    if pointer == "present" or allocatable == "present":
        return "ACCEPTED"
    if shape == "explicit-shape-list":
        return "ACCEPTED"
    if pointer == "absent" and allocatable == "absent" and shape == "deferred-shape-list":
        return "REJECTED"
    return "UNRESOLVED"


def standardir_field(line: str, pattern: str, label: str) -> str:
    match = re.search(pattern, line)
    if match is None:
        raise ContractError(f"StandardIR row has no {label}")
    return match.group(1)


def validate_standardir(source: dict[str, Any], path: Path) -> None:
    require(digest(path) == STANDARDIR_SHA256, "StandardIR hash differs")
    expected = {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "sha256": STANDARDIR_SHA256, "source_hash": SOURCE_SHA256, "rows": STANDARDIR_ROWS}
    require(source["standardir"] == expected, "StandardIR fixture identity differs")
    lines = path.read_text(encoding="utf-8").splitlines()
    for row in STANDARDIR_ROWS:
        matching = [line for line in lines if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matching) == 1, f"expected one {row['rule']} row")
        line = matching[0]
        require(standardir_field(line, r"\(lhs ([^)]+)\)", "lhs") == row["lhs"], f"{row['rule']} lhs differs")
        require(int(standardir_field(line, r"\(page (\d+)\)", "page")) == row["page"], f"{row['rule']} page differs")
        require(int(standardir_field(line, r"\(byte-start (\d+)\)", "byte-start")) == row["byte_start"], f"{row['rule']} start differs")
        require(int(standardir_field(line, r"\(byte-length (\d+)\)", "byte-length")) == row["byte_length"], f"{row['rule']} length differs")
        require(int(standardir_field(line, r"\(occurrence (\d+)\)", "occurrence")) == row["occurrence"], f"{row['rule']} occurrence differs")
        require(standardir_field(line, r"\(source-sha256 ([^)]+)\)", "source hash") == SOURCE_SHA256, f"{row['rule']} source hash differs")
    fragments = {
        "R737": ("(lhs data-component-def-stmt)", "(ref component-decl-list)"),
        "R738": ("(lhs component-attr-spec)", "(token ALLOCATABLE)", "(token POINTER)", "(ref component-array-spec)"),
        "R739": ("(lhs component-decl)", "(ref component-array-spec)"),
        "R740": ("(lhs component-array-spec)", "(ref explicit-shape-spec-list)", "(ref deferred-shape-spec-list)"),
    }
    for rule, required in fragments.items():
        line = next(line for line in lines if line.startswith(f"(syntax {rule} "))
        for fragment in required:
            require(fragment in line, f"{rule} shape lacks {fragment}")


def validate_binding(document: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(document, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture")
    require(digest(root / "tests/fixtures/m3-c754-source-backed-v0.json") == SOURCE_FIXTURE_SHA256, "source fixture hash differs")
    require(document["schema_version"] == "m3-c754-source-backed-v0" and document["origin"] == "HUMAN" and document["property"] == PROPERTY, "fixture identity differs")
    require(document["contract"] == CONTRACT, "contract identity differs")
    source = document["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C754" and source["printed_page"] == 79, "source identity differs")
    require(source["canonical_lines"] == CANONICAL_LINES, "canonical line table differs")
    require(source["canonical_text_sha256"] == SOURCE_SHA256 and digest(canonical) == SOURCE_SHA256, "canonical source hash differs")
    require(source["source_span"] == SOURCE_SPAN, "source span differs")
    require(canonical.read_bytes()[241715:241715 + 150] == SOURCE_BYTES, "source bytes differ")
    lines = canonical.read_text(encoding="utf-8").splitlines()
    for expected in CANONICAL_LINES:
        actual = next((line for line in lines if expected["text"] in line), None)
        require(actual is not None and actual.split(" ", 1)[1] == expected["text"], f"canonical line {expected['line']} differs")
    require(source["page_index"]["sha256"] == PAGE_INDEX_SHA256 and digest(page_index) == PAGE_INDEX_SHA256, "page index hash differs")
    require(source["page_index"]["pages"] == PAGE_INDEX, "page index record differs")
    index_lines = page_index.read_text(encoding="utf-8").splitlines()
    for page in PAGE_INDEX:
        require(f"page {page['page']} start {page['start']} length {page['length']}" in index_lines, f"page index record {page['page']} absent")
    validate_standardir(source, standardir)
    require(source["pdf_sha256"] == PDF_SHA256 and digest(pdf) == PDF_SHA256, "normative PDF hash differs")
    require(document["semantic_item"] == {**SEMANTIC_ITEM, "sha256": SEMANTIC_ITEM_SHA256}, "semantic item differs")
    require(digest(semantic) == SEMANTIC_ITEM_SHA256, "semantic item hash differs")
    require(document["mutation_controls"] == [name for name, _, _ in MUTATIONS], "mutation inventory differs")


def validate_expected(document: dict[str, Any], path: Path, ids: list[str]) -> dict[str, str]:
    exact_keys(document, {"schema_version", "origin", "property", "source_rule", "outcomes"}, "expected outcomes")
    require(digest(path) == EXPECTED_OUTCOMES_SHA256, "expected outcomes hash differs")
    require(document["schema_version"] == "m3-c754-expected-outcomes-v0" and document["origin"] == "HUMAN" and document["property"] == PROPERTY and document["source_rule"] == "C754", "expected identity differs")
    outcomes = document["outcomes"]
    require(isinstance(outcomes, dict) and set(outcomes) == set(ids), "expected rows differ")
    require(all(value in OUTCOMES for value in outcomes.values()), "expected outcome invalid")
    return outcomes


def validate_cases(document: dict[str, Any], expected: dict[str, str]) -> dict[str, Any]:
    cases = document["cases"]
    require(len(cases) == 27, "case count differs")
    ids = [case.get("id") for case in cases]
    require(len(ids) == len(set(ids)) and set(ids) == set(expected), "case IDs differ")
    results = []
    for case in cases:
        exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case['id']}")
        candidate = case["candidate"]
        exact_keys(candidate, {"fact", "source_rule", "pointer_attribute", "allocatable_attribute", "component_array_spec"}, f"case {case['id']} candidate")
        require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind invalid")
        require(candidate["fact"] == PROPERTY and candidate["source_rule"] == "C754", f"case {case['id']} identity differs")
        require(candidate["pointer_attribute"] in ATTRIBUTES and candidate["allocatable_attribute"] in ATTRIBUTES and candidate["component_array_spec"] in SHAPES, f"case {case['id']} field invalid")
        require(case["expected"] == expected[case["id"]], f"case {case['id']} expected differs")
        computed = oracle(candidate)
        require(computed == expected[case["id"]], f"case {case['id']} oracle disagrees")
        expected_kind = {"ACCEPTED": "positive", "REJECTED": "negative", "UNRESOLVED": "unresolved"}[computed]
        require(case["kind"] == expected_kind, f"case {case['id']} kind disagrees")
        results.append({"id": case["id"], "kind": case["kind"], "pointer_attribute": candidate["pointer_attribute"], "allocatable_attribute": candidate["allocatable_attribute"], "component_array_spec": candidate["component_array_spec"], "computed": computed, "expected": expected[case["id"]]})
    return {"cases": results, "counts": {outcome: sum(item["computed"] == outcome for item in results) for outcome in sorted(OUTCOMES)}}


def set_path(value: Any, path: tuple[Any, ...], replacement: Any) -> None:
    target = value
    for part in path[:-1]:
        target = target[part]
    target[path[-1]] = replacement


def self_test(root: Path) -> None:
    fixture_path = root / "tests/fixtures/m3-c754-source-backed-v0.json"
    original = json.loads(fixture_path.read_text(encoding="utf-8"))
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original)
        set_path(mutated, path, replacement)
        try:
            validate_binding(mutated, root, root / ".cache/j3-24-007.pdf", root / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", root / ".cache/runs/E0001/R000003/j3-24-007.pages.index", root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c754-semantic-items.sx")
        except ContractError:
            continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C754 self-test PASS: {len(MUTATIONS)} mutation controls rejected")


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test(Path(__file__).resolve().parents[2])
        return 0
    if len(sys.argv) != 10:
        raise ContractError("usage: validator.py fixture expected semantic-canonical standardir canonical page-index pdf golden result")
    root = Path(__file__).resolve().parents[2]
    fixture_path, expected_path, semantic_canonical, standardir, canonical, page_index, pdf, golden, result_path = map(Path, sys.argv[1:])
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
    expected_doc = json.loads(expected_path.read_text(encoding="utf-8"))
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c754-semantic-items.sx")
    expected = validate_expected(expected_doc, expected_path, [case["id"] for case in fixture["cases"]])
    result = validate_cases(fixture, expected)
    require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs from golden")
    mutations = [{"id": name, "result": "REJECTED"} for name, _, _ in MUTATIONS]
    output = {"schema_version": "m3-c754-result-v0", "origin": "MECHANICAL", "property": PROPERTY, "source_rule": "C754", "source_span": SOURCE_SPAN, "page_index": PAGE_INDEX[0], "standardir_rules": [row["rule"] for row in STANDARDIR_ROWS], "state_count": len(result["cases"]), "outcome_counts": result["counts"], "mutation_controls": mutations, "model_calls": 0, "semantic_promotions": 0, "candidate_promotion": "BOUNDED_ONLY", "full_m3": "OPEN"}
    result_path.write_text(json.dumps(output, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"C754 validation failure: {error}", file=sys.stderr)
        raise SystemExit(1)
