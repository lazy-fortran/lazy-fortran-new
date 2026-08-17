#!/usr/bin/env python3
"""Independent validator for the bounded M3 C749 semantic slice."""

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
ATTRIBUTE_STATES = {"absent", "present", "unknown"}
TYPE_CATEGORIES = {
    "intrinsic",
    "previously-defined-derived",
    "enum",
    "enumeration",
    "other",
    "unknown",
}
CONTEXTS = {"component-def-stmt", "other", "unknown"}
ALLOWED_TYPES = {"intrinsic", "previously-defined-derived", "enum", "enumeration"}

SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
EXPECTED_OUTCOMES_SHA256 = "7e21ca9ab12c2fc7595f4510ffe8dc2246f5867192809da8cff1412c56318d68"
EXPECTED_OUTCOMES_PATH = "tests/fixtures/m3-c749-expected-outcomes-v0.json"
SEMANTIC_ITEM_SHA256 = "70838c6a2d651a02f57689d7ccff315fc3c106ee8166d8d0cbf4c90b9d73cacd"
PROPERTY = "component-def-stmt-component-type-eligibility"
SOURCE_SPAN = {"byte_start": 240824, "byte_length": 234, "page_start": 93, "page_end": 93}
PAGE = {"page": 93, "start": 239957, "length": 2451}
CANONICAL_LINES = [
    {
        "line": 3835,
        "text": "C749 (R737) If neither the POINTER nor the ALLOCATABLE attribute is specified, the declaration-type-",
    },
    {
        "line": 3836,
        "text": "spec in the component-def-stmt shall specify an intrinsic type, or a previously defined derived, enum, or",
    },
    {"line": 3837, "text": "enumeration type."},
]
SOURCE_BYTES = (
    b"21 C749 (R737) If neither the POINTER nor the ALLOCATABLE attribute is specified, the declaration-type-\n"
    b"22 spec in the component-def-stmt shall specify an intrinsic type, or a previously defined derived, enum, or\n"
    b"23 enumeration type.\n"
)
STANDARDIR_ROWS = [
    {
        "rule": "R703",
        "lhs": "declaration-type-spec",
        "page": 77,
        "byte_start": 197098,
        "byte_length": 309,
        "occurrence": 53,
    },
    {
        "rule": "R737",
        "lhs": "data-component-def-stmt",
        "page": 93,
        "byte_start": 240182,
        "byte_length": 115,
        "occurrence": 87,
    },
]
CONTRACT = {
    "schema": "contracts/m3-c749-component-type-eligibility-v0.sxs",
    "fixture": "contracts/fixtures/m3-c749-component-type-eligibility-v0.sx",
    "version": 0,
}
SEMANTIC_ITEM = {
    "path": "tests/fixtures/m3-c749-semantic-items.sx",
    "sha256": SEMANTIC_ITEM_SHA256,
    "id": "S-C749",
    "subject": PROPERTY,
    "document": "J3-24-007",
    "clause": "7",
    "rule": "C749",
    "page": 79,
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


def validate_expected_outcomes(
    document: dict[str, Any], path: Path, case_ids: list[str]
) -> dict[str, str]:
    exact_keys(
        document,
        {"schema_version", "origin", "property", "source_rule", "outcomes"},
        "expected outcomes",
    )
    require(digest(path) == EXPECTED_OUTCOMES_SHA256, "expected outcomes hash differs")
    require(
        document["schema_version"] == "m3-c749-expected-outcomes-v0",
        "expected outcomes schema differs",
    )
    require(document["origin"] == "HUMAN", "expected outcomes origin differs")
    require(
        document["property"] == PROPERTY and document["source_rule"] == "C749",
        "expected outcomes identity differs",
    )
    outcomes = document["outcomes"]
    require(isinstance(outcomes, dict), "expected outcomes are not a table")
    require(len(case_ids) == len(set(case_ids)), "fixture case IDs are not unique")
    exact_keys(outcomes, set(case_ids), "expected outcome rows")
    require(all(outcome in OUTCOMES for outcome in outcomes.values()), "outcome invalid")
    return {case_id: outcomes[case_id] for case_id in case_ids}


def oracle(candidate: dict[str, str]) -> str:
    if candidate["context"] != "component-def-stmt":
        return "UNRESOLVED"
    if candidate["pointer_or_allocatable_attribute"] != "absent":
        return "UNRESOLVED"
    if candidate["declaration_type_category"] in ALLOWED_TYPES:
        return "ACCEPTED"
    if candidate["declaration_type_category"] == "other":
        return "REJECTED"
    return "UNRESOLVED"


def validate_case(case: dict[str, Any], expected_outcomes: dict[str, str]) -> dict[str, Any]:
    case_id = case.get("id", "<missing>")
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case_id}")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case_id} kind invalid")
    require(case["expected"] in OUTCOMES, f"case {case_id} outcome invalid")
    candidate = case["candidate"]
    exact_keys(
        candidate,
        {
            "fact",
            "source_rule",
            "pointer_or_allocatable_attribute",
            "declaration_type_category",
            "context",
        },
        f"case {case_id} candidate",
    )
    require(candidate["fact"] == PROPERTY, f"case {case_id} property differs")
    require(candidate["source_rule"] == "C749", f"case {case_id} source rule differs")
    require(
        candidate["pointer_or_allocatable_attribute"] in ATTRIBUTE_STATES,
        f"case {case_id} attribute state invalid",
    )
    require(
        candidate["declaration_type_category"] in TYPE_CATEGORIES,
        f"case {case_id} type category invalid",
    )
    require(candidate["context"] in CONTEXTS, f"case {case_id} context invalid")
    independent_expected = expected_outcomes[case["id"]]
    require(
        case["expected"] == independent_expected,
        f"case {case_id} fixture expectation differs from independent table",
    )
    computed = oracle(candidate)
    require(computed == independent_expected, f"case {case_id} oracle disagrees")
    return {
        "id": case["id"],
        "kind": case["kind"],
        "pointer_or_allocatable_attribute": candidate["pointer_or_allocatable_attribute"],
        "declaration_type_category": candidate["declaration_type_category"],
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
    expected = {
        "path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx",
        "sha256": STANDARDIR_SHA256,
        "source_hash": SOURCE_SHA256,
        "rows": STANDARDIR_ROWS,
    }
    require(source["standardir"] == expected, "StandardIR fixture identity differs")
    lines = path.read_text(encoding="utf-8").splitlines()
    for row in STANDARDIR_ROWS:
        matching = [line for line in lines if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matching) == 1, f"expected one {row['rule']} StandardIR row")
        line = matching[0]
        require(field(line, r"\(lhs ([^)]+)\)", "lhs") == row["lhs"], f"{row['rule']} lhs differs")
        require(int(field(line, r"\(page (\d+)\)", "page")) == row["page"], f"{row['rule']} page differs")
        require(
            int(field(line, r"\(byte-start (\d+)\)", "byte-start")) == row["byte_start"],
            f"{row['rule']} byte-start differs",
        )
        require(
            int(field(line, r"\(byte-length (\d+)\)", "byte-length")) == row["byte_length"],
            f"{row['rule']} byte-length differs",
        )
        require(
            int(field(line, r"\(occurrence (\d+)\)", "occurrence")) == row["occurrence"],
            f"{row['rule']} occurrence differs",
        )
        require(
            field(line, r"\(source-sha256 ([^)]+)\)", "source hash") == SOURCE_SHA256,
            f"{row['rule']} source hash differs",
        )
    r703 = next(line for line in lines if line.startswith("(syntax R703 "))
    r737 = next(line for line in lines if line.startswith("(syntax R737 "))
    for fragment in (
        "(lhs declaration-type-spec)",
        "(ref intrinsic-type-spec)",
        "(ref derived-type-spec)",
        "(ref enum-type-spec)",
        "(ref enumeration-type-spec)",
    ):
        require(fragment in r703, f"R703 shape lacks {fragment}")
    for fragment in (
        "(lhs data-component-def-stmt)",
        "(ref declaration-type-spec)",
        "(ref component-attr-spec-list)",
        "(ref component-decl-list)",
    ):
        require(fragment in r737, f"R737 shape lacks {fragment}")


