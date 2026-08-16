#!/usr/bin/env python3
"""Independent oracle for the L1 StandardIR-to-frontier slice.

The oracle reads plain SX/text and does not import either component's parser
or runtime. It checks the reviewed StandardIR fixture, canonical output, and
the independently reviewed accepted/rejected frontend observations.
"""

from __future__ import annotations

import hashlib
import re
import sys
import tomllib
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(message: str) -> None:
    raise SystemExit(f"oracle failure: {message}")


def main() -> int:
    if len(sys.argv) != 9:
        fail("usage: oracle_l1.py manifest source roundtrip golden accept reject cases negative")
    (
        manifest_path,
        source_path,
        roundtrip_path,
        golden_path,
        accept_path,
        reject_path,
        cases_path,
        negative_path,
    ) = map(Path, sys.argv[1:])
    manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("boundary") != "central-standardir-grammar-v0":
        fail("fixture does not declare the central StandardIR grammar boundary")
    if manifest.get("central_contract") != "standardir-grammar-v0":
        fail("fixture does not declare the standardir-grammar-v0 contract")
    repository_root = Path(__file__).resolve().parents[2]
    central_schema = repository_root / manifest["central_schema"]
    if digest(central_schema) != manifest["central_schema_sha256"]:
        fail("central StandardIR grammar schema differs from the reviewed schema")

    expected = {
        source_path: manifest["source_hash"],
        roundtrip_path: manifest["roundtrip_sha256"],
        accept_path: manifest["accept_sha256"],
        reject_path: manifest["reject_sha256"],
    }
    for path, value in expected.items():
        if digest(path) != value:
            fail(f"{path} hash differs from the reviewed manifest")
    if digest(cases_path) != manifest["cases_sha256"]:
        fail("frontend case manifest hash differs from the reviewed manifest")
    if digest(negative_path) != manifest["negative_sha256"]:
        fail("negative fixture differs from the reviewed malformed fixture")
    negative = negative_path.read_text(encoding="utf-8")
    if negative.count("(") != negative.count(")") + 1:
        fail("negative fixture no longer has the reviewed single missing close")
    if not negative.startswith("(syntax-rule ") or not negative.rstrip().endswith(
        "(resolution resolved)"
    ):
        fail("negative fixture no longer has the reviewed malformed syntax-rule shape")

    cases = {
        case_id: token
        for case_id, token in (
            line.split("\t", 1)
            for line in cases_path.read_text(encoding="utf-8").splitlines()
            if line
        )
    }
    if cases != {"accept": "PROGRAM", "reject": "BAD"}:
        fail(f"frontend cases differ from the reviewed cases: {cases!r}")

    source = source_path.read_bytes()
    if source != roundtrip_path.read_bytes():
        fail("standard-new canonical output differs from the source fixture")
    if source != golden_path.read_bytes():
        fail("canonical output differs from the reviewed StandardIR golden")

    lines = roundtrip_path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 2:
        fail("the bounded grammar fixture does not contain exactly two records")
    if not all(line.startswith("(syntax-rule ") and line.endswith(")") for line in lines):
        fail("the canonical artifact contains a non-syntax-rule record")
    for rule in ("R501", "R502"):
        if not any(f"(id {rule})" in line for line in lines):
            fail(f"missing reviewed rule {rule}")
    if "(lhs program)" not in lines[0] or "(grammar-node reference program-unit" not in lines[0]:
        fail("R501 does not preserve its program-unit reference")
    if "(lhs program-unit)" not in lines[1] or "(grammar-node token PROGRAM" not in lines[1]:
        fail("R502 does not preserve its PROGRAM token")
    if any("(source-hash fixture)" not in line for line in lines):
        fail("a fixture rule lost its source lineage")

    accept = accept_path.read_text(encoding="utf-8")
    reject = reject_path.read_text(encoding="utf-8")
    if not re.search(r"^rules=2\nlines=2\noutcome=accepted\nmessage=", accept):
        fail("PROGRAM was not accepted by the frontend observable")
    if not re.search(r"^rules=2\nlines=2\noutcome=rejected\nmessage=", reject):
        fail("BAD was not rejected by the frontend observable")
    if not accept.rstrip().endswith("grammar-frontier-input-is-accepted"):
        fail("accepted frontend diagnostic changed")
    if not reject.rstrip().endswith("grammar-frontier-input-is-rejected"):
        fail("rejected frontend diagnostic changed")

    print("oracle: PASS canonical StandardIR, provenance, acceptance and rejection")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
