#!/usr/bin/env python3
"""Independent validator for the bounded M3 C752 semantic slice."""

from __future__ import annotations

import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
SPECS = {"absent", "present", "unknown"}
TYPES = {"C_PTR", "C_FUNPTR", "TEAM_TYPE", "other", "unknown"}
FORBIDDEN_TYPES = {"C_PTR", "C_FUNPTR", "TEAM_TYPE"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
EXPECTED_OUTCOMES_SHA256 = "9fd60d9134b5a073f2b460041ea08a0fbc6c010c6fa20077857f87f5bd456c56"
SOURCE_FIXTURE_SHA256 = "b3e48765c9bf5a236f1e71d7dd1b2b62b6e709235de1999dd8a9de3ed4376b43"
SEMANTIC_ITEM_SHA256 = "b64aeab421960c9f8d62090a7402793fe6ad2b0aa13919f2939263f1c3e9e316"
PROPERTY = "component-c752-forbidden-coarray-type"
SOURCE_SPAN = {"byte_start": 241335, "byte_length": 223, "page_start": 93, "page_end": 93}
PAGE_INDEX = [{"page": 93, "start": 239957, "length": 2451}]
CANONICAL_LINES = [
    {"line": 3842, "text": "C752 (R737) If a coarray-spec appears, the component shall not be of type C_PTR or C_FUNPTR from"},
    {"line": 3843, "text": "the intrinsic module ISO_C_BINDING (18.2), or of type TEAM_TYPE from the intrinsic module"},
    {"line": 3844, "text": "ISO_FORTRAN_ENV (16.10.2)."},
]
SOURCE_BYTES = (
    b"28 C752 (R737) If a coarray-spec appears, the component shall not be of type C_PTR or C_FUNPTR from\n"
    b"29 the intrinsic module ISO_C_BINDING (18.2), or of type TEAM_TYPE from the intrinsic module\n"
    b"30 ISO_FORTRAN_ENV (16.10.2).\n"
)
STANDARDIR_ROWS = [
    {"rule": "R702", "lhs": "type-spec", "page": 77, "byte_start": 196903, "byte_length": 113, "occurrence": 52},
    {"rule": "R703", "lhs": "declaration-type-spec", "page": 77, "byte_start": 197098, "byte_length": 309, "occurrence": 53},
    {"rule": "R704", "lhs": "intrinsic-type-spec", "page": 80, "byte_start": 205210, "byte_length": 195, "occurrence": 54},
    {"rule": "R737", "lhs": "data-component-def-stmt", "page": 93, "byte_start": 240182, "byte_length": 115, "occurrence": 87},
    {"rule": "R739", "lhs": "component-decl", "page": 93, "byte_start": 240478, "byte_length": 157, "occurrence": 89},
]
CONTRACT = {"schema": "contracts/m3-c752-forbidden-coarray-type-v0.sxs", "fixture": "contracts/fixtures/m3-c752-forbidden-coarray-type-v0.sx", "version": 0}
SEMANTIC_ITEM = {"path": "tests/fixtures/m3-c752-semantic-items.sx", "id": "S-C752", "subject": PROPERTY, "document": "J3-24-007", "clause": "7", "rule": "C752", "page": 79, "source_hash": SOURCE_SHA256, "origin": "human", "resolution": "unwitnessed"}
MUTATIONS = [
    ("source-rule", ("source", "rule"), "C751"),
    ("printed-page", ("source", "printed_page"), 80),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64),
    ("span-start", ("source", "source_span", "byte_start"), 241336),
    ("span-length", ("source", "source_span", "byte_length"), 224),
    ("canonical-line", ("source", "canonical_lines", 0, "text"), "C752 (R737) changed"),
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
    spec = candidate["coarray_spec"]
    component_type = candidate["component_type"]
    if spec == "absent":
        return "ACCEPTED"
    if spec == "present":
        if component_type in FORBIDDEN_TYPES:
            return "REJECTED"
        if component_type == "other":
            return "ACCEPTED"
        return "UNRESOLVED"
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
        "R702": ("(lhs type-spec)", "(ref intrinsic-type-spec)", "(ref derived-type-spec)"),
        "R703": ("(lhs declaration-type-spec)", "(ref intrinsic-type-spec)", "(ref derived-type-spec)"),
        "R704": ("(lhs intrinsic-type-spec)", "(ref integer-type-spec)", "(token REAL)", "(token CHARACTER)"),
        "R737": ("(lhs data-component-def-stmt)", "(ref component-decl-list)"),
        "R739": ("(lhs component-decl)", "(ref coarray-spec)"),
    }
    for rule, required in fragments.items():
        line = next(line for line in lines if line.startswith(f"(syntax {rule} "))
        for fragment in required:
            require(fragment in line, f"{rule} shape lacks {fragment}")


