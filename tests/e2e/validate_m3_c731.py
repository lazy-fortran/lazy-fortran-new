#!/usr/bin/env python3
"""Independent validator for the bounded M3 C731 semantic slice."""

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
LENGTH_FORMS = {"constant-expression", "non-constant-expression", "unknown"}
CONTEXTS = {
    "character-statement-function",
    "statement-function-dummy-argument",
    "other",
    "unknown",
}
SOURCE_NAMED_CONTEXTS = {
    "character-statement-function",
    "statement-function-dummy-argument",
}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PROPERTY = "character-statement-function-length-constant-expression"
SOURCE_SPAN = {"byte_start": 219036, "byte_length": 167, "page_start": 85, "page_end": 85}
EXPECTED_CANONICAL_LINES = [
    {"line": 3469, "text": "C731 (R721) The length specified for a character statement function or for a statement function dummy argument of type"},
    {"line": 3470, "text": "character shall be a constant expression."},
]
EXPECTED_PAGE_INDEX = {
    "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index",
    "sha256": PAGE_INDEX_SHA256,
    "pages": [{"page": 85, "start": 218135, "length": 3925}],
}
EXPECTED_STANDARDIR_ROWS = [
    {"rule": "R721", "lhs": "char-selector", "page": 84, "byte_start": 217200, "byte_length": 251, "occurrence": 71},
]
EXPECTED_SOURCE_BYTES = (
    b"10 C731 (R721) The length specified for a character statement function or for a statement function dummy argument of type\n"
    b"11 character shall be a constant expression.\n"
)


class ContractError(Exception):
    """A source, schema, fact or oracle contract failure."""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    require(set(value) == expected, f"{label} keys differ")


def c731_oracle(candidate: dict[str, Any]) -> str:
    """Apply only C731's typed length-form/context relation."""

    if candidate["context"] not in SOURCE_NAMED_CONTEXTS:
        return "UNRESOLVED"
    if candidate["length_form"] == "constant-expression":
        return "ACCEPTED"
    if candidate["length_form"] == "non-constant-expression":
        return "REJECTED"
    return "UNRESOLVED"


def validate_candidate(case: dict[str, Any]) -> dict[str, Any]:
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case.get('id', '<missing>')}")
    require(isinstance(case["id"], str) and case["id"], "case id is invalid")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind is invalid")
    require(case["expected"] in OUTCOMES, f"case {case['id']} expected outcome is invalid")
    candidate = case["candidate"]
    require(isinstance(candidate, dict), f"case {case['id']} candidate is not an object")
    exact_keys(candidate, {"fact", "source_rule", "length_form", "context"}, f"case {case['id']} candidate")
    require(candidate["fact"] == PROPERTY, f"case {case['id']} candidate fact differs")
    require(candidate["source_rule"] == "C731", f"case {case['id']} source rule differs")
    require(candidate["length_form"] in LENGTH_FORMS, f"case {case['id']} length-form state is invalid")
    require(candidate["context"] in CONTEXTS, f"case {case['id']} context state is invalid")
    computed = c731_oracle(candidate)
    require(computed == case["expected"], f"case {case['id']} expected outcome disagrees with oracle")
    return {
        "id": case["id"],
        "kind": case["kind"],
        "length_form": candidate["length_form"],
        "context": candidate["context"],
        "computed": computed,
        "expected": case["expected"],
    }


def source_field(line: str, pattern: str, label: str) -> str:
    match = re.search(pattern, line)
    if match is None:
        raise ContractError(f"StandardIR row has no {label}: {line}")
    return match.group(1)


def validate_standardir(source: dict[str, Any], path: Path) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    require(digest(path) == STANDARDIR_SHA256, "StandardIR source hash differs")
    expected = {
        "path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx",
        "sha256": STANDARDIR_SHA256,
        "source_hash": SOURCE_SHA256,
        "rows": EXPECTED_STANDARDIR_ROWS,
    }
    require(source["standardir"] == expected, "StandardIR fixture identity differs")
    for row in EXPECTED_STANDARDIR_ROWS:
        matches = [line for line in lines if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matches) == 1, f"expected one StandardIR row for {row['rule']}")
        line = matches[0]
        require(source_field(line, r"\(lhs ([^)]+)\)", "lhs") == row["lhs"], f"{row['rule']} lhs differs")
        require(int(source_field(line, r"\(page (\d+)\)", "page")) == row["page"], f"{row['rule']} page differs")
        require(int(source_field(line, r"\(byte-start (\d+)\)", "byte-start")) == row["byte_start"], f"{row['rule']} byte-start differs")
        require(int(source_field(line, r"\(byte-length (\d+)\)", "byte-length")) == row["byte_length"], f"{row['rule']} byte-length differs")
        require(int(source_field(line, r"\(occurrence (\d+)\)", "occurrence")) == row["occurrence"], f"{row['rule']} occurrence differs")
        require(source_field(line, r"\(source-sha256 ([^)]+)\)", "source-sha256") == SOURCE_SHA256, f"{row['rule']} source hash differs")


