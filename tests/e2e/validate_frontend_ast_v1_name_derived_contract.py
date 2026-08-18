#!/usr/bin/env python3
"""Independent pre-implementation oracle for the source-derived-name contract."""

from __future__ import annotations

import hashlib
import re
import sys
import tomllib
from pathlib import Path


class ValidationError(RuntimeError):
    pass


NAME = re.compile(rb"^[A-Za-z][A-Za-z0-9_]*$")
POSITIVE_PREFIX = b"program p\n  integer :: "
POSITIVE_SUFFIX = b"\nend program p\n"
NEGATIVE = b"program p\n  integer ::\nend program p\n"
RULES = ["R501", "R1401", "R504", "R507", "R508", "R601", "R602", "R603", "R704", "R705", "R801", "R903"]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if len(sys.argv) != 2:
        raise ValidationError("usage: validate_frontend_ast_v1_name_derived_contract.py manifest")
    root = Path(__file__).resolve().parents[2]
    manifest_path = root / sys.argv[1]
    manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))
    witness = root / manifest["contract_witness"]
    schema = root / manifest["contract_schema"]
    oracle_path = root / manifest["expected_oracle"]
    oracle = tomllib.loads(oracle_path.read_text(encoding="utf-8"))

    require(manifest["origin"] == "LLM", "fixture origin differs")
    require(manifest["model_calls"] == 0, "model-call guard differs")
    require(manifest["semantic_promotions"] == 0, "promotion guard differs")
    require(digest(schema) == manifest["contract_schema_sha256"], "schema hash differs")
    require(digest(witness) == manifest["contract_witness_sha256"], "witness hash differs")
    require(digest(oracle_path) == manifest["expected_oracle_sha256"], "oracle hash differs")
    require(manifest["source_evidence_document"] == "J3-24-007", "source document differs")
    require(manifest["source_evidence_rules"] == RULES, "source rules differ")
    require(oracle["origin"] == "LLM", "oracle origin differs")
    require(oracle["property"] == manifest["property"], "oracle property differs")
    require(oracle["source_rules"] == ["R601", "R602", "R603", "R903"], "oracle source rules differ")
    require(oracle["model_calls"] == 0 and oracle["semantic_promotions"] == 0, "oracle guard differs")

    cases = manifest["case"]
    oracle_cases = {case["id"]: case for case in oracle["case"]}
    require([case["id"] for case in cases] == ["beta", "q7", "theta-2"], "case order differs")
    require(set(oracle_cases) == {case["id"] for case in cases}, "oracle case IDs differ")
    sources: dict[str, bytes] = {}
    for case in cases:
        source_path = root / case["source"]
        source = source_path.read_bytes()
        sources[case["id"]] = source
        require(digest(source_path) == case["source_sha256"], f"{case['id']} source hash differs")
        require(source.startswith(POSITIVE_PREFIX) and source.endswith(POSITIVE_SUFFIX), f"{case['id']} source envelope differs")
        name = case["expected_variable_name"].encode("ascii")
        require(NAME.fullmatch(name) is not None, f"{case['id']} name is outside R603 witness")
        expected = POSITIVE_PREFIX + name + POSITIVE_SUFFIX
        require(source == expected, f"{case['id']} source spelling differs")
        start = case["expected_variable_start_byte"]
        end = case["expected_variable_end_byte"]
        require((start, end) == (10, len(POSITIVE_PREFIX + name)), f"{case['id']} span is not source-derived")
        require(source[start:end] == b"  integer :: " + name, f"{case['id']} declaration span differs")
        expected_oracle = oracle_cases[case["id"]]
        oracle_fields = {
            "expected_outcome": "expected_outcome",
            "expected_variable_name": "expected_variable_name",
            "expected_variable_start_byte": "expected_start_byte",
            "expected_variable_end_byte": "expected_end_byte",
        }
        for manifest_field, oracle_field in oracle_fields.items():
            require(case[manifest_field] == expected_oracle[oracle_field], f"{case['id']} oracle field {oracle_field} differs")

    require(sources["beta"] != sources["q7"] and sources["beta"] != sources["theta-2"], "mutations are not distinct")
    for mutated in ("q7", "theta-2"):
        base_without_name = sources["beta"].replace(b"beta", b"NAME", 1)
        mutated_without_name = sources[mutated].replace(oracle_cases[mutated]["expected_variable_name"].encode(), b"NAME", 1)
        require(base_without_name == mutated_without_name, f"{mutated} changes more than the name")

    negative_path = root / manifest["negative"]
    require(digest(negative_path) == manifest["negative_sha256"], "negative hash differs")
    require(negative_path.read_bytes() == NEGATIVE, "negative source differs")
    require(oracle["negative"] == [{"id": "missing-entity", "expected_outcome": "REJECTED"}], "negative oracle differs")
    print("frontend AST v1 source-derived-name contract oracle PASS: 3 source cases, 2 name mutations, 1 malformed negative")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValidationError, ValueError) as error:
        print(f"frontend AST v1 source-derived-name contract oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
