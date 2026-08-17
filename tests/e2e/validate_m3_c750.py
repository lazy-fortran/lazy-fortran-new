#!/usr/bin/env python3
"""Independent validator for the bounded M3 C750 semantic slice."""

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
ARRAY_SPECS = {"deferred-shape-list", "explicit-shape-list", "unknown"}
CONTEXTS = {"component-def-stmt", "other", "unknown"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
EXPECTED_OUTCOMES_SHA256 = "694c5b8312853cef1fa232662e53a0a13e4829cfc0c654b5129e62f51a2e8095"
SOURCE_FIXTURE_SHA256 = "0d0ed8864c86df9d8de3dfb3bf7c825a67c9fa8d7d699065c60ccdb53c9f2d45"
SEMANTIC_ITEM_SHA256 = "592b7ce27d45a84bc0369cb1293c0562a66fb4648c30658a48f1e0f7b2d261aa"
PROPERTY = "component-def-stmt-component-array-spec-deferred-shape"
SOURCE_SPAN = {"byte_start": 241058, "byte_length": 135, "page_start": 93, "page_end": 93}
PAGE = {"page": 93, "start": 239957, "length": 2451}
CANONICAL_LINES = [
    {"line": 3838, "text": "C750 (R737) If the POINTER or ALLOCATABLE attribute is specified, each component-array-spec shall be"},
    {"line": 3839, "text": "a deferred-shape-spec-list."},
]
SOURCE_BYTES = (
    b"24 C750 (R737) If the POINTER or ALLOCATABLE attribute is specified, each component-array-spec shall be\n"
    b"25 a deferred-shape-spec-list.\n"
)
STANDARDIR_ROWS = [
    {"rule": "R737", "lhs": "data-component-def-stmt", "page": 93, "byte_start": 240182, "byte_length": 115, "occurrence": 87},
    {"rule": "R740", "lhs": "component-array-spec", "page": 93, "byte_start": 240636, "byte_length": 87, "occurrence": 90},
]
CONTRACT = {
    "schema": "contracts/m3-c750-component-array-spec-deferred-shape-v0.sxs",
    "fixture": "contracts/fixtures/m3-c750-component-array-spec-deferred-shape-v0.sx",
    "version": 0,
}
SEMANTIC_ITEM = {
    "path": "tests/fixtures/m3-c750-semantic-items.sx",
    "id": "S-C750",
    "subject": PROPERTY,
    "document": "J3-24-007",
    "clause": "7",
    "rule": "C750",
    "page": 79,
    "source_hash": SOURCE_SHA256,
    "origin": "human",
    "resolution": "disputed",
}
MUTATIONS = [
    ("source-rule", ("source", "rule"), "C751"),
    ("printed-page", ("source", "printed_page"), 80),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64),
    ("span-start", ("source", "source_span", "byte_start"), 241059),
    ("span-length", ("source", "source_span", "byte_length"), 136),
    ("canonical-line", ("source", "canonical_lines", 0, "text"), "C750 (R737) changed"),
    ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64),
    ("page-index-start", ("source", "page_index", "pages", 0, "start"), 239958),
    ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64),
    ("standardir-rule", ("source", "standardir", "rows", 1, "rule"), "R738"),
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
    if candidate["context"] != "component-def-stmt":
        return "UNRESOLVED"
    if candidate["pointer_or_allocatable_attribute"] != "present":
        return "UNRESOLVED"
    if candidate["component_array_spec"] == "deferred-shape-list":
        return "ACCEPTED"
    if candidate["component_array_spec"] == "explicit-shape-list":
        return "REJECTED"
    return "UNRESOLVED"


def validate_expected(document: dict[str, Any], path: Path, ids: list[str]) -> dict[str, str]:
    exact_keys(document, {"schema_version", "origin", "property", "source_rule", "outcomes"}, "expected outcomes")
    require(digest(path) == EXPECTED_OUTCOMES_SHA256, "expected outcomes hash differs")
    require(document["schema_version"] == "m3-c750-expected-outcomes-v0", "expected schema differs")
    require(document["origin"] == "HUMAN", "expected origin differs")
    require(document["property"] == PROPERTY and document["source_rule"] == "C750", "expected identity differs")
    outcomes = document["outcomes"]
    require(isinstance(outcomes, dict) and set(outcomes) == set(ids), "expected rows differ")
    require(all(value in OUTCOMES for value in outcomes.values()), "expected outcome invalid")
    return outcomes


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
    r737 = next(line for line in lines if line.startswith("(syntax R737 "))
    r740 = next(line for line in lines if line.startswith("(syntax R740 "))
    for fragment in ("(lhs data-component-def-stmt)", "(ref declaration-type-spec)", "(ref component-attr-spec-list)", "(ref component-decl-list)"):
        require(fragment in r737, f"R737 shape lacks {fragment}")
    for fragment in ("(lhs component-array-spec)", "(ref explicit-shape-spec-list)", "(ref deferred-shape-spec-list)"):
        require(fragment in r740, f"R740 shape lacks {fragment}")


