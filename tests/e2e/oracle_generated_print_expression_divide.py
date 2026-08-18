#!/usr/bin/env python3
"""Independent oracle for one x / 2 item in a generic PRINT list."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

from oracle_generated_print_expression_variable import digest, groups, require


class OracleFailure(Exception):
    pass


def check_contract(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-divide-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-divide)", "(version 0)",
        "(origin mechanical)", "(resolution resolved)",
        "(property generic-integer-division-expression-output)",
        "(rules R901 R1006 R1009 R1212 R1215 R1217)",
        "(pages 155 169 242 244 248)",
    ):
        require(witness in text, f"divide contract differs: {witness}")
    cases = {
        "tests/fixtures/l3-print-expression-divide-v0.f90":
            "ae0dee49879be978c7d9d36052f23cac2f567a15978d73fcbc8945282500bd0f",
        "tests/fixtures/l3-print-expression-divide-wide-v0.f90":
            "c0e0c11180dc6a5f22102219bfcdd358da76ceb42fcae40af654e117f182d337",
        "tests/negative/l3-print-expression-divide-v0-missing-operand.f90":
            "71b7bdee588d5efb5183d7f99753571712cf991dbc243a5a74403244047edb81",
        "tests/negative/l3-print-expression-divide-v0-wrong-operator.f90":
            "373a5260c68ca30b7e9e4b55564dd0e63e680835429ad43f183e4bbbe8181644",
        "tests/negative/l3-print-expression-divide-v0-write.f90":
            "4dbbed6c26c728c99b049d247acfa53b631d8ca9f072aa253c41560692c192b5",
        "tests/negative/l3-print-expression-divide-v0-wrong-name.f90":
            "9ec6217e4ad6d9d0e373dad5b2b01e304f4ae399f44889c6e666a4a4035a33e7",
    }
    for relative, expected in cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"divide source case differs: {relative}")
        require(digest(source) == expected, f"divide source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    ir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    pdf = root / ".cache/j3-24-007.pdf"
    ir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(pdf) == pdf_hash, "divide PDF differs")
    require(f"(standardir-sha256 {ir_hash})" in text and digest(ir) == ir_hash, "divide StandardIR differs")


def parse_items(source: pathlib.Path) -> list[tuple[str, str]]:
    match = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(match is not None, "divide source has no PRINT list")
    result = []
    for raw in match.group(1).strip().split(","):
        value = raw.strip()
        if value == "x / 2":
            result.append(("expression", value))
        elif value == "x":
            result.append(("variable", value))
        elif value.isdigit():
            result.append(("literal", value))
        else:
            raise OracleFailure(f"unsupported divide item: {value}")
    return result


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    identity = "l3-raw-program-generic-print-expression-v0"
    require("(program-unit-v2 " in text and f"(file {source})" in text, "divide AST root differs")
    spans = groups(text, "(source-span ")
    require(spans, "divide AST has no spans")
    for span in spans:
        require(f"(file {source})" in span and f"(source-hash {identity})" in span,
                "divide AST span provenance differs")
    require(f"(source-identity {identity})" in text, "divide AST identity differs")
    cursor = text.index("(output-items ")
    require(f"(output-count {len(items)})" in text, "divide AST count differs")
    for kind, value in items:
        if kind == "expression":
            witness = "(output-item (kind integer-expression) (operator /) (left x) (right 2) (rule R1217) (clause 12.6.3) (page 248))"
        elif kind == "variable":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        else:
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"divide AST item missing: {witness}")
        cursor = position + len(witness)
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)", "(output-rule R1217)",
        "(source-document J3-24-007)", "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
        "(statement-page 242)", "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"divide AST provenance missing: {witness}")


def check_mir(path: pathlib.Path, items: list[tuple[str, str]]) -> None:
    instructions = groups(path.read_text(encoding="utf-8"), "(instruction ")
    printed = [item for item in instructions if "(source-rule frontend-ast-v2/print-stmt)" in item]
    expected = []
    for kind, value in items:
        if kind == "expression":
            expected += [("load", "(storage-key x)"), ("const", "(literal 2)"), ("div", ""), ("output", "")]
        elif kind == "variable":
            expected += [("load", "(storage-key x)"), ("output", "")]
        else:
            expected += [("const", f"(literal {value})"), ("output", "")]
    require(len(printed) == len(expected) + 1, "divide MIR count differs")
    for actual, (opcode, operand) in zip(printed, expected):
        require(f"(opcode {opcode})" in actual, f"divide MIR opcode differs: {opcode}")
        if operand:
            require(operand in actual, f"divide MIR operand differs: {operand}")
    require("(opcode return)" in printed[-1], "divide MIR has no return")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_divide.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    require(elf.read_bytes().startswith(b"\x7fELF"), "divide artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((b"1\n" if kind == "expression" else b"3\n" if kind == "variable" else f"{value}\n".encode())
                         for kind, value in items)
    require(runtime.returncode == 0 and runtime.stdout == expected, "divide runtime output differs")
    print(f"generic divide-expression oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic divide-expression oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
