#!/usr/bin/env python3
"""Independent validator for the bounded M3 C745 semantic slice."""

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
SEQUENCE_PRESENCES = {"absent", "present", "unknown"}
COMPONENT_PRESENCES = {"zero", "one-or-more", "unknown"}
CONTEXTS = {"derived-type-def", "other", "unknown"}
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PROPERTY = "derived-type-def-sequence-component-presence"
SOURCE_SPAN = {"byte_start": 232141, "byte_length": 276, "page_start": 89, "page_end": 89}
CANONICAL_LINES = [
    {"line": 3665, "text": "C745 (R726) If SEQUENCE appears, the type shall have at least one component, each data component shall"},
    {"line": 3666, "text": "be declared to be of an intrinsic type or of a sequence type, the derived type shall not have any type"},
    {"line": 3667, "text": "parameter, and a type-bound-procedure-part shall not appear."},
]
PAGE = {"page": 89, "start": 230288, "length": 2594}
STANDARDIR_ROWS = [
    {"rule": "R726", "lhs": "derived-type-def", "page": 88, "byte_start": 229000, "byte_length": 177, "occurrence": 76},
    {"rule": "R731", "lhs": "sequence-stmt", "page": 89, "byte_start": 232107, "byte_length": 33, "occurrence": 81},
    {"rule": "R735", "lhs": "component-part", "page": 93, "byte_start": 240048, "byte_length": 51, "occurrence": 85},
]
SOURCE_BYTES = b"20 C745 (R726) If SEQUENCE appears, the type shall have at least one component, each data component shall\n21 be declared to be of an intrinsic type or of a sequence type, the derived type shall not have any type\n22 parameter, and a type-bound-procedure-part shall not appear.\n"


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
    if candidate["context"] != "derived-type-def":
        return "UNRESOLVED"
    if candidate["sequence_presence"] == "absent":
        return "ACCEPTED"
    if candidate["sequence_presence"] == "present" and candidate["component_presence"] == "one-or-more":
        return "ACCEPTED"
    if candidate["sequence_presence"] == "present" and candidate["component_presence"] == "zero":
        return "REJECTED"
    return "UNRESOLVED"


def validate_case(case: dict[str, Any]) -> dict[str, Any]:
    exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case.get('id', '<missing>')}")
    require(case["kind"] in {"positive", "negative", "unresolved"}, f"case {case['id']} kind invalid")
    require(case["expected"] in OUTCOMES, f"case {case['id']} outcome invalid")
    candidate = case["candidate"]
    exact_keys(candidate, {"fact", "source_rule", "sequence_presence", "component_presence", "context"}, f"case {case['id']} candidate")
    require(candidate["fact"] == PROPERTY, f"case {case['id']} property differs")
    require(candidate["source_rule"] == "C745", f"case {case['id']} source rule differs")
    require(candidate["sequence_presence"] in SEQUENCE_PRESENCES, f"case {case['id']} sequence presence invalid")
    require(candidate["component_presence"] in COMPONENT_PRESENCES, f"case {case['id']} component presence invalid")
    require(candidate["context"] in CONTEXTS, f"case {case['id']} context invalid")
    computed = oracle(candidate)
    require(computed == case["expected"], f"case {case['id']} expected outcome disagrees")
    return {"id": case["id"], "kind": case["kind"], "sequence_presence": candidate["sequence_presence"], "component_presence": candidate["component_presence"], "context": candidate["context"], "computed": computed, "expected": case["expected"]}


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
    r726 = next(line for line in lines if line.startswith("(syntax R726 "))
    r731 = next(line for line in lines if line.startswith("(syntax R731 "))
    r735 = next(line for line in lines if line.startswith("(syntax R735 "))
    require("(lhs derived-type-def)" in r726, "R726 shape differs")
    require("(lhs sequence-stmt)" in r731 and "(token SEQUENCE)" in r731, "R731 shape differs")
    require("(lhs component-part)" in r735 and "(repeat (ref component-def-stmt) 0 unbounded)" in r735, "R735 shape differs")


