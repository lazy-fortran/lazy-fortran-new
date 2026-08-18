#!/usr/bin/env python3
"""Independent oracle for the bounded source-derived REAL replay."""

from __future__ import annotations

import hashlib
import sys
import tomllib
from pathlib import Path


class ValidationError(RuntimeError):
    pass


REAL_SOURCE = b"program main\n  real :: x\nend program main\n"
INTEGER_SOURCE = b"program main\n  integer :: x\nend program main\n"


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
        raise ValidationError("usage: validate_frontend_ast_v1_real_type.py replay-manifest run-dir frontend")
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
    require(list(expected) == ["real", "integer-control"], "case order differs")
    require(set(expected) == set(oracle_cases), "oracle cases differ")
    expected_types = {"real": "real", "integer-control": "integer"}
    for case_id, case in expected.items():
        source = root / case["source"]
        output = run_dir / f"case-{case_id}.ast.sx"
        repeat = run_dir / f"case-{case_id}.repeat.ast.sx"
        require(source.is_file() and digest(source) == case["source_sha256"], f"source differs for {case_id}")
        expected_source = REAL_SOURCE if case_id == "real" else INTEGER_SOURCE
        require(source.read_bytes() == expected_source, f"source shape differs for {case_id}")
        require(case["expected_outcome"] == "ACCEPTED", f"expected outcome differs for {case_id}")
        require(case["expected_variable_type"] == expected_types[case_id], f"expected type differs for {case_id}")
        require(output.is_file() and repeat.is_file(), f"missing output for {case_id}")
        require(output.read_bytes() == repeat.read_bytes(), f"repeat differs for {case_id}")
        output_text = output.read_text(encoding="utf-8")
        require("DEBUG" not in output_text, f"debug output leaked for {case_id}")
        root_node = parse_sx(output_text.rstrip("\n"))
        require(root_node[0] == "program-unit", f"root differs for {case_id}")
        root_record = child(root_node, "root")[0]
        declaration = child(root_node, "declaration")[0]
        variable = child(root_node, "variable")[0]
        require(root_record[0] == "program-root", f"program root record differs for {case_id}")
        require(declaration[0] == "program-declaration", f"program declaration record differs for {case_id}")
        require(variable[0] == "variable-declaration", f"variable record differs for {case_id}")
        require(field(root_record, "name") == "main", f"source-derived root name differs for {case_id}")
        require(field(declaration, "declaration-kind") == "program", f"declaration kind differs for {case_id}")
        require(field(declaration, "name") == "main", f"declaration name differs for {case_id}")
        require(field(variable, "type-spec") == expected_types[case_id], f"variable type differs for {case_id}")
        require(field(variable, "name") == "x", f"variable name differs for {case_id}")
        source_path = str(source)
        for record, label in ((root_record, "root"), (declaration, "declaration"), (variable, "variable")):
            span = child(record, "span")[0]
            require(span[0] == "source-span", f"{label} span record differs for {case_id}")
            require(field(span, "file") == source_path, f"{label} source path differs for {case_id}")
        oracle_case = oracle_cases[case_id]
        require(oracle_case["expected_outcome"] == "ACCEPTED", f"oracle outcome differs for {case_id}")
        require(oracle_case["expected_variable_type"] == expected_types[case_id], f"oracle type differs for {case_id}")
    require(not (run_dir / "negative.ast.sx").exists(), "negative AST was written")
    negative_log = run_dir / "negative.log"
    require(negative_log.is_file(), "negative rejection log is missing")
    require("typed frontend rejected source:" in negative_log.read_text(encoding="utf-8"), "negative rejection marker differs")
    require(oracle["negative"] == [{"id": "missing-entity", "expected_outcome": "REJECTED"}], "negative oracle differs")
    print("frontend AST v1 REAL type oracle PASS: real and integer controls accepted, malformed real rejected")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValidationError, ValueError, StopIteration) as error:
        print(f"frontend AST v1 REAL type oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
