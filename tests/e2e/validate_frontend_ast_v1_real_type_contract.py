#!/usr/bin/env python3
"""Independent pre-implementation oracle for the bounded REAL type contract."""

from __future__ import annotations

import hashlib
import sys
import tomllib
from pathlib import Path


class ValidationError(RuntimeError):
    pass


RULES = ["R501", "R1401", "R1402", "R1403", "C1401", "R601", "R603", "R702", "R703", "R704", "R801"]
PAGES = [53, 54, 68, 77, 80, 117, 317]
CANONICAL_LINES = [3135, 3140, 3255, 3256, 3257, 3258, 3259, 3260, 4869, 13669, 13670]
CANONICAL_TEXT = [
    "15 R702 type-spec is intrinsic-type-spec",
    "20 R703 declaration-type-spec is intrinsic-type-spec",
    "7 R704 intrinsic-type-spec is integer-type-spec",
    "8 or REAL [ kind-selector ]",
    "9 or DOUBLE PRECISION",
    "10 or COMPLEX [ kind-selector ]",
    "11 or CHARACTER [ char-selector ]",
    "12 or LOGICAL [ kind-selector ]",
    "13 R801 type-declaration-stmt is declaration-type-spec [ [ , attr-spec ] ... :: ] entity-decl-list",
    "12 C1401 (R1401) The program-name shall not be included in the end-program-stmt unless the optional program-",
    "13 stmt is used. If included, it shall be identical to the program-name specified in the program-stmt.",
]
REAL_SOURCE = b"program main\n  real :: x\nend program main\n"
INTEGER_SOURCE = b"program main\n  integer :: x\nend program main\n"
NEGATIVE_SOURCE = b"program main\n  real ::\nend program main\n"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if len(sys.argv) != 2:
        raise ValidationError("usage: validate_frontend_ast_v1_real_type_contract.py manifest")
    root = Path(__file__).resolve().parents[2]
    manifest = tomllib.loads((root / sys.argv[1]).read_text(encoding="utf-8"))
    witness = root / manifest["contract_witness"]
    schema = root / manifest["contract_schema"]
    oracle_path = root / manifest["expected_oracle"]
    oracle = tomllib.loads(oracle_path.read_text(encoding="utf-8"))
    canonical = root / manifest["source_evidence_canonical_text"]
    require(manifest["origin"] == "LLM", "fixture origin differs")
    require(manifest["model_calls"] == 0 and manifest["semantic_promotions"] == 0, "promotion guard differs")
    require(digest(schema) == manifest["contract_schema_sha256"], "schema hash differs")
    require(digest(witness) == manifest["contract_witness_sha256"], "witness hash differs")
    require(digest(oracle_path) == manifest["expected_oracle_sha256"], "oracle hash differs")
    require(manifest["source_evidence_document"] == "J3-24-007", "source document differs")
    require(manifest["source_evidence_pdf_sha256"] == "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2", "PDF hash differs")
    require(manifest["source_evidence_standardir_sha256"] == "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2", "StandardIR hash differs")
    require(manifest["source_evidence_source_sha256"] == "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e", "source hash differs")
    require(canonical.is_file(), "canonical source text is absent")
    require(digest(canonical) == manifest["source_evidence_canonical_text_sha256"], "canonical hash differs")
    canonical_lines = canonical.read_text(encoding="utf-8").split("\n")
    require([canonical_lines[line - 1] for line in manifest["source_evidence_canonical_lines"]] == manifest["source_evidence_canonical_line_text"], "canonical evidence differs")
    require(manifest["source_evidence_rules"] == RULES, "source rules differ")
    require(manifest["source_evidence_pages"] == PAGES, "source pages differ")
    require(manifest["source_evidence_canonical_lines"] == CANONICAL_LINES, "canonical line numbers differ")
    require(manifest["source_evidence_canonical_line_text"] == CANONICAL_TEXT, "canonical line text differs")
    require(oracle["origin"] == "LLM" and oracle["model_calls"] == 0 and oracle["semantic_promotions"] == 0, "oracle guard differs")
    witness_text = witness.read_text(encoding="utf-8")
    require(f"(property {manifest['property']})" in witness_text, "witness property differs")
    require("(rules R501 R1401 R1402 R1403 C1401 R601 R603 R702 R703 R704 R801)" in witness_text, "witness rules differ")
    require("(canonical-lines 3135 3140 3255 3256 3257 3258 3259 3260 4869 13669 13670)" in witness_text, "witness line numbers differ")
    expected = {case["id"]: case for case in manifest["case"]}
    oracle_cases = {case["id"]: case for case in oracle["case"]}
    require(list(expected) == ["real", "integer-control"], "case order differs")
    require(set(expected) == set(oracle_cases), "oracle cases differ")
    for case_id, case in expected.items():
        source_path = root / case["source"]
        source = source_path.read_bytes()
        require(digest(source_path) == case["source_sha256"], f"{case_id} source hash differs")
        expected_source = REAL_SOURCE if case_id == "real" else INTEGER_SOURCE
        require(source == expected_source, f"{case_id} source spelling differs")
        require(case["expected_variable_type"] in {"real", "integer"}, f"{case_id} type differs")
        require(case["expected_variable_name"] == "x", f"{case_id} variable differs")
        require(case["expected_root_name"] == "main" and case["expected_program_declaration_name"] == "main", f"{case_id} root differs")
        oracle_case = oracle_cases[case_id]
        for field in ("expected_outcome", "expected_root_name", "expected_program_declaration_name", "expected_variable_type", "expected_variable_name"):
            require(case[field] == oracle_case[field], f"{case_id} oracle field differs: {field}")
        require(f"(id {case_id})" in witness_text, f"{case_id} witness case missing")
        require(f"(source {case['source']})" in witness_text, f"{case_id} witness source differs")
        require(f"(source-sha256 {case['source_sha256']})" in witness_text, f"{case_id} witness hash differs")
        require(f"(variable-type {case['expected_variable_type']})" in witness_text, f"{case_id} witness type differs")
    require(expected["real"]["source"] != expected["integer-control"]["source"], "changed-type control reuses positive source")
    negative = root / manifest["negative"]
    require(digest(negative) == manifest["negative_sha256"], "negative hash differs")
    require(negative.read_bytes() == NEGATIVE_SOURCE, "negative source differs")
    require(oracle["negative"] == [{"id": "missing-entity", "expected_outcome": "REJECTED"}], "negative oracle differs")
    require("(id missing-entity)" in witness_text and "(expected-outcome rejected)" in witness_text, "negative witness differs")
    print("frontend AST v1 REAL type contract oracle PASS: REAL positive, integer changed-type control, malformed negative")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValidationError, ValueError) as error:
        print(f"frontend AST v1 REAL type contract oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
