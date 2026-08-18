#!/usr/bin/env python3
"""Independent oracle for the source-derived program-root-name replay."""

from __future__ import annotations

import sys
import hashlib
import tomllib
from pathlib import Path


class ValidationError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


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
    require(len(stack) == 1 and len(stack[0]) == 1, "invalid SX root")
    return stack[0][0]


def child(node, name: str):
    for item in node[1:]:
        if isinstance(item, list) and item and item[0] == name:
            return item[1:]
    raise ValidationError(f"missing {name}")


def field(node, name: str) -> str:
    values = child(node, name)
    require(len(values) == 1 and isinstance(values[0], str), f"malformed {name}")
    return values[0]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if len(sys.argv) != 4:
        raise ValidationError("usage: validate_frontend_ast_v1_program_root_name.py replay-manifest run-dir frontend")
    replay_path, run_dir_name, frontend = sys.argv[1:]
    root = Path(__file__).resolve().parents[2]
    replay = tomllib.loads((root / replay_path).read_text(encoding="utf-8"))
    run_dir = Path(run_dir_name)
    contract = tomllib.loads((root / replay["contract_manifest"]).read_text(encoding="utf-8"))
    oracle = tomllib.loads((root / contract["expected_oracle"]).read_text(encoding="utf-8"))
    require(replay["model_calls"] == 0 and replay["semantic_promotions"] == 0, "replay guard differs")
    require(frontend == replay["frontend_component_commit"], "frontend component commit differs")
    require(contract["origin"] == "LLM" and contract["model_calls"] == 0 and contract["semantic_promotions"] == 0, "contract guard differs")
    require(oracle["origin"] == "LLM" and oracle["model_calls"] == 0 and oracle["semantic_promotions"] == 0, "oracle guard differs")
    expected = {case["id"]: case for case in contract["case"]}
    oracle_cases = {case["id"]: case for case in oracle["case"]}
    require(set(expected) == set(oracle_cases), "oracle cases differ")
    for case_id, case in expected.items():
        source = root / case["source"]
        output = run_dir / f"case-{case_id}.ast.sx"
        repeat = run_dir / f"case-{case_id}.repeat.ast.sx"
        require(source.is_file() and digest(source) == case["source_sha256"], f"source differs for {case_id}")
        expected_source = (
            f"program {case['expected_root_name']}\n"
            "  integer :: x\n"
            f"end program {case['expected_root_name']}\n"
        ).encode("ascii")
        require(source.read_bytes() == expected_source, f"source shape differs for {case_id}")
        require(output.is_file() and repeat.is_file(), f"missing output for {case_id}")
        require(output.read_bytes() == repeat.read_bytes(), f"repeat differs for {case_id}")
        root_node = parse_sx(output.read_text(encoding="utf-8").rstrip("\n"))
        require(root_node[0] == "program-unit", f"root differs for {case_id}")
        root_record = child(root_node, "root")[0]
        declaration = child(root_node, "declaration")[0]
        require(root_record[0] == "program-root", f"program root record differs for {case_id}")
        require(declaration[0] == "program-declaration", f"program declaration record differs for {case_id}")
        require(field(root_record, "name") == case["expected_root_name"], f"source-derived root name differs for {case_id}")
        require(field(declaration, "declaration-kind") == "program", f"declaration kind differs for {case_id}")
        require(field(declaration, "name") == case["expected_program_declaration_name"], f"declaration name differs for {case_id}")
        for record, label in ((root_record, "root"), (declaration, "declaration")):
            span = child(record, "span")[0]
            require(span[0] == "source-span", f"{label} span record differs for {case_id}")
            require(field(span, "file") == str(source), f"{label} source path differs for {case_id}")
        require(field(child(root_node, "variable")[0], "name") == "x", f"variable control differs for {case_id}")
        require(field(child(root_node, "variable")[0], "type-spec") == "integer", f"variable type differs for {case_id}")
        oracle_case = oracle_cases[case_id]
        require(oracle_case["expected_root_name"] == field(root_record, "name"), f"oracle root name differs for {case_id}")
    require(not (run_dir / "negative.ast.sx").exists(), "negative AST was written")
    print("frontend AST v1 program-root-name oracle PASS: 2 source names, repeats identical, mismatched end rejected")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValidationError, ValueError, StopIteration) as error:
        print(f"frontend AST v1 program-root-name oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