def validate_binding(doc: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutations"}, "fixture")
    require(doc["schema_version"] == "m3-c745-source-backed-v0" and doc["origin"] == "HUMAN" and doc["property"] == PROPERTY, "fixture identity differs")
    source = doc["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C745" and source["printed_page"] == 89, "source identity differs")
    require(source["pdf_sha256"] == PDF_SHA256 and source["canonical_text_sha256"] == SOURCE_SHA256, "source hash differs")
    require(canonical.resolve() == (root / source["canonical_text"]).resolve(), "canonical path differs")
    require(page_index.resolve() == (root / source["page_index"]["path"]).resolve(), "page index path differs")
    manifest = tomllib.loads((root / "artifacts/standards/j3-24-007.toml").read_text(encoding="utf-8"))
    require(manifest["sha256"] == PDF_SHA256 and manifest["bytes"] == pdf.stat().st_size and digest(pdf) == PDF_SHA256, "normative PDF differs")
    require(digest(canonical) == SOURCE_SHA256 and source["canonical_lines"] == CANONICAL_LINES, "canonical identity differs")
    lines = canonical.read_bytes().splitlines(keepends=True)
    require(lines[3664] == SOURCE_BYTES.splitlines(keepends=True)[0] and lines[3665] == SOURCE_BYTES.splitlines(keepends=True)[1] and lines[3666] == SOURCE_BYTES.splitlines(keepends=True)[2], "canonical lines differ")
    require(source["source_span"] == SOURCE_SPAN and canonical.read_bytes()[232141:232417] == SOURCE_BYTES, "source span differs")
    require(digest(page_index) == PAGE_INDEX_SHA256 and source["page_index"] == {"path": ".cache/runs/E0001/R000003/j3-24-007.pages.index", "sha256": PAGE_INDEX_SHA256, "pages": [PAGE]}, "page index identity differs")
    require("page 89 start 230288 length 2594" in page_index.read_text(encoding="utf-8"), "page index span differs")
    validate_standardir(source, standardir)
    item = doc["semantic_item"]
    exact_keys(item, {"path", "sha256", "id", "subject", "document", "clause", "rule", "page", "source_hash", "origin", "resolution"}, "semantic item")
    require(item["document"] == "J3-24-007" and item["clause"] == "7" and item["rule"] == "C745" and item["page"] == 89 and item["source_hash"] == SOURCE_SHA256, "semantic source identity differs")
    require((root / item["path"]).resolve() == semantic.resolve() and digest(semantic) == item["sha256"], "semantic item hash differs")
    text = semantic.read_text(encoding="utf-8")
    for fragment in ("(id S-C745)", "(subject " + PROPERTY + ")", "(origin human)", "(resolution disputed)"):
        require(fragment in text, f"semantic item lacks {fragment}")
    schema = (root / doc["contract"]["schema"]).read_text(encoding="utf-8")
    for fragment in ("(enum c745-sequence-presence absent present unknown)", "(enum c745-component-presence zero one-or-more unknown)", "(record sequence-component-use"):
        require(fragment in schema, f"contract schema lacks {fragment}")
    witness = (root / doc["contract"]["fixture"]).read_text(encoding="utf-8")
    for fragment in ("(contract m3-c745-derived-type-sequence-component-presence)", "(property " + PROPERTY + ")", "(rule C745)", "(page 89)", "(byte-start 232141)", "(byte-length 276)", "(source-hash " + SOURCE_SHA256 + ")"):
        require(fragment in witness, f"contract fixture lacks {fragment}")


def set_path(document: dict[str, Any], path: list[Any], value: Any) -> None:
    target: Any = document
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value


def build_result(fixture_path: Path, fixture: dict[str, Any], root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path, semantic_output: Path, golden: Path, output: Path) -> dict[str, Any]:
    require(len(fixture["cases"]) == 27, "case count differs")
    cases = [validate_case(case) for case in fixture["cases"]]
    require({(case["sequence_presence"], case["component_presence"], case["context"]) for case in cases} == {(sequence_presence, component_presence, context) for sequence_presence in SEQUENCE_PRESENCES for component_presence in COMPONENT_PRESENCES for context in CONTEXTS}, "27-state table incomplete")
    require(sum(case["kind"] == "positive" for case in cases) == 4 and sum(case["kind"] == "negative" for case in cases) == 1 and sum(case["kind"] == "unresolved" for case in cases) == 22, "witness kind counts differ")
    require(len(fixture["mutations"]) == 12, "mutation count differs")
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, semantic)
    require(semantic_output.read_bytes() == semantic.read_bytes() == golden.read_bytes(), "semantic canonicalization differs")
    mutations = []
    for mutation in fixture["mutations"]:
        mutated = copy.deepcopy(fixture)
        set_path(mutated, mutation["path"], mutation["value"])
        try:
            validate_binding(mutated, root, pdf, canonical, page_index, standardir, semantic)
        except (ContractError, OSError, KeyError, TypeError, ValueError):
            mutations.append({"id": mutation["id"], "result": "REJECTED"})
        else:
            raise ContractError(f"mutation accepted: {mutation['id']}")
    result = {
        "schema_version": fixture["schema_version"], "milestone": "M3", "property": PROPERTY,
        "fixture": str(fixture_path.relative_to(root)), "fixture_sha256": digest(fixture_path),
        "contract": {"schema": fixture["contract"]["schema"], "schema_sha256": digest(root / fixture["contract"]["schema"]), "fixture": fixture["contract"]["fixture"], "fixture_sha256": digest(root / fixture["contract"]["fixture"]), "version": fixture["contract"]["version"]},
        "source": {"document": "J3-24-007", "clause": "7", "rule": "C745", "printed_page": 89, "pdf_sha256": digest(pdf), "canonical_text_sha256": digest(canonical), "page_index_sha256": digest(page_index), "standardir_sha256": digest(standardir), "canonical_lines": [3665, 3666, 3667], "source_span": SOURCE_SPAN, "page_index": {"path": ".cache/runs/E0001/R000003/j3-24-007.pages.index", "sha256": PAGE_INDEX_SHA256, "pages": [PAGE]}, "standardir_rules": ["R726", "R731", "R735"]},
        "semantic_items": {"input": "tests/fixtures/m3-c745-semantic-items.sx", "input_sha256": digest(semantic), "canonical_output_sha256": digest(semantic_output), "canonical_output": "PASS"},
        "cases": cases, "outcome_counts": {outcome: sum(case["computed"] == outcome for case in cases) for outcome in sorted(OUTCOMES)}, "mutation_controls": mutations,
        "model_calls": 0, "semantic_promotions": 0, "origin": "MECHANICAL", "oracle": "tests/e2e/validate_m3_c745.py",
    }
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


