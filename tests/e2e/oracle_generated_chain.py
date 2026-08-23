#!/usr/bin/env python3
"""Independent behavioral oracle for the bounded generated compiler chain."""

from __future__ import annotations

import pathlib
import sys
import hashlib
import re


def fail(message: str) -> None:
    raise SystemExit(message)


def add_legacy_print_fields(ast: str) -> str:
    """Expose old item fields to the unchanged cardinality checks.

    The frontend now stores literal PRINT items in one allocated list. The
    older chain modes still name their expected items individually, so derive
    those check tokens from the canonical list in the oracle only.
    """
    if "(output-items " not in ast:
        return ast
    items = re.findall(
        r"\(output-item \(kind ([^)]+)\) \(value ([^)]+)\).*?\(rule ([^)]+)\)",
        ast,
    )
    if not items:
        fail("generic PRINT item list is malformed")
    fields = []
    for index, (kind, value, rule) in enumerate(items, start=1):
        suffix = "" if index == 1 else f"-{index}"
        fields.extend((
            f"(output-kind{suffix} {kind})",
            f"(output-value{suffix} {value})",
            f"(output-rule{suffix} {rule})",
        ))
    return ast + " " + " ".join(fields)


def main() -> None:
    if len(sys.argv) not in (4, 5, 6, 7, 8):
        fail("usage: oracle_generated_chain.py AST MIR ELF [PROGRAM_NAME] [TYPE_SPEC] [MODE] [SOURCE]")

    ast = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    ast = add_legacy_print_fields(ast)
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
            if output_count in range(7, 101):
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
                    21: "a4e4bf62ec07a6b2df2e0667afe7d4d0d518730228f3cd0ace81bb5dc90fe157",
                    22: "02b41045a0cd223ad9239c85ea3b5d07420f46c89fd811d710ad36d86ccbb967",
                    23: "b978de839f90533d7bc95b90e03488408205e7b84f145fac8edb13635643349a",
                    24: "855ffaa4b0ac642edbeb6d7028879b4c12e434c1fd4453bd4c8d4cec821a2674",
                    25: "7c2be3ca12b0199d510a4e0bacac859c0582f0fcc738eaa472f21f8517ea7fe9",
                    26: "0988a5c9478ed6081b589e44e9a4770234fca49c451cf2b752fd6fb7640fd43d",
                    27: "3ca998629b9a4b77bfbff09f642d083fd0f28c2a2788fd4cedb754a7608f9136",
                    28: "3c6c1f652b32d53521979dbd668648c70f9c44cfd5c797ca25a9a733c0e16149",
                    29: "001b97b339723aaf78aaad504f5399a4869893f97c3eec2bb9e60ac3c1842776",
                    30: "78285e930ce46844684904e00155af25e816b19b1b6b127e0582e8b55fafbc7e",
                    31: "8a13a8fc1190cf36c7bce4a5feafe301a9ef54405b3ba8090308dab7025dc4b3",
                    32: "609af2166bbc33477d487680a07f086ed5d6c7ec50acb603a1cc9834cf09a6f2",
                    33: "c8b0e0394871ef18ec24a58d0b5888a0dd4492d0de6f18ebd53f4c862622f68e",
                    34: "40ee5ad55f783c0d9fee0aa8f2e1ff1877a9412bbb993769b87a86fb38b3403c",
                    35: "a14f1e31a945178bc6115b716bc446647454d1be1077d3bebc220e13a697e90d",
                    36: "1d868d1dc9b2697a035ab245f876b41c70af61b658531d17288d8990769999ba",
                    37: "1edd4f3d32348789e070c060ca4e2377e7da9dc1c6ab6498627aed7c393b48b0",
                    38: "263697ac307b0faacb2d37ae37da325ad73332cb10f4735b7b30cedd2bc843ac",
                    39: "e0ca74b126cfa6ab201080b2256a8fb78f5bd8ffef83ea789bfab2cb9e83931c",
                    40: "3ef8b475c004c56ee832bc7ca89185f25243911c6c37ab814257dede982e6587",
                    41: "b5e9ac8460e8897f5b40b06869e7b577910ca7c40c58f4e1157d1caf3bdc76fb",
                    42: "8c24c89d0bc0eb2b808b60f03a1513b1156089faaa4cf4b1a81ac7dd0e67921f",
                    43: "997221db4ce45c8f38c5d2b30dedae753f3f85538db36cede036e4aee0395123",
                    44: "11ec15b40be525e1685bd8f81fefd2d2afbbe0aa18271465c47f78c2b3487cc9",
                    45: "3dedc7c2afa4650750180ab2fa17277f916991a23503dff106a21ea39d2c5124",
                    46: "2cf40ea450eae471667d07d8ebc0be5a1d71cf99433ec5521920a48843ebbf79",
                    47: "8c7728e929dc612ef103b23775a88e58f3abd5ed890743671fa274dc3576af0e",
                    48: "0e92c7ea95ff8bf82ebe073f91a9c56ef5622e13ef512cf3d8718445870b57ef",
                    49: "744a95f83623d262be1c7720049cd04bdd134ec46844dfb8e07281ec3bbc7c6f",
                    50: "9f2505c47f906bbf53e8166f2b741b5c1e66fb4c26097123b6c21bed13155611",
                    51: "5ad92076380816647dbb6a021b5fe1722f2579cf031bf05593e7f253d6e20673",
                    52: "8af982c45b5ff54236de6020e55c4e6eb1e8a265d240845bfd69f0824bdbf859",
                    53: "207c17e15ce148fbdf8a0f18a6f5f24c128de0dcda179942a8af3bbe66f56329",
                    54: "528dc50b4c2f8b23c6ab1221065e02d8a70df9b5ff8d1dad214d29d811624696",
                    55: "f259586b12f0a87893951f09435397670ee94ceef3c8bdca49d2ec46dd72d3a2",
                    56: "1e96bba70c377793ff73d819a63c38a54a16bb17a046877dd11de4909b819080",
                    57: "24f5fc437b10bde017ea3dd160be5b9af36d54f51dd65ec16897ad29fb94e89e",
                    58: "1dc07dba5e2f9f9430ae81569c5860c992949a8f90a597541306aa596c1243e6",
                    59: "f530efd0dcd7eb10e73c937f88ae4ee48bc7deb9c4e5553d9d9452e39c721f42",
                    60: "f4307e2e4d6f68afd68f16cd5673364e67ca3b5a8e2ebb96d5a36194078f3ac4",
                    61: "c73ecd5a558c86d7a7aa547ce748233b37884a4543328e9d759df2fc6d7df01a",
                    62: "02da82b3f89aec817d950ba3abdf4043d8e2af3176becf2286fc162c57f9734b",
                    63: "75c204aaedba13a217a2fed60b8b51c7303d221c9897d410b9aafac6e5975df1",
                    64: "cb2af23f1bf48faf0b2e64fe1c3814c896707ec30518e8452aa99ba235e565b6",
                    65: "f10ed45874acfb3d3c1e06a2d417abfea104d315f191c3525814ae0efe257920",
                    66: "4949d6c3bbc9656f375d00b25055146d68adf1cb0a2a5d7c51fc5a0d02dddb6f",
                    67: "6b9f30b025b6d8bf7bc3fc69ebfbd24255573a31499065d1c2130ceaf6223817",
                    68: "c4e90aa1d76d8a588241f50da7127b3cc856c29dfb3a989ff3cd1566fbfc9e86",
                    69: "47b18fe21a1b6fee875e41894218e7059526b9c49033fb5d6972814e2add2ae9",
                    70: "368dfd789e7575ec9dca23f0db88a1ddc3f21ee6c56fcd557948e9ce5043ff38",
                    71: "bddb2b026f395ee20dd04a6affb1d193e262e754eb6039917e7e1eb36ce107ee",
                    72: "c6168f3f0f498ab1345af45175fc71ffc2b40971aa16e467906e71d58d7f52b7",
                    73: "99dc15f57af119e6765f952d611cf959d9012c450fdee0e60161c55941816bad",
                    74: "938ecaf854a0f29b196ddb0398eafdd9191fdfa0415d4392f3c3586e54eab477",
                    75: "5d87744ccaf1a2c1e608d0463888e6715b94d73ee048a3d9ffa647fc5ffb29e6",
                    76: "24272a6075ff1bec89fda5ee37a491ebe9014fe9263b24d776c17bf4122afdcc",
                    77: "c0a0779998aadfc56c74e61483aef9c39e03e486738a70517a600e9cdcba02b0",
                    78: "a3008263a0f6fc0cbbe70553865d35502474de2efdace7e5c6197cb3438e59fe",
                    79: "53fd0b2d1698b095d084d8456e1196a598533b6c7de3e67f234cdd1d453c49f1",
                    80: "433f6910bc3c26755ed16c8a0d27a2667061e2aa8fd590bcb2c24bcf5366e05d",
                    81: "bee0efc1794453bf0e5814a8254f60192d3c9633d0da19efc7148f822e5559d0",
                    82: "fbac03f2f791f53428ab299d27acc54786a9150565300ccf94d4448fef619587",
                    83: "23adbdccfa070367b4405817deef0ffe2b939ee10a40f6940a6032762bcb7353",
                    84: "98554c6fcd6824f317a6886bc0f81c88d93bd1d6c963f4ef71594fa9cc79333d",
                    85: "ec60fbb8b905c2139229bcee6fd68931cdb1b4af4b8f32e403c20b87ec077666",
                    86: "5aef2f74704f608f6ac2aa8e3199b983cf8a230930d66d40494aac170670f206",
                    87: "f09bf24c7dbab17dced031cd54c553345df3c76d8875cfa741724c53d4229ddb",
                    88: "3ad817463ba30fcf1d84e84f2c19daa1fe7c232a985d6c0321a0a81e5c744996",
                    89: "4844dc91adcbb46bc010d20aebd43a6d214c1b6eeed8ecb69e3c3fe98d10a0e7",
                    90: "2721b1c8e0c12fbcc0716f0dce473aa8ee82a4fe1b59a753cb4c032e2b7fb9db",
                    91: "7327133ef5d590ba5a206f88f85c75d1d3510989ff84165196147f795c0cf7e9",
                    92: "c1ef4647aaa50fafae5a96ce352ad22ff1a4f0695ac9a6dfa2291254980b3a93",
                    93: "156892ec279f4c384b274c348076626c175569d444c6430badd4b979bb06f789",
                    94: "013100496daf8defd2d0abb35aed9fb86958ea66d3b8127a101777d3c0159a9e",
                    95: "aa77d258871a0037c5db4e5624b2a50ee162def5b0e432e468ecd4984d2ed67f",
                    96: "ea03abdfa38a1eb451a1fe7bbb73bbacf012d84d35b7b80a583074a70e23755e",
                    97: "04754ad68dfdd11bce29332bc1680395db553e43974651891132045b7bb04e7c",
                    98: "5d50885c4aa68593777dfe864c7d1cfee055cd1a818f63989498f0784b678847",
                    99: "d1682d12842aa6a8f074694b69afc5b820ad965dbc6a7e0f62adc42fbe8ba715",
                    100: "8ecadebd098e26e8f3e1603cf24daed5172463fc754440e82f9cd5d40a80b11d",
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
                    21: "8e9967d1340bd9760e091bd02f949aa0ba5d139e9135b2bd31e9337638f90dcf",
                    22: "1b56f87d905b5668c753458594b401f1cfc0b9f38c658038ac7ccb5b4f55d972",
                    23: "ada11ee537e77a6f8cfc226db8e08a3f8f5f07a5413cc7b511d75662660d75b2",
                    24: "9b14039d9f14a8e855fec5c2dd9bbb38891800d17a0f74e2be74f80f29f9dc00",
                    25: "ff654a3562ad2398f05309e399c11b134907a4e6af9cd173585359612e78074b",
                    26: "6a72ea21e4dbc7336a20abc8c761d68b145de5081fae75dc862d2dc39f7bd68e",
                    27: "d0f0ff68d763e1b4a898f85ab8f39c15a432d2c272132fc4ec35ae75db3b0146",
                    28: "6d19a82e9e909eccadfdd8e9c602c487d25240ec070cd3e1f083d2fd60477662",
                    29: "d8b3874767d774e278095820611105c6eb34424fc56a50298104cf9f46085fb4",
                    30: "9e52d0e3718fad4aaa187c3533100317330066d28afee6b7c091dcbf457d3e62",
                    31: "8310e3049a01907e850b036b9b505959ddf1ef54d3d7826641a840f1221a0498",
                    32: "26f25625e1d0bce6dc2343f8e9d7eefe4806e4bffa80e310a67e179c736d6ff5",
                    33: "a048b840b559d52aabd28dabbbd4ab29c4f6de6032ca7194d08ce9caeb809e1b",
                    34: "f4582b578b6ceab313d63c59eee1258905d6baed9d28e8173aee18a2f335faad",
                    35: "21c78a78e98b4a12597d8d6a8edf361f702f8a34fe51764e1e45b57c7f6e9bb8",
                    36: "c6390150631f58641fe8f7fb4622ff5e1e64b153bda96d146dcbe078a2e0489a",
                    37: "d5e2f71ec419589599089b9e9dfb830191241ae0680036e68982adcf5f334e2d",
                    38: "81cd5beb160ad229073405515775a16a9112deebc187e8e8b2d31621d20e0f39",
                    39: "73c85aec0ee6cc2674d909f05d6fd7c0a7504a2ed62c8183f3a1801030259558",
                    40: "713b20a36000fe4e20051c8172c2c1a8288320fad16296b5d45f58f696b0db83",
                    41: "dd5b5ce34601652df03694e94ef22ce48960de33f3f7a8e570ac7e89a77294da",
                    42: "32b8d08952c02054722b6f61b85fe0ee6db4b5bfbc439b296512e6b045525c6d",
                    43: "e18f696f0ea34db95f5442e35c9a6ac356dd4f4fb7baf928b252613606f627c3",
                    44: "077e138d99f09f19649040d914a6e9828a67f97809270efc5305611426012d3b",
                    45: "57f6646b332941b97a586b2895c8dc82fd9460f919aa3708f882ac76d3aa9c7a",
                    46: "ceb7df1a21c448561e03f843799e0aa4581c9b9dd24950776c4c03e2fd9f5e24",
                    47: "3cb1e123252443363cfe8a5bd4d501939d99d36774ea9c42d85bc3252c6de397",
                    48: "c81ad806cd3262d8bccf196766148264ec73e0d6328871449e233222effeace5",
                    49: "d1ac1d6cde40e4023f89a9e6e70ded9882e8f6b6bca87fa2549634e421d481b5",
                    50: "5113edd58d773e106a861f05b6b3950ff77ec8bb94f631d3568e0403685d189d",
                    51: "9590403780e3a19afdaa16b0393f931d80c095b525e13067ff4187143b413e44",
                    52: "b2a9b520b1bd2b99ef170ada3228721e856bede222d21d263dfe91e059e98d95",
                    53: "05a814a65b4e47cc8e5c078eef69aa5c4b24fec46d6329d144ac75e63c822b17",
                    54: "95fff9278ab7d63b0f9020c311cf1892e27dd823be94f7bf232cd1dd8cff0206",
                    55: "10be0254f8467b2796ba1270cc3b65a5cca8d0a67ae3ff5f8eb5109fbe73113c",
                    56: "80215830342b8c8d506047a271e772e8aaae0bf878557a92afe8805878c0db89",
                    57: "225d461b024ad99a75d0fd6687886348d6440bb6ed0b3c90ec6352cb4e271262",
                    58: "18e5bc35a50ac3df582b7e7916749e6ddb6f7db6f76d8cacc6f05215bb69685d",
                    59: "9b47001226b4c389a605c02a74b49dd47eb9e4e9d6ab27e7af3576f4147447a6",
                    60: "fc70f3d265abdd213ffd55a9f74e2b455e7e0c01684ce56f5a129c425016c7d8",
                    61: "bc07d33789fdd73f0470d90459669c5d40e2ca4df29419bd51cbd5eb168ac7a5",
                    62: "6fa45b70641581131b0b39f8e5fc725d3e8106e86b65d15d45e18a074a792678",
                    63: "a73b21c96350ddf2c6f2f13d33582bbd38b25bce90de8db8727f2cce62a9e4e2",
                    64: "b872c7acfea538c33f1cedb0f66557cfe7c3199c1b5f2bce12ec4579c5dc4062",
                    65: "539794c1ed8266ab87e8d4b3eaa67c99595c56d2366a796711f5e1c77a3aa824",
                    66: "91b9f93e4fa93c0e5e1dfbac607998fe6fb56d9c38a53c8922c93760e0f9724f",
                    67: "d641e76ba35f497fdb3774e51fea0074cdf8bce563bdd5138220ad29395dfb0f",
                    68: "0efa39c40b8b50272cb00a9a4c65b001a7481a7560d57cd8ef7ca8772e744f43",
                    69: "b03d68b0fac7d88ad487bb89c2b86361aadc64cb59929539fa69ce8f0260436a",
                    70: "aba737fbc3690722bdf60f1b0511fe8a8313656bf2980a08ec861c9df62f414f",
                    71: "598a6b1cf367870e82598c66963feb71db8df25fe087dc92a56a1c725a36f04c",
                    72: "4c49ad7cbddba226274de0c1fe446a300ed59b8d78ccb249cd1816a261a1544c",
                    73: "a42b424bb9a8a549e9641b60072ff7a5af3b627da4e33c82527ef0c1c110eaa6",
                    74: "3008600b4eb9de90415c2347f3652c3a3bde77cb1fb88672f393aa4eacaf262e",
                    75: "e7c18fcd4754b50f4ce9c745110f9f6f58d7029e336f12d08bfab24154af5ea0",
                    76: "fbb0dbbe0bad7b6675d5e35f5f692d7336fd8df81421352f9b9ee231c3e0bb3c",
                    77: "351424d975a5e62f507958241d74ee181690471cf3738f77fddc2009e3fa93c3",
                    78: "2c041ce7cde2992331b66456eb6ae5c4ab16a9c4e4d62652b9b6640203d1eb24",
                    79: "b15afd4cad4aab4180a925aec2290de8741d452022d8b7eba86a2feafc1730f5",
                    80: "1aa45e4bf83be40fd23488602581f1ee9843fcc7f581dd00e760d5a9d547ade5",
                    81: "bea374ebfbd476726b49ed7f2073669838329a4f5e3540741d2177d6f5a95e71",
                    82: "0f56358b6079ca34cd90c4904e6c5bd02cf9f6b851918a7511fb757d699ff574",
                    83: "aea102dcc58f64c0a3058a89449d8b831dad19e36a121b3f8eb8701c9e711d69",
                    84: "04e8a2fbfdcd2ff3058db8d0296bc94ee27359154f51be340df4e61fdf43cf95",
                    85: "61b2104a74ce4e62297b1bc1ac2c1480efcb3627ebefd226fe73206511959056",
                    86: "e8d83348d3648ead367550f562057fb7671c792ab79f0c1172a488d02e54059d",
                    87: "e3e047afdba8ed9ccae027cfd053e75aee5e171d63c4695a6af18f610fd443c2",
                    88: "a9641dae80ee46b4af5c8a99855237c2dbc846202b26486f76461f502a680dfd",
                    89: "cf27ac4c56f1f7046a9e13445c597ba34d53fc8178d26cf5cb61cb0597ef60c6",
                    90: "746297303bd9eccabdf602c3aca50be1589242d60fd55e044767c0b86eb5b918",
                    91: "a3d5879f88c004c9f4f90585e40dbfa0606d58ee79fe1ade2140a39ee8072bd7",
                    92: "183f62a50935391cd25b0c9108d7595a74b3f5605e5f854ef9c172ceefb9a738",
                    93: "9675f09524a4e956e998132a3140d2ad55bd27ea0af8cf53fecc0d4a5ee6f271",
                    94: "b91cdc2ba8a7308624f92a69f6d8bf588884cea2ed93a2154e739e5f7017d90e",
                    95: "1845d05dbc36d650b16f8095320038fd5c42671748d48dc1ab4111cf8c1da493",
                    96: "fc07f1e891f693e3859486a5a219e595830d0ba6e6504d1482ea9a28552e173c",
                    97: "4719f1bbffdb378a13a5333580630b87b0608e09362b59068ce1aee5d4088778",
                    98: "8623b8fbf0c17145744d276e73179b1743f1b5643ecc7f357854c179821c521d",
                    99: "6073a86ff10f6449f45832ce25b9446bff9f1ea27355b0683995f160c7c4a6ec",
                    100: "c1d224288dee97a5fffe55c59ea12ca1e1265cc0d8d63ba02a6c460e814bf37a",
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
                expected_elf_hash = "3de4d363641cca980a085a8c83d9b0402eead71e314f3a884c79a1587a97c3fc"
            else:
                expected_elf_hash = "d57426ffb421821ae2f450d6694c65523fcb9e10fcf91f45a321e87fe19cb6f4"
        if hashlib.sha256(elf).hexdigest() != expected_elf_hash:
            fail("stored-variable ELF identity changed")
        expected_file_marker = f"(file {source_path})"
        expected_span_count = 6 if is_expression else 5
        if ast.count("(file ") != expected_span_count or ast.count(expected_file_marker) != expected_span_count:
            fail("stored-variable AST source-file identity is wrong")
        expected_source_hash_marker = "l3-raw-program-v2"
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
            initializer_end_byte = 33 + len(str(expected_literal))
            expression_end_byte = expression_start_byte + \
                len(f"  x = x {expression_operator} {expression_rhs}") - 1
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
                "(start-byte 28)", f"(end-byte {initializer_end_byte})",
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
