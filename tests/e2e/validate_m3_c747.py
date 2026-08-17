#!/usr/bin/env python3
"""Independent validator for the bounded M3 C747 semantic slice."""

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
DERIVED_NAME_PRESENCES = {"absent", "present", "unknown"}
DEFINITION_OCCURRENCE_CARDINALITIES = {"zero", "one", "many", "unknown"}
CONTEXTS = {"derived-type-def", "other", "unknown"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
EXPECTED_OUTCOMES_SHA256 = "fc2d31361b99e523dd4e2ec32de91e528ec40f41aac5244e3611f9571c5a34ce"
EXPECTED_OUTCOMES_PATH = "tests/fixtures/m3-c747-expected-outcomes-v0.json"
PROPERTY = "derived-type-def-type-parameter-name-exact-once"
SOURCE_SPAN = {"byte_start": 237572, "byte_length": 183, "page_start": 77, "page_end": 77}
CANONICAL_LINES = [
    {"line": 3766, "text": "C747 (R732) Each type-param-name in the derived-type-stmt in a derived-type-def shall appear exactly once as"},
    {"line": 3767, "text": "a type-param-name in a type-param-def-stmt in that derived-type-def ."},
]
PAGE = {"page": 77, "start": 195782, "length": 2519}
STANDARDIR_ROWS = [
    {"rule": "R727", "lhs": "derived-type-stmt", "page": 88, "byte_start": 229178, "byte_length": 108, "occurrence": 77},
    {"rule": "R732", "lhs": "type-param-def-stmt", "page": 91, "byte_start": 237232, "byte_length": 95, "occurrence": 82},
    {"rule": "R733", "lhs": "type-param-decl", "page": 91, "byte_start": 237328, "byte_length": 72, "occurrence": 83},
]
SOURCE_BYTES = (
    b"8 C747 (R732) Each type-param-name in the derived-type-stmt in a derived-type-def shall appear exactly once as\n"
    b"9 a type-param-name in a type-param-def-stmt in that derived-type-def .\n"
)
CONTRACT = {
    "schema": "contracts/m3-c747-derived-type-type-parameter-name-exact-once-v0.sxs",
    "fixture": "contracts/fixtures/m3-c747-derived-type-type-parameter-name-exact-once-v0.sx",
    "version": 0,
}
SEMANTIC_ITEM = {
    "path": "tests/fixtures/m3-c747-semantic-items.sx",
    "sha256": "1719c5cea78f6cd5c174d6b7e2cfc6328362828ca995bb145f760f9fff4241a0",
    "id": "S-C747",
    "subject": PROPERTY,
    "document": "J3-24-007",
    "clause": "7",
    "rule": "C747",
    "page": 77,
    "source_hash": SOURCE_SHA256,
    "origin": "human",
    "resolution": "disputed",
}


class ContractError(Exception):
    pass


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    require(set(value) == expected, f"{label} keys differ")


def validate_expected_outcomes(doc: dict[str, Any], path: Path, case_ids: list[str]) -> dict[str, str]:
    exact_keys(doc, {"schema_version", "origin", "property", "source_rule", "outcomes"}, "expected outcomes")
    require(digest(path) == EXPECTED_OUTCOMES_SHA256, "expected outcomes hash differs")
    require(doc["schema_version"] == "m3-c747-expected-outcomes-v0", "expected outcomes schema differs")
    require(doc["origin"] == "HUMAN", "expected outcomes origin differs")
    require(doc["property"] == PROPERTY and doc["source_rule"] == "C747", "expected outcomes identity differs")
    outcomes = doc["outcomes"]
    require(isinstance(outcomes, dict), "expected outcomes are not a table")
    require(len(case_ids) == len(set(case_ids)), "fixture case IDs are not unique")
    exact_keys(outcomes, set(case_ids), "expected outcome rows")
    require(all(outcome in OUTCOMES for outcome in outcomes.values()), "expected outcome value invalid")
    return {case_id: outcomes[case_id] for case_id in case_ids}


def oracle(candidate: dict[str, str]) -> str:
    if candidate["context"] != "derived-type-def":
        return "UNRESOLVED"
    if candidate["derived_name_presence"] == "absent":
        return "ACCEPTED"
    if candidate["derived_name_presence"] == "present" and candidate["definition_occurrence_cardinality"] == "one":
        return "ACCEPTED"
    if candidate["derived_name_presence"] == "present" and candidate["definition_occurrence_cardinality"] in {"zero", "many"}:
        return "REJECTED"
    return "UNRESOLVED"


def validate_case(case: dict[str, Any], expected_outcomes: dict[str, str]) -> dict[str, Any]:
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case.get('id', '<missing>')}")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind invalid")
    require(case["expected"] in OUTCOMES, f"case {case['id']} outcome invalid")
    candidate = case["candidate"]
    exact_keys(candidate, {"fact", "source_rule", "derived_name_presence", "definition_occurrence_cardinality", "context"}, f"case {case['id']} candidate")
    require(candidate["fact"] == PROPERTY, f"case {case['id']} property differs")
    require(candidate["source_rule"] == "C747", f"case {case['id']} source rule differs")
    require(candidate["derived_name_presence"] in DERIVED_NAME_PRESENCES, f"case {case['id']} derived-name presence invalid")
    require(candidate["definition_occurrence_cardinality"] in DEFINITION_OCCURRENCE_CARDINALITIES, f"case {case['id']} occurrence cardinality invalid")
    require(candidate["context"] in CONTEXTS, f"case {case['id']} context invalid")
    independent_expected = expected_outcomes[case["id"]]
    require(case["expected"] == independent_expected, f"case {case['id']} fixture expectation differs from independent table")
    computed = oracle(candidate)
    require(computed == independent_expected, f"case {case['id']} independent outcome disagrees")
    return {
        "id": case["id"],
        "kind": case["kind"],
        "derived_name_presence": candidate["derived_name_presence"],
        "definition_occurrence_cardinality": candidate["definition_occurrence_cardinality"],
        "context": candidate["context"],
        "computed": computed,
        "expected": independent_expected,
        "fixture_expected": case["expected"],
    }