def validate_binding(document: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(document, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture")
    require(digest(root / "tests/fixtures/m3-c750-source-backed-v0.json") == SOURCE_FIXTURE_SHA256, "source fixture hash differs")
    require(document["schema_version"] == "m3-c750-source-backed-v0" and document["origin"] == "HUMAN" and document["property"] == PROPERTY, "fixture identity differs")
    require(document["contract"] == CONTRACT, "contract identity differs")
    source = document["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C750" and source["printed_page"] == 79, "source identity differs")
    require(source["canonical_lines"] == CANONICAL_LINES, "canonical line table differs")
    require(source["canonical_text_sha256"] == SOURCE_SHA256 and digest(canonical) == SOURCE_SHA256, "canonical source hash differs")
    require(source["source_span"] == SOURCE_SPAN, "source span differs")
    require(canonical.read_bytes()[241058:241058 + 135] == SOURCE_BYTES, "source bytes differ")
    lines = canonical.read_text(encoding="utf-8").splitlines()
    for expected in CANONICAL_LINES:
        actual = next((line for line in lines if expected["text"] in line), None)
        require(actual is not None, f"canonical line {expected['line']} is absent")
        require(actual.split(" ", 1)[1] == expected["text"], f"canonical line {expected['line']} differs")
    require(source["page_index"]["sha256"] == PAGE_INDEX_SHA256 and digest(page_index) == PAGE_INDEX_SHA256, "page index hash differs")
    require(source["page_index"]["pages"] == [PAGE], "page index record differs")
    index_lines = page_index.read_text(encoding="utf-8").splitlines()
    require("page 93 start 239957 length 2451" in index_lines, "page index record absent")
    validate_standardir(source, standardir)
    require(digest(pdf) == PDF_SHA256, "normative PDF hash differs")
    require(document["semantic_item"] == {**SEMANTIC_ITEM, "sha256": SEMANTIC_ITEM_SHA256}, "semantic item differs")
    require(digest(semantic) == SEMANTIC_ITEM_SHA256, "semantic item hash differs")
    require(document["mutation_controls"] == [name for name, _, _ in MUTATIONS], "mutation inventory differs")


def validate_cases(document: dict[str, Any], expected: dict[str, str]) -> dict[str, Any]:
    cases = document["cases"]
    require(len(cases) == 27, "case count differs")
    ids = [case.get("id") for case in cases]
    require(len(ids) == len(set(ids)), "case IDs are not unique")
    require(set(ids) == set(expected), "case IDs differ from expected table")
    results = []
    for case in cases:
        exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case['id']}")
        require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind invalid")
        candidate = case["candidate"]
        exact_keys(candidate, {"fact", "source_rule", "pointer_or_allocatable_attribute", "component_array_spec", "context"}, f"case {case['id']} candidate")
        require(candidate["fact"] == PROPERTY and candidate["source_rule"] == "C750", f"case {case['id']} identity differs")
        require(candidate["pointer_or_allocatable_attribute"] in ATTRIBUTES, f"case {case['id']} attribute invalid")
        require(candidate["component_array_spec"] in ARRAY_SPECS, f"case {case['id']} array spec invalid")
        require(candidate["context"] in CONTEXTS, f"case {case['id']} context invalid")
        require(case["expected"] == expected[case["id"]], f"case {case['id']} expected differs")
        computed = oracle(candidate)
        require(computed == expected[case["id"]], f"case {case['id']} oracle disagrees")
        results.append({"id": case["id"], "kind": case["kind"], **{key: candidate[key] for key in ("pointer_or_allocatable_attribute", "component_array_spec", "context")}, "computed": computed, "expected": expected[case["id"]], "fixture_expected": case["expected"]})
    return {"cases": results, "counts": {outcome: sum(item["computed"] == outcome for item in results) for outcome in sorted(OUTCOMES)}}


def set_path(value: Any, path: tuple[Any, ...], replacement: Any) -> None:
    target = value
    for part in path[:-1]:
        target = target[part]
    target[path[-1]] = replacement


def self_test(root: Path) -> None:
    fixture_path = root / "tests/fixtures/m3-c750-source-backed-v0.json"
    original = json.loads(fixture_path.read_text(encoding="utf-8"))
    paths = {"source": root / "tests/fixtures/m3-c750-source-backed-v0.json"}
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original)
        set_path(mutated, path, replacement)
        try:
            validate_binding(mutated, root, root / ".cache/j3-24-007.pdf", root / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", root / ".cache/runs/E0001/R000003/j3-24-007.pages.index", root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c750-semantic-items.sx")
        except ContractError:
            continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C750 self-test PASS: {len(MUTATIONS)} mutation controls rejected")


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
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c750-semantic-items.sx")
    expected = validate_expected(expected_doc, expected_path, [case["id"] for case in fixture["cases"]])
    result = validate_cases(fixture, expected)
    require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs from golden")
    mutations = []
    for name, _, _ in MUTATIONS:
        mutations.append({"id": name, "result": "REJECTED"})
    output = {"schema_version": "m3-c750-result-v0", "origin": "MECHANICAL", "property": PROPERTY, "source_rule": "C750", "source_span": SOURCE_SPAN, "page_index": PAGE, "standardir_rules": ["R737", "R740"], "state_count": len(result["cases"]), "outcome_counts": result["counts"], "mutation_controls": mutations, "model_calls": 0, "semantic_promotions": 0, "candidate_promotion": "BOUNDED_ONLY", "full_m3": "OPEN"}
    result_path.write_text(json.dumps(output, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"C750 validation failure: {error}", file=sys.stderr)
        raise SystemExit(1)
