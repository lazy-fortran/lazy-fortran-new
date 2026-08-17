#!/usr/bin/env python3
"""Independent validator for the bounded M3 C732 semantic slice."""

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
KIND_PARAM_STATES = {"processor-supported", "processor-unsupported", "unknown"}
CONTEXTS = {"char-literal-constant", "other", "unknown"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PROPERTY = "character-literal-kind-param-processor-representation-method"
SOURCE_SPAN = {"byte_start": 221195, "byte_length": 107, "page_start": 85, "page_end": 85}
EXPECTED_CANONICAL_LINES = [
    {"line": 3493, "text": "C732 (R724) The value of kind-param shall specify a representation method that exists on the processor."},
]
EXPECTED_PAGE_INDEX = {
    "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index",
    "sha256": PAGE_INDEX_SHA256,
    "pages": [{"page": 85, "start": 218135, "length": 3925}],
}
EXPECTED_STANDARDIR_ROWS = [
    {"rule": "R724", "lhs": "char-literal-constant", "page": 85, "byte_start": 221076, "byte_length": 118, "occurrence": 74},
]
EXPECTED_SOURCE_BYTES = b"34 C732 (R724) The value of kind-param shall specify a representation method that exists on the processor.\n"


class ContractError(Exception):
    """A source, schema, fact or oracle contract failure."""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    require(set(value) == expected, f"{label} keys differ")


def c732_oracle(candidate: dict[str, Any]) -> str:
    """Apply only C732's typed representation-method/context relation."""

    if candidate["context"] != "char-literal-constant":
        return "UNRESOLVED"
    if candidate["kind_param_state"] == "processor-supported":
        return "ACCEPTED"
    if candidate["kind_param_state"] == "processor-unsupported":
        return "REJECTED"
    return "UNRESOLVED"


def validate_candidate(case: dict[str, Any]) -> dict[str, Any]:
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case.get('id', '<missing>')}")
    require(isinstance(case["id"], str) and case["id"], "case id is invalid")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind is invalid")
    require(case["expected"] in OUTCOMES, f"case {case['id']} expected outcome is invalid")
    candidate = case["candidate"]
    require(isinstance(candidate, dict), f"case {case['id']} candidate is not an object")
    exact_keys(candidate, {"fact", "source_rule", "kind_param_state", "context"}, f"case {case['id']} candidate")
    require(candidate["fact"] == PROPERTY, f"case {case['id']} candidate fact differs")
    require(candidate["source_rule"] == "C732", f"case {case['id']} source rule differs")
    require(candidate["kind_param_state"] in KIND_PARAM_STATES, f"case {case['id']} kind-param state is invalid")
    require(candidate["context"] in CONTEXTS, f"case {case['id']} context state is invalid")
    computed = c732_oracle(candidate)
    require(computed == case["expected"], f"case {case['id']} expected outcome disagrees with oracle")
    return {
        "id": case["id"],
        "kind": case["kind"],
        "kind_param_state": candidate["kind_param_state"],
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
    require(actual == EXPECTED_SOURCE_BYTES, "C732 source bytes differ")


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
        "(enum c732-kind-param-state processor-supported processor-unsupported unknown)",
        "(enum c732-context-state char-literal-constant other unknown)",
        "(record kind-param-representation-use", "(record semantic-candidate",
    ):
        require(fragment in schema, f"contract schema lacks {fragment}")
    witness = (root / doc["contract"]["fixture"]).read_text(encoding="utf-8")
    for fragment in (
        "(contract m3-c732-kind-param-representation-method-oracle)", "(property " + PROPERTY + ")",
        "(document J3-24-007)", "(clause 7)", "(rule C732)", "(page 85)",
        "(byte-start 221195)", "(byte-length 107)", "(page-start 85)",
        "(page-end 85)", "(source-hash " + SOURCE_SHA256 + ")",
    ):
        require(fragment in witness, f"contract fixture lacks {fragment}")


