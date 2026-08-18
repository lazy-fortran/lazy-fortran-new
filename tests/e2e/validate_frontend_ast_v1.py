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


def parse_sx(text: str):
    tokens = text.replace("(", " ( ").replace(")", " ) ").split()
    stack = [[]]
    for token in tokens:
        if token == "(":
            node = []
            stack[-1].append(node)
            stack.append(node)
        elif token == ")":
            require(len(stack) > 1, "unbalanced SX")
            stack.pop()
        else:
            stack[-1].append(token)
    require(len(stack) == 1, "unbalanced SX")
    require(len(stack[0]) == 1, "SX has multiple roots")
    return stack[0][0]


def schema_records(schema: Path) -> dict[str, tuple[str, ...]]:
    root = parse_sx(schema.read_text(encoding="utf-8"))
    require(root[0] == "schema" and root[1] == "frontend-ast-v1",
            "schema identity differs")
    records = {}
    for item in root[2:]:
        if isinstance(item, list) and item and item[0] == "record":
            raw_fields = item[2:]
            require(all(isinstance(field, list) and len(field) == 2
                        for field in raw_fields),
                    f"malformed schema record: {item[1]}")
            fields = tuple(field[0] for field in raw_fields)
            records[item[1]] = fields
    require(records, "schema has no records")
    return records


def validate_output_structure(node, records: dict[str, tuple[str, ...]]) -> None:
    if not isinstance(node, list) or not node:
        return
    head = node[0]
    if head in records:
        fields = [item[0] for item in node[1:]
                  if isinstance(item, list) and item]
        require(tuple(fields) == records[head],
                f"schema fields differ for {head}")
    for item in node[1:]:
        validate_output_structure(item, records)


def main() -> int:
    if len(sys.argv) != 4:
        raise ValidationError("usage: validate_frontend_ast_v1.py manifest run-dir frontend")
    manifest_path, run_dir, frontend = sys.argv[1:]
    manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
    run_dir = Path(run_dir)
    root = Path(__file__).resolve().parents[2]
    source = root / manifest["source"]
    negative = root / manifest["negative"]
    schema = root / manifest["contract_schema"]
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
    records = schema_records(schema)
    validate_output_structure(parse_sx(normalized(golden)), records)
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