def field(line: str, pattern: str, label: str) -> str:
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
        require(len(matching) == 1, f"expected one {row['rule']} StandardIR row")
        line = matching[0]
        require(field(line, r"\(lhs ([^)]+)\)", "lhs") == row["lhs"], f"{row['rule']} lhs differs")
        require(int(field(line, r"\(page (\d+)\)", "page")) == row["page"], f"{row['rule']} page differs")
        require(int(field(line, r"\(byte-start (\d+)\)", "byte-start")) == row["byte_start"], f"{row['rule']} byte-start differs")
        require(int(field(line, r"\(byte-length (\d+)\)", "byte-length")) == row["byte_length"], f"{row['rule']} byte-length differs")
        require(int(field(line, r"\(occurrence (\d+)\)", "occurrence")) == row["occurrence"], f"{row['rule']} occurrence differs")
        require(field(line, r"\(source-sha256 ([^)]+)\)", "source hash") == SOURCE_SHA256, f"{row['rule']} source hash differs")
    r727 = next(line for line in lines if line.startswith("(syntax R727 "))
    r732 = next(line for line in lines if line.startswith("(syntax R732 "))
    r733 = next(line for line in lines if line.startswith("(syntax R733 "))
    require("(lhs derived-type-stmt)" in r727 and "(ref type-param-name-list)" in r727, "R727 shape differs")
    require("(lhs type-param-def-stmt)" in r732 and "(ref type-param-decl-list)" in r732, "R732 shape differs")
    require("(lhs type-param-decl)" in r733 and "(ref type-param-name)" in r733, "R733 shape differs")