def validate_source_binding(doc: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"}, "fixture")
    require(doc["schema_version"] == "m3-c732-source-backed-v0", "fixture schema version differs")
    require(doc["origin"] == "HUMAN", "fixture origin is not HUMAN")
    require(doc["property"] == PROPERTY, "fixture property differs")
    validate_contract(doc, root)
    source = doc["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C732" and source["printed_page"] == 85, "source identity differs")
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
    require(isinstance(doc["cases"], list) and len(doc["cases"]) == 9, "fixture case count differs")
    results = [validate_candidate(case) for case in doc["cases"]]
    require({(item["kind_param_state"], item["context"]) for item in results} == {(state, context) for state in KIND_PARAM_STATES for context in CONTEXTS}, "C732 9-state table is incomplete")
    require({item["kind"] for item in results} == {"positive", "negative", "unresolved"}, "fixture witness kinds are incomplete")
    require(sum(item["kind"] == "positive" for item in results) == 1, "positive witness count differs")
    require(sum(item["kind"] == "negative" for item in results) == 1, "negative witness count differs")
    require(sum(item["kind"] == "unresolved" for item in results) == 7, "unresolved witness count differs")
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
    result = {
        "schema_version": fixture["schema_version"], "milestone": "M3", "property": PROPERTY,
        "fixture": str(fixture_path.relative_to(root)), "fixture_sha256": digest(fixture_path),
        "contract": {"schema": fixture["contract"]["schema"], "schema_sha256": digest(root / fixture["contract"]["schema"]), "fixture": fixture["contract"]["fixture"], "fixture_sha256": digest(root / fixture["contract"]["fixture"]), "version": fixture["contract"]["version"]},
        "source": {"document": fixture["source"]["document"], "clause": fixture["source"]["clause"], "rule": fixture["source"]["rule"], "printed_page": fixture["source"]["printed_page"], "pdf_sha256": digest(pdf), "canonical_text_sha256": digest(canonical), "page_index_sha256": digest(page_index), "standardir_sha256": digest(standardir), "canonical_lines": [item["line"] for item in fixture["source"]["canonical_lines"]], "source_span": fixture["source"]["source_span"], "page_index": fixture["source"]["page_index"], "standardir_rules": [row["rule"] for row in fixture["source"]["standardir"]["rows"]]},
        "semantic_items": {"input": fixture["semantic_item"]["path"], "input_sha256": digest(semantic), "canonical_output_sha256": digest(semantic_output), "canonical_output": "PASS"},
        "cases": cases, "outcome_counts": counts, "mutation_controls": mutations,
        "model_calls": 0, "semantic_promotions": 0, "origin": "MECHANICAL", "oracle": "tests/e2e/validate_m3_c732.py",
    }
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


def self_test() -> None:
    expected = {
        (state, context): "ACCEPTED" if state == "processor-supported" and context == "char-literal-constant" else "REJECTED" if state == "processor-unsupported" and context == "char-literal-constant" else "UNRESOLVED"
        for state in KIND_PARAM_STATES for context in CONTEXTS
    }
    for (state, context), outcome in expected.items():
        require(c732_oracle({"kind_param_state": state, "context": context}) == outcome, f"self-test failed for {state}/{context}")


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
        print("C732 oracle self-test PASS")
        return 0
    if len(sys.argv) != 9:
        raise SystemExit("usage: validate_m3_c732.py fixture semantic-output standardir canonical page-index pdf golden result")
    fixture_path, semantic_output, standardir, canonical, page_index, pdf, golden, output = map(Path, sys.argv[1:])
    root = Path(__file__).resolve().parents[2]
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        result = build_result(fixture_path, fixture, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c732-semantic-items.sx", semantic_output, golden, output)
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"C732 oracle FAIL: {error}", file=sys.stderr)
        return 1
    print(json.dumps({"outcome_counts": result["outcome_counts"], "mutation_controls": len(result["mutation_controls"]), "model_calls": 0, "semantic_promotions": 0}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
