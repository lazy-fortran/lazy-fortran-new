#!/usr/bin/env python3
"""Independent oracle for the generic integer PRINT-list slice."""

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


def check_contract_fixture(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-list-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    require("(contract-witness" in text and "(contract l3-print-list)" in text,
            "PRINT-list contract witness differs")
    for witness in (
        "(version 0)",
        "(origin mechanical)",
        "(resolution resolved)",
        "(property generic-integer-list-directed-print)",
    ):
        require(witness in text, f"contract witness metadata differs: {witness}")
    source_cases = {
        "tests/fixtures/l3-print-list-v0.f90":
            "a992439011f29067faeef7688206580f7fe9a24cdd914a0486047a3a2d89a3df",
        "tests/fixtures/l3-print-list-wide-v0.f90":
            "f3c67e7885f16ef004637180d5cfb4954fa530ed4e28e89b560d72ee21b93057",
        "tests/negative/l3-print-list-v0-empty.f90":
            "bb60bb5e0ab7c93c79877b4d733f9171b0c0d88708bc693a4fe6cf2dee47a024",
        "tests/negative/l3-print-list-v0-missing-item.f90":
            "490d6f645d43fb25e3a5741ead09f804d97af86e35af9fe37598bf6221bc49ef",
        "tests/negative/l3-print-list-v0-write.f90":
            "fdfbd04d044941311fd32d2155f99f2fcc5c74bc304c7fc09301832e17dd92ec",
        "tests/negative/l3-print-list-v0-wrong-name.f90":
            "a497e9a410ba5476284b88e06b231491db3053c78efc0c7e7e224a1cc67e55c0",
    }
    for relative, expected in source_cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"contract source case differs: {relative}")
        require(digest(source) == expected, f"source hash differs: {relative}")

    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    standardir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    standardir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    pdf = root / ".cache/j3-24-007.pdf"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(pdf) == pdf_hash,
            "normative PDF hash differs")
    require(f"(standardir-sha256 {standardir_hash})" in text and
            digest(standardir) == standardir_hash,
            "StandardIR artifact hash differs")
    require("(source-sha256 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e)" in
            standardir.read_text(encoding="utf-8").splitlines()[0],
            "StandardIR source hash differs")
    require("(standardir-path .cache/runs/E0171/R000433-provenance-replay/standardir.sx)" in text,
            "StandardIR path differs")
    require("(rules R901 R1212 R1215 R1217)" in text and
            "(pages 155 242 244 248)" in text,
            "normative rule/page set differs")


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
    spans = groups(text, "(source-span ")
    require(spans, "AST has no source spans")
    for span in spans:
        require(f"(file {source})" in span and
                "(source-hash l3-raw-program-generic-print-list-v0)" in span,
                "AST source-span provenance differs")
    require("(output-items " in text, "generic output-list node is absent")
    require(f"(output-count {len(items)})" in text, "AST output count differs")
    for witness in (
        "(statement-rule R1212)",
        "(format-rule R1215)",
        "(source-document J3-24-007)",
        "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)",
        "(output-clause 12.6.3)",
        "(statement-page 242)",
        "(format-page 244)",
        "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
        "(source-identity l3-raw-program-generic-print-list-v0)",
    ):
        require(witness in text, f"AST provenance witness missing: {witness}")
    require("(output-kind-2 " not in text and "(output-name-2 " not in text,
            "AST retained numbered output fields")
    cursor = text.index("(output-items ")
    for kind, value in items:
        if kind == "variable":
            witness = f"(output-item (kind variable) (name {value}) (rule R901) (clause 12.6.3) (page 248))"
        else:
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"AST item missing: {witness}")
        cursor = position + len(witness)
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
    check_contract_fixture(pathlib.Path(__file__).resolve().parents[2])
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
