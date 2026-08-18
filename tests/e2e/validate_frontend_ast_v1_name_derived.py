#!/usr/bin/env python3
"""Independent oracle for the source-derived typed AST v1 replay."""

from __future__ import annotations

import sys
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


def main() -> int:
    if len(sys.argv) != 4:
        raise ValidationError("usage: validate_frontend_ast_v1_name_derived.py replay-manifest run-dir frontend")
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
        require(output.is_file() and repeat.is_file(), f"missing output for {case_id}")
        require(output.read_bytes() == repeat.read_bytes(), f"repeat differs for {case_id}")
        root_node = parse_sx(output.read_text(encoding="utf-8").rstrip("\n"))
        require(root_node[0] == "program-unit", f"root differs for {case_id}")
        require(field(root_node, "declaration-count") == "1" and field(root_node, "variable-count") == "1", f"counts differ for {case_id}")
        root_record = child(root_node, "root")[0]
        require(root_record[0] == "program-root" and field(root_record, "name") == case["expected_root_name"], f"root name differs for {case_id}")
        variable_record = child(root_node, "variable")[0]
        require(variable_record[0] == "variable-declaration", f"variable record differs for {case_id}")
        require(field(variable_record, "type-spec") == case["expected_variable_type"], f"type differs for {case_id}")
        require(field(variable_record, "name") == case["expected_variable_name"], f"source-derived name differs for {case_id}")
        span = child(variable_record, "span")[0]
        require(span[0] == "source-span", f"span record differs for {case_id}")
        require(field(span, "file") == str(source), f"source path differs for {case_id}")
        require(int(field(span, "start-byte")) == case["expected_variable_start_byte"], f"span start differs for {case_id}")
        require(int(field(span, "end-byte")) == case["expected_variable_end_byte"], f"span end differs for {case_id}")
        require(field(span, "source-hash") == case["expected_source_hash"], f"source hash label differs for {case_id}")
        oracle_case = oracle_cases[case_id]
        require(oracle_case["expected_variable_name"] == field(variable_record, "name"), f"oracle name differs for {case_id}")
    require(not (run_dir / "negative.ast.sx").exists(), "negative AST was written")
    print("frontend AST v1 source-derived-name oracle PASS: 3 names, repeats identical, malformed neighbour rejected")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValidationError, ValueError, StopIteration) as error:
        print(f"frontend AST v1 source-derived-name oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