def self_test() -> None:
    for sequence_presence in SEQUENCE_PRESENCES:
        for component_presence in COMPONENT_PRESENCES:
            for context in CONTEXTS:
                expected = "UNRESOLVED"
                if context == "derived-type-def" and sequence_presence == "absent":
                    expected = "ACCEPTED"
                elif context == "derived-type-def" and sequence_presence == "present" and component_presence == "one-or-more":
                    expected = "ACCEPTED"
                elif context == "derived-type-def" and sequence_presence == "present" and component_presence == "zero":
                    expected = "REJECTED"
                require(oracle({"sequence_presence": sequence_presence, "component_presence": component_presence, "context": context}) == expected, f"self-test failed for {sequence_presence}/{component_presence}/{context}")


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
        print("C745 oracle self-test PASS")
        return 0
    if len(sys.argv) != 9:
        raise SystemExit("usage: validate_m3_c745.py fixture semantic-output standardir canonical page-index pdf golden result")
    fixture_path, semantic_output, standardir, canonical, page_index, pdf, golden, output = map(Path, sys.argv[1:])
    root = Path(__file__).resolve().parents[2]
    try:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        result = build_result(fixture_path, fixture, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c745-semantic-items.sx", semantic_output, golden, output)
    except (ContractError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"C745 oracle FAIL: {error}", file=sys.stderr)
        return 1
    print(json.dumps({"outcome_counts": result["outcome_counts"], "mutation_controls": len(result["mutation_controls"]), "model_calls": 0, "semantic_promotions": 0}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
