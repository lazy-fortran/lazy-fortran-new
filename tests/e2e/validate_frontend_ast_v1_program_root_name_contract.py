#!/usr/bin/env python3
"""Independent pre-implementation oracle for the program-root-name contract."""

from __future__ import annotations

import hashlib
import re
import sys
import tomllib
from pathlib import Path


class ValidationError(RuntimeError):
    pass


NAME = re.compile(rb"^[A-Za-z][A-Za-z0-9_]*$")
RULES = ["R501", "R1401", "R1402", "R1403", "C1401", "R601", "R603", "R704", "R705", "R801"]
PREFIX = b"program "
MIDDLE = b"\n  integer :: x\nend program "
SUFFIX = b"\n"
NEGATIVE = b"program main\n  integer :: x\nend program other\n"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if len(sys.argv) != 2:
        raise ValidationError("usage: validate_frontend_ast_v1_program_root_name_contract.py manifest")
    root = Path(__file__).resolve().parents[2]
    manifest = tomllib.loads((root / sys.argv[1]).read_text(encoding="utf-8"))
    witness = root / manifest["contract_witness"]
    schema = root / manifest["contract_schema"]
    oracle_path = root / manifest["expected_oracle"]
    oracle = tomllib.loads(oracle_path.read_text(encoding="utf-8"))
    require(manifest["origin"] == "LLM", "fixture origin differs")
    require(manifest["model_calls"] == 0 and manifest["semantic_promotions"] == 0, "promotion guard differs")
    require(digest(schema) == manifest["contract_schema_sha256"], "schema hash differs")
    require(digest(witness) == manifest["contract_witness_sha256"], "witness hash differs")
    require(digest(oracle_path) == manifest["expected_oracle_sha256"], "oracle hash differs")
    require(manifest["source_evidence_document"] == "J3-24-007", "source document differs")
    require(manifest["source_evidence_pdf_sha256"] == "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2", "PDF evidence hash differs")
    require(manifest["source_evidence_standardir_sha256"] == "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2", "StandardIR evidence hash differs")
    require(manifest["source_evidence_source_sha256"] == "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e", "source evidence hash differs")
    canonical = root / manifest["source_evidence_canonical_text"]
    require(canonical.is_file(), "canonical source text is absent")
    require(digest(canonical) == manifest["source_evidence_canonical_text_sha256"], "canonical source text hash differs")
    canonical_lines = canonical.read_text(encoding="utf-8").split("\n")
    require(
        [canonical_lines[line - 1] for line in manifest["source_evidence_canonical_lines"]]
        == manifest["source_evidence_canonical_line_text"],
        "canonical C1401 text differs",
    )
    require(manifest["source_evidence_rules"] == RULES, "source rules differ")
    require(manifest["source_evidence_pages"] == [53, 54, 67, 68, 80, 117, 317], "source pages differ")
    require(manifest["source_evidence_canonical_lines"] == [13669, 13670], "canonical constraint lines differ")
    witness_text = witness.read_text(encoding="utf-8")
    require(f"(property {manifest['property']})" in witness_text, "witness property differs")
    require("(pdf-sha256 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" in witness_text, "witness PDF hash differs")
    require("(source-sha256 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e)" in witness_text, "witness source hash differs")
    require("(canonical-text .cache/runs/E0001/R000003/j3-24-007.canonical.txt)" in witness_text, "witness canonical text path differs")
    require("(canonical-text-sha256 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e)" in witness_text, "witness canonical text hash differs")
    require("(rules R501 R1401 R1402 R1403 C1401 R601 R603 R704 R705 R801)" in witness_text, "witness rules differ")
    require("(canonical-lines 13669 13670)" in witness_text, "witness constraint lines differ")
    oracle_cases = {case["id"]: case for case in oracle["case"]}
    cases = manifest["case"]
    require([case["id"] for case in cases] == ["main", "unit"], "case order differs")
    require(set(oracle_cases) == {case["id"] for case in cases}, "oracle cases differ")
    sources: dict[str, bytes] = {}
    for case in cases:
        source_path = root / case["source"]
        source = source_path.read_bytes()
        sources[case["id"]] = source
        require(digest(source_path) == case["source_sha256"], f"{case['id']} source hash differs")
        name = case["expected_root_name"].encode("ascii")
        require(NAME.fullmatch(name) is not None, f"{case['id']} root name is outside R603 witness")
        expected = PREFIX + name + MIDDLE + name + SUFFIX
        require(source == expected, f"{case['id']} source spelling differs")
        require(case["expected_program_declaration_name"] == case["expected_root_name"], f"{case['id']} root/declaration relation differs")
        require(f"(id {case['id']})" in witness_text, f"{case['id']} witness case missing")
        require(f"(source {case['source']})" in witness_text, f"{case['id']} witness source differs")
        require(f"(source-sha256 {case['source_sha256']})" in witness_text, f"{case['id']} witness hash differs")
        require(f"(root-name {case['expected_root_name']})" in witness_text, f"{case['id']} witness root differs")
        require(f"(program-declaration-name {case['expected_program_declaration_name']})" in witness_text, f"{case['id']} witness declaration differs")
        expected_oracle = oracle_cases[case["id"]]
        for field in ("expected_outcome", "expected_root_name", "expected_program_declaration_name"):
            require(case[field] == expected_oracle[field], f"{case['id']} oracle field differs: {field}")
    require(sources["main"] != sources["unit"], "changed-name control is not distinct")
    require(sources["main"].replace(b"main", b"NAME") == sources["unit"].replace(b"unit", b"NAME"), "changed control changes more than root name")
    negative_path = root / manifest["negative"]
    require(digest(negative_path) == manifest["negative_sha256"], "negative hash differs")
    require(negative_path.read_bytes() == NEGATIVE, "negative source differs")
    require("(id mismatched-end)" in witness_text, "negative witness case missing")
    require(f"(source {manifest['negative']})" in witness_text, "negative witness source differs")
    require(f"(source-sha256 {manifest['negative_sha256']})" in witness_text, "negative witness hash differs")
    require("(expected-outcome rejected)" in witness_text, "negative witness outcome differs")
    require(oracle["negative"] == [{"id": "mismatched-end", "expected_outcome": "REJECTED"}], "negative oracle differs")
    print("frontend AST v1 program-root-name contract oracle PASS: 2 source cases, 1 changed-name control, 1 mismatched-end negative")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValidationError, ValueError) as error:
        print(f"frontend AST v1 program-root-name contract oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
