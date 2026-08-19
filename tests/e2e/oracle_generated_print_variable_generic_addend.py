#!/usr/bin/env python3
"""Independent oracle for bounded initialized x + n transport."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys


class OracleFailure(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise OracleFailure(message)


def groups(text: str, marker: str) -> list[str]:
    result: list[str] = []
    start = 0
    while True:
        start = text.find(marker, start)
        if start < 0:
            return result
        depth = 0
        began = False
        for position in range(start, len(text)):
            if text[position] == "(":
                depth += 1
                began = True
            elif text[position] == ")":
                depth -= 1
                if began and depth == 0:
                    result.append(text[start : position + 1])
                    start = position + 1
                    break
        else:
            raise OracleFailure("unbalanced SX group")


def source_values(path: pathlib.Path) -> tuple[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.search(
        r"^  x = (-?[0-9]+)\n  x = x \+ ([0-9]+)$", text, flags=re.MULTILINE
    )
    require(match is not None, "source assignment shape differs")
    initializer, addend = match.groups()
    require(-100 <= int(initializer) <= 2047, "initializer is outside policy range")
    require(1 <= int(addend) <= 10, "addend is outside policy range")
    require("  print *, x" in text, "source PRINT variable differs")
    return initializer, addend


def check_ast(path: pathlib.Path, source: pathlib.Path, initializer: str, addend: str) -> None:
    text = path.read_text(encoding="utf-8")
    require(text.startswith("(program-unit-v2 "), "AST root differs")
    require(f"(file {source})" in text, "AST source path differs")
    require("(source-hash l3-raw-program-v2)" in text, "AST source identity differs")
    require("(assignment-sequence (assignment-count 2)" in text, "AST assignment count differs")
    require(f"(kind integer-literal) (operator ) (left-operand {initializer})" in text,
            "AST initializer differs")
    require(f"(kind binary-expression) (operator +) (left-operand x) (right-operand {addend})" in text,
            "AST addend differs")
    require("(output-kind variable) (output-name x)" in text, "AST PRINT variable differs")
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)", "(output-rule R901)",
        "(source-document J3-24-007)", "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
        "(statement-page 242)", "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"AST provenance missing: {witness}")


def check_mir(path: pathlib.Path, initializer: str, addend: str) -> None:
    text = path.read_text(encoding="utf-8")
    instructions = groups(text, "(instruction ")
    require(len(instructions) == 9, "MIR instruction count differs")
    expected = ["const", "store", "load", "const", "add", "store", "load", "output", "return"]
    for instruction, opcode in zip(instructions, expected):
        require(f"(opcode {opcode})" in instruction, f"MIR opcode differs: {opcode}")
    require(f"(literal {initializer})" in instructions[0], "MIR initializer differs")
    require(f"(literal {addend})" in instructions[3], "MIR addend differs")
    require("(storage-key x)" in instructions[1], "MIR initializer store differs")
    require("(storage-key x)" in instructions[2], "MIR add load differs")
    require("(storage-key x)" in instructions[5], "MIR result store differs")
    require("(storage-key x)" in instructions[6], "MIR PRINT load differs")
    require("(source-rule frontend-ast-v2/print-stmt)" in instructions[6],
            "MIR PRINT source rule differs")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_variable_generic_addend.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    initializer, addend = source_values(source)
    check_ast(ast, source, initializer, addend)
    check_mir(mir, initializer, addend)
    binary = elf.read_bytes()
    require(binary.startswith(b"\x7fELF"), "artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    require(runtime.returncode == 0, "runtime returned nonzero")
    require(runtime.stdout == f"{int(initializer) + int(addend)}\n".encode(),
            "runtime output differs")
    print("generic initialized addend oracle PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic initialized addend oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
