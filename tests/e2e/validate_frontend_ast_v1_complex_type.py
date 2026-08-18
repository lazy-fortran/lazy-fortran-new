#!/usr/bin/env python3
"""Independent oracle for the bounded COMPLEX typed-AST slice."""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path


class ValidationError(RuntimeError):
    pass


ROOT = Path(__file__).resolve().parents[2]
CASES = {
    "complex": {
        "source": b"program main\n  complex :: x\nend program main\n",
        "type": "complex",
    },
    "real-control": {
        "source": b"program main\n  real :: x\nend program main\n",
        "type": "real",
    },
}
NEGATIVE = b"program main\n  complex ::\nend program main\n"


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


def load_contract(path: str):
    return tomllib.loads((ROOT / path).read_text(encoding="utf-8"))


def validate_contract(contract_path: str):
    contract = load_contract(contract_path)
    require(contract["property"] == "source-derived-complex-type-spec", "property differs")
    require(contract["model_calls"] == 0 and contract["semantic_promotions"] == 0, "promotion guard differs")
    require([case["id"] for case in contract["case"]] == list(CASES), "case order differs")
    witness = (ROOT / contract["contract_witness"]).read_text(encoding="utf-8")
    oracle = tomllib.loads((ROOT / contract["expected_oracle"]).read_text(encoding="utf-8"))
    require("(property source-derived-complex-type-spec)" in witness, "witness property differs")
    require(oracle["property"] == contract["property"], "oracle property differs")
    require(oracle["model_calls"] == 0 and oracle["semantic_promotions"] == 0, "oracle guard differs")
    for case in contract["case"]:
        expected = CASES[case["id"]]
        source = ROOT / case["source"]
        require(source.read_bytes() == expected["source"], f"source differs for {case['id']}")
        require(case["expected_outcome"] == "ACCEPTED", f"outcome differs for {case['id']}")
        require(case["expected_variable_type"] == expected["type"], f"type differs for {case['id']}")
        require(case["expected_root_name"] == "main", f"root differs for {case['id']}")
        require(case["expected_program_declaration_name"] == "main", f"declaration differs for {case['id']}")
        require(case["expected_variable_name"] == "x", f"name differs for {case['id']}")
        require(f"(id {case['id']})" in witness, f"witness case differs for {case['id']}")
    negative = ROOT / contract["negative"]
    require(negative.read_bytes() == NEGATIVE, "negative source differs")
    require(oracle["negative"] == [{"id": "missing-entity", "expected_outcome": "REJECTED"}], "negative oracle differs")
    return contract


def validate_outputs(contract_path: str, run_dir: str) -> None:
    contract = validate_contract(contract_path)
    run = Path(run_dir)
    for case in contract["case"]:
        case_id = case["id"]
        output = run / f"case-{case_id}.ast.sx"
        repeat = run / f"case-{case_id}.repeat.ast.sx"
        require(output.is_file() and repeat.is_file(), f"missing output for {case_id}")
        require(output.read_bytes() == repeat.read_bytes(), f"repeat differs for {case_id}")
        root = parse_sx(output.read_text(encoding="utf-8").rstrip("\n"))
        require(root[0] == "program-unit", f"root differs for {case_id}")
        root_record = child(root, "root")[0]
        declaration = child(root, "declaration")[0]
        variable = child(root, "variable")[0]
        require(field(root_record, "name") == "main", f"root name differs for {case_id}")
        require(field(declaration, "declaration-kind") == "program", f"declaration kind differs for {case_id}")
        require(field(declaration, "name") == "main", f"declaration name differs for {case_id}")
        require(field(variable, "type-spec") == CASES[case_id]["type"], f"type differs for {case_id}")
        require(field(variable, "name") == "x", f"variable name differs for {case_id}")
        source_path = str(ROOT / case["source"])
        for record in (root_record, declaration, variable):
            span = child(record, "span")[0]
            require(field(span, "file") == source_path, f"source path differs for {case_id}")
    require(not (run / "negative.ast.sx").exists(), "negative AST was written")
    require("typed frontend rejected source:" in (run / "negative.log").read_text(encoding="utf-8"), "negative marker differs")


def main() -> int:
    if len(sys.argv) == 3 and sys.argv[1] == "--contract":
        validate_contract(sys.argv[2])
        return 0
    if len(sys.argv) == 3 and sys.argv[1] == "--cases":
        contract = load_contract(sys.argv[2])
        for case in contract["case"]:
            print(f"{case['id']}\t{case['source']}")
        return 0
    if len(sys.argv) == 3 and sys.argv[1] == "--negative":
        print(load_contract(sys.argv[2])["negative"])
        return 0
    if len(sys.argv) == 4 and sys.argv[1] == "--outputs":
        validate_outputs(sys.argv[2], sys.argv[3])
        return 0
    if len(sys.argv) == 2:
        validate_outputs("tests/fixtures/frontend-ast-v1-complex-type-contract.toml", sys.argv[1])
        return 0
    raise ValidationError("usage: validate_frontend_ast_v1_complex_type.py [--contract|--cases|--negative|--outputs] path")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValidationError, KeyError) as error:
        print(f"frontend AST v1 COMPLEX oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
