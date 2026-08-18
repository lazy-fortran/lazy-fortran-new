#!/usr/bin/env python3
"""Independent behavioral oracle for the bounded generated compiler chain."""

from __future__ import annotations

import pathlib
import sys


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    if len(sys.argv) not in (4, 5, 6, 7):
        fail("usage: oracle_generated_chain.py AST MIR ELF [PROGRAM_NAME] [TYPE_SPEC] [MODE]")

    ast = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    mir = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
    elf = pathlib.Path(sys.argv[3]).read_bytes()
    program_name = sys.argv[4] if len(sys.argv) >= 5 else "p"
    type_spec = sys.argv[5] if len(sys.argv) == 6 else "integer"
    mode = sys.argv[6] if len(sys.argv) == 7 else "declaration"
    type_shapes = {
        "integer": ("integer", "i32"),
        "real": ("real", "f32"),
        "double-precision": ("real", "f64"),
        "complex": ("complex", "c32"),
        "logical": ("logical", "logical"),
        "character": ("character", "character"),
    }
    if type_spec not in type_shapes:
        fail("unsupported typed chain oracle shape")
    mir_kind, mir_type = type_shapes[type_spec]

    if not ast.startswith("(program-unit ") or f"(name {program_name})" not in ast:
        fail("AST-v1 root witness is wrong")
    if "(declaration-count 1)" not in ast or "(variable-count 1)" not in ast:
        fail("AST-v1 declaration cardinality is wrong")
    if ast.count("(variable (variable-declaration ") != 1:
        fail("AST-v1 variable declaration cardinality is wrong")
    if f"(variable (variable-declaration (type-spec {type_spec}) (name x)" not in ast:
        fail("AST-v1 declaration witness is wrong")

    if not mir.startswith(f"(mir-function (name {program_name}) "):
        fail("MIR-v0 function witness is wrong")
    if mode == "declaration":
        if mir.count("source-rule frontend-ast-v1/program") != 2:
            fail("MIR-v0 source correspondence is wrong")
    elif mode == "assignment":
        if "(assignment-count 1)" not in ast or \
                "(assignment (assignment-stmt (variable x) (expression (assignment-expression (kind integer-literal)" not in ast:
            fail("AST-v1 assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/assignment") != 2:
            fail("MIR-v0 assignment correspondence is wrong")
        if "(opcode store)" not in mir or "(opcode return)" not in mir:
            fail("MIR-v0 assignment opcode shape is wrong")
    elif mode == "expression":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator +) (left-operand 1) (right-operand 2)" not in ast:
            fail("AST-v1 expression assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 3:
            fail("MIR-v0 expression correspondence is wrong")
        if "(opcode add)" not in mir or "(opcode store)" not in mir or \
                "(opcode return)" not in mir:
            fail("MIR-v0 expression opcode shape is wrong")
    elif mode == "multiplication":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator *) (left-operand 2) (right-operand 3)" not in ast:
            fail("AST-v1 multiplication assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 3:
            fail("MIR-v0 multiplication correspondence is wrong")
        if "(opcode mul)" not in mir or "(opcode store)" not in mir or \
                "(opcode return)" not in mir:
            fail("MIR-v0 multiplication opcode shape is wrong")
    elif mode == "division":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator /) (left-operand 6) (right-operand 2)" not in ast:
            fail("AST-v1 division assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 3:
            fail("MIR-v0 division correspondence is wrong")
        if "(opcode div)" not in mir or "(opcode store)" not in mir or \
                "(opcode return)" not in mir:
            fail("MIR-v0 division opcode shape is wrong")
    elif mode == "subtraction":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator –) (left-operand 5) (right-operand 3)" not in ast:
            fail("AST-v1 subtraction assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 3:
            fail("MIR-v0 subtraction correspondence is wrong")
        if "(opcode sub)" not in mir or "(opcode store)" not in mir or \
                "(opcode return)" not in mir:
            fail("MIR-v0 subtraction opcode shape is wrong")
    else:
        fail("unsupported generated chain mode")
    expected_result_count = 3 if mode in ("expression", "multiplication", "division", "subtraction") else 2
    if mir.count(f"(kind {mir_kind}) (type {mir_type})") != expected_result_count:
        fail("MIR-v0 typed result is wrong")

    if len(elf) < 20 or elf[:4] != b"\x7fELF":
        fail("output is not ELF")
    if elf[4] != 2 or elf[5] != 1:
        fail("output is not little-endian ELF64")
    if int.from_bytes(elf[18:20], "little") != 243:
        fail("output is not RISC-V ELF")

    print("generated chain oracle: accepted")


if __name__ == "__main__":
    main()
