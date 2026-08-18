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

    if mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9") and (not ast.startswith("(program-unit ") or f"(name {program_name})" not in ast):
        fail("AST-v1 root witness is wrong")
    if mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9") and ("(declaration-count 1)" not in ast or "(variable-count 1)" not in ast):
        fail("AST-v1 declaration cardinality is wrong")
    if mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9") and ast.count("(variable (variable-declaration ") != 1:
        fail("AST-v1 variable declaration cardinality is wrong")
    if mode not in ("sequence", "sequence-3", "sequence-4", "sequence-5", "sequence-6", "sequence-7", "sequence-8", "sequence-9", "sequence-10", "envelope", "envelope-5", "envelope-6", "stop-7", "print-7", "print-7-8", "print-7-8-9") and f"(variable (variable-declaration (type-spec {type_spec}) (name x)" not in ast:
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
        5 if mode in ("expression", "multiplication", "division", "subtraction", "variable-expression") else \
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
