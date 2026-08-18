#!/usr/bin/env python3
"""Independent oracle for the generic integer PRINT-list slice."""

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
            raise OracleFailure(f"unbalanced group beginning at {marker!r}")


def expected_source(path: pathlib.Path, items: list[tuple[str, str]]) -> None:
    source = path.read_text(encoding="utf-8")
    expected_line = "  print *, " + ", ".join(value for _, value in items)
    require(expected_line in source, "source output list differs")
    require("program main" in source and "end program main" in source,
            "program envelope differs")


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    require("(program-unit-v2 " in text, "AST root differs")
    require(f"(file {source})" in text, "AST source path differs")
    require("(source-hash l3-raw-program-generic-print-list-v0)" in text,
            "AST source identity differs")
    require("(output-items " in text, "generic output-list node is absent")
    require(f"(output-count {len(items)})" in text, "AST output count differs")
    require("(output-kind-2 " not in text and "(output-name-2 " not in text,
            "AST retained numbered output fields")
    cursor = text.index("(output-items ")
    for kind, value in items:
        if kind == "variable":
            witness = f"(output-item (kind variable) (name {value}) (rule R901))"
        else:
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217))"
        position = text.find(witness, cursor)
        require(position >= 0, f"AST item missing: {witness}")
        cursor = position + len(witness)
    require("(statement-rule R1212)" in text and "(format-rule R1215)" in text,
            "PRINT provenance differs")


def check_mir(path: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    instructions = groups(text, "(instruction ")
    require(instructions, "MIR has no instructions")
    print_instructions = [
        instruction for instruction in instructions
        if "(source-rule frontend-ast-v2/print-stmt)" in instruction
    ]
    require(len(print_instructions) == 2 * len(items) + 1,
            "MIR PRINT instruction count differs")
    cursor = 0
    for kind, value in items:
        if kind == "variable":
            require("(opcode load)" in print_instructions[cursor],
                    "MIR variable item is not a load")
            require("(storage-key x)" in print_instructions[cursor],
                    "MIR variable storage key differs")
        else:
            require("(opcode const)" in print_instructions[cursor],
                    "MIR literal item is not a const")
            require(f"(literal {value})" in print_instructions[cursor],
                    "MIR literal differs")
        require("(opcode output)" in print_instructions[cursor + 1],
                "MIR item has no output")
        cursor += 2
    require("(opcode return)" in print_instructions[-1], "MIR has no PRINT return")
    require("(opcode output)" in text, "MIR has no output operation")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_list.py AST MIR ELF SOURCE")
    ast_path, mir_path, elf_path, source_path = map(pathlib.Path, sys.argv[1:])
    source = pathlib.Path(source_path)
    items_text = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(items_text is not None, "source has no PRINT list")
    items: list[tuple[str, str]] = []
    for value in items_text.group(1).strip().split(","):
        value = value.strip()
        items.append(("variable", value) if value == "x" else ("literal", value))
    expected_source(source, items)
    check_ast(ast_path, source, items)
    check_mir(mir_path, items)
    elf = elf_path.read_bytes()
    require(elf.startswith(b"\x7fELF"), "artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf_path)], capture_output=True, check=False)
    expected = "".join("3\n" if kind == "variable" else f"{value}\n" for kind, value in items).encode()
    require(runtime.returncode == 0, "runtime returned nonzero")
    require(runtime.stdout == expected, "runtime stdout differs")
    print(f"generic print-list oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic print-list oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