def validate_binding(
    document: dict[str, Any],
    root: Path,
    pdf: Path,
    canonical: Path,
    page_index: Path,
    standardir: Path,
    semantic: Path,
) -> None:
    exact_keys(
        document,
        {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"},
        "fixture",
    )
    require(
        document["schema_version"] == "m3-c749-source-backed-v0"
        and document["origin"] == "HUMAN"
        and document["property"] == PROPERTY,
        "fixture identity differs",
    )
    require(document["contract"] == CONTRACT, "contract identity differs")
    source = document["source"]
    exact_keys(
        source,
        {
            "document",
            "clause",
            "rule",
            "printed_page",
            "pdf_sha256",
            "canonical_text",
            "canonical_text_sha256",
            "canonical_lines",
            "source_span",
            "page_index",
            "standardir",
        },
        "source",
    )
    require(
        source["document"] == "J3-24-007"
        and source["clause"] == "7"
        and source["rule"] == "C749"
        and source["printed_page"] == 79,
        "source identity differs",
    )
    require(
        source["pdf_sha256"] == PDF_SHA256
        and source["canonical_text_sha256"] == SOURCE_SHA256,
        "source hash differs",
    )
    require(canonical.resolve() == (root / source["canonical_text"]).resolve(), "canonical path differs")
    require(page_index.resolve() == (root / source["page_index"]["path"]).resolve(), "page index path differs")
    manifest = tomllib.loads(
        (root / "artifacts/standards/j3-24-007.toml").read_text(encoding="utf-8")
    )
    require(
        manifest["sha256"] == PDF_SHA256
        and manifest["bytes"] == pdf.stat().st_size
        and digest(pdf) == PDF_SHA256,
        "normative PDF differs",
    )
    require(
        digest(canonical) == SOURCE_SHA256
        and source["canonical_lines"] == CANONICAL_LINES,
        "canonical identity differs",
    )
    require(
        canonical.read_bytes()[SOURCE_SPAN["byte_start"] : SOURCE_SPAN["byte_start"] + SOURCE_SPAN["byte_length"]]
        == SOURCE_BYTES,
        "canonical source span differs",
    )
    require(
        source["source_span"] == SOURCE_SPAN,
        "source span metadata differs",
    )
    require(
        digest(page_index) == PAGE_INDEX_SHA256
        and source["page_index"]
        == {
            "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index",
            "sha256": PAGE_INDEX_SHA256,
            "pages": [PAGE],
        },
        "page index identity differs",
    )
    page_records = []
    for line in page_index.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"page (\d+) start (\d+) length (\d+)", line)
        if match:
            page_records.append(
                {
                    "page": int(match.group(1)),
                    "start": int(match.group(2)),
                    "length": int(match.group(3)),
                }
            )
    start = SOURCE_SPAN["byte_start"]
    end = start + SOURCE_SPAN["byte_length"]
    containing_pages = [
        record
        for record in page_records
        if record["start"] <= start <= end <= record["start"] + record["length"]
    ]
    require(containing_pages == [PAGE], "source span is not contained by page 93")
    validate_standardir(source, standardir)
    require(document["semantic_item"] == SEMANTIC_ITEM, "semantic item identity differs")
    require(
        (root / SEMANTIC_ITEM["path"]).resolve() == semantic.resolve()
        and digest(semantic) == SEMANTIC_ITEM_SHA256,
        "semantic item hash differs",
    )
    semantic_text = semantic.read_text(encoding="utf-8")
    for fragment in (
        "(id S-C749)",
        "(subject " + PROPERTY + ")",
        "(origin human)",
        "(resolution disputed)",
    ):
        require(fragment in semantic_text, f"semantic item lacks {fragment}")
    schema = (root / CONTRACT["schema"]).read_text(encoding="utf-8")
    for fragment in (
        "(enum c749-pointer-or-allocatable-attribute absent present unknown)",
        "(enum c749-declaration-type-category intrinsic previously-defined-derived enum enumeration other unknown)",
        "(record component-type-eligibility",
    ):
        require(fragment in schema, f"contract schema lacks {fragment}")
    witness = (root / CONTRACT["fixture"]).read_text(encoding="utf-8")
    for fragment in (
        "(contract m3-c749-component-type-eligibility)",
        "(property " + PROPERTY + ")",
        "(rule C749)",
        "(page 79)",
        "(byte-start 240824)",
        "(byte-length 234)",
        "(source-hash " + SOURCE_SHA256 + ")",
    ):
        require(fragment in witness, f"contract witness lacks {fragment}")


