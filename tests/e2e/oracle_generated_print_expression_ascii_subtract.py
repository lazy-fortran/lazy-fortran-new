#!/usr/bin/env python3
"""Independent oracle for one canonical ASCII x - 2 PRINT item."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

from oracle_generated_print_expression_variable import digest, groups, require


class OracleFailure(Exception):
    pass


def check_contract(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-ascii-subtract-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-ascii-subtract)", "(version 0)",
        "(origin mechanical)", "(resolution resolved)",
        "(property generic-integer-ascii-subtraction-expression-output)",
        "(rules R901 R1006 R1010 R1212 R1215 R1217)",
        "(pages 69 155 242 244 248)",
    ):
        require(witness in text, f"ASCII subtract contract differs: {witness}")
    cases = {
        "tests/fixtures/l3-print-expression-ascii-subtract-v0.f90": "f0f05ec771f9f0ab3c4cfc48d8e598e9b8d9b8616b44d1093cf886c4aca1977c",
        "tests/fixtures/l3-print-expression-ascii-subtract-wide-v0.f90": "5be319e3aca8d9442b4d93f93981c0c7c57f7ece820291ed6ecc2e5d99b7028e",
        "tests/negative/l3-print-expression-ascii-subtract-v0-missing-operand.f90": "ea6495f4e541260012dbbe2037bb8318e4845d464b81740a61fe9693a6165ddd",
        "tests/negative/l3-print-expression-ascii-subtract-v0-wrong-operator.f90": "65f2d97d0a8ee66ddd875ffffc6d3531d2152eb92bbb768674d54aa764d98b20",
        "tests/negative/l3-print-expression-ascii-subtract-v0-write.f90": "ea07d97eef93893846662079f94a369978ae7bc75923b1a8cbe1a62d2d819de8",
        "tests/negative/l3-print-expression-ascii-subtract-v0-wrong-name.f90": "78739f2375f86d8ed6b2a49a66694244b02679556b48dd4f3f15d7145c4a9cb5",
        "tests/negative/l3-print-expression-ascii-subtract-v0-wrong-right.f90": "8c12ccfcbb31820eac9edd41a2e8d64a3ee734110d28c2053129db167ec0f4f6",
    }
    for relative, expected in cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"ASCII subtract source case differs: {relative}")
        require(digest(source) == expected, f"ASCII subtract source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    ir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    pdf = root / ".cache/j3-24-007.pdf"
    ir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(pdf) == pdf_hash, "ASCII subtract PDF differs")
    require(f"(standardir-sha256 {ir_hash})" in text and digest(ir) == ir_hash, "ASCII subtract StandardIR differs")


def parse_items(source: pathlib.Path) -> list[tuple[str, str]]:
    match = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(match is not None, "ASCII subtract source has no PRINT list")
    result = []
    for raw in match.group(1).strip().split(","):
        value = raw.strip()
        if value == "x - 2":
            result.append(("expression", value))
        elif value == "x":
            result.append(("variable", value))
        elif value.isdigit():
            result.append(("literal", value))
        else:
            raise OracleFailure(f"unsupported ASCII subtract item: {value}")
    return result


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    identity = "l3-raw-program-generic-print-expression-v0"
    require("(program-unit-v2 " in text and f"(file {source})" in text, "ASCII subtract AST root differs")
    spans = groups(text, "(source-span ")
    require(spans, "ASCII subtract AST has no spans")
    for span in spans:
        require(f"(file {source})" in span and f"(source-hash {identity})" in span,
                "ASCII subtract AST span provenance differs")
    require(f"(source-identity {identity})" in text, "ASCII subtract AST identity differs")
    cursor = text.index("(output-items ")
    require(f"(output-count {len(items)})" in text, "ASCII subtract AST count differs")
    for kind, value in items:
        if kind == "expression":
            witness = "(output-item (kind integer-expression) (operator -) (left x) (right 2) (rule R1217) (clause 12.6.3) (page 248))"
        elif kind == "variable":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        else:
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"ASCII subtract AST item missing: {witness}")
        cursor = position + len(witness)
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)", "(output-rule R1217)",
        "(source-document J3-24-007)", "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
        "(statement-page 242)", "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"ASCII subtract AST provenance missing: {witness}")


def check_mir(path: pathlib.Path, items: list[tuple[str, str]]) -> None:
    instructions = groups(path.read_text(encoding="utf-8"), "(instruction ")
    printed = [item for item in instructions if "(source-rule frontend-ast-v2/print-stmt)" in item]
    expected = []
    for kind, value in items:
        if kind == "expression":
            expected += [("load", "(storage-key x)"), ("const", "(literal 2)"), ("sub", ""), ("output", "")]
        elif kind == "variable":
            expected += [("load", "(storage-key x)"), ("output", "")]
        else:
            expected += [("const", f"(literal {value})"), ("output", "")]
    require(len(printed) == len(expected) + 1, "ASCII subtract MIR count differs")
    for actual, (opcode, operand) in zip(printed, expected):
        require(f"(opcode {opcode})" in actual, f"ASCII subtract MIR opcode differs: {opcode}")
        if operand:
            require(operand in actual, f"ASCII subtract MIR operand differs: {operand}")
    require("(opcode return)" in printed[-1], "ASCII subtract MIR has no return")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_ascii_subtract.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    require(elf.read_bytes().startswith(b"\x7fELF"), "ASCII subtract artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((b"3\n" if kind == "expression" else b"5\n" if kind == "variable" else f"{value}\n".encode())
                         for kind, value in items)
    require(runtime.returncode == 0 and runtime.stdout == expected, "ASCII subtract runtime output differs")
    print(f"generic ASCII subtract oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic ASCII subtract oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
