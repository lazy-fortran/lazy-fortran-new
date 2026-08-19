#!/usr/bin/env python3
"""Independent oracle for the zero and upper-bound PRINT constant slice."""

from __future__ import annotations

import pathlib
import subprocess
import sys

from oracle_generated_print_expression_decimal_constant import (
    check_ast,
    check_mir,
    digest,
    parse_items,
)
from oracle_generated_print_expression_variable import require


class OracleFailure(Exception):
    pass


def check_contract(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-decimal-constant-zero-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-decimal-constant-zero)", "(version 0)",
        "(origin mechanical)", "(resolution resolved)",
        "(property generated-integer-decimal-expression-zero-and-boundary)",
        "(rules R901 R1006 R1007 R1010 R1212 R1215 R1217)",
        "(pages 69 155 242 244 248)",
    ):
        require(witness in text, f"zero-constant contract differs: {witness}")
    cases = {
        "tests/fixtures/l3-print-expression-decimal-constant-zero-v0.f90": "98ee081bdbab4e77e79c9a4fd379428d2de8d8820afa136569fb974c497d60a3",
        "tests/fixtures/l3-print-expression-decimal-constant-boundary-v0.f90": "d39610e9ec9a7844289d4bc037c5730f9b2e0aba50e37cc27f62554c944b0f4d",
        "tests/negative/l3-print-expression-decimal-constant-zero-v0-missing-operand.f90": "06688957a17099f13ddec436fc81487be060931c845eeb168ffd79cd3583e7d6",
        "tests/negative/l3-print-expression-decimal-constant-zero-v0-real-right.f90": "7712c90a8cb37a6cb490fd9a011cd11d75df380cfc2609b9ab29f339372500e6",
        "tests/negative/l3-print-expression-decimal-constant-zero-v0-out-of-range.f90": "3ba13cdc307183eff203bf4c42f2bc3c1ce34b768bbb3e1a2639dcb5d6a47bff",
        "tests/negative/l3-print-expression-decimal-constant-zero-v0-write.f90": "a42288e565021e182a8b91053825743cde7c2e80d0b34dd5038f83ff5be70fb7",
        "tests/negative/l3-print-expression-decimal-constant-zero-v0-wrong-name.f90": "aa7847a0ead2b7cae6dc03f25c1d7b9517478004d2f847104f4403619658a4e0",
    }
    for relative, expected in cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"zero-constant source case differs: {relative}")
        require(digest(source) == expected, f"zero-constant source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    ir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(root / ".cache/j3-24-007.pdf") == pdf_hash,
            "zero-constant PDF differs")
    require(f"(standardir-sha256 {ir_hash})" in text and
            digest(root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx") == ir_hash,
            "zero-constant StandardIR differs")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_decimal_constant_zero.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    require(elf.read_bytes().startswith(b"\x7fELF"), "zero-constant artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join(
        (f"{5 + number if value == '+' else 5 - number}\n".encode()
         if kind == "expression" else f"{number}\n".encode())
        for kind, value, number in items
    )
    require(runtime.returncode == 0 and runtime.stdout == expected,
            "zero-constant runtime output differs")
    print(f"generic decimal-constant-zero oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic decimal-constant-zero oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
