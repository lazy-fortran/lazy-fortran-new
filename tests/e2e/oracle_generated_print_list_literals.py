#!/usr/bin/env python3
"""Independent oracle for novel nonnegative integer PRINT-list literals."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
import hashlib


class OracleFailure(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise OracleFailure(message)


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_contract(root: pathlib.Path) -> None:
    fixture = (root / "contracts/fixtures/l3-print-list-literals-v0.sx").read_text(
        encoding="utf-8"
    )
    require("(contract l3-print-list-literals)" in fixture,
            "literal-list contract differs")
    cases = {
        "tests/fixtures/l3-print-list-literals-v0.f90":
            "b4c1bdfd103aa29f035a91b7a16f8dc941034be38694791df6d05090de8703af",
        "tests/fixtures/l3-print-list-literals-wide-v0.f90":
            "ecff4c7c879a482521adc22bf83234e05849bb6fe320fea9f84dcdb0ee7b5a14",
        "tests/negative/l3-print-list-literals-v0-trailing-comma.f90":
            "e62d6b2c06d7102ce2746da5a6ff0a39e3c1b7a39ce94f2d28f0988784182ddb",
        "tests/negative/l3-print-list-literals-v0-real.f90":
            "11b3b3162652c2bec191ecb621daa4cc237d45523ac524dd65ca4015662925cf",
        "tests/negative/l3-print-list-literals-v0-write.f90":
            "94d3d630b5e4fb8154f49cc4a8ad1fab764da3b55f869b9e41edc1ef8de61e0e",
        "tests/negative/l3-print-list-literals-v0-name.f90":
            "81806387da1821487c775aebf6a521c28526b61829e23f1a36dfe71b1f055acb",
    }
    for relative, expected in cases.items():
        path = root / relative
        require(f"(path {relative})" in fixture and f"(sha256 {expected})" in fixture,
                f"contract case differs: {relative}")
        require(digest(path) == expected, f"source hash differs: {relative}")
    pdf = root / ".cache/j3-24-007.pdf"
    standardir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    require(digest(pdf) == "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2",
            "normative PDF hash differs")
    require(digest(standardir) == "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2",
            "StandardIR hash differs")
    require("(rules R901 R1212 R1215 R1217)" in fixture and
            "(pages 155 242 244 248)" in fixture,
            "normative evidence set differs")


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


def check_source(source: pathlib.Path, values: list[str]) -> None:
    text = source.read_text(encoding="utf-8")
    require(f"  print *, {', '.join(values)}" in text, "source list differs")
    require("program main" in text and "end program main" in text,
            "program envelope differs")


def check_ast(ast: pathlib.Path, source: pathlib.Path, values: list[str]) -> None:
    text = ast.read_text(encoding="utf-8")
    require("(program-unit-v2 " in text, "AST root differs")
    require(f"(file {source})" in text, "AST source path differs")
    require("(source-hash l3-raw-program-generic-print-list-v0)" in text,
            "AST source identity differs")
    require(f"(output-count {len(values)})" in text, "AST count differs")
    require("(output-items " in text, "AST output-items node missing")
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)",
        "(output-clause 12.6.3)", "(output-page 248)",
        "(source-document J3-24-007)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"AST provenance missing: {witness}")
    cursor = text.index("(output-items ")
    for value in values:
        if value == "x":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        else:
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"AST literal missing: {value}")
        cursor = position + len(witness)


def check_mir(mir: pathlib.Path, values: list[str]) -> None:
    text = mir.read_text(encoding="utf-8")
    instructions = groups(text, "(instruction ")
    print_instructions = [
        instruction for instruction in instructions
        if "(source-rule frontend-ast-v2/print-stmt)" in instruction
    ]
    require(len(print_instructions) == 2 * len(values) + 1,
            "MIR print instruction count differs")
    cursor = 0
    for value in values:
        if value == "x":
            require("(opcode load)" in print_instructions[cursor] and
                    "(storage-key x)" in print_instructions[cursor],
                    "variable item is not a load")
        else:
            require("(opcode const)" in print_instructions[cursor],
                    "literal item is not const")
            require(f"(literal {value})" in print_instructions[cursor],
                    f"MIR literal differs: {value}")
        require("(opcode output)" in print_instructions[cursor + 1],
                "literal item has no output")
        cursor += 2
    require("(opcode return)" in print_instructions[-1], "MIR return missing")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_list_literals.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    check_contract(pathlib.Path(__file__).resolve().parents[2])
    values_match = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(values_match is not None, "source has no PRINT list")
    values = [value.strip() for value in values_match.group(1).split(",")]
    require(values and all(value == "x" or value.isdigit() for value in values),
            "source values are not variables or nonnegative decimal literals")
    check_source(source, values)
    check_ast(ast, source, values)
    check_mir(mir, values)
    require(elf.read_bytes().startswith(b"\x7fELF"), "artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    require(runtime.returncode == 0, "runtime returned nonzero")
    require(runtime.stdout == "".join(f"{'3' if value == 'x' else value}\n" for value in values).encode(),
            "runtime stdout differs")
    print(f"generic print-list-literals oracle PASS: {len(values)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic print-list-literals oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
