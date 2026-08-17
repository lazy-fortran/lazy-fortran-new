#!/usr/bin/env python3
"""Independent oracle for the bounded typed frontend AST v1 slice."""

from __future__ import annotations

import hashlib
import sys
import tomllib
from pathlib import Path


POSITIVE = b"program p\n  integer :: x\nend program p\n"
NEGATIVE = b"program p\n  integer ::\nend program p\n"


class ValidationError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized(path: Path) -> str:
    return path.read_text(encoding="utf-8").rstrip("\n")


def main() -> int:
    if len(sys.argv) != 4:
        raise ValidationError("usage: validate_frontend_ast_v1.py manifest run-dir frontend")
    manifest_path, run_dir, frontend = sys.argv[1:]
    manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
    run_dir = Path(run_dir)
    root = Path(__file__).resolve().parents[2]
    source = root / manifest["source"]
    negative = root / manifest["negative"]
    golden = root / manifest["output_golden"]
    oracle_path = root / manifest["oracle"]
    oracle = tomllib.loads(oracle_path.read_text(encoding="utf-8"))

    require(manifest["boundary"] == oracle["boundary"], "boundary differs")
    require(manifest["origin"] == "MECHANICAL", "fixture origin differs")
    require(manifest["model_calls"] == 0 and manifest["semantic_promotions"] == 0,
            "promotion guard differs")
    require(source.read_bytes() == POSITIVE, "positive source differs")
    require(negative.read_bytes() == NEGATIVE, "negative source differs")
    for field, path in (
        ("contract_schema", root / manifest["contract_schema"]),
        ("contract_witness", root / manifest["contract_witness"]),
        ("source", source),
        ("negative", negative),
        ("output_golden", golden),
        ("oracle", oracle_path),
    ):
        expected = manifest.get(field + "_sha256")
        if expected is not None:
            require(digest(path) == expected, f"{field} hash differs")
    require(frontend == manifest["frontend_component_commit"],
            "frontend component commit differs")
    require(oracle["root_name"] == "p", "root name differs")
    require(oracle["variable_type_spec"] == "integer", "variable type differs")
    require(oracle["variable_name"] == "x", "variable name differs")
    require(oracle["variable_start_byte"] == 10 and oracle["variable_end_byte"] == 24,
            "variable span differs")

    positive = run_dir / "positive.ast.sx"
    repeat = run_dir / "positive.ast.repeat.sx"
    negative_output = run_dir / "negative.ast.sx"
    expected = normalized(golden).replace("(file SOURCE)", f"(file {source})")
    require(normalized(positive) == expected, "positive AST differs from golden")
    require(normalized(repeat) == expected, "repeated AST differs from golden")
    require(not negative_output.exists(), "negative AST was written")
    print("frontend AST v1 oracle PASS: 1 typed declaration, 1 rejected neighbour, 0 promotions")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValidationError, OSError, tomllib.TOMLDecodeError, ValueError) as error:
        print(f"frontend AST v1 oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
