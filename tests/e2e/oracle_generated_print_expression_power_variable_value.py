#!/usr/bin/env python3
"""Independent oracle for x ** x with the initializer x = 4."""

from __future__ import annotations

import pathlib
import subprocess
import sys

from oracle_generated_print_expression_power_variable import (
    check_ast,
    check_mir,
    digest,
    parse_items,
    require,
)


class OracleFailure(Exception):
    pass


def check_contract(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-power-variable-value-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-power-variable-value)",
        "(version 0)",
        "(origin mechanical)",
        "(resolution resolved)",
        "(property generic-integer-variable-power-expression-output-at-value-4)",
        "(rules R901 R1008 R1212 R1215 R1217)",
        "(pages 155 242 244 248)",
    ):
        require(witness in text, f"power-variable-value contract differs: {witness}")
    cases = {
        "tests/fixtures/l3-print-expression-power-variable-value-v0.f90":
            "73e1e4a474b327578b3fd30737306d86d4c33bf6396d682de15213a08fa4dd01",
        "tests/fixtures/l3-print-expression-power-variable-value-wide-v0.f90":
            "aa4135efac7e18dce2251c7f9d74adf0ef5e0306232ec63ff009b258e686d2ef",
    }
    for relative, expected in cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"power-variable-value source case differs: {relative}")
        require(digest(source) == expected, f"power-variable-value source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    ir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    require(digest(root / ".cache/j3-24-007.pdf") == pdf_hash, "power-variable-value PDF differs")
    require(digest(root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx") == ir_hash,
            "power-variable-value StandardIR differs")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_power_variable_value.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    require(elf.read_bytes().startswith(b"\x7fELF"), "power-variable-value artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((b"256\n" if kind == "expression" else b"4\n" if kind == "variable" else f"{value}\n".encode())
                         for kind, value in items)
    require(runtime.returncode == 0 and runtime.stdout == expected,
            "power-variable-value runtime output differs")
    print(f"generic power-variable-value oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic power-variable-value oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
