#!/usr/bin/env python3
"""Independent oracle for the bounded L3 integer-declaration source slice."""

from __future__ import annotations

import hashlib
import subprocess
import sys
import tomllib
from pathlib import Path


POSITIVE = b"program p\n  integer :: x\nend program p\n"
NEGATIVE = b"program p\n  integer ::\nend program p\n"
FRONTEND = b"(frontend-result (status accepted) (root-kind program) (diagnostic-count 0))"
MIR = b"(mir-function (name main) (entry-block 0) (instruction-count 2) (instructions (instruction (id 0) (opcode add) (source-rule frontend-v0/program) (result (id 1) (kind integer) (type i32))) (instruction (id 1) (opcode return) (source-rule frontend-v0/program) (result (id 1) (kind integer) (type i32)))))"


class ValidationError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized(path: Path) -> bytes:
    return path.read_bytes().rstrip(b"\n")


def main() -> int:
    if len(sys.argv) != 8:
        raise ValidationError(
            "usage: validate_l3_declaration.py manifest run-dir standard frontend compiler backend runtime"
        )
    manifest_path, run_dir, standard, frontend, compiler, backend, runtime = sys.argv[1:]
    manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
    run_dir = Path(run_dir)
    root = Path(__file__).resolve().parents[2]
    source = root / manifest["source"]
    negative = root / manifest["negative"]
    frontend_golden = root / manifest["frontend_golden"]
    mir_golden = root / manifest["mir_golden"]
    oracle_path = root / manifest["oracle"]
    oracle = tomllib.loads(oracle_path.read_text(encoding="utf-8"))

    require(manifest["boundary"] == oracle["boundary"], "boundary differs")
    require(manifest["central_contracts"] == [
        "l3-declaration", "l3-raw-program", "frontend-v0", "mir-v0"
    ], "contract lineage differs")
    require(manifest["origin"] == "MECHANICAL", "fixture origin differs")
    require(manifest["model_calls"] == 0 and manifest["semantic_promotions"] == 0,
            "promotion guard differs")
    require(source.read_bytes() == POSITIVE, "positive source differs")
    require(negative.read_bytes() == NEGATIVE, "negative source differs")
    for field, path in (
        ("contract_schema", root / manifest["contract_schema"]),
        ("contract_witness", root / manifest["contract_witness"]),
        ("source", source),
        ("negative", negative),
        ("frontend_golden", frontend_golden),
        ("mir_golden", mir_golden),
        ("oracle", oracle_path),
    ):
        require(digest(path) == manifest[field + "_sha256"], f"{field} hash differs")
    require(oracle["frontend_status"] == "accepted", "oracle frontend status differs")
    require(oracle["mir_function_name"] == "main", "oracle MIR name differs")
    require(oracle["mir_instruction_count"] == 2, "oracle MIR count differs")
    require(oracle["runtime_exit_status"] == 0 and int(runtime) == 0,
            "runtime outcome differs")
    for actual, field in (
        (standard, "standard_component_commit"),
        (frontend, "frontend_component_commit"),
        (compiler, "compiler_component_commit"),
        (backend, "backend_component_commit"),
    ):
        require(actual == manifest[field], f"{field} differs")

    positive_frontend = run_dir / "positive.frontend.sx"
    negative_frontend = run_dir / "negative.frontend.sx"
    positive_mir = run_dir / "positive.mir.sx"
    artifact = run_dir / "l3.elf"
    require(normalized(positive_frontend) == FRONTEND, "positive frontend result differs")
    require(normalized(frontend_golden) == FRONTEND, "frontend golden differs")
    require(normalized(positive_mir) == MIR, "positive MIR differs")
    require(normalized(mir_golden) == MIR, "MIR golden differs")

    negative_text = negative_frontend.read_text(encoding="utf-8")
    require("(status rejected)" in negative_text, "negative frontend was not rejected")
    require("(root-kind none)" in negative_text, "negative root kind differs")
    require("(message invalid-program)" in negative_text, "negative diagnostic differs")
    require(f"(file {negative})" in negative_text, "negative source path differs")
    require("(source-hash l3-raw-program-v0)" in negative_text,
            "negative source identity differs")
    require("(status accepted)" not in negative_text, "negative output contains acceptance")
    require(not (run_dir / "negative.mir.sx").exists(), "negative MIR was written")

    require(artifact.read_bytes().startswith(b"\x7fELF"), "artifact is not ELF")
    readelf = subprocess.run(["readelf", "-h", str(artifact)], text=True,
                             capture_output=True, check=False)
    require(readelf.returncode == 0, "readelf rejected artifact")
    require("Class:                             ELF64" in readelf.stdout, "ELF class differs")
    require("Machine:                           RISC-V" in readelf.stdout,
            "ELF machine differs")
    qemu = subprocess.run(["qemu-riscv64", str(artifact)], capture_output=True, check=False)
    require(qemu.returncode == 0, "independent runtime oracle rejected artifact")
    print("L3 declaration oracle PASS: 1 accepted source, 1 rejected neighbour, 0 promotions")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValidationError, OSError, tomllib.TOMLDecodeError, ValueError) as error:
        print(f"L3 declaration oracle failure: {error}", file=sys.stderr)
        raise SystemExit(1)
