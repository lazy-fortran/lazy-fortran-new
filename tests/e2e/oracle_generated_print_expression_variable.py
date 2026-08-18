#!/usr/bin/env python3
"""Independent oracle for an x + x item in a generic PRINT list."""

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
    fixture = root / "contracts/fixtures/l3-print-expression-variable-v0.sx"
    text = fixture.read_text(encoding="utf-8")
    for witness in (
        "(contract l3-print-expression-variable)",
        "(version 0)",
        "(origin mechanical)",
        "(resolution resolved)",
        "(property generic-integer-expression-variable-output)",
        "(rules R901 R1010 R1212 R1215 R1217)",
        "(pages 155 170 242 244 248)",
    ):
        require(witness in text, f"variable-expression contract differs: {witness}")
    source_cases = {
        "tests/fixtures/l3-print-expression-variable-v0.f90":
            "228d269eaf3023dfa99bc7edcaa940a207776dc3a8a87df1837403415d65bf6a",
        "tests/fixtures/l3-print-expression-variable-wide-v0.f90":
            "c21c9c557952ab4697c34bde8ec7dc3cde5c214e3a1cf100473c640f602f85fa",
        "tests/negative/l3-print-expression-variable-v0-missing-operand.f90":
            "1dc2fac53ee92d2045a880378c27a3c9c26bc1df54a68794036d6aeebcf718cd",
        "tests/negative/l3-print-expression-variable-v0-wrong-operator.f90":
            "e118008aee8fc4aa950d8b132d8d897f570debe0b929a2480635552f6f572152",
        "tests/negative/l3-print-expression-variable-v0-write.f90":
            "ff22d48c1f752ed567a7c06c07d2cd49c5a64e87d273f563d15d28a91b157d9b",
        "tests/negative/l3-print-expression-variable-v0-wrong-name.f90":
            "0d5893900df092cb02412ac6afb1ee7df8dca21dd7ff36f839a402c7c5c479f6",
    }
    for relative, expected in source_cases.items():
        source = root / relative
        require(f"(path {relative})" in text and f"(sha256 {expected})" in text,
                f"variable-expression source case differs: {relative}")
        require(digest(source) == expected, f"variable-expression source hash differs: {relative}")
    pdf_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
    standardir_hash = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
    pdf = root / ".cache/j3-24-007.pdf"
    standardir = root / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    require(f"(pdf-sha256 {pdf_hash})" in text and digest(pdf) == pdf_hash,
            "variable-expression normative PDF hash differs")
    require(f"(standardir-sha256 {standardir_hash})" in text and
            digest(standardir) == standardir_hash,
            "variable-expression StandardIR hash differs")
    require("(source-sha256 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e)" in
            standardir.read_text(encoding="utf-8").splitlines()[0],
            "variable-expression StandardIR source hash differs")


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
        elif value == "x + x":
            items.append(("expression", value))
        else:
            raise OracleFailure(f"unsupported variable-expression fixture item: {value}")
    return items


def check_ast(path: pathlib.Path, source: pathlib.Path, items: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    identity = "l3-raw-program-generic-print-expression-v0"
    require("(program-unit-v2 " in text, "variable-expression AST root differs")
    require(f"(file {source})" in text, "variable-expression AST source path differs")
    spans = groups(text, "(source-span ")
    require(spans, "variable-expression AST has no source spans")
    for span in spans:
        require(f"(file {source})" in span and f"(source-hash {identity})" in span,
                "variable-expression AST source-span provenance differs")
    require(f"(source-identity {identity})" in text, "variable-expression AST identity differs")
    require("(output-items " in text, "variable-expression output-list node is absent")
    require(f"(output-count {len(items)})" in text, "variable-expression output count differs")
    cursor = text.index("(output-items ")
    for kind, value in items:
        if kind == "variable":
            witness = "(output-item (kind variable) (name x) (rule R901) (clause 12.6.3) (page 248))"
        elif kind == "literal":
            witness = f"(output-item (kind integer-literal) (value {value}) (rule R1217) (clause 12.6.3) (page 248))"
        else:
            witness = "(output-item (kind integer-expression) (operator +) (left x) (right x) (rule R1217) (clause 12.6.3) (page 248))"
        position = text.find(witness, cursor)
        require(position >= 0, f"variable-expression AST item missing: {witness}")
        cursor = position + len(witness)
    for witness in (
        "(statement-rule R1212)", "(format-rule R1215)", "(output-rule R1217)",
        "(source-document J3-24-007)", "(statement-clause 12.6.1)",
        "(format-clause 12.6.2.2)", "(output-clause 12.6.3)",
        "(statement-page 242)", "(format-page 244)", "(output-page 248)",
        "(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)",
    ):
        require(witness in text, f"variable-expression AST provenance missing: {witness}")


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
            expected += [("load", "(storage-key x)"), ("load", "(storage-key x)"), ("add", ""), ("output", "")]
    require(len(printed) == len(expected) + 1, "variable-expression MIR instruction count differs")
    for actual, (opcode, witness) in zip(printed, expected):
        require(f"(opcode {opcode})" in actual, f"variable-expression MIR opcode differs: {opcode}")
        if witness:
            require(witness in actual, f"variable-expression MIR operand differs: {witness}")
    require("(opcode return)" in printed[-1], "variable-expression MIR has no return")


def main() -> int:
    if len(sys.argv) != 5:
        raise OracleFailure("usage: oracle_generated_print_expression_variable.py AST MIR ELF SOURCE")
    ast, mir, elf, source = map(pathlib.Path, sys.argv[1:])
    root = pathlib.Path(__file__).resolve().parents[2]
    check_contract_fixture(root)
    items = parse_items(source)
    check_ast(ast, source, items)
    check_mir(mir, items)
    binary = elf.read_bytes()
    require(binary.startswith(b"\x7fELF"), "variable-expression artifact is not ELF")
    runtime = subprocess.run(["qemu-riscv64", str(elf)], capture_output=True, check=False)
    expected = b"".join((b"3\n" if kind == "variable" else b"6\n" if kind == "expression" else f"{value}\n".encode())
                         for kind, value in items)
    require(runtime.returncode == 0 and runtime.stdout == expected,
            "variable-expression runtime output differs")
    print(f"generic variable-expression oracle PASS: {len(items)} items")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OracleFailure, OSError, ValueError) as error:
        print(f"generic variable-expression oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
