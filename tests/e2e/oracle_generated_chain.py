#!/usr/bin/env python3
"""Independent behavioral oracle for the bounded generated compiler chain."""

from __future__ import annotations

import pathlib
import sys
import hashlib


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    if len(sys.argv) not in (4, 5, 6, 7, 8):
        fail("usage: oracle_generated_chain.py AST MIR ELF [PROGRAM_NAME] [TYPE_SPEC] [MODE] [SOURCE]")

    ast = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    mir = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
    elf = pathlib.Path(sys.argv[3]).read_bytes()
    program_name = sys.argv[4] if len(sys.argv) >= 5 else "p"
    type_spec = sys.argv[5] if len(sys.argv) >= 6 else "integer"
    mode = sys.argv[6] if len(sys.argv) >= 7 else "declaration"
    source_path = pathlib.Path(sys.argv[7]) if len(sys.argv) == 8 else None
    requested_mode = mode
    if mode == "print-variable-expression":
        mode = "print-variable"
    elif mode == "print-variable-two-item":
        mode = "print-variable"
    elif mode == "print-variable-three-item":
        mode = "print-variable"
    elif mode == "print-variable-four-item":
        mode = "print-variable"
    elif mode == "print-variable-five-item":
        mode = "print-variable"
    elif mode == "print-variable-six-item":
        mode = "print-variable"
    elif mode.startswith("print-variable-") and mode.endswith("-item"):
        mode = "print-variable"
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

    if mode != "print-variable" and mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9", "print-7-8-9-10", "print-7-8-9-10-11", "print-7-8-9-10-11-12", "print-7-8-9-10-11-12-13", "print-7-8-9-10-11-12-13-14", "print-7-8-9-10-11-12-13-14-15", "print-7-8-9-10-11-12-13-14-15-16", "print-generic-items") and (not ast.startswith("(program-unit ") or f"(name {program_name})" not in ast):
        fail("AST-v1 root witness is wrong")
    if mode != "print-variable" and mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9", "print-7-8-9-10", "print-7-8-9-10-11", "print-7-8-9-10-11-12", "print-7-8-9-10-11-12-13", "print-7-8-9-10-11-12-13-14", "print-7-8-9-10-11-12-13-14-15", "print-7-8-9-10-11-12-13-14-15-16", "print-generic-items") and ("(declaration-count 1)" not in ast or "(variable-count 1)" not in ast):
        fail("AST-v1 declaration cardinality is wrong")
    if mode != "print-variable" and mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9", "print-7-8-9-10", "print-7-8-9-10-11", "print-7-8-9-10-11-12", "print-7-8-9-10-11-12-13", "print-7-8-9-10-11-12-13-14", "print-7-8-9-10-11-12-13-14-15", "print-7-8-9-10-11-12-13-14-15-16", "print-generic-items") and ast.count("(variable (variable-declaration ") != 1:
        fail("AST-v1 variable declaration cardinality is wrong")
    if mode != "print-variable" and mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9", "print-7-8-9-10", "print-7-8-9-10-11", "print-7-8-9-10-11-12", "print-7-8-9-10-11-12-13", "print-7-8-9-10-11-12-13-14", "print-7-8-9-10-11-12-13-14-15", "print-7-8-9-10-11-12-13-14-15-16", "print-generic-items") and f"(variable (variable-declaration (type-spec {type_spec}) (name x)" not in ast:
        fail("AST-v1 declaration witness is wrong")

    if not mir.startswith(f"(mir-function (name {program_name}) "):
        fail("MIR-v0 function witness is wrong")
    if mode == "stop-7":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(stop-stmt (code 7)") != 1 or \
                "(source-rule R1162)" not in ast or \
                "(code-rule R1164)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(source-clause 11)" not in ast or \
                "(source-page 214)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 STOP 7 provenance witness is wrong")
        if mir.count("(opcode const)") != 1 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/stop-stmt)") != 2 or \
                "(opcode store)" in mir:
            fail("MIR-v0 STOP 7 shape is wrong")
    elif mode == "print-7":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7 provenance witness is wrong")
        if mir.count("(opcode const)") != 1 or \
                mir.count("(opcode output)") != 1 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 3 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7 shape is wrong")
    elif mode == "print-7-8":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 2)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8 provenance witness is wrong")
        if mir.count("(opcode const)") != 2 or \
                mir.count("(opcode output)") != 2 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 5 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8 shape is wrong")
    elif mode == "print-7-8-9":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 3)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(output-kind-3 integer-literal)" not in ast or \
                "(output-value-3 9)" not in ast or \
                "(output-rule-3 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9 provenance witness is wrong")
        if mir.count("(opcode const)") != 3 or \
                mir.count("(opcode output)") != 3 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(literal 9)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 7 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9 shape is wrong")
    elif mode == "print-7-8-9-10":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 4)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(output-kind-3 integer-literal)" not in ast or \
                "(output-value-3 9)" not in ast or \
                "(output-rule-3 R1217)" not in ast or \
                "(output-kind-4 integer-literal)" not in ast or \
                "(output-value-4 10)" not in ast or \
                "(output-rule-4 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9,10 provenance witness is wrong")
        if mir.count("(opcode const)") != 4 or \
                mir.count("(opcode output)") != 4 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(literal 9)") != 1 or \
                mir.count("(literal 10)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 9 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9,10 shape is wrong")
    elif mode == "print-7-8-9-10-11":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 5)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(output-kind-3 integer-literal)" not in ast or \
                "(output-value-3 9)" not in ast or \
                "(output-rule-3 R1217)" not in ast or \
                "(output-kind-4 integer-literal)" not in ast or \
                "(output-value-4 10)" not in ast or \
                "(output-rule-4 R1217)" not in ast or \
                "(output-kind-5 integer-literal)" not in ast or \
                "(output-value-5 11)" not in ast or \
                "(output-rule-5 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9,10,11 provenance witness is wrong")
        if mir.count("(opcode const)") != 5 or \
                mir.count("(opcode output)") != 5 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(literal 9)") != 1 or \
                mir.count("(literal 10)") != 1 or \
                mir.count("(literal 11)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 11 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9,10,11 shape is wrong")
    elif mode == "print-7-8-9-10-11-12":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 6)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(output-kind-3 integer-literal)" not in ast or \
                "(output-value-3 9)" not in ast or \
                "(output-rule-3 R1217)" not in ast or \
                "(output-kind-4 integer-literal)" not in ast or \
                "(output-value-4 10)" not in ast or \
                "(output-rule-4 R1217)" not in ast or \
                "(output-kind-5 integer-literal)" not in ast or \
                "(output-value-5 11)" not in ast or \
                "(output-rule-5 R1217)" not in ast or \
                "(output-kind-6 integer-literal)" not in ast or \
                "(output-value-6 12)" not in ast or \
                "(output-rule-6 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9,10,11,12 provenance witness is wrong")
        if mir.count("(opcode const)") != 6 or \
                mir.count("(opcode output)") != 6 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(literal 9)") != 1 or \
                mir.count("(literal 10)") != 1 or \
                mir.count("(literal 11)") != 1 or \
                mir.count("(literal 12)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 13 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9,10,11,12 shape is wrong")
    elif mode == "print-7-8-9-10-11-12-13":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 7)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(output-kind-3 integer-literal)" not in ast or \
                "(output-value-3 9)" not in ast or \
                "(output-rule-3 R1217)" not in ast or \
                "(output-kind-4 integer-literal)" not in ast or \
                "(output-value-4 10)" not in ast or \
                "(output-rule-4 R1217)" not in ast or \
                "(output-kind-5 integer-literal)" not in ast or \
                "(output-value-5 11)" not in ast or \
                "(output-rule-5 R1217)" not in ast or \
                "(output-kind-6 integer-literal)" not in ast or \
                "(output-value-6 12)" not in ast or \
                "(output-rule-6 R1217)" not in ast or \
                "(output-kind-7 integer-literal)" not in ast or \
                "(output-value-7 13)" not in ast or \
                "(output-rule-7 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9,10,11,12,13 provenance witness is wrong")
        if mir.count("(opcode const)") != 7 or \
                mir.count("(opcode output)") != 7 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(literal 9)") != 1 or \
                mir.count("(literal 10)") != 1 or \
                mir.count("(literal 11)") != 1 or \
                mir.count("(literal 12)") != 1 or \
                mir.count("(literal 13)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 15 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9,10,11,12,13 shape is wrong")
    elif mode == "print-7-8-9-10-11-12-13-14":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 8)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(output-kind-3 integer-literal)" not in ast or \
                "(output-value-3 9)" not in ast or \
                "(output-rule-3 R1217)" not in ast or \
                "(output-kind-4 integer-literal)" not in ast or \
                "(output-value-4 10)" not in ast or \
                "(output-rule-4 R1217)" not in ast or \
                "(output-kind-5 integer-literal)" not in ast or \
                "(output-value-5 11)" not in ast or \
                "(output-rule-5 R1217)" not in ast or \
                "(output-kind-6 integer-literal)" not in ast or \
                "(output-value-6 12)" not in ast or \
                "(output-rule-6 R1217)" not in ast or \
                "(output-kind-7 integer-literal)" not in ast or \
                "(output-value-7 13)" not in ast or \
                "(output-rule-7 R1217)" not in ast or \
                "(output-kind-8 integer-literal)" not in ast or \
                "(output-value-8 14)" not in ast or \
                "(output-rule-8 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9,10,11,12,13,14 provenance witness is wrong")
        if mir.count("(opcode const)") != 8 or \
                mir.count("(opcode output)") != 8 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(literal 9)") != 1 or \
                mir.count("(literal 10)") != 1 or \
                mir.count("(literal 11)") != 1 or \
                mir.count("(literal 12)") != 1 or \
                mir.count("(literal 13)") != 1 or \
                mir.count("(literal 14)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 17 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9,10,11,12,13,14 shape is wrong")
    elif mode == "print-7-8-9-10-11-12-13-14-15":
        if not ast.startswith("(program-unit-v2 ") or \
                "(root (program-root (name p)" not in ast or \
                "(declaration-count 0)" not in ast or \
                "(variable-count 0)" not in ast or \
                ast.count("(print-stmt ") != 1 or \
                "(format-kind default-char-expr)" not in ast or \
                "(format-value *)" not in ast or \
                "(output-kind integer-literal)" not in ast or \
                "(output-value 7)" not in ast or \
                "(output-count 9)" not in ast or \
                "(output-kind-2 integer-literal)" not in ast or \
                "(output-value-2 8)" not in ast or \
                "(output-rule-2 R1217)" not in ast or \
                "(output-kind-3 integer-literal)" not in ast or \
                "(output-value-3 9)" not in ast or \
                "(output-rule-3 R1217)" not in ast or \
                "(output-kind-4 integer-literal)" not in ast or \
                "(output-value-4 10)" not in ast or \
                "(output-rule-4 R1217)" not in ast or \
                "(output-kind-5 integer-literal)" not in ast or \
                "(output-value-5 11)" not in ast or \
                "(output-rule-5 R1217)" not in ast or \
                "(output-kind-6 integer-literal)" not in ast or \
                "(output-value-6 12)" not in ast or \
                "(output-rule-6 R1217)" not in ast or \
                "(output-kind-7 integer-literal)" not in ast or \
                "(output-value-7 13)" not in ast or \
                "(output-rule-7 R1217)" not in ast or \
                "(output-kind-8 integer-literal)" not in ast or \
                "(output-value-8 14)" not in ast or \
                "(output-rule-8 R1217)" not in ast or \
                "(output-kind-9 integer-literal)" not in ast or \
                "(output-value-9 15)" not in ast or \
                "(output-rule-9 R1217)" not in ast or \
                "(statement-rule R1212)" not in ast or \
                "(format-rule R1215)" not in ast or \
                "(output-rule R1217)" not in ast or \
                "(source-document J3-24-007)" not in ast or \
                "(statement-clause 12.6.1)" not in ast or \
                "(format-clause 12.6.2.2)" not in ast or \
                "(output-clause 12.6.3)" not in ast or \
                "(statement-page 242)" not in ast or \
                "(format-page 244)" not in ast or \
                "(output-page 248)" not in ast or \
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)" not in ast or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9,10,11,12,13,14,15 provenance witness is wrong")
        if mir.count("(opcode const)") != 9 or \
                mir.count("(opcode output)") != 9 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(literal 7)") != 1 or \
                mir.count("(literal 8)") != 1 or \
                mir.count("(literal 9)") != 1 or \
                mir.count("(literal 10)") != 1 or \
                mir.count("(literal 11)") != 1 or \
                mir.count("(literal 12)") != 1 or \
                mir.count("(literal 13)") != 1 or \
                mir.count("(literal 14)") != 1 or \
                mir.count("(literal 15)") != 1 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 19 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9,10,11,12,13,14,15 shape is wrong")
    elif mode == "print-7-8-9-10-11-12-13-14-15-16":
        required = [
            "(program-unit-v2 ", "(root (program-root (name p)",
            "(declaration-count 0)", "(variable-count 0)",
            "(format-kind default-char-expr)", "(format-value *)",
            "(output-kind integer-literal)", "(output-value 7)",
            "(output-count 10)", "(statement-rule R1212)",
            "(format-rule R1215)", "(output-rule R1217)",
            "(source-document J3-24-007)", "(statement-clause 12.6.1)",
            "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
            "(statement-page 242)", "(format-page 244)",
            "(output-page 248)",
            "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
        ]
        for index, value in enumerate(range(8, 17), start=2):
            required.extend([
                f"(output-kind-{index} integer-literal)",
                f"(output-value-{index} {value})",
                f"(output-rule-{index} R1217)",
            ])
        if any(item not in ast for item in required) or \
                ast.count("(print-stmt ") != 1 or \
                "(assignment-sequence" in ast:
            fail("AST-v2 PRINT 7,8,9,10,11,12,13,14,15,16 provenance witness is wrong")
        if mir.count("(opcode const)") != 10 or \
                mir.count("(opcode output)") != 10 or \
                mir.count("(opcode return)") != 1 or \
                any(mir.count(f"(literal {value})") != 1 for value in range(7, 17)) or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 21 or \
                "(opcode store)" in mir:
            fail("MIR-v0 PRINT 7,8,9,10,11,12,13,14,15,16 shape is wrong")
    elif mode == "print-generic-items":
        required = [
            "(program-unit-v2 ", "(root (program-root (name p)",
            "(declaration-count 0)", "(variable-count 0)",
            "(print-stmt ", "(format-kind default-char-expr)",
            "(format-value *)", "(output-kind integer-literal)",
            "(output-value 17)", "(output-count 3)",
            "(output-kind-2 integer-literal)", "(output-value-2 18)",
            "(output-rule-2 R1217)", "(output-kind-3 integer-literal)",
            "(output-value-3 19)", "(output-rule-3 R1217)",
            "(statement-rule R1212)", "(format-rule R1215)",
            "(output-rule R1217)", "(source-document J3-24-007)",
            "(statement-clause 12.6.1)", "(format-clause 12.6.2.2)",
            "(output-clause 12.6.3)", "(statement-page 242)",
            "(format-page 244)", "(output-page 248)",
            "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
        ]
        if any(item not in ast for item in required) or "(assignment-sequence" in ast:
            fail("AST-v2 generic PRINT item provenance witness is wrong")
        if mir.count("(opcode const)") != 3 or \
                mir.count("(opcode output)") != 3 or \
                mir.count("(opcode return)") != 1 or \
                any(mir.count(f"(literal {value})") != 1 for value in (17, 18, 19)) or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 7 or \
                "(opcode store)" in mir:
            fail("MIR-v0 generic PRINT item shape is wrong")
    elif mode == "print-variable":
        if source_path is None:
            fail("stored-variable oracle requires a source fixture")
        if requested_mode == "print-variable-two-item":
            source_bytes = source_path.read_bytes()
            expected_source = (
                b"program main\n"
                b"  integer :: x\n"
                b"  x = 3\n"
                b"  x = x ** 2\n"
                b"  print *, x, x\n"
                b"end program main\n"
            )
            if source_bytes != expected_source or \
                    hashlib.sha256(source_bytes).hexdigest() != \
                    "c7dc1f449caf651bdeea13f57a8921d3a3c4a7309d8ac87e276123cd0e0d8b35":
                fail("stored-variable two-item source fixture bytes changed")
            if hashlib.sha256(elf).hexdigest() != \
                    "c44f212bed55cfdb7ff2d2d0ba8aa3d159ac1f603ff5e134fdc93c5046d02b1d":
                fail("stored-variable two-item ELF identity changed")
            expected_file_marker = f"(file {source_path})"
            if ast.count("(file ") != 6 or ast.count(expected_file_marker) != 6 or \
                    ast.count("(source-hash l3-raw-program-two-assignment-v1)") != 6:
                fail("stored-variable two-item AST source identity is wrong")
            required_two_item = [
                "(program-unit-v2 ", "(root (program-root (name main)",
                "(declaration-count 1)", "(variable-count 1)",
                "(execution-part (assignment-sequence (assignment-count 2)",
                "(kind integer-literal)", "(left-operand 3)",
                "(kind binary-expression)", "(operator **)",
                "(left-operand x)", "(right-operand 2)",
                "(output-count 2)", "(output-kind variable)",
                "(output-name x)", "(output-kind-2 variable)",
                "(output-name-2 x)", "(statement-rule R1212)",
                "(format-rule R1215)", "(output-rule R901)",
                "(output-rule-2 R901)", "(source-document J3-24-007)",
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
            ]
            if any(item not in ast for item in required_two_item) or \
                    ast.count("(assignment (assignment-stmt ") != 2 or \
                    ast.count("(print-stmt ") != 1:
                fail("AST-v2 stored-variable two-item PRINT witness is wrong")
            if mir.count("(instruction-count 11)") != 1 or \
                    mir.count("(opcode const)") != 2 or \
                    mir.count("(opcode store)") != 2 or \
                    mir.count("(opcode load)") != 3 or \
                    mir.count("(opcode pow)") != 1 or \
                    mir.count("(opcode output)") != 2 or \
                    mir.count("(opcode return)") != 1 or \
                    mir.count("(literal 3)") != 1 or mir.count("(literal 2)") != 1 or \
                    mir.count("(storage-key x)") != 5 or \
                    mir.count("(source-rule frontend-ast-v2/execution-part)") != 6 or \
                    mir.count("(source-rule frontend-ast-v2/print-stmt)") != 5:
                fail("MIR-v0 stored-variable two-item PRINT shape is wrong")
            print("generated chain oracle: accepted")
            return
        if requested_mode == "print-variable-five-item":
            source_bytes = source_path.read_bytes()
            expected_source = (
                b"program main\n"
                b"  integer :: x\n"
                b"  x = 3\n"
                b"  x = x ** 2\n"
                b"  print *, x, x, x, x, x\n"
                b"end program main\n"
            )
            if source_bytes != expected_source or \
                    hashlib.sha256(source_bytes).hexdigest() != \
                    "f8ba31749daad7b6b89dc45ba40986639d8cf77b27c702569b10468486b5b499":
                fail("stored-variable five-item source fixture bytes changed")
            if hashlib.sha256(elf).hexdigest() != \
                    "4cbdd960fa9b8e2ae81f1f868bafadf6df20b8b8b557c6344befef99dcd54cfd":
                fail("stored-variable five-item ELF identity changed")
            expected_file_marker = f"(file {source_path})"
            if ast.count("(file ") != 6 or ast.count(expected_file_marker) != 6 or \
                    ast.count("(source-hash l3-raw-program-two-assignment-v1)") != 6:
                fail("stored-variable five-item AST source identity is wrong")
            required_five_item = [
                "(program-unit-v2 ", "(root (program-root (name main)",
                "(declaration-count 1)", "(variable-count 1)",
                "(execution-part (assignment-sequence (assignment-count 2)",
                "(kind integer-literal)", "(left-operand 3)",
                "(kind binary-expression)", "(operator **)",
                "(left-operand x)", "(right-operand 2)",
                "(output-count 5)", "(output-kind variable)",
                "(output-name x)", "(output-kind-2 variable)",
                "(output-name-2 x)", "(output-kind-3 variable)",
                "(output-name-3 x)", "(output-kind-4 variable)",
                "(output-name-4 x)", "(output-kind-5 variable)",
                "(output-name-5 x)", "(statement-rule R1212)",
                "(format-rule R1215)", "(output-rule R901)",
                "(output-rule-2 R901)", "(output-rule-3 R901)",
                "(output-rule-4 R901)", "(output-rule-5 R901)",
                "(source-document J3-24-007)",
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
            ]
            if any(item not in ast for item in required_five_item) or \
                    ast.count("(assignment (assignment-stmt ") != 2 or \
                    ast.count("(print-stmt ") != 1:
                fail("AST-v2 stored-variable five-item PRINT witness is wrong")
            if mir.count("(instruction-count 17)") != 1 or \
                    mir.count("(opcode const)") != 2 or \
                    mir.count("(opcode store)") != 2 or \
                    mir.count("(opcode load)") != 6 or \
                    mir.count("(opcode pow)") != 1 or \
                    mir.count("(opcode output)") != 5 or \
                    mir.count("(opcode return)") != 1 or \
                    mir.count("(literal 3)") != 1 or mir.count("(literal 2)") != 1 or \
                    mir.count("(storage-key x)") != 8 or \
                    mir.count("(source-rule frontend-ast-v2/execution-part)") != 6 or \
                    mir.count("(source-rule frontend-ast-v2/print-stmt)") != 11:
                fail("MIR-v0 stored-variable five-item PRINT shape is wrong")
            print("generated chain oracle: accepted")
            return
        if requested_mode == "print-variable-six-item":
            source_bytes = source_path.read_bytes()
            expected_source = (
                b"program main\n"
                b"  integer :: x\n"
                b"  x = 3\n"
                b"  x = x ** 2\n"
                b"  print *, x, x, x, x, x, x\n"
                b"end program main\n"
            )
            if source_bytes != expected_source or \
                    hashlib.sha256(source_bytes).hexdigest() != \
                    "d52841c478e4a791db7c31901b3198aa193eb29879699e2be3234ccf5a7626bb":
                fail("stored-variable six-item source fixture bytes changed")
            if hashlib.sha256(elf).hexdigest() != \
                    "4b5ce4759e826883e665023d16f90b083525f1d0eca1d6c13634988097748667":
                fail("stored-variable six-item ELF identity changed")
            expected_file_marker = f"(file {source_path})"
            if ast.count("(file ") != 6 or ast.count(expected_file_marker) != 6 or \
                    ast.count("(source-hash l3-raw-program-two-assignment-v1)") != 6:
                fail("stored-variable six-item AST source identity is wrong")
            required_six_item = [
                "(program-unit-v2 ", "(root (program-root (name main)",
                "(declaration-count 1)", "(variable-count 1)",
                "(execution-part (assignment-sequence (assignment-count 2)",
                "(kind integer-literal)", "(left-operand 3)",
                "(kind binary-expression)", "(operator **)",
                "(left-operand x)", "(right-operand 2)",
                "(output-count 6)", "(output-kind variable)",
                "(output-name x)", "(output-kind-2 variable)",
                "(output-name-2 x)", "(output-kind-3 variable)",
                "(output-name-3 x)", "(output-kind-4 variable)",
                "(output-name-4 x)", "(output-kind-5 variable)",
                "(output-name-5 x)", "(output-kind-6 variable)",
                "(output-name-6 x)", "(statement-rule R1212)",
                "(format-rule R1215)", "(output-rule R901)",
                "(output-rule-2 R901)", "(output-rule-3 R901)",
                "(output-rule-4 R901)", "(output-rule-5 R901)",
                "(output-rule-6 R901)", "(source-document J3-24-007)",
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
            ]
            if any(item not in ast for item in required_six_item) or \
                    ast.count("(assignment (assignment-stmt ") != 2 or \
                    ast.count("(print-stmt ") != 1:
                fail("AST-v2 stored-variable six-item PRINT witness is wrong")
            if mir.count("(instruction-count 19)") != 1 or \
                    mir.count("(opcode const)") != 2 or \
                    mir.count("(opcode store)") != 2 or \
                    mir.count("(opcode load)") != 7 or \
                    mir.count("(opcode pow)") != 1 or \
                    mir.count("(opcode output)") != 6 or \
                    mir.count("(opcode return)") != 1 or \
                    mir.count("(literal 3)") != 1 or mir.count("(literal 2)") != 1 or \
                    mir.count("(storage-key x)") != 9 or \
                    mir.count("(source-rule frontend-ast-v2/execution-part)") != 6 or \
                    mir.count("(source-rule frontend-ast-v2/print-stmt)") != 13:
                fail("MIR-v0 stored-variable six-item PRINT shape is wrong")
            print("generated chain oracle: accepted")
            return
        if requested_mode.startswith("print-variable-") and requested_mode.endswith("-item"):
            count_text = requested_mode[len("print-variable-"):-len("-item")]
            try:
                output_count = int(count_text)
            except ValueError:
                output_count = 0
            if output_count in range(7, 41):
                source_hashes = {
                    7: "7c6021632b8035916749178f06ee778506cad38953db2de10fae28a39941f200",
                    8: "25fd7fa4285ba064d93a886d3033b43a09346b9e62cd152308941578f0c1d785",
                    9: "51b4e620e303d2193d59c74bd2d0141c301a29551732fe775c00f458c2cd142d",
                    10: "1e5cf76546bf0261b2eef495b4e541bb43eb58c0f79fc242733b88215cc77a30",
                    11: "8d4c00a6ad5113c26ddf23fe92ff18db7892891eb8d72ce09c4697f7e60f69f2",
                    12: "6d2ca45834a829d237e3912718a96795ab5f5a8e8446109c4bdbaaf41f1b978e",
                    13: "9441258875da643d356cce0232f0c9a41b17c78202e0b9d3e2191595c99eac8a",
                    14: "020c4ca14a470855c17d87849ac2f1f3f7e4c10e9170ec64d0f3c49781daff81",
                    15: "1a615bd7777569abbae4fbdc7b4371013d64f09aa4c20478e83061f2fc392319",
                    16: "c9ccf65bf05f7fd2e5c57d53baf0e561e8633e07ff8f39cd1ea582507b44d38f",
                    17: "a4873beedd239d0ea8b6a5ada5fe1d3bf2b7cdb7616c2fcfc71b236c09b899f5",
                    18: "414e2c1093683ff71e85da4d66389c5de2ffe1739574b25711e1314759060467",
                    19: "5f30ac6c38f6f71045c7ef16debcd79ff21f56bebae4d8937c4a3d273fca3f1a",
                    20: "8707e62d4aa8d8b33da80c3be980b7f49e8bb71aaba50dbb14890f67642b7b55",
                    21: "6e23c0dba4b3450593e4081e3b15ff862aae33159947c79c2dd9d0444372645a",
                    22: "a6c50be040d956e55e54d13b1eb881020fea0353b961152f1b6508cf191a6719",
                    23: "03eb79624fb79cc47e6940176c564595f99cd31cc9b9dc4fb68172707c64ce7d",
                    24: "b6e459671f3c5eb02bd4043140435034f05eadc3cf93783fd0f4378068ffae6d",
                    25: "d49b229ec2d9ab74e38159511850bc741ca0e1feadd6089b017b2a77b281ce22",
                    26: "34597de3c8559eda7e9c4e88ff9d58e8c8a6116056377b50dd161a663ee6f135",
                    27: "f6c267e651b72c756acafdd444f8ec7f0a893ae31ceea1bfd55b56c938c50c93",
                    28: "9f6a87983cf6972f9bef8f3d5167624dae28c24e4e1b63ac150de9a3f30e9c72",
                    29: "0fb0911b1e0d3710bdfff0b3a630fe509c49e456010e3e72f84c85c37b04df6d",
                    30: "7686a8b398ace2fb6d8b5a46087d6ed924fd2bc892aa890fad0491e88e806147",
                    31: "9f63fef9ba57fab7172e0d8c91aeed865fc5b280237e51b2ad9d3ef2b7ac0f47",
                    32: "1a9ab93152a3ef13932463905d05f4538c321cd55faae1c1dcb3072e776fb819",
                    33: "df999ae27acc4d35593f88ba0bc063d3a3cdab9cb20de83eb393fa277a9dd7b6",
                    34: "653f323d30b0aa8f3cfa39dfe7c57a6b392de2770032b943e04907ba0757b086",
                    35: "e22d34a72297048c5bb69f13ebba237d9459de2c5795feb6e184a9023f79cf5c",
                    36: "a9d4d6ac3eb062a8019cc9fa910bc8239741bd184cabec4c7537ee7e81738bb9",
                    37: "e885552fb50061c97bd128a15272d5c35a62316bb1bab07eff1d671269f12a8d",
                    38: "5d2f03c70425d7fc8606ee56b30800a6b66d4f07d61a9479377308a308bb3995",
                    39: "6af0ea569909b7ab15ea944c98795b6edca044abcfa8ce78fc9910b171a6c7c2",
                    40: "8c451a6e4f91648174615867564d58697a19ea3fc011fc5260ed0b2cfb9da8b9",
                }
                elf_hashes = {
                    7: "27a377c55a74589b606f06f89840a58f52987b41ec1df659e93926a9b27ce5ff",
                    8: "1ebc4c8c2ef62db1cc426a536c39f8f84f0b60fbd2f665c1817e9cd96e370f31",
                    9: "9ae93def173c838df96748f87017230fab21201799ac56ad1a59dfe58b6130ef",
                    10: "359cc425701669913094a69461c5f6d2e6da7848ed75061da89d5b6d462dcb5f",
                    11: "2919dfed6a42995cab29ce2a39dc552f3c3c0a2e57e37aae9b5d474c896d19ac",
                    12: "f9fc7b160e62c9461d2f61e3729a61de22f90a8008fb6911e8809886bf2c7290",
                    13: "ec178e0b887a0d851a8566278b643ddb92e439cd9d7fb9a1e33671269d3a60ec",
                    14: "10af19f1674fdf4ec1fb8b679bf272c13872aeb427c8c85f47493ed462b3ec00",
                    15: "fe61fb3d56ca0496db52c7facf9676e77140df600c86877f6183fcf7856aa929",
                    16: "bb1b009b7fd79f91874e21cd11b8ceffdcd68fe6ef7314686ecd6779a4596be9",
                    17: "5c70a243bca9f4ec9bfdb89102d5998a9bfed68fbea1d4677d545c3c66fba59e",
                    18: "83c021a7406bdb7b4e461ea2e5adef915d34e59386dba2a28857cc5f78c3ab28",
                    19: "9e950afe8203dc13ce18682be82d1ce6069eba0ed0e0d1de929eb84c472a9d3c",
                    20: "6a5726d6f493317ddf3b06c317cb75fbee031a5c55c1f9901c87ad802feaef06",
                    21: "", 22: "", 23: "", 24: "", 25: "",
                    26: "", 27: "", 28: "", 29: "", 30: "",
                    31: "", 32: "", 33: "", 34: "", 35: "",
                    36: "", 37: "", 38: "", 39: "", 40: "",
                }
                output_names = ", ".join(["x"] * output_count)
                expected_source = (
                    "program main\n"
                    "  integer :: x\n"
                    "  x = 3\n"
                    "  x = x ** 2\n"
                    f"  print *, {output_names}\n"
                    "end program main\n"
                ).encode()
                if source_path.read_bytes() != expected_source or \
                        hashlib.sha256(expected_source).hexdigest() != source_hashes[output_count]:
                    fail(f"stored-variable {output_count}-item source fixture bytes changed")
                if hashlib.sha256(elf).hexdigest() != elf_hashes[output_count]:
                    fail(f"stored-variable {output_count}-item ELF identity changed")
                expected_file_marker = f"(file {source_path})"
                if ast.count("(file ") != 6 or ast.count(expected_file_marker) != 6 or \
                        ast.count("(source-hash l3-raw-program-two-assignment-v1)") != 6:
                    fail(f"stored-variable {output_count}-item AST source identity is wrong")
                required_items = [
                    "(program-unit-v2 ", "(root (program-root (name main)",
                    "(declaration-count 1)", "(variable-count 1)",
                    "(execution-part (assignment-sequence (assignment-count 2)",
                    "(kind integer-literal)", "(left-operand 3)",
                    "(kind binary-expression)", "(operator **)",
                    "(left-operand x)", "(right-operand 2)",
                    f"(output-count {output_count})", "(output-kind variable)",
                    "(output-name x)", "(statement-rule R1212)",
                    "(format-rule R1215)", "(output-rule R901)",
                    "(source-document J3-24-007)",
                    "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
                ]
                for index in range(2, output_count + 1):
                    required_items.extend([
                        f"(output-kind-{index} variable)",
                        f"(output-name-{index} x)",
                        f"(output-rule-{index} R901)",
                    ])
                if any(item not in ast for item in required_items) or \
                        ast.count("(assignment (assignment-stmt ") != 2 or \
                        ast.count("(print-stmt ") != 1:
                    fail(f"AST-v2 stored-variable {output_count}-item PRINT witness is wrong")
                instruction_count = 2 * output_count + 7
                if mir.count(f"(instruction-count {instruction_count})") != 1 or \
                        mir.count("(opcode const)") != 2 or mir.count("(opcode store)") != 2 or \
                        mir.count("(opcode load)") != output_count + 1 or \
                        mir.count("(opcode pow)") != 1 or \
                        mir.count("(opcode output)") != output_count or \
                        mir.count("(opcode return)") != 1 or \
                        mir.count("(literal 3)") != 1 or mir.count("(literal 2)") != 1 or \
                        mir.count("(storage-key x)") != output_count + 3 or \
                        mir.count("(source-rule frontend-ast-v2/execution-part)") != 6 or \
                        mir.count("(source-rule frontend-ast-v2/print-stmt)") != 2 * output_count + 1:
                    fail(f"MIR-v0 stored-variable {output_count}-item PRINT shape is wrong")
                print("generated chain oracle: accepted")
                return
        if requested_mode == "print-variable-three-item":
            source_bytes = source_path.read_bytes()
            expected_source = (
                b"program main\n"
                b"  integer :: x\n"
                b"  x = 3\n"
                b"  x = x ** 2\n"
                b"  print *, x, x, x\n"
                b"end program main\n"
            )
            if source_bytes != expected_source or \
                    hashlib.sha256(source_bytes).hexdigest() != \
                    "ea779c7f1510243caaf54443e4ed70a61e6e0a404399088454606e02f3dbcf1c":
                fail("stored-variable three-item source fixture bytes changed")
            if hashlib.sha256(elf).hexdigest() != \
                    "a790a4360aa36eb5c39d9e8f1fe119a8da9bb9d9f56dec559f0ff706720004f9":
                fail("stored-variable three-item ELF identity changed")
            expected_file_marker = f"(file {source_path})"
            if ast.count("(file ") != 6 or ast.count(expected_file_marker) != 6 or \
                    ast.count("(source-hash l3-raw-program-two-assignment-v1)") != 6:
                fail("stored-variable three-item AST source identity is wrong")
            required_three_item = [
                "(program-unit-v2 ", "(root (program-root (name main)",
                "(declaration-count 1)", "(variable-count 1)",
                "(execution-part (assignment-sequence (assignment-count 2)",
                "(kind integer-literal)", "(left-operand 3)",
                "(kind binary-expression)", "(operator **)",
                "(left-operand x)", "(right-operand 2)",
                "(output-count 3)", "(output-kind variable)",
                "(output-name x)", "(output-kind-2 variable)",
                "(output-name-2 x)", "(output-kind-3 variable)",
                "(output-name-3 x)", "(statement-rule R1212)",
                "(format-rule R1215)", "(output-rule R901)",
                "(output-rule-2 R901)", "(output-rule-3 R901)",
                "(source-document J3-24-007)",
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
            ]
            if any(item not in ast for item in required_three_item) or \
                    ast.count("(assignment (assignment-stmt ") != 2 or \
                    ast.count("(print-stmt ") != 1:
                fail("AST-v2 stored-variable three-item PRINT witness is wrong")
            if mir.count("(instruction-count 13)") != 1 or \
                    mir.count("(opcode const)") != 2 or \
                    mir.count("(opcode store)") != 2 or \
                    mir.count("(opcode load)") != 4 or \
                    mir.count("(opcode pow)") != 1 or \
                    mir.count("(opcode output)") != 3 or \
                    mir.count("(opcode return)") != 1 or \
                    mir.count("(literal 3)") != 1 or mir.count("(literal 2)") != 1 or \
                    mir.count("(storage-key x)") != 6 or \
                    mir.count("(source-rule frontend-ast-v2/execution-part)") != 6 or \
                    mir.count("(source-rule frontend-ast-v2/print-stmt)") != 7:
                fail("MIR-v0 stored-variable three-item PRINT shape is wrong")
            print("generated chain oracle: accepted")
            return
        if requested_mode == "print-variable-four-item":
            source_bytes = source_path.read_bytes()
            expected_source = (
                b"program main\n"
                b"  integer :: x\n"
                b"  x = 3\n"
                b"  x = x ** 2\n"
                b"  print *, x, x, x, x\n"
                b"end program main\n"
            )
            if source_bytes != expected_source or \
                    hashlib.sha256(source_bytes).hexdigest() != \
                    "a4d37442f36020cede92e34e5b756952cf99f32c90d6f02473d35ef12553cfd7":
                fail("stored-variable four-item source fixture bytes changed")
            if hashlib.sha256(elf).hexdigest() != \
                    "7f771aa82b029d8177ab273eefc7f481f9d15b5b07109be99176461b057a2e30":
                fail("stored-variable four-item ELF identity changed")
            expected_file_marker = f"(file {source_path})"
            if ast.count("(file ") != 6 or ast.count(expected_file_marker) != 6 or \
                    ast.count("(source-hash l3-raw-program-two-assignment-v1)") != 6:
                fail("stored-variable four-item AST source identity is wrong")
            required_four_item = [
                "(program-unit-v2 ", "(root (program-root (name main)",
                "(declaration-count 1)", "(variable-count 1)",
                "(execution-part (assignment-sequence (assignment-count 2)",
                "(kind integer-literal)", "(left-operand 3)",
                "(kind binary-expression)", "(operator **)",
                "(left-operand x)", "(right-operand 2)",
                "(output-count 4)", "(output-kind variable)",
                "(output-name x)", "(output-kind-2 variable)",
                "(output-name-2 x)", "(output-kind-3 variable)",
                "(output-name-3 x)", "(output-kind-4 variable)",
                "(output-name-4 x)", "(statement-rule R1212)",
                "(format-rule R1215)", "(output-rule R901)",
                "(output-rule-2 R901)", "(output-rule-3 R901)",
                "(output-rule-4 R901)", "(source-document J3-24-007)",
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
            ]
            if any(item not in ast for item in required_four_item) or \
                    ast.count("(assignment (assignment-stmt ") != 2 or \
                    ast.count("(print-stmt ") != 1:
                fail("AST-v2 stored-variable four-item PRINT witness is wrong")
            if mir.count("(instruction-count 15)") != 1 or \
                    mir.count("(opcode const)") != 2 or \
                    mir.count("(opcode store)") != 2 or \
                    mir.count("(opcode load)") != 5 or \
                    mir.count("(opcode pow)") != 1 or \
                    mir.count("(opcode output)") != 4 or \
                    mir.count("(opcode return)") != 1 or \
                    mir.count("(literal 3)") != 1 or mir.count("(literal 2)") != 1 or \
                    mir.count("(storage-key x)") != 7 or \
                    mir.count("(source-rule frontend-ast-v2/execution-part)") != 6 or \
                    mir.count("(source-rule frontend-ast-v2/print-stmt)") != 9:
                fail("MIR-v0 stored-variable four-item PRINT shape is wrong")
            print("generated chain oracle: accepted")
            return
        source_bytes = source_path.read_bytes()
        expected_source_17 = (
            b"program main\n"
            b"  integer :: x\n"
            b"  x = 17\n"
            b"  print *, x\n"
            b"end program main\n"
        )
        expected_source_23 = expected_source_17.replace(b"x = 17", b"x = 23")
        expected_source_expression = (
            b"program main\n"
            b"  integer :: x\n"
            b"  x = 23\n"
            b"  x = x + 1\n"
            b"  print *, x\n"
            b"end program main\n"
        )
        expected_source_multiply = expected_source_expression.replace(b"x + 1", b"x * 2")
        expected_source_subtract = expected_source_expression.replace(b"x + 1", "x – 2".encode())
        expected_source_divide = (
            b"program main\n"
            b"  integer :: x\n"
            b"  x = 24\n"
            b"  x = x / 2\n"
            b"  print *, x\n"
            b"end program main\n"
        )
        expected_source_power = (
            b"program main\n"
            b"  integer :: x\n"
            b"  x = 2\n"
            b"  x = x ** 3\n"
            b"  print *, x\n"
            b"end program main\n"
        )
        expected_source_power_value = (
            b"program main\n"
            b"  integer :: x\n"
            b"  x = 3\n"
            b"  x = x ** 2\n"
            b"  print *, x\n"
            b"end program main\n"
        )
        is_multiply = source_bytes == expected_source_multiply
        is_subtract = source_bytes == expected_source_subtract
        is_divide = source_bytes == expected_source_divide
        is_power = source_bytes == expected_source_power
        is_power_value = source_bytes == expected_source_power_value
        is_expression = source_bytes == expected_source_expression or is_multiply or \
            is_subtract or is_divide or is_power or is_power_value
        if source_bytes == expected_source_17:
            expected_literal = 17
            expected_source_hash = "e30b7f0f50e828d6dea378ed426ae5117691a6943dbfb63da590b074d33730e1"
        elif source_bytes == expected_source_23:
            expected_literal = 23
            expected_source_hash = "390dbc3f3f29b0bcb1fedcf37aaee26f1e37c6611cdc8d4528a6f81f66c4c24b"
        elif is_expression:
            expected_literal = 24 if is_divide else 3 if is_power_value else 2 if is_power else 23
            if is_multiply:
                expected_source_hash = "5714f3e548f0eafbc1853be1c1ef3bf9a3e685e475ffcc673621ddaf0a2aa53e"
            elif is_subtract:
                expected_source_hash = "dbe6766fcf84970c11a7a2d0c7680b45aea80ee6628df71af72a6e48a469eac7"
            elif is_divide:
                expected_source_hash = "701ce2b90e5b8eec3c6a21ccc11b1054a6fabd64b7947204fd2b04ba96a7e02b"
            elif is_power:
                expected_source_hash = "3546930be8c713977596159a5ddf5a5a9c3c992f5d4fe0fa46429365c7701926"
            elif is_power_value:
                expected_source_hash = "54f5f94956e9f8dd28285ddfb40684eb77ab1022ae58e9e7e5337e0363620621"
            else:
                expected_source_hash = "57598821b9bf538e1f9781c9d9a1a3f18482ec2f1eae95130400bb9848971f15"
        else:
            fail("stored-variable source fixture bytes changed")
        if hashlib.sha256(source_bytes).hexdigest() != expected_source_hash:
            fail("stored-variable source fixture bytes changed")
        expected_elf_hash = {
            17: "7f0355d86cc212318582099617ebea686ff4df43f949b5033ec20859734aa355",
            23: "10fd1f27538000dc6c1544eb12dea40b7e2341851ceb2bd17b9b29c75ed91238",
        }.get(expected_literal, "")
        if is_expression:
            if is_multiply:
                expected_elf_hash = "8e1b8646e3b8ec689596d844578ce4ee8579ced6c9c4ce4af3bfd520fa126474"
            elif is_subtract:
                expected_elf_hash = "cec67a413a9e9774cae8c5a5336ebc4b124239e37c0ab989834075f92ccb8605"
            elif is_divide:
                expected_elf_hash = "bd295eb5eaa9cac3faa6d7312fe2879ef7bf973c2e6970479e2b7177d25edc39"
            elif is_power:
                expected_elf_hash = "9c8a5d5c442541ed33cc9e4a598f98ca8ec4a64a1e6e7f4431ba0f490897c20e"
            elif is_power_value:
                expected_elf_hash = "e7045b194486fa624de68ac286af2651bbae96826df7821688081cd916a85e8e"
            else:
                expected_elf_hash = "d57426ffb421821ae2f450d6694c65523fcb9e10fcf91f45a321e87fe19cb6f4"
        if hashlib.sha256(elf).hexdigest() != expected_elf_hash:
            fail("stored-variable ELF identity changed")
        expected_file_marker = f"(file {source_path})"
        expected_span_count = 6 if is_expression else 5
        if ast.count("(file ") != expected_span_count or ast.count(expected_file_marker) != expected_span_count:
            fail("stored-variable AST source-file identity is wrong")
        expected_source_hash_marker = "l3-raw-program-two-assignment-v1" if is_expression else "l3-raw-program-v2"
        if ast.count(f"(source-hash {expected_source_hash_marker})") != expected_span_count:
            fail("stored-variable AST source-hash identity is wrong")
        if is_expression:
            expression_operator = "*" if is_multiply else \
                "–" if is_subtract else "/" if is_divide else "**" if (is_power or is_power_value) else "+"
            expression_rhs = 3 if is_power else 2 if (is_multiply or is_subtract or is_divide or is_power_value) else 1
            expression_opcode = "mul" if is_multiply else \
                "sub" if is_subtract else "div" if is_divide else "pow" if (is_power or is_power_value) else "add"
            expression_left = expected_literal
            expression_start_byte = 36 if (is_power or is_power_value) else 37
            expression_end_byte = 46 if (is_power or is_power_value) else 47
            print_start_byte = 51 if is_subtract else 49
            print_end_byte = 62 if is_subtract else 60
            required_expression = [
                "(program-unit-v2 ", "(root (program-root (name main)",
                "(declaration-count 1)", "(variable-count 1)",
                "(variable (variable-declaration (type-spec integer) (name x)",
                "(execution-part (assignment-sequence (assignment-count 2)",
                "(kind integer-literal)", f"(left-operand {expression_left})",
                "(kind binary-expression)", f"(operator {expression_operator})",
                "(left-operand x)", "(right-operand 1)",
                "(start-byte 28)", "(end-byte 34)",
                f"(start-byte {expression_start_byte})", f"(end-byte {expression_end_byte})",
                f"(start-byte {print_start_byte})", f"(end-byte {print_end_byte})",
                "(output-kind variable)", "(output-name x)",
                "(statement-rule R1212)", "(format-rule R1215)",
                "(output-rule R901)", "(source-document J3-24-007)",
                "(statement-clause 12.6.1)", "(format-clause 12.6.2.2)",
                "(output-clause 12.6.3)", "(statement-page 242)",
                "(format-page 244)", "(output-page 248)",
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
            ]
            required_expression[required_expression.index("(right-operand 1)")] = \
                f"(right-operand {expression_rhs})"
            if any(item not in ast for item in required_expression) or \
                    ast.count("(assignment (assignment-stmt ") != 2 or \
                    ast.count("(print-stmt ") != 1:
                fail("AST-v2 variable-expression PRINT witness is wrong")
            if mir.count("(instruction-count 9)") != 1 or \
                    mir.count("(opcode const)") != 2 or \
                    mir.count("(opcode store)") != 2 or \
                    mir.count("(opcode load)") != 2 or \
                    mir.count(f"(opcode {expression_opcode})") != 1 or \
                    mir.count("(opcode output)") != 1 or \
                    mir.count("(opcode return)") != 1 or \
                    mir.count(f"(literal {expression_left})") != 1 or \
                    mir.count(f"(literal {expression_rhs})") != 1 or \
                    mir.count("(storage-key x)") != 4 or \
                    mir.count("(source-rule frontend-ast-v2/execution-part)") != 6 or \
                    mir.count("(source-rule frontend-ast-v2/print-stmt)") != 3:
                fail("MIR-v0 variable-expression PRINT shape is wrong")
            print("generated chain oracle: accepted")
            return
        required = [
            "(program-unit-v2 ", "(root (program-root (name main)",
            "(declaration-count 1)", "(variable-count 1)",
            "(variable (variable-declaration (type-spec integer) (name x)",
            "(execution-part (assignment-sequence (assignment-count 1)",
            "(assignment-stmt (variable x)",
            "(start-byte 28)", "(end-byte 31)",
            "(source-hash l3-raw-program-v2)",
            "(kind integer-literal)", f"(left-operand {expected_literal})",
            "(start-byte 34)", "(end-byte 45)",
            "(output-kind variable)", "(output-name x)",
            "(statement-rule R1212)", "(format-rule R1215)",
            "(output-rule R901)", "(source-document J3-24-007)",
            "(statement-clause 12.6.1)", "(format-clause 12.6.2.2)",
            "(output-clause 12.6.3)", "(statement-page 242)",
            "(format-page 244)", "(output-page 248)",
            "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
        ]
        if any(item not in ast for item in required) or \
                ast.count("(assignment (assignment-stmt ") != 1 or \
                ast.count("(print-stmt ") != 1:
            fail("AST-v2 stored-variable PRINT provenance witness is wrong")
        if mir.count("(opcode const)") != 1 or \
                mir.count("(opcode store)") != 1 or \
                mir.count("(opcode load)") != 1 or \
                mir.count("(opcode output)") != 1 or \
                mir.count("(opcode return)") != 1 or \
                mir.count(f"(literal {expected_literal})") != 1 or \
                mir.count("(storage-key x)") != 2 or \
                mir.count("(source-rule frontend-ast-v2/execution-part)") != 2 or \
                mir.count("(source-rule frontend-ast-v2/print-stmt)") != 3:
            fail("MIR-v0 stored-variable PRINT shape is wrong")
    elif mode == "envelope-6":
        if not ast.startswith("(program-unit-v2 ") or \
                "(declaration-count 1)" not in ast or \
                "(variable-count 1)" not in ast or \
                "(variable (variable-declaration (type-spec integer) (name x)" not in ast or \
                "(execution-part (assignment-sequence (assignment-count 6)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 6:
            fail("AST-v2 six-assignment execution envelope witness is wrong")
        if mir.count("(opcode const)") != 6 or \
                mir.count("(opcode store)") != 6 or \
                mir.count("(opcode load)") != 5 or \
                mir.count("(opcode add)") != 5 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 11 or \
                mir.count("(source-rule frontend-ast-v2/execution-part-6)") != 23 or \
                "(literal 7)" not in mir or mir.count("(literal 1)") != 5:
            fail("MIR-v0 six-assignment execution envelope shape is wrong")
    elif mode == "envelope-5":
        if not ast.startswith("(program-unit-v2 ") or \
                "(declaration-count 1)" not in ast or \
                "(variable-count 1)" not in ast or \
                "(variable (variable-declaration (type-spec integer) (name x)" not in ast or \
                "(execution-part (assignment-sequence (assignment-count 5)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 5:
            fail("AST-v2 five-assignment execution envelope witness is wrong")
        if mir.count("(opcode const)") != 5 or \
                mir.count("(opcode store)") != 5 or \
                mir.count("(opcode load)") != 4 or \
                mir.count("(opcode add)") != 4 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 9 or \
                mir.count("(source-rule frontend-ast-v2/execution-part-5)") != 19 or \
                "(literal 7)" not in mir or mir.count("(literal 1)") != 4:
            fail("MIR-v0 five-assignment execution envelope shape is wrong")
    elif mode == "envelope":
        if not ast.startswith("(program-unit-v2 ") or \
                "(declaration-count 1)" not in ast or \
                "(variable-count 1)" not in ast or \
                "(variable (variable-declaration (type-spec integer) (name x)" not in ast or \
                "(execution-part (assignment-sequence (assignment-count 2)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 2:
            fail("AST-v2 program execution envelope witness is wrong")
        if mir.count("(opcode const)") != 2 or \
                mir.count("(opcode store)") != 2 or \
                mir.count("(opcode load)") != 1 or \
                mir.count("(opcode add)") != 1 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 3 or \
                mir.count("(source-rule frontend-ast-v2/execution-part)") != 7 or \
                "(literal 7)" not in mir or "(literal 1)" not in mir:
            fail("MIR-v0 program execution envelope shape is wrong")
    elif mode == "sequence":
        if not ast.startswith("(assignment-sequence ") or \
                "(assignment-count 2)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 2 or \
                "(kind integer-literal)" not in ast or \
                "(left-operand 7)" not in ast or \
                "(operator +) (left-operand x) (right-operand 1)" not in ast:
            fail("AST-v1 two-assignment sequence witness is wrong")
        if mir.count("(opcode const)") != 2 or \
                mir.count("(opcode store)") != 2 or \
                mir.count("(opcode load)") != 1 or \
                mir.count("(opcode add)") != 1 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 3 or \
                mir.count("(source-rule frontend-ast-v1/storage-sequence)") != 7 or \
                "(literal 7)" not in mir or "(literal 1)" not in mir:
            fail("MIR-v0 two-assignment sequence shape is wrong")
    elif mode == "sequence-3":
        if not ast.startswith("(assignment-sequence ") or \
                "(assignment-count 3)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 3 or \
                ast.count("(kind binary-expression)") != 2 or \
                "(kind integer-literal)" not in ast or \
                ast.count("(operator +) (left-operand x) (right-operand 1)") != 2:
            fail("AST-v1 three-assignment sequence witness is wrong")
        if mir.count("(opcode const)") != 3 or \
                mir.count("(opcode store)") != 3 or \
                mir.count("(opcode load)") != 2 or \
                mir.count("(opcode add)") != 2 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 5 or \
                mir.count("(source-rule frontend-ast-v1/storage-sequence-3)") != 11 or \
                "(literal 7)" not in mir or "(literal 1)" not in mir:
            fail("MIR-v0 three-assignment sequence shape is wrong")
    elif mode == "sequence-4":
        if not ast.startswith("(assignment-sequence ") or \
                "(assignment-count 4)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 4 or \
                ast.count("(kind binary-expression)") != 3 or \
                "(kind integer-literal)" not in ast or \
                ast.count("(operator +) (left-operand x) (right-operand 1)") != 3:
            fail("AST-v1 four-assignment sequence witness is wrong")
        if mir.count("(opcode const)") != 4 or \
                mir.count("(opcode store)") != 4 or \
                mir.count("(opcode load)") != 3 or \
                mir.count("(opcode add)") != 3 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 7 or \
                mir.count("(source-rule frontend-ast-v1/storage-sequence-4)") != 15 or \
                "(literal 7)" not in mir or mir.count("(literal 1)") != 3:
            fail("MIR-v0 four-assignment sequence shape is wrong")
    elif mode == "sequence-5":
        if not ast.startswith("(assignment-sequence ") or \
                "(assignment-count 5)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 5 or \
                ast.count("(kind binary-expression)") != 4 or \
                "(kind integer-literal)" not in ast or \
                ast.count("(operator +) (left-operand x) (right-operand 1)") != 4:
            fail("AST-v1 five-assignment sequence witness is wrong")
        if mir.count("(opcode const)") != 5 or \
                mir.count("(opcode store)") != 5 or \
                mir.count("(opcode load)") != 4 or \
                mir.count("(opcode add)") != 4 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 9 or \
                mir.count("(source-rule frontend-ast-v1/storage-sequence-5)") != 19 or \
                "(literal 7)" not in mir or mir.count("(literal 1)") != 4:
            fail("MIR-v0 five-assignment sequence shape is wrong")
    elif mode == "sequence-6":
        if not ast.startswith("(assignment-sequence ") or \
                "(assignment-count 6)" not in ast or \
                ast.count("(assignment (assignment-stmt ") != 6 or \
                ast.count("(kind binary-expression)") != 5 or \
                "(kind integer-literal)" not in ast or \
                ast.count("(operator +) (left-operand x) (right-operand 1)") != 5:
            fail("AST-v1 six-assignment sequence witness is wrong")
        if mir.count("(opcode const)") != 6 or \
                mir.count("(opcode store)") != 6 or \
                mir.count("(opcode load)") != 5 or \
                mir.count("(opcode add)") != 5 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 11 or \
                mir.count("(source-rule frontend-ast-v1/storage-sequence-6)") != 23 or \
                "(literal 7)" not in mir or mir.count("(literal 1)") != 5:
            fail("MIR-v0 six-assignment sequence shape is wrong")
    elif mode in ("sequence-7", "sequence-8", "sequence-9", "sequence-10"):
        assignment_count = int(mode.split("-")[1])
        instruction_count = 4 * assignment_count - 1
        first_literal = "(assignment (assignment-stmt (variable x) (expression (assignment-expression (kind integer-literal) (operator ) (left-operand 7) (right-operand )))"
        repeated_assignment = "(assignment (assignment-stmt (variable x) (expression (assignment-expression (kind binary-expression) (operator +) (left-operand x) (right-operand 1)))"
        if not ast.startswith("(assignment-sequence ") or \
                f"(assignment-count {assignment_count})" not in ast or \
                ast.count("(assignment (assignment-stmt (variable x)") != assignment_count or \
                ast.count(first_literal) != 1 or \
                ast.count("(kind integer-literal)") != 1 or \
                ast.count("(kind binary-expression)") != assignment_count - 1 or \
                ast.count(repeated_assignment) != assignment_count - 1 or \
                ast.find(first_literal) > ast.find(repeated_assignment):
            fail(f"AST-v1 {assignment_count}-assignment sequence witness is wrong")
        if mir.count("(opcode const)") != assignment_count or \
                mir.count("(opcode store)") != assignment_count or \
                mir.count("(opcode load)") != assignment_count - 1 or \
                mir.count("(opcode add)") != assignment_count - 1 or \
                mir.count("(opcode return)") != 1 or \
                mir.count("(storage-key x)") != 2 * assignment_count - 1 or \
                mir.count(f"(source-rule frontend-ast-v1/storage-sequence-{assignment_count})") != instruction_count or \
                "(literal 7)" not in mir or mir.count("(literal 1)") != assignment_count - 1:
            fail(f"MIR-v0 {assignment_count}-assignment sequence shape is wrong")
    elif mode == "declaration":
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
        if mir.count("source-rule frontend-ast-v1/expression") != 5:
            fail("MIR-v0 expression correspondence is wrong")
        if mir.count("(opcode const)") != 2 or "(literal 1)" not in mir or \
                "(literal 2)" not in mir or "(opcode add)" not in mir or \
                "(opcode store)" not in mir or "(opcode return)" not in mir:
            fail("MIR-v0 expression opcode shape is wrong")
    elif mode == "multiplication":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator *) (left-operand 2) (right-operand 3)" not in ast:
            fail("AST-v1 multiplication assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 5:
            fail("MIR-v0 multiplication correspondence is wrong")
        if mir.count("(opcode const)") != 2 or "(literal 2)" not in mir or \
                "(literal 3)" not in mir or "(opcode mul)" not in mir or \
                "(opcode store)" not in mir or "(opcode return)" not in mir:
            fail("MIR-v0 multiplication opcode shape is wrong")
    elif mode == "division":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator /) (left-operand 6) (right-operand 2)" not in ast:
            fail("AST-v1 division assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 5:
            fail("MIR-v0 division correspondence is wrong")
        if mir.count("(opcode const)") != 2 or "(literal 6)" not in mir or \
                "(literal 2)" not in mir or "(opcode div)" not in mir or \
                "(opcode store)" not in mir or "(opcode return)" not in mir:
            fail("MIR-v0 division opcode shape is wrong")
    elif mode == "subtraction":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator –) (left-operand 5) (right-operand 3)" not in ast:
            fail("AST-v1 subtraction assignment witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 5:
            fail("MIR-v0 subtraction correspondence is wrong")
        if mir.count("(opcode const)") != 2 or "(literal 5)" not in mir or \
                "(literal 3)" not in mir or "(opcode sub)" not in mir or \
                "(opcode store)" not in mir or "(opcode return)" not in mir:
            fail("MIR-v0 subtraction opcode shape is wrong")
    elif mode in ("literal", "literal-boundary"):
        expected_literal = "7" if mode == "literal" else "2047"
        if "(assignment-count 1)" not in ast or \
                f"(assignment-expression (kind integer-literal) (operator ) (left-operand {expected_literal}) (right-operand ))" not in ast:
            fail("AST-v1 literal assignment witness is wrong")
        if "(opcode const)" not in mir or f"(literal {expected_literal})" not in mir or \
                "(source-rule frontend-ast-v1/assignment)" not in mir or \
                "(opcode store)" not in mir or "(opcode return)" not in mir:
            fail("MIR-v0 literal value shape is wrong")
    elif mode == "variable-expression":
        if "(assignment-count 1)" not in ast or \
                "(assignment-expression (kind binary-expression) (operator +) (left-operand x) (right-operand 1)" not in ast:
            fail("AST-v1 variable expression witness is wrong")
        if mir.count("source-rule frontend-ast-v1/expression") != 5 or \
                "(opcode load)" not in mir or "(opcode const)" not in mir or \
                "(literal 1)" not in mir or "(opcode add)" not in mir or \
                "(opcode store)" not in mir or "(opcode return)" not in mir:
            fail("MIR-v0 variable expression shape is wrong")
        if mir.count("(storage-key x)") != 2:
            fail("MIR-v0 variable storage identity is wrong")
    else:
        fail("unsupported generated chain mode")
    expected_result_count = 23 if mode in ("sequence-6", "envelope-6") else \
        4 * int(mode.split("-")[1]) - 1 if mode in ("sequence-7", "sequence-8", "sequence-9", "sequence-10") else \
        19 if mode == "envelope-5" else \
        19 if mode == "sequence-5" else \
        15 if mode == "sequence-4" else \
        11 if mode == "sequence-3" else \
        7 if mode == "sequence" else \
        7 if mode == "envelope" else \
        5 if mode in ("expression", "multiplication", "division", "subtraction", "variable-expression", "print-variable") else \
        7 if mode == "print-generic-items" else \
        21 if mode == "print-7-8-9-10-11-12-13-14-15-16" else \
        19 if mode == "print-7-8-9-10-11-12-13-14-15" else \
        17 if mode == "print-7-8-9-10-11-12-13-14" else \
        15 if mode == "print-7-8-9-10-11-12-13" else \
        13 if mode == "print-7-8-9-10-11-12" else \
        11 if mode == "print-7-8-9-10-11" else \
        9 if mode == "print-7-8-9-10" else \
        7 if mode == "print-7-8-9" else \
        5 if mode == "print-7-8" else \
        3 if mode in ("literal", "literal-boundary", "print-7") else 2
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