def set_path(document: dict[str, Any], path: list[Any], value: Any) -> None:
    target: Any = document
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value


def build_result(
    fixture_path: Path,
    expected_path: Path,
    fixture: dict[str, Any],
    expected_document: dict[str, Any],
    root: Path,
    pdf: Path,
    canonical: Path,
    page_index: Path,
    standardir: Path,
    semantic_output: Path,
    golden: Path,
    output: Path,
) -> dict[str, Any]:
    require(len(fixture["cases"]) == 54, "case count differs")
    expected_outcomes = validate_expected_outcomes(
        expected_document, expected_path, [case["id"] for case in fixture["cases"]]
    )
    cases = [validate_case(case, expected_outcomes) for case in fixture["cases"]]
    product = {
        (
            case["pointer_or_allocatable_attribute"],
            case["declaration_type_category"],
            case["context"],
        )
        for case in cases
    }
    require(
        product
        == {
            (attribute, category, context)
            for attribute in ATTRIBUTE_STATES
            for category in TYPE_CATEGORIES
            for context in CONTEXTS
        },
        "54-state table incomplete",
    )
    require(sum(case["kind"] == "positive" for case in cases) == 4, "positive count differs")
    require(sum(case["kind"] == "negative" for case in cases) == 1, "negative count differs")
    require(sum(case["kind"] == "unresolved" for case in cases) == 49, "unresolved count differs")
    require(len(fixture["mutations"]) == 12, "mutation count differs")
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, root / SEMANTIC_ITEM["path"])
    require(
        semantic_output.read_bytes() == (root / SEMANTIC_ITEM["path"]).read_bytes() == golden.read_bytes(),
        "semantic canonicalization differs",
    )
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
        "schema_version": fixture["schema_version"],
        "milestone": "M3",
        "property": PROPERTY,
        "fixture": str(fixture_path.relative_to(root)),
        "fixture_sha256": digest(fixture_path),
        "expected_outcomes": {
            "path": str(expected_path.relative_to(root)),
            "sha256": digest(expected_path),
            "origin": expected_document["origin"],
            "comparison": "PASS",
        },
        "contract": {
            "schema": CONTRACT["schema"],
            "schema_sha256": digest(root / CONTRACT["schema"]),
            "fixture": CONTRACT["fixture"],
            "fixture_sha256": digest(root / CONTRACT["fixture"]),
            "version": 0,
        },
        "source": {
            "document": "J3-24-007",
            "clause": "7",
            "rule": "C749",
            "printed_page": 79,
            "pdf_sha256": digest(pdf),
            "canonical_text_sha256": digest(canonical),
            "page_index_sha256": digest(page_index),
            "standardir_sha256": digest(standardir),
            "canonical_lines": [3835, 3836, 3837],
            "source_span": SOURCE_SPAN,
            "page_index": {
                "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index",
                "sha256": PAGE_INDEX_SHA256,
                "pages": [PAGE],
            },
            "standardir_rules": ["R703", "R737"],
        },
        "semantic_items": {
            "input": SEMANTIC_ITEM["path"],
            "input_sha256": digest(root / SEMANTIC_ITEM["path"]),
            "canonical_output_sha256": digest(semantic_output),
            "canonical_output": "PASS",
        },
        "cases": cases,
        "outcome_counts": {
            outcome: sum(case["computed"] == outcome for case in cases)
            for outcome in sorted(OUTCOMES)
        },
        "mutation_controls": mutations,
        "model_calls": 0,
        "semantic_promotions": 0,
        "origin": "MECHANICAL",
        "oracle": "tests/e2e/validate_m3_c749.py",
    }
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


