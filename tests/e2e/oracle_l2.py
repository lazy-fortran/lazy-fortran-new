#!/usr/bin/env python3
"""Independent oracle for the first executable cross-repository slice.

This oracle does not import the FFC or fortback implementations.  It checks
the reviewed fixture/golden bytes, the declared contract lineage, the
recorded toolchain/runtime witnesses, and the basic ELF identity of the
produced executable.  The shell runner supplies the observed runtime/tool
values; this oracle compares them with the committed evidence manifest.
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
    if len(sys.argv) != 21:
        fail(
            "usage: oracle_l2.py manifest source mir golden mir-oracle artifact "
            "negative malformed-mir out-of-scope-mir qemu-status fo-version "
            "fo-sha256 runtime-oracle qemu-version readelf-version host-os "
            "host-architecture lc-all lang worktree-state"
        )
    (
        manifest_path,
        source_path,
        mir_path,
        golden_path,
        mir_oracle_path,
        artifact_path,
        negative_path,
        malformed_mir_path,
        out_of_scope_mir_path,
        qemu_status,
        fo_version,
        fo_sha256,
        runtime_oracle,
        qemu_version,
        readelf_version,
        host_os,
        host_architecture,
        lc_all,
        lang,
        worktree_state,
    ) = sys.argv[1:]
    manifest_path, source_path, mir_path, golden_path, mir_oracle_path, artifact_path, \
        negative_path, malformed_mir_path, out_of_scope_mir_path = map(
            Path,
            (manifest_path, source_path, mir_path, golden_path, mir_oracle_path,
             artifact_path,
             negative_path, malformed_mir_path, out_of_scope_mir_path),
        )
    qemu_status = int(qemu_status)
    manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("boundary") != "frontend-v0-to-mir-v0-to-riscv64-linux-v0":
        fail("unexpected L2 boundary")
    if manifest.get("central_contracts") != ["frontend-v0", "mir-v0"]:
        fail("L2 contract lineage is not the reviewed sequence")
    root = Path(__file__).resolve().parents[2]
    evidence_manifest = root / manifest["evidence_manifest"]
    evidence = tomllib.loads(evidence_manifest.read_text(encoding="utf-8"))
    for field, actual in (
        ("fo_version", fo_version),
        ("fo_sha256", fo_sha256),
        ("runtime_oracle", runtime_oracle),
        ("qemu_version", qemu_version),
        ("readelf_version", readelf_version),
        ("host_os", host_os),
        ("host_architecture", host_architecture),
        ("lc_all", lc_all),
        ("lang", lang),
        ("worktree_state", worktree_state),
    ):
        if evidence[field] != actual:
            fail(f"{field} differs from the committed evidence manifest")
    if qemu_status != evidence["runtime_exit_status"]:
        fail("QEMU exit status differs from the committed evidence manifest")
    if evidence["id"] != manifest["id"]:
        fail("evidence manifest has a different fixture ID")
    if evidence["contracts"] != manifest["central_contracts"]:
        fail("evidence manifest disagrees on the central contract boundary")
    for key in ("standard_commit", "frontend_commit", "compiler_commit", "backend_commit"):
        if evidence[key] != manifest[key.replace("_commit", "_component_commit")]:
            fail(f"evidence manifest disagrees on {key}")
    if digest(source_path) != evidence["source_sha256"]:
        fail("source hash differs from the committed evidence manifest")
    if digest(negative_path) != evidence["negative_sha256"]:
        fail("negative hash differs from the committed evidence manifest")
    if digest(mir_oracle_path) != evidence["mir_oracle_sha256"]:
        fail("MIR oracle differs from the committed evidence manifest")
    if digest(mir_path) != evidence["mir_sha256"]:
        fail("MIR output differs from the committed evidence manifest")
    if digest(artifact_path) != evidence["artifact_sha256"]:
        fail("ELF output differs from the committed evidence manifest")
    if digest(malformed_mir_path) != evidence["negative_mir_malformed_sha256"]:
        fail("malformed MIR hash differs from the committed evidence manifest")
    if digest(out_of_scope_mir_path) != evidence["negative_mir_out_of_scope_sha256"]:
        fail("out-of-scope MIR hash differs from the committed evidence manifest")
    oracle = tomllib.loads(mir_oracle_path.read_text(encoding="utf-8"))
    if mir_oracle_path.relative_to(root).as_posix() != evidence["mir_oracle"]:
        fail("MIR oracle path differs from the evidence manifest")
    for name in ("frontend-v0", "mir-v0"):
        schema = root / "contracts" / f"{name}.sxs"
        if not schema.is_file():
            fail(f"missing contract schema: {schema}")
        if not schema.read_text(encoding="utf-8").startswith("(schema "):
            fail(f"malformed contract schema: {schema}")
    mir_schema = (root / "contracts" / "mir-v0.sxs").read_text(encoding="utf-8")
    if "(list instructions instruction)" not in mir_schema:
        fail("mir-v0 does not declare its instruction list")
    if "(instructions instructions)" not in mir_schema:
        fail("mir-v0 function does not declare its instruction list field")

    source = source_path.read_bytes()
    expected_source = b"(frontend-result (status accepted) (root-kind program) (diagnostic-count 0))\n"
    if source != expected_source:
        fail("positive frontend fixture changed")
    negative = negative_path.read_bytes()
    expected_negative = b"(frontend-result (status rejected) (root-kind none) (diagnostic-count 1))\n"
    if negative != expected_negative:
        fail("negative frontend fixture changed")
    serialized_mir = mir_path.read_bytes()
    expected_mir = golden_path.read_bytes()
    if expected_mir.endswith(b"\n"):
        expected_mir = expected_mir[:-1]
    if serialized_mir != expected_mir:
        fail("FFC output differs from the reviewed MIR serialization golden")
    if not serialized_mir.startswith(b"(mir-function "):
        fail("MIR golden has no mir-function root")
    text = serialized_mir.decode("utf-8")
    if f"(name {oracle['function_name']})" not in text:
        fail("MIR function name differs from the independent witness")
    if f"(instruction-count {oracle['instruction_count']})" not in text:
        fail("MIR instruction count differs from the independent witness")
    opcodes = [value for value in text.split("(opcode ")[1:]]
    opcodes = [value.split(")", 1)[0] for value in opcodes]
    if opcodes != oracle["opcodes"]:
        fail(f"MIR opcode sequence differs from the independent witness: {opcodes!r}")
    result = (
        f"(result (id {oracle['result_id']}) (kind {oracle['result_kind']}) "
        f"(type {oracle['result_type']}))"
    )
    if text.count(result) != oracle["instruction_count"]:
        fail("MIR result facts differ from the independent witness")
    if text.count(f"(source-rule {oracle['source_rule']})") != oracle["instruction_count"]:
        fail("MIR source lineage differs from the independent witness")
    if malformed_mir_path.read_text(encoding="utf-8").count("(") != malformed_mir_path.read_text(encoding="utf-8").count(")") + 1:
        fail("malformed MIR fixture is not the reviewed missing-close neighbor")
    if "(name test)" not in out_of_scope_mir_path.read_text(encoding="utf-8"):
        fail("out-of-scope MIR fixture is not the reviewed function-name neighbor")

    artifact = artifact_path.read_bytes()
    if len(artifact) < 64 or artifact[:4] != b"\x7fELF":
        fail("output is not an ELF artifact")
    if artifact[4] != oracle["elf_class"] or artifact[5] != oracle["elf_data"]:
        fail("output is not little-endian ELF64")
    if struct.unpack_from("<H", artifact, 16)[0] != oracle["elf_type"]:
        fail("output is not an executable ELF")
    if struct.unpack_from("<H", artifact, 18)[0] != oracle["elf_machine"]:
        fail("output is not an RV64 ELF")
    entry = struct.unpack_from("<Q", artifact, 24)[0]
    if entry != oracle["entry"]:
        fail("ELF entry point differs from the independent witness")
    program_header_offset = struct.unpack_from("<Q", artifact, 32)[0]
    program_header_size = struct.unpack_from("<H", artifact, 54)[0]
    program_header_count = struct.unpack_from("<H", artifact, 56)[0]
    code = None
    for index in range(program_header_count):
        offset = program_header_offset + index * program_header_size
        if struct.unpack_from("<I", artifact, offset)[0] != 1:
            continue
        segment_offset = struct.unpack_from("<Q", artifact, offset + 8)[0]
        segment_address = struct.unpack_from("<Q", artifact, offset + 16)[0]
        code_offset = segment_offset + entry - segment_address
        code = list(struct.unpack_from("<3I", artifact, code_offset))
        break
    if code != oracle["code_words"]:
        fail(f"RV64 code words differ from the independent witness: {code!r}")
    print(
        "oracle: PASS independent MIR/ELF witness, contract shape, and negative inputs"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
