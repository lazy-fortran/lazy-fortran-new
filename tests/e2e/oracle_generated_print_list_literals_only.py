#!/usr/bin/env python3
"""Independent oracle for literal-only generic integer PRINT lists."""

from __future__ import annotations

import hashlib
import pathlib
import re
import subprocess
import sys


class OracleFailure(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise OracleFailure(message)


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def groups(text: str, marker: str) -> list[str]:
    result: list[str] = []
    start = 0
    while True:
        start = text.find(marker, start)
        if start < 0:
            return result
        depth = 0
        for position in range(start, len(text)):
            if text[position] == "(":
                depth += 1
            elif text[position] == ")":
                depth -= 1
                if depth == 0:
                    result.append(text[start : position + 1])
                    start = position + 1
                    break
        else:
            raise OracleFailure("unbalanced SX group")


def check_contract(root: pathlib.Path) -> None:
    fixture = (root / "contracts/fixtures/l3-print-list-literals-only-v0.sx").read_text(
        encoding="utf-8"
    )
    require("(contract l3-print-list-literals-only)" in fixture,
            "literal-only contract differs")
    cases = {
        "tests/fixtures/l3-print-list-literals-only-v0.f90":
            "154b7cade7a0881ecc0921f8021d5027b359e957ebbf68ba5eeeaf6fd1c796a0",
        "tests/fixtures/l3-print-list-literals-only-wide-v0.f90":
            "31a0c61de7cadb90cf970115fb01695bdfe3cc42d617c0d67840d9ebf73558b7",
        "tests/negative/l3-print-list-literals-only-v0-trailing-comma.f90":
            "e62d6b2c06d7102ce2746da5a6ff0a39e3c1b7a39ce94f2d28f0988784182ddb",
        "tests/negative/l3-print-list-literals-only-v0-real.f90":
            "362090bb631407df454adea0073ef9693dcb4e9870ed9a3f4d42902c1d1b68be",
        "tests/negative/l3-print-list-literals-only-v0-write.f90":
            "94d3d630b5e4fb8154f49cc4a8ad1fab764da3b55f869b9e41edc1ef8de61e0e",
        "tests/negative/l3-print-list-literals-only-v0-name.f90":
            "81806387da1821487c775aebf6a521c28526b61829e23f1a36dfe71b1f055acb",
    }
    for relative, expected in cases.items():
        path = root / relative
        require(f"(path {relative})" in fixture and f"(sha256 {expected})" in fixture,
                f"contract case differs: {relative}")
        require(digest(path) == expected, f"source hash differs: {relative}")
    require(digest(root / ".cache/j3-24-007.pdf") ==
            "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2",
            "normative PDF hash differs")
    require(digest(root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx") ==
            "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2",
            "StandardIR hash differs")
    require("(rules R901 R1212 R1215 R1217)" in fixture,
            "normative evidence set differs")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_list_literals_only.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract(root)
    match = re.search(r"print \*, (.*)", source.read_text(encoding="utf-8"))
    require(match is not None, "source has no PRINT list")
    values = [value.strip() for value in match.group(1).split(",")]
    require(values and all(value.isdigit() for value in values),
            "source list is not literal-only")
    ast_text = ast.read_text(encoding="utf-8")
    require("(program-unit-v2 " in ast_text and f"(file {source})" in ast_text,
            "AST envelope differs")
    require("(source-hash l3-raw-program-generic-print-list-v0)" in ast_text,
            "AST source identity differs")
    require(f"(output-count {len(values)})" in ast_text, "AST output count differs")
    cursor = ast_text.index("(output-items ")
    for value in values:
        witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        position = ast_text.find(witness, cursor)
        require(position >= 0, f"AST literal missing: {value}")
        cursor = position + len(witness)
    mir_text = mir.read_text(encoding="utf-8")
    instructions = groups(mir_text, "(instruction ")
    printed = [item for item in instructions
               if "(source-rule frontend-ast-v2/print-stmt)" in item]
    require(len(printed) == 2 * len(values) + 1, "MIR item count differs")
    for index, value in enumerate(values):
        require("(opcode const)" in printed[2 * index] and
                f"(literal {value})" in printed[2 * index],
                f"MIR literal differs: {value}")
        require("(opcode output)" in printed[2 * index + 1],
                "MIR output missing")
    require("(opcode return)" in printed[-1], "MIR return missing")
    require(elf.read_bytes().startswith(b"\x7fELF"), "artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    require(runtime.returncode == 0, "runtime returned nonzero")
    require(runtime.stdout == "".join(f"{value}\n" for value in values).encode(),
            "runtime stdout differs")
    print(f"generic print-list-literals-only oracle PASS: {len(values)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic print-list-literals-only oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