def self_test(root: Path) -> None:
    fixture_path = root / "tests/fixtures/m3-c749-source-backed-v0.json"
    expected_path = root / EXPECTED_OUTCOMES_PATH
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
    expected_document = json.loads(expected_path.read_text(encoding="utf-8"))
    expected_outcomes = validate_expected_outcomes(
        expected_document, expected_path, [case["id"] for case in fixture["cases"]]
    )
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
    source_negative = copy.deepcopy(fixture)
    source_negative["source"]["rule"] = "C750"
    try:
        validate_binding(
            source_negative,
            root,
            root / ".cache/j3-24-007.pdf",
            root / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt",
            root / ".cache/runs/E0001/R000003/j3-24-007.pages.index",
            root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx",
            root / SEMANTIC_ITEM["path"],
        )
    except ContractError:
        pass
    else:
        raise ContractError("self-test accepted a mutated source binding")


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test(root)
        print("C749 oracle self-test PASS")
        return 0
    if len(sys.argv) != 10:
        raise SystemExit(
            "usage: validate_m3_c749.py fixture expected-outcomes semantic-output standardir canonical page-index pdf golden result"
        )
    fixture_path, expected_path, semantic_output, standardir, canonical, page_index, pdf, golden, output = map(
        Path, sys.argv[1:]
    )
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        expected_document = json.loads(expected_path.read_text(encoding="utf-8"))
        result = build_result(
            fixture_path,
            expected_path,
            fixture,
            expected_document,
            root,
            pdf,
            canonical,
            page_index,
            standardir,
            semantic_output,
            golden,
            output,
        )
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"C749 oracle FAIL: {error}", file=sys.stderr)
        return 1
    print(
        json.dumps(
            {
                "outcome_counts": result["outcome_counts"],
                "mutation_controls": len(result["mutation_controls"]),
                "model_calls": 0,
                "semantic_promotions": 0,
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
