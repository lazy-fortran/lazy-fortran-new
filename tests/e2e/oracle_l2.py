#!/usr/bin/env python3
"""Independent oracle for the first executable cross-repository slice.

This oracle does not import the FFC or fortback implementations.  It checks
the reviewed fixture/golden bytes, the declared contract lineage, and the
basic ELF identity of the produced executable.  Runtime behavior is checked
independently by qemu-riscv64 in the shell runner.
"""

from __future__ import annotations

import hashlib
import struct
import sys
import tomllib
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(message: str) -> None:
    raise SystemExit(f"oracle failure: {message}")


def main() -> int:
    if len(sys.argv) != 7:
        fail("usage: oracle_l2.py manifest source mir golden artifact negative")
    manifest_path, source_path, mir_path, golden_path, artifact_path, negative_path = map(
        Path, sys.argv[1:]
    )
    manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("boundary") != "frontend-v0-to-mir-v0-to-riscv64-linux-v0":
        fail("unexpected L2 boundary")
    if manifest.get("central_contracts") != ["frontend-v0", "mir-v0", "targetir-v0", "emission-v0"]:
        fail("L2 contract lineage is not the reviewed sequence")
    root = Path(__file__).resolve().parents[2]
    for name in ("frontend-v0", "mir-v0", "targetir-v0", "emission-v0"):
        schema = root / "contracts" / f"{name}.sxs"
        if not schema.is_file():
            fail(f"missing contract schema: {schema}")
        if not schema.read_text(encoding="utf-8").startswith("(schema "):
            fail(f"malformed contract schema: {schema}")

    source = source_path.read_bytes()
    expected_source = b"(frontend-result (status accepted) (root-kind program) (diagnostic-count 0))\n"
    if source != expected_source:
        fail("positive frontend fixture changed")
    negative = negative_path.read_bytes()
    expected_negative = b"(frontend-result (status rejected) (root-kind none) (diagnostic-count 1))\n"
    if negative != expected_negative:
        fail("negative frontend fixture changed")
    expected_mir = golden_path.read_bytes()
    if expected_mir.endswith(b"\n"):
        expected_mir = expected_mir[:-1]
    if mir_path.read_bytes() != expected_mir:
        fail("FFC output differs from the reviewed MIR golden")
    if not expected_mir.startswith(b"(mir-function "):
        fail("MIR golden has no mir-function root")
    if b"(opcode add)" not in expected_mir or b"(opcode return)" not in expected_mir:
        fail("MIR golden does not contain the bounded add/return witness")

    artifact = artifact_path.read_bytes()
    if len(artifact) < 64 or artifact[:4] != b"\x7fELF":
        fail("output is not an ELF artifact")
    if artifact[4] != 2 or artifact[5] != 1:
        fail("output is not little-endian ELF64")
    if struct.unpack_from("<H", artifact, 16)[0] != 2:
        fail("output is not an executable ELF")
    if struct.unpack_from("<H", artifact, 18)[0] != 243:
        fail("output is not an RV64 ELF")
    print(
        "oracle: PASS fixture lineage, MIR golden, ELF identity, and negative input shape"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
