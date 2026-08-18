#!/usr/bin/env python3
"""Independent oracle for one integer expression item in a generic PRINT list."""

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
        began = False
        for position in range(start, len(text)):
            if text[position] == "(":
                depth += 1
                began = True
            elif text[position] == ")":
                depth -= 1
                if began and depth == 0:
                    result.append(text[start:position + 1])
                    start = position + 1
                    break
        else:
            raise OracleFailure(f"unbalanced group beginning at {marker!r}")


def check_contract_fixture(root: pathlib.Path) -> None:
    fixture = root / "contracts/fixtures/l3-print-expression-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression)",
        "(version 0)",
        "(origin mechanical)",
        "(resolution resolved)",
        "(property generic-integer-expression-output)",
        "(rules R901 R1010 R1212 R1215 R1217)",
        "(pages 155 170 242 244 248)",
    ):
        require(witness in text, f"expression contract witness differs: {witness}")
    source_cases = {
        "tests/fixtures/l3-print-expression-v0.f90":
            "ff090458bf8d0938c6520e4fb67b103a1797224089ffa868027df207f6c41720",
        "tests/fixtures/l3-print-expression-wide-v0.f90":
            "ba904f1f349399a91d6c533f31da47fe1abdb4f61e3079c8be3e9aae01ef165e",
        "tests/negative/l3-print-expression-v0-missing-operand.f90":
            "dcce9d12b6c2038dfcf7a0cb6509fbdf562aff6b3cce0f9a8595a72ab9e959c3",
        "tests/negative/l3-print-expression-v0-wrong-operator.f90":
            "0a0c17777324ba6010fddd91822cc99a45c529211534248dc1c6c33a0a0c9474",
        "tests/negative/l3-print-expression-v0-write.f90":
            "17e6fcb9f2641eea2f8748ccc8810c5abafb166622c28dbfe47ec45637e83ccf",
        "tests/negative/l3-print-expression-v0-wrong-name.f90":
            "cbc9b6bfd7885dcf0ca068bee2c46f6653bb6ca54d9679a88cecd1ed76be64e7",
    }
    for relative, expected in source_cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"expression contract source case differs: {relative}")
        require(digest(source) == expected, f"expression source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    standardir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    pdf = root / ".cache/j3-24-007.pdf"
    standardir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(pdf) == pdf_hash,
            "expression normative PDF hash differs")
    require(f"(standardir-sha256 {standardir_hash})" in text and
            digest(standardir) == standardir_hash,
            "expression StandardIR hash differs")
    require("(source-sha256 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e)" in
            standardir.read_text(encoding="utf-8").splitlines()[0],
            "expression StandardIR source hash differs")


def parse_items(source: pathlib.Path) -> list[tuple[str, str]]:
    text = source.read_text(encoding="utf-8")
    match = re.search(r"print \*, (.*)", text)
    require(match is not None, "source has no PRINT list")
    items = []
    for raw in match.group(1).strip().split(","):
        value = raw.strip()
        if value == "x":
            items.append(("variable", value))
        elif value.isdigit():
            items.append(("literal", value))
        elif value == "x + 1":
            items.append(("expression", value))
        else:
            raise OracleFailure(f"unsupported expression fixture item: {value}")
    return items


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    identity = "l3-raw-program-generic-print-expression-v0"
    require("(program-unit-v2 " in text, "expression AST root differs")
    require(f"(file {source})" in text, "expression AST source path differs")
    spans = groups(text, "(source-span ")
    require(spans, "expression AST has no source spans")
    for span in spans:
        require(f"(file {source})" in span and f"(source-hash {identity})" in span,
                "expression AST source-span provenance differs")
    require(f"(source-identity {identity})" in text, "expression AST identity differs")
    require("(output-items " in text, "expression output-list node is absent")
    require(f"(output-count {len(items)})" in text, "expression output count differs")
    cursor = text.index("(output-items ")
    for kind, value in items:
        if kind == "variable":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        elif kind == "literal":
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        else:
            witness = "(output-item (kind integer-expression) (operator +) (left x) (right 1) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"expression AST item missing: {witness}")
        cursor = position + len(witness)
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)",
        "(output-rule R1217)", "(source-document J3-24-007)",
        "(statement-clause 12.6.1)", "(format-clause 12.6.2.2)",
        "(output-clause 12.6.3)", "(statement-page 242)",
        "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"expression AST provenance missing: {witness}")


def check_mir(path: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    instructions = groups(text, "(instruction ")
    printed = [group for group in instructions if "(source-rule frontend-ast-v2/print-stmt)" in group]
    expected = []
    for kind, value in items:
        if kind == "variable":
            expected += [("load", "(storage-key x)"), ("output", "")]
        elif kind == "literal":
            expected += [("const", f"(literal {value})"), ("output", "")]
        else:
            expected += [("load", "(storage-key x)"), ("const", "(literal 1)"), ("add", ""), ("output", "")]
    require(len(printed) == len(expected) + 1, "expression MIR instruction count differs")
    for actual, (opcode, witness) in zip(printed, expected):
        require(f"(opcode {opcode})" in actual, f"expression MIR opcode differs: {opcode}")
        if witness:
            require(witness in actual, f"expression MIR operand differs: {witness}")
    require("(opcode return)" in printed[-1], "expression MIR has no return")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract_fixture(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    binary = elf.read_bytes()
    require(binary.startswith(b"\x7fELF"), "expression artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((b"3\n" if kind == "variable" else b"4\n" if kind == "expression" else f"{value}\n".encode())
                         for kind, value in items)
    require(runtime.returncode == 0 and runtime.stdout == expected,
            "expression runtime output differs")
    print(f"generic print-expression oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic print-expression oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