def validate_binding(doc: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"}, "fixture")
    require(doc["schema_version"] == "m3-c747-source-backed-v0" and doc["origin"] == "HUMAN" and doc["property"] == PROPERTY, "fixture identity differs")
    require(doc["contract"] == CONTRACT, "contract identity differs")
    source = doc["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C747" and source["printed_page"] == 77, "source identity differs")
    require(source["pdf_sha256"] == PDF_SHA256 and source["canonical_text_sha256"] == SOURCE_SHA256, "source hash differs")
    require(canonical.resolve() == (root / source["canonical_text"]).resolve(), "canonical path differs")
    require(page_index.resolve() == (root / source["page_index"]["path"]).resolve(), "page index path differs")
    manifest = tomllib.loads((root / "artifacts/standards/j3-24-007.toml").read_text(encoding="utf-8"))
    require(manifest["sha256"] == PDF_SHA256 and manifest["bytes"] == pdf.stat().st_size and digest(pdf) == PDF_SHA256, "normative PDF differs")
    require(digest(canonical) == SOURCE_SHA256 and source["canonical_lines"] == CANONICAL_LINES, "canonical identity differs")
    lines = canonical.read_bytes().splitlines(keepends=True)
    require(lines[3765] == SOURCE_BYTES.splitlines(keepends=True)[0] and lines[3766] == SOURCE_BYTES.splitlines(keepends=True)[1], "canonical lines differ")
    require(source["source_span"] == SOURCE_SPAN and canonical.read_bytes()[237572:237755] == SOURCE_BYTES, "source span differs")
    require(digest(page_index) == PAGE_INDEX_SHA256 and source["page_index"] == {"path": ".cache/runs/E0001/R000003/j3-24-007.pages.index", "sha256": PAGE_INDEX_SHA256, "pages": [PAGE]}, "page index identity differs")
    require("page 77 start 195782 length 2519" in page_index.read_text(encoding="utf-8"), "page index span differs")
    validate_standardir(source, standardir)
    require(doc["semantic_item"] == SEMANTIC_ITEM, "semantic item identity differs")
    require((root / SEMANTIC_ITEM["path"]).resolve() == semantic.resolve() and digest(semantic) == SEMANTIC_ITEM["sha256"], "semantic item hash differs")
    text = semantic.read_text(encoding="utf-8")
    for fragment in ("(id S-C747)", "(subject " + PROPERTY + ")", "(origin human)", "(resolution disputed)"):
        require(fragment in text, f"semantic item lacks {fragment}")
    schema = (root / CONTRACT["schema"]).read_text(encoding="utf-8")
    for fragment in ("(enum c747-derived-name-presence absent present unknown)", "(enum c747-definition-occurrence-cardinality zero one many unknown)", "(record type-parameter-name-exact-once"):
        require(fragment in schema, f"contract schema lacks {fragment}")
    witness = (root / CONTRACT["fixture"]).read_text(encoding="utf-8")
    for fragment in ("(contract m3-c747-derived-type-type-parameter-name-exact-once)", "(property " + PROPERTY + ")", "(rule C747)", "(page 77)", "(byte-start 237572)", "(byte-length 183)", "(source-hash " + SOURCE_SHA256 + ")"):
        require(fragment in witness, f"contract fixture lacks {fragment}")


def set_path(document: dict[str, Any], path: list[Any], value: Any) -> None:
    target: Any = document
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value


def build_result(fixture_path: Path, expected_path: Path, fixture: dict[str, Any], expected_doc: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic_output: Path, golden: Path, output: Path) -> dict[str, Any]:
    require(len(fixture["cases"]) == 36, "case count differs")
    expected_outcomes = validate_expected_outcomes(expected_doc, expected_path, [case["id"] for case in fixture["cases"]])
    cases = [validate_case(case, expected_outcomes) for case in fixture["cases"]]
    require({(case["derived_name_presence"], case["definition_occurrence_cardinality"], case["context"]) for case in cases} == {(derived_name_presence, definition_occurrence_cardinality, context) for derived_name_presence in DERIVED_NAME_PRESENCES for definition_occurrence_cardinality in DEFINITION_OCCURRENCE_CARDINALITIES for context in CONTEXTS}, "36-state table incomplete")
    require(sum(case["kind"] == "positive" for case in cases) == 5 and sum(case["kind"] == "negative" for case in cases) == 2 and sum(case["kind"] == "unresolved" for case in cases) == 29, "witness kind counts differ")
    require(len(fixture["mutations"]) == 12, "mutation count differs")
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, root / SEMANTIC_ITEM["path"])
    require(semantic_output.read_bytes() == (root / SEMANTIC_ITEM["path"]).read_bytes() == golden.read_bytes(), "semantic canonicalization differs")
    mutations = []
    for mutation in fixture["mutations"]:
        mutated = copy.deepcopy(fixture)
        set_path(mutated, mutation["path"], mutation["value"])
        try:
            validate_binding(mutated, root, pdf, canonical, page_index, standardir, root / SEMANTIC_ITEM["path"])
        except (ContractError, OSError, KeyError, TypeError, ValueError):
            mutations.append({"id": mutation["id"], "result": "REJECTED"})
        else:
            raise ContractError(f"mutation accepted: {mutation['id']}")
    result = {
        "schema_version": fixture["schema_version"], "milestone": "M3", "property": PROPERTY,
        "fixture": str(fixture_path.relative_to(root)), "fixture_sha256": digest(fixture_path),
        "expected_outcomes": {"path": str(expected_path.relative_to(root)), "sha256": digest(expected_path), "origin": expected_doc["origin"], "comparison": "PASS"},
        "contract": {"schema": CONTRACT["schema"], "schema_sha256": digest(root / CONTRACT["schema"]), "fixture": CONTRACT["fixture"], "fixture_sha256": digest(root / CONTRACT["fixture"]), "version": 0},
        "source": {"document": "J3-24-007", "clause": "7", "rule": "C747", "printed_page": 77, "pdf_sha256": digest(pdf), "canonical_text_sha256": digest(canonical), "page_index_sha256": digest(page_index), "standardir_sha256": digest(standardir), "canonical_lines": [3766, 3767], "source_span": SOURCE_SPAN, "page_index": {"path": ".cache/runs/E0001/R000003/j3-24-007.pages.index", "sha256": PAGE_INDEX_SHA256, "pages": [PAGE]}, "standardir_rules": ["R727", "R732", "R733"]},
        "semantic_items": {"input": SEMANTIC_ITEM["path"], "input_sha256": digest(root / SEMANTIC_ITEM["path"]), "canonical_output_sha256": digest(semantic_output), "canonical_output": "PASS"},
        "cases": cases, "outcome_counts": {outcome: sum(case["computed"] == outcome for case in cases) for outcome in sorted(OUTCOMES)}, "mutation_controls": mutations,
        "model_calls": 0, "semantic_promotions": 0, "origin": "MECHANICAL", "oracle": "tests/e2e/validate_m3_c747.py",
    }
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