def validate_source_lines(source: dict[str, Any], path: Path) -> None:
    require(digest(path) == SOURCE_SHA256, "canonical source hash differs")
    require(source["canonical_lines"] == EXPECTED_CANONICAL_LINES, "canonical source identity differs")
    lines = path.read_text(encoding="utf-8").split("\n")
    for item in EXPECTED_CANONICAL_LINES:
        parts = lines[item["line"] - 1].split(maxsplit=1)
        require(len(parts) == 2 and parts[0].isdigit() and parts[1] == item["text"], f"canonical source differs at line {item['line']}")
    span = source["source_span"]
    require(span == SOURCE_SPAN, "source span identity differs")
    actual = path.read_bytes()[span["byte_start"] : span["byte_start"] + span["byte_length"]]
    require(actual == EXPECTED_SOURCE_BYTES, "C731 source bytes differ")


def validate_page_index(source: dict[str, Any], path: Path) -> None:
    require(digest(path) == PAGE_INDEX_SHA256, "page index hash differs")
    require(source["page_index"] == EXPECTED_PAGE_INDEX, "page index identity differs")
    require("page 85 start 218135 length 3925" in path.read_text(encoding="utf-8"), "page index span differs")


def validate_semantic_item(doc: dict[str, Any], root: Path, path: Path) -> None:
    item = doc["semantic_item"]
    exact_keys(item, {"path", "sha256", "id", "subject", "document", "clause", "rule", "page", "source_hash", "origin", "resolution"}, "semantic item")
    expected_path = root / item["path"]
    require(path.resolve() == expected_path.resolve(), "semantic-items path differs")
    require(digest(expected_path) == item["sha256"], "semantic-items input hash differs")
    text = expected_path.read_text(encoding="utf-8").strip()
    for fragment in (
        f"(id {item['id']})", f"(subject {item['subject']})", f"(document {item['document']})",
        f"(clause {item['clause']})", f"(rule {item['rule']})", f"(page {item['page']})",
        f"(source-hash {item['source_hash']})", f"(origin {item['origin']})", f"(resolution {item['resolution']})",
    ):
        require(fragment in text, f"semantic-items input lacks {fragment}")


def validate_contract(doc: dict[str, Any], root: Path) -> None:
    schema = (root / doc["contract"]["schema"]).read_text(encoding="utf-8")
    for fragment in (
        "(enum outcome accepted rejected unresolved)",
        "(enum c731-length-form-state constant-expression non-constant-expression unknown)",
        "(enum c731-context-state character-statement-function statement-function-dummy-argument other unknown)",
        "(record character-length-constant-use", "(record semantic-candidate",
    ):
        require(fragment in schema, f"contract schema lacks {fragment}")
    witness = (root / doc["contract"]["fixture"]).read_text(encoding="utf-8")
    for fragment in (
        "(contract m3-c731-constant-expression-oracle)", "(property character-statement-function-length-constant-expression)",
        "(document J3-24-007)", "(clause 7)", "(rule C731)", "(page 85)", "(byte-start 219036)",
        "(byte-length 167)", "(page-start 85)", "(page-end 85)", "(source-hash " + SOURCE_SHA256 + ")",
    ):
        require(fragment in witness, f"contract fixture lacks {fragment}")


