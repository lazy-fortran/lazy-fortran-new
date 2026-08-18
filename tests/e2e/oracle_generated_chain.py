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
    if mode == "print-variable-expression":
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
        is_expression = source_bytes == expected_source_expression
        if source_bytes == expected_source_17:
            expected_literal = 17
            expected_source_hash = "e30b7f0f50e828d6dea378ed426ae5117691a6943dbfb63da590b074d33730e1"
        elif source_bytes == expected_source_23:
            expected_literal = 23
            expected_source_hash = "390dbc3f3f29b0bcb1fedcf37aaee26f1e37c6611cdc8d4528a6f81f66c4c24b"
        elif is_expression:
            expected_literal = 23
            expected_source_hash = "57598821b9bf538e1f9781c9d9a1a3f18482ec2f1eae95130400bb9848971f15"
        else:
            fail("stored-variable source fixture bytes changed")
        if hashlib.sha256(source_bytes).hexdigest() != expected_source_hash:
            fail("stored-variable source fixture bytes changed")
        expected_elf_hash = {
            17: "7f0355d86cc212318582099617ebea686ff4df43f949b5033ec20859734aa355",
            23: "10fd1f27538000dc6c1544eb12dea40b7e2341851ceb2bd17b9b29c75ed91238",
        }[expected_literal]
        if is_expression:
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
            required_expression = [
                "(program-unit-v2 ", "(root (program-root (name main)",
                "(declaration-count 1)", "(variable-count 1)",
                "(variable (variable-declaration (type-spec integer) (name x)",
                "(execution-part (assignment-sequence (assignment-count 2)",
                "(kind integer-literal)", "(left-operand 23)",
                "(kind binary-expression)", "(operator +)",
                "(left-operand x)", "(right-operand 1)",
                "(start-byte 28)", "(end-byte 34)",
                "(start-byte 37)", "(end-byte 47)",
                "(start-byte 49)", "(end-byte 60)",
                "(output-kind variable)", "(output-name x)",
                "(statement-rule R1212)", "(format-rule R1215)",
                "(output-rule R901)", "(source-document J3-24-007)",
                "(statement-clause 12.6.1)", "(format-clause 12.6.2.2)",
                "(output-clause 12.6.3)", "(statement-page 242)",
                "(format-page 244)", "(output-page 248)",
                "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
            ]
            if any(item not in ast for item in required_expression) or \
                    ast.count("(assignment (assignment-stmt ") != 2 or \
                    ast.count("(print-stmt ") != 1:
                fail("AST-v2 variable-expression PRINT witness is wrong")
            if mir.count("(instruction-count 9)") != 1 or \
                    mir.count("(opcode const)") != 2 or \
                    mir.count("(opcode store)") != 2 or \
                    mir.count("(opcode load)") != 2 or \
                    mir.count("(opcode add)") != 1 or \
                    mir.count("(opcode output)") != 1 or \
                    mir.count("(opcode return)") != 1 or \
                    mir.count("(literal 23)") != 1 or \
                    mir.count("(literal 1)") != 1 or \
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