def self_test(root: Path) -> None:
    fixture_path = root / "tests/fixtures/m3-c747-source-backed-v0.json"
    expected_path = root / EXPECTED_OUTCOMES_PATH
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
    expected_doc = json.loads(expected_path.read_text(encoding="utf-8"))
    expected_outcomes = validate_expected_outcomes(expected_doc, expected_path, [case["id"] for case in fixture["cases"]])
    for case in fixture["cases"]:
        validate_case(case, expected_outcomes)
    negative = copy.deepcopy(fixture["cases"][0])
    negative["expected"] = "REJECTED"
    try:
        validate_case(negative, expected_outcomes)
    except ContractError:
        pass
    else:
        raise ContractError("self-test accepted a mutated expected outcome")


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test(root)
        print("C747 oracle self-test PASS")
        return 0
    if len(sys.argv) != 10:
        raise SystemExit("usage: validate_m3_c747.py fixture expected-outcomes semantic-output standardir canonical page-index pdf golden result")
    fixture_path, expected_path, semantic_output, standardir, canonical, page_index, pdf, golden, output = map(Path, sys.argv[1:])
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        expected_doc = json.loads(expected_path.read_text(encoding="utf-8"))
        result = build_result(fixture_path, expected_path, fixture, expected_doc, root, pdf, canonical, page_index, standardir, semantic_output, golden, output)
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"C747 oracle FAIL: {error}", file=sys.stderr)
        return 1
    print(json.dumps({"outcome_counts": result["outcome_counts"], "mutation_controls": len(result["mutation_controls"]), "model_calls": 0, "semantic_promotions": 0}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
