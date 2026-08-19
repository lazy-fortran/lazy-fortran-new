#!/usr/bin/env python3
"""Independent oracle for one x + 2 item in a generic PRINT list."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

from oracle_generated_print_expression_variable import digest, groups, require


class OracleFailure(Exception):
    pass


def check_contract(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-add-constant-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-add-constant)", "(version 0)",
        "(origin mechanical)", "(resolution resolved)",
        "(property generic-integer-add-constant-expression-output)",
        "(rules R901 R1006 R1007 R1009 R1212 R1215 R1217)",
        "(pages 155 169 242 244 248)",
    ):
        require(witness in text, f"add-constant contract differs: {witness}")
    cases = {
        "tests/fixtures/l3-print-expression-add-constant-v0.f90": "c7e3ee57b4b815cbee20b4eaa8044b2a66a713b0ad6e3a244b479202f0d69eb4",
        "tests/fixtures/l3-print-expression-add-constant-wide-v0.f90": "a85755f5a85481d041fd7e479312daa64b7435005c3567c6e0dadc5cf5608129",
        "tests/negative/l3-print-expression-add-constant-v0-missing-operand.f90": "06688957a17099f13ddec436fc81487be060931c845eeb168ffd79cd3583e7d6",
        "tests/negative/l3-print-expression-add-constant-v0-wrong-operator.f90": "65f2d97d0a8ee66ddd875ffffc6d3531d2152eb92bbb768674d54aa764d98b20",
        "tests/negative/l3-print-expression-add-constant-v0-write.f90": "e6e4f0b58867ccb3b4787121c52f5a982f835b8c828e59c3a2cca66bc00fd62e",
        "tests/negative/l3-print-expression-add-constant-v0-wrong-name.f90": "aa7847a0ead2b7cae6dc03f25c1d7b9517478004d2f847104f4403619658a4e0",
        "tests/negative/l3-print-expression-add-constant-v0-wrong-right.f90": "8771f33783d9736daff348dcf1b7ad288d0d021e1524f456be955aaf838d11d8",
    }
    for relative, expected in cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"add-constant source case differs: {relative}")
        require(digest(source) == expected, f"add-constant source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    ir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    pdf = root / ".cache/j3-24-007.pdf"
    ir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(pdf) == pdf_hash, "add-constant PDF differs")
    require(f"(standardir-sha256 {ir_hash})" in text and digest(ir) == ir_hash, "add-constant StandardIR differs")


def parse_items(source: pathlib.Path) -> list[tuple[str, str]]:
    match = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(match is not None, "add-constant source has no PRINT list")
    result = []
    for raw in match.group(1).strip().split(","):
        value = raw.strip()
        if value == "x + 2":
            result.append(("expression", value))
        elif value == "x":
            result.append(("variable", value))
        elif value.isdigit():
            result.append(("literal", value))
        else:
            raise OracleFailure(f"unsupported add-constant item: {value}")
    return result


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    identity = "l3-raw-program-generic-print-expression-v0"
    require("(program-unit-v2 " in text and f"(file {source})" in text, "add-constant AST root differs")
    spans = groups(text, "(source-span ")
    require(spans, "add-constant AST has no spans")
    for span in spans:
        require(f"(file {source})" in span and f"(source-hash {identity})" in span,
                "add-constant AST span provenance differs")
    require(f"(source-identity {identity})" in text, "add-constant AST identity differs")
    cursor = text.index("(output-items ")
    require(f"(output-count {len(items)})" in text, "add-constant AST count differs")
    for kind, value in items:
        if kind == "expression":
            witness = "(output-item (kind integer-expression) (operator +) (left x) (right 2) (rule R1217) (clause 12.6.3) (page 248))"
        elif kind == "variable":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        else:
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"add-constant AST item missing: {witness}")
        cursor = position + len(witness)
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)", "(output-rule R1217)",
        "(source-document J3-24-007)", "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
        "(statement-page 242)", "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"add-constant AST provenance missing: {witness}")


def check_mir(path: pathlib.Path, items: list[tuple[str, str]]) -> None:
    instructions = groups(path.read_text(encoding="utf-8"), "(instruction ")
    printed = [item for item in instructions if "(source-rule frontend-ast-v2/print-stmt)" in item]
    expected = []
    for kind, value in items:
        if kind == "expression":
            expected += [("load", "(storage-key x)"), ("const", "(literal 2)"), ("add", ""), ("output", "")]
        elif kind == "variable":
            expected += [("load", "(storage-key x)"), ("output", "")]
        else:
            expected += [("const", f"(literal {value})"), ("output", "")]
    require(len(printed) == len(expected) + 1, "add-constant MIR count differs")
    for actual, (opcode, operand) in zip(printed, expected):
        require(f"(opcode {opcode})" in actual, f"add-constant MIR opcode differs: {opcode}")
        if operand:
            require(operand in actual, f"add-constant MIR operand differs: {operand}")
    require("(opcode return)" in printed[-1], "add-constant MIR has no return")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_add_constant.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    require(elf.read_bytes().startswith(b"\x7fELF"), "add-constant artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((b"7\n" if kind == "expression" else b"5\n" if kind == "variable" else f"{value}\n".encode())
                         for kind, value in items)
    require(runtime.returncode == 0 and runtime.stdout == expected, "add-constant runtime output differs")
    print(f"generic add-constant oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic add-constant oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