def validate_binding(document: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(document, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture")
    require(digest(root / "tests/fixtures/m3-c752-source-backed-v0.json") == SOURCE_FIXTURE_SHA256, "source fixture hash differs")
    require(document["schema_version"] == "m3-c752-source-backed-v0" and document["origin"] == "HUMAN" and document["property"] == PROPERTY, "fixture identity differs")
    require(document["contract"] == CONTRACT, "contract identity differs")
    source = document["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C752" and source["printed_page"] == 79, "source identity differs")
    require(source["canonical_lines"] == CANONICAL_LINES, "canonical line table differs")
    require(source["canonical_text_sha256"] == SOURCE_SHA256 and digest(canonical) == SOURCE_SHA256, "canonical source hash differs")
    require(source["source_span"] == SOURCE_SPAN, "source span differs")
    require(canonical.read_bytes()[241335:241335 + 223] == SOURCE_BYTES, "source bytes differ")
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
    require(digest(pdf) == PDF_SHA256, "normative PDF hash differs")
    require(document["semantic_item"] == {**SEMANTIC_ITEM, "sha256": SEMANTIC_ITEM_SHA256}, "semantic item differs")
    require(digest(semantic) == SEMANTIC_ITEM_SHA256, "semantic item hash differs")
    require(document["mutation_controls"] == [name for name, _, _ in MUTATIONS], "mutation inventory differs")


def validate_expected(document: dict[str, Any], path: Path, ids: list[str]) -> dict[str, str]:
    exact_keys(document, {"schema_version", "origin", "property", "source_rule", "outcomes"}, "expected outcomes")
    require(digest(path) == EXPECTED_OUTCOMES_SHA256, "expected outcomes hash differs")
    require(document["schema_version"] == "m3-c752-expected-outcomes-v0", "expected schema differs")
    require(document["origin"] == "HUMAN" and document["property"] == PROPERTY and document["source_rule"] == "C752", "expected identity differs")
    outcomes = document["outcomes"]
    require(isinstance(outcomes, dict) and set(outcomes) == set(ids), "expected rows differ")
    require(all(value in OUTCOMES for value in outcomes.values()), "expected outcome invalid")
    return outcomes


def validate_cases(document: dict[str, Any], expected: dict[str, str]) -> dict[str, Any]:
    cases = document["cases"]
    require(len(cases) == 15, "case count differs")
    ids = [case.get("id") for case in cases]
    require(len(ids) == len(set(ids)) and set(ids) == set(expected), "case IDs differ")
    results = []
    for case in cases:
        exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case['id']}")
        require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind invalid")
        candidate = case["candidate"]
        exact_keys(candidate, {"fact", "source_rule", "coarray_spec", "component_type"}, f"case {case['id']} candidate")
        require(candidate["fact"] == PROPERTY and candidate["source_rule"] == "C752", f"case {case['id']} identity differs")
        require(candidate["coarray_spec"] in SPECS and candidate["component_type"] in TYPES, f"case {case['id']} field invalid")
        require(case["expected"] == expected[case["id"]], f"case {case['id']} expected differs")
        computed = oracle(candidate)
        require(computed == expected[case["id"]], f"case {case['id']} oracle disagrees")
        results.append({"id": case["id"], "kind": case["kind"], "coarray_spec": candidate["coarray_spec"], "component_type": candidate["component_type"], "computed": computed, "expected": expected[case["id"]]})
    return {"cases": results, "counts": {outcome: sum(item["computed"] == outcome for item in results) for outcome in sorted(OUTCOMES)}}


def set_path(value: Any, path: tuple[Any, ...], replacement: Any) -> None:
    target = value
    for part in path[:-1]:
        target = target[part]
    target[path[-1]] = replacement


def self_test(root: Path) -> None:
    fixture_path = root / "tests/fixtures/m3-c752-source-backed-v0.json"
    original = json.loads(fixture_path.read_text(encoding="utf-8"))
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original)
        set_path(mutated, path, replacement)
        try:
            validate_binding(mutated, root, root / ".cache/j3-24-007.pdf", root / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", root / ".cache/runs/E0001/R000003/j3-24-007.pages.index", root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c752-semantic-items.sx")
        except ContractError:
            continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C752 self-test PASS: {len(MUTATIONS)} mutation controls rejected")


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
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c752-semantic-items.sx")
    expected = validate_expected(expected_doc, expected_path, [case["id"] for case in fixture["cases"]])
    result = validate_cases(fixture, expected)
    require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs from golden")
    mutations = [{"id": name, "result": "REJECTED"} for name, _, _ in MUTATIONS]
    output = {"schema_version": "m3-c752-result-v0", "origin": "MECHANICAL", "property": PROPERTY, "source_rule": "C752", "source_span": SOURCE_SPAN, "page_index": PAGE_INDEX[0], "standardir_rules": [row["rule"] for row in STANDARDIR_ROWS], "state_count": len(result["cases"]), "outcome_counts": result["counts"], "mutation_controls": mutations, "model_calls": 0, "semantic_promotions": 0, "candidate_promotion": "BOUNDED_ONLY", "full_m3": "OPEN"}
    result_path.write_text(json.dumps(output, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"C752 validation failure: {error}", file=sys.stderr)
        raise SystemExit(1)
