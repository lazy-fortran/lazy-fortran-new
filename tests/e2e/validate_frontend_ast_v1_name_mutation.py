#!/usr/bin/env python3
"""Independent oracle for the bounded typed-AST v1 z-name mutation slice."""

from __future__ import annotations

import hashlib
import sys
import tomllib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_frontend_ast_v1 import (  # noqa: E402
    ValidationError,
    parse_sx,
    require,
    schema_records,
    validate_output_structure,
)


POSITIVE = b"program p\n  integer :: z\nend program p\n"
CONTROL = b"program p\n  integer :: y\nend program p\n"
NEGATIVE = b"program p\n  integer ::\nend program p\n"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized(path: Path) -> str:
    return path.read_text(encoding="utf-8").rstrip("\n")


def main() -> int:
    if len(sys.argv) != 4:
        raise ValidationError(
            "usage: validate_frontend_ast_v1_name_mutation.py manifest run-dir frontend"
        )
    manifest_path, run_dir_name, frontend = sys.argv[1:]
    manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
    run_dir = Path(run_dir_name)
    root = Path(__file__).resolve().parents[2]
    source = root / manifest["source"]
    control = root / manifest["changed_name_control"]
    negative = root / manifest["negative"]
    schema = root / manifest["contract_schema"]
    witness = root / manifest["contract_witness"]
    golden = root / manifest["output_golden"]
    oracle_path = root / manifest["oracle"]
    oracle = tomllib.loads(oracle_path.read_text(encoding="utf-8"))

    require(manifest["boundary"] == oracle["boundary"], "boundary differs")
    require(manifest["origin"] == "LLM", "fixture origin differs")
    require("(origin llm)" in witness.read_text(encoding="utf-8"),
            "witness origin differs")
    require(manifest["model_calls"] == 0 and manifest["semantic_promotions"] == 0,
            "promotion guard differs")
    require(source.read_bytes() == POSITIVE, "positive source differs")
    require(control.read_bytes() == CONTROL, "changed-name control differs")
    require(negative.read_bytes() == NEGATIVE, "negative source differs")
    for field, path in (
        ("contract_schema", schema),
        ("contract_witness", witness),
        ("source", source),
        ("changed_name_control", control),
        ("negative", negative),
        ("output_golden", golden),
        ("oracle", oracle_path),
    ):
        expected_hash = manifest.get(field + "_sha256")
        if expected_hash is not None:
            require(digest(path) == expected_hash, f"{field} hash differs")
    require(frontend == manifest["frontend_component_commit"],
            "frontend component commit differs")
    records = schema_records(schema)
    validate_output_structure(parse_sx(normalized(golden)), records)
    require(oracle["root_name"] == manifest["expected_root_name"], "root name differs")
    require(oracle["variable_type_spec"] == manifest["expected_variable_type"],
            "variable type differs")
    require(oracle["variable_name"] == manifest["expected_variable_name"],
            "variable name differs")
    require(oracle["variable_start_byte"] == manifest["expected_variable_start_byte"],
            "variable span start differs")
    require(oracle["variable_end_byte"] == manifest["expected_variable_end_byte"],
            "variable span end differs")
    require(oracle["source_hash"] == manifest["expected_source_hash"],
            "source hash label differs")

    expected = normalized(golden).replace("(file SOURCE)", f"(file {source})")
    require(normalized(run_dir / "positive.ast.sx") == expected,
            "positive AST differs from golden")
    require(normalized(run_dir / "positive.ast.repeat.sx") == expected,
            "repeated AST differs from golden")
    require(not (run_dir / "negative.ast.sx").exists(), "negative AST was written")
    print("frontend AST v1 name mutation oracle PASS: z preserved, y control and malformed neighbour checked")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValidationError, OSError, tomllib.TOMLDecodeError, ValueError) as error:
        print(f"frontend AST v1 name mutation oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
