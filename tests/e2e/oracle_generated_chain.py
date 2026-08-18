#!/usr/bin/env python3
"""Independent behavioral oracle for the bounded generated compiler chain."""

from __future__ import annotations

import pathlib
import sys


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    if len(sys.argv) != 4:
        fail("usage: oracle_generated_chain.py AST MIR ELF")

    ast = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    mir = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
    elf = pathlib.Path(sys.argv[3]).read_bytes()

    if not ast.startswith("(program-unit ") or "(name main)" not in ast:
        fail("AST-v1 root witness is wrong")
    if "(type-spec integer)" not in ast or "(name x)" not in ast:
        fail("AST-v1 declaration witness is wrong")

    if not mir.startswith("(mir-function (name main) "):
        fail("MIR-v0 function witness is wrong")
    if mir.count("source-rule frontend-ast-v1/program") != 2:
        fail("MIR-v0 source correspondence is wrong")
    if mir.count("(kind integer) (type i32)") != 2:
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
