#!/usr/bin/env python3
"""Independent oracle for bounded decimal x +/- n PRINT expressions."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

from oracle_generated_print_expression_variable import digest, groups, require


class OracleFailure(Exception):
    pass


def check_contract(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-decimal-constant-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-decimal-constant)", "(version 0)",
        "(origin mechanical)", "(resolution resolved)",
        "(property generic-integer-decimal-expression-constant-output)",
        "(rules R901 R1006 R1007 R1010 R1212 R1215 R1217)",
        "(pages 69 155 242 244 248)",
    ):
        require(witness in text, f"decimal-constant contract differs: {witness}")
    cases = {
        "tests/fixtures/l3-print-expression-decimal-constant-v0.f90": "8915241870000c81b2e28248a1825d8a3b139ce8e02135e42c6ecef9e126b0d5",
        "tests/fixtures/l3-print-expression-decimal-constant-wide-v0.f90": "0cc946a116972a39f58baefdfae3c65a2ab6a1d50f9794dc7b6b1d1cdf21c0f9",
        "tests/negative/l3-print-expression-decimal-constant-v0-missing-operand.f90": "06688957a17099f13ddec436fc81487be060931c845eeb168ffd79cd3583e7d6",
        "tests/negative/l3-print-expression-decimal-constant-v0-real-right.f90": "ec11fe6806e6ecc56d521552e913ddb16354c2aa55c5f0e75804a9e305316e00",
        "tests/negative/l3-print-expression-decimal-constant-v0-out-of-range.f90": "3ba13cdc307183eff203bf4c42f2bc3c1ce34b768bbb3e1a2639dcb5d6a47bff",
        "tests/negative/l3-print-expression-decimal-constant-v0-write.f90": "3f2ca90ac826a22ed5630bd8054ce77284432e734a0c2f33d3d477fe3e8a0c5a",
        "tests/negative/l3-print-expression-decimal-constant-v0-wrong-name.f90": "78739f2375f86d8ed6b2a49a66694244b02679556b48dd4f3f15d7145c4a9cb5",
    }
    for relative, expected in cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"decimal-constant source case differs: {relative}")
        require(digest(source) == expected, f"decimal-constant source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    ir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    pdf = root / ".cache/j3-24-007.pdf"
    ir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(pdf) == pdf_hash, "decimal-constant PDF differs")
    require(f"(standardir-sha256 {ir_hash})" in text and digest(ir) == ir_hash, "decimal-constant StandardIR differs")


def parse_items(source: pathlib.Path) -> list[tuple[str, str, int | None]]:
    match = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(match is not None, "decimal-constant source has no PRINT list")
    result = []
    for raw in match.group(1).strip().split(","):
        value = raw.strip()
        expression = re.fullmatch(r"x ([+-]) ([0-9]+)", value)
        if expression:
            result.append(("expression", expression.group(1), int(expression.group(2))))
        elif value == "x":
            result.append(("variable", value, None))
        elif value.isdigit():
            result.append(("literal", value, int(value)))
        else:
            raise OracleFailure(f"unsupported decimal-constant item: {value}")
    return result


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str, int | None]]) -> None:
    text = path.read_text(encoding="utf-8")
    identity = "l3-raw-program-generic-print-expression-v0"
    require("(program-unit-v2 " in text and f"(file {source})" in text, "decimal-constant AST root differs")
    spans = groups(text, "(source-span ")
    require(spans, "decimal-constant AST has no spans")
    for span in spans:
        require(f"(file {source})" in span and f"(source-hash {identity})" in span,
                "decimal-constant AST span provenance differs")
    require(f"(source-identity {identity})" in text, "decimal-constant AST identity differs")
    cursor = text.index("(output-items ")
    require(f"(output-count {len(items)})" in text, "decimal-constant AST count differs")
    for kind, value, number in items:
        if kind == "expression":
            witness = f"(output-item (kind integer-expression) (operator {value}) (left x) (right {number}) (rule R1217) (clause 12.6.3) (page 248))"
        elif kind == "variable":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        else:
            witness = f"(output-item (kind integer-literal) (value {number}) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"decimal-constant AST item missing: {witness}")
        cursor = position + len(witness)
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)", "(output-rule R1217)",
        "(source-document J3-24-007)", "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
        "(statement-page 242)", "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"decimal-constant AST provenance missing: {witness}")


def check_mir(path: pathlib.Path, items: list[tuple[str, str, int | None]]) -> None:
    instructions = groups(path.read_text(encoding="utf-8"), "(instruction ")
    printed = [item for item in instructions if "(source-rule frontend-ast-v2/print-stmt)" in item]
    expected = []
    for kind, value, number in items:
        if kind == "expression":
            expected += [("load", "(storage-key x)"), ("const", f"(literal {number})"), ("sub" if value == "-" else "add", ""), ("output", "")]
        elif kind == "variable":
            expected += [("load", "(storage-key x)"), ("output", "")]
        else:
            expected += [("const", f"(literal {number})"), ("output", "")]
    require(len(printed) == len(expected) + 1, "decimal-constant MIR count differs")
    for actual, (opcode, operand) in zip(printed, expected):
        require(f"(opcode {opcode})" in actual, f"decimal-constant MIR opcode differs: {opcode}")
        if operand:
            require(operand in actual, f"decimal-constant MIR operand differs: {operand}")
    require("(opcode return)" in printed[-1], "decimal-constant MIR has no return")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_decimal_constant.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    require(elf.read_bytes().startswith(b"\x7fELF"), "decimal-constant artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((f"{5 + number if value == '+' else 5 - number}\n".encode() if kind == "expression" else f"{number}\n".encode())
                         for kind, value, number in items)
    require(runtime.returncode == 0 and runtime.stdout == expected, "decimal-constant runtime output differs")
    print(f"generic decimal-constant oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic decimal-constant oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