def validate_source_binding(doc: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"}, "fixture")
    require(doc["schema_version"] == "m3-c731-source-backed-v0", "fixture schema version differs")
    require(doc["origin"] == "HUMAN", "fixture origin is not HUMAN")
    require(doc["property"] == PROPERTY, "fixture property differs")
    validate_contract(doc, root)
    source = doc["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C731" and source["printed_page"] == 85, "source identity differs")
    require(source["pdf_sha256"] == PDF_SHA256 and source["canonical_text_sha256"] == SOURCE_SHA256, "source hashes differ")
    require(source["canonical_text"] == ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", "canonical path differs")
    require(canonical.resolve() == (root / source["canonical_text"]).resolve(), "canonical input path differs")
    require(page_index.resolve() == (root / source["page_index"]["path"]).resolve(), "page-index input path differs")
    manifest = tomllib.loads((root / "artifacts/standards/j3-24-007.toml").read_text(encoding="utf-8"))
    require(manifest["sha256"] == PDF_SHA256 and manifest["bytes"] == pdf.stat().st_size and digest(pdf) == PDF_SHA256, "normative PDF differs")
    validate_source_lines(source, canonical)
    validate_page_index(source, page_index)
    validate_standardir(source, standardir)
    item = doc["semantic_item"]
    require(item["document"] == source["document"] and item["clause"] == source["clause"] and item["rule"] == source["rule"] and item["page"] == source["printed_page"] and item["source_hash"] == SOURCE_SHA256, "semantic source identity differs")
    validate_semantic_item(doc, root, semantic)


def set_path(document: dict[str, Any], path: list[Any], value: Any) -> None:
    target: Any = document
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value


def validate_shape(doc: dict[str, Any]) -> None:
    require(isinstance(doc["cases"], list) and len(doc["cases"]) == 12, "fixture case count differs")
    results = [validate_candidate(case) for case in doc["cases"]]
    require({(item["length_form"], item["context"]) for item in results} == {(form, context) for form in LENGTH_FORMS for context in CONTEXTS}, "C731 12-state table is incomplete")
    require({item["kind"] for item in results} == {"positive", "negative", "unresolved"}, "fixture witness kinds are incomplete")
    require(sum(item["kind"] == "positive" for item in results) == 2, "positive witness count differs")
    require(sum(item["kind"] == "negative" for item in results) == 2, "negative witness count differs")
    require(sum(item["kind"] == "unresolved" for item in results) == 8, "unresolved witness count differs")
    require(len(doc["mutations"]) == 12, "mutation control count differs")
    for mutation in doc["mutations"]:
        exact_keys(mutation, {"id", "path", "value"}, f"mutation {mutation.get('id', '<missing>')}")
        require(isinstance(mutation["path"], list) and mutation["path"], "mutation path is invalid")


def build_result(fixture_path: Path, fixture: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path, semantic_output: Path, golden: Path, output: Path) -> dict[str, Any]:
    validate_shape(fixture)
    validate_source_binding(fixture, root, pdf, canonical, page_index, standardir, semantic)
    require(semantic_output.read_bytes() == semantic.read_bytes() == golden.read_bytes(), "canonical semantic-items output differs")
    cases = [validate_candidate(case) for case in fixture["cases"]]
    mutations = []
    for mutation in fixture["mutations"]:
        mutated = copy.deepcopy(fixture)
        set_path(mutated, mutation["path"], mutation["value"])
        try:
            validate_source_binding(mutated, root, pdf, canonical, page_index, standardir, semantic)
        except (ContractError, OSError, KeyError, TypeError, ValueError):
            mutations.append({"id": mutation["id"], "result": "REJECTED"})
        else:
            raise ContractError(f"mutation control was accepted: {mutation['id']}")
    counts = {outcome: sum(case["computed"] == outcome for case in cases) for outcome in sorted(OUTCOMES)}
    return {
        "schema_version": fixture["schema_version"], "milestone": "M3", "property": PROPERTY,
        "fixture": str(fixture_path.relative_to(root)), "fixture_sha256": digest(fixture_path),
        "contract": {"schema": fixture["contract"]["schema"], "schema_sha256": digest(root / fixture["contract"]["schema"]), "fixture": fixture["contract"]["fixture"], "fixture_sha256": digest(root / fixture["contract"]["fixture"]), "version": fixture["contract"]["version"]},
        "source": {"document": fixture["source"]["document"], "clause": fixture["source"]["clause"], "rule": fixture["source"]["rule"], "printed_page": fixture["source"]["printed_page"], "pdf_sha256": digest(pdf), "canonical_text_sha256": digest(canonical), "page_index_sha256": digest(page_index), "standardir_sha256": digest(standardir), "canonical_lines": [item["line"] for item in fixture["source"]["canonical_lines"]], "source_span": fixture["source"]["source_span"], "page_index": fixture["source"]["page_index"], "standardir_rules": [row["rule"] for row in fixture["source"]["standardir"]["rows"]]},
        "semantic_items": {"input": fixture["semantic_item"]["path"], "input_sha256": digest(semantic), "canonical_output_sha256": digest(semantic_output), "canonical_output": "PASS"},
        "cases": cases, "outcome_counts": counts, "mutation_controls": mutations,
        "model_calls": 0, "semantic_promotions": 0, "origin": "MECHANICAL", "oracle": "tests/e2e/validate_m3_c731.py",
    }


def self_test() -> None:
    expected = {
        (form, context): ("ACCEPTED" if form == "constant-expression" else "REJECTED" if form == "non-constant-expression" else "UNRESOLVED")
        if context in SOURCE_NAMED_CONTEXTS else "UNRESOLVED"
        for form in LENGTH_FORMS for context in CONTEXTS
    }
    for (form, context), outcome in expected.items():
        require(c731_oracle({"length_form": form, "context": context}) == outcome, f"self-test outcome differs: {form}/{context}")
    print("M3 C731 oracle self-test: PASS")


def main(argv: list[str]) -> int:
    if argv[1:] == ["--self-test"]:
        self_test()
        return 0
    if len(argv) != 9:
        print("usage: validate_m3_c731.py FIXTURE SEMANTIC_OUTPUT STANDARDIR CANONICAL_TEXT PAGE_INDEX PDF GOLDEN RESULT_JSON", file=sys.stderr)
        return 2
    fixture_path, semantic_output, standardir, canonical, page_index, pdf, golden, result_path = map(Path, argv[1:])
    root = fixture_path.resolve().parents[2]
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        result = build_result(fixture_path.resolve(), fixture, root, pdf.resolve(), canonical.resolve(), page_index.resolve(), standardir.resolve(), root / fixture["semantic_item"]["path"], semantic_output.resolve(), golden.resolve(), result_path.resolve())
        result_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"M3 C731 validator: FAIL: {error}", file=sys.stderr)
        return 1
    print("M3 C731 validator: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
