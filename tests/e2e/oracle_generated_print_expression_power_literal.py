#!/usr/bin/env python3
"""Independent oracle for generic integer-literal power expressions."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

from oracle_generated_print_expression_variable import digest, groups, require


class OracleFailure(Exception):
    pass


def check_contract(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-power-literal-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-power-literal)", "(version 0)",
        "(origin mechanical)", "(resolution resolved)",
        "(property generic-integer-power-literal-expression-output)",
        "(rules R901 R1008 R1212 R1215 R1217)",
        "(pages 155 242 244 248)",
    ):
        require(witness in text, f"power-literal contract differs: {witness}")
    cases = {
        "tests/fixtures/l3-print-expression-power-literal-v0.f90":
            "e87b9505334234168df36c727a7988acb4d182b1722b78935a353d5b2b833977",
        "tests/fixtures/l3-print-expression-power-literal-wide-v0.f90":
            "1155b18477f47b1f032c47c1c46564f49eabb4c917487ec33a5c53eb3659dfbe",
        "tests/fixtures/l3-print-expression-power-literal-large-v0.f90":
            "754cf953141432880bab77a85e453e27b9d902836758498aceb8f4041957fd24",
        "tests/negative/l3-print-expression-power-literal-v0-missing-operand.f90":
            "3b7c0a788a5c9bd6a42df32124f069a778f759656491975958615eafee844496",
        "tests/negative/l3-print-expression-power-literal-v0-variable-exponent.f90":
            "1450cee87c799e4038a40eaabc61cd404b04786a400f247b4e7aef3d4fe25a05",
        "tests/negative/l3-print-expression-power-literal-v0-negative-exponent.f90":
            "c0031f58cac515fedd39d1e752a35c1c42bfc1f91ccaad74defef1301b5a727b",
        "tests/negative/l3-print-expression-power-literal-v0-write.f90":
            "6640792fad5f57968aa7c6b1cfa396ace308a5d039bd7bc61891d8dc8762a68f",
    }
    for relative, expected in cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"power-literal source case differs: {relative}")
        require(digest(source) == expected, f"power-literal source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    ir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(root / ".cache/j3-24-007.pdf") == pdf_hash,
            "power-literal PDF differs")
    require(f"(standardir-sha256 {ir_hash})" in text and
            digest(root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx") == ir_hash,
            "power-literal StandardIR differs")


def parse_items(source: pathlib.Path) -> list[tuple[str, str]]:
    match = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(match is not None, "power-literal source has no PRINT list")
    result = []
    for raw in match.group(1).strip().split(","):
        value = raw.strip()
        if re.fullmatch(r"x \*\* [0-9]+", value):
            result.append(("expression", value))
        elif value == "x":
            result.append(("variable", value))
        elif value.isdigit():
            result.append(("literal", value))
        else:
            raise OracleFailure(f"unsupported power-literal item: {value}")
    return result


def expression_exponent(value: str) -> int:
    return int(value.rsplit(" ", 1)[1])


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    identity = "l3-raw-program-generic-print-expression-v0"
    require("(program-unit-v2 " in text and f"(file {source})" in text, "power-literal AST root differs")
    spans = groups(text, "(source-span ")
    require(spans, "power-literal AST has no spans")
    for span in spans:
        require(f"(file {source})" in span and f"(source-hash {identity})" in span,
                "power-literal AST span provenance differs")
    require(f"(source-identity {identity})" in text, "power-literal AST identity differs")
    cursor = text.index("(output-items ")
    require(f"(output-count {len(items)})" in text, "power-literal AST count differs")
    for kind, value in items:
        if kind == "expression":
            witness = f"(output-item (kind integer-expression) (operator **) (left x) (right {expression_exponent(value)}) (rule R1217) (clause 12.6.3) (page 248))"
        elif kind == "variable":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        else:
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"power-literal AST item missing: {witness}")
        cursor = position + len(witness)
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)", "(output-rule R1217)",
        "(source-document J3-24-007)", "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
        "(statement-page 242)", "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"power-literal AST provenance missing: {witness}")


def check_mir(path: pathlib.Path, items: list[tuple[str, str]]) -> None:
    instructions = groups(path.read_text(encoding="utf-8"), "(instruction ")
    printed = [item for item in instructions if "(source-rule frontend-ast-v2/print-stmt)" in item]
    expected = []
    for kind, value in items:
        if kind == "expression":
            expected += [("load", "(storage-key x)"), ("const", f"(literal {expression_exponent(value)})"), ("pow", ""), ("output", "")]
        elif kind == "variable":
            expected += [("load", "(storage-key x)"), ("output", "")]
        else:
            expected += [("const", f"(literal {value})"), ("output", "")]
    require(len(printed) == len(expected) + 1, "power-literal MIR count differs")
    for actual, (opcode, operand) in zip(printed, expected):
        require(f"(opcode {opcode})" in actual, f"power-literal MIR opcode differs: {opcode}")
        if operand:
            require(operand in actual, f"power-literal MIR operand differs: {operand}")
    require("(opcode return)" in printed[-1], "power-literal MIR has no return")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_power_literal.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    require(elf.read_bytes().startswith(b"\x7fELF"), "power-literal artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((f"{3 ** expression_exponent(value)}\n".encode() if kind == "expression" else
                          b"3\n" if kind == "variable" else f"{value}\n".encode())
                         for kind, value in items)
    require(runtime.returncode == 0 and runtime.stdout == expected, "power-literal runtime output differs")
    print(f"generic power-literal oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic power-literal oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
