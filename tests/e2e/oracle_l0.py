#!/usr/bin/env python3
"""Independent oracle for the narrow L0 lexical StandardIR slice.

This parser deliberately does not import the SX implementation under test. It
checks the reviewed golden output and independently inspects the source
provenance and generated schema surface.
"""

from __future__ import annotations

import hashlib
import re
import sys
import tomllib
from pathlib import Path


SOURCE_DOCUMENT_HASH = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

EXPECTED = (
    {
        "source-term": "letter",
        "class": "lexical-class",
        "target": "LETTER",
        "rule": "P6.1.2-3",
        "codepoint": "U+0041-U+005A,U+0061-U+007A",
        "page": "53",
        "clause": "P6.1.2-3",
    },
    {
        "source-term": "digit",
        "class": "lexical-class",
        "target": "DIGIT",
        "rule": "P6.1.3-3",
        "codepoint": "U+0030-U+0039",
        "page": "53",
        "clause": "P6.1.3-3",
    },
    {
        "source-term": "rep-char",
        "class": "lexical-class",
        "target": "REP_CHAR",
        "rule": "R724-P3",
        "codepoint": "processor-defined",
        "page": "71",
        "clause": "R724-P3",
    },
    {
        "source-term": "–",
        "canonical-spelling": "-",
        "class": "unicode-lexical",
        "target": "EN_DASH",
        "rule": "R1010",
        "codepoint": "U+2013",
        "page": "69",
        "clause": "R1010",
    },
    {
        "source-term": "’",
        "canonical-spelling": "'",
        "class": "unicode-lexical",
        "target": "RIGHT_SINGLE_QUOTE",
        "rule": "R724",
        "codepoint": "U+2019",
        "page": "85",
        "clause": "R724",
    },
)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def atom(line: str, field: str) -> str | None:
    match = re.search(rf"\({re.escape(field)} ([^()]*)\)", line)
    if match is None:
        return None
    value = match.group(1).strip()
    if len(value) >= 2 and value[0] == value[-1] == '"':
        return value[1:-1]
    return value


def parse_fact(line: str) -> dict[str, str]:
    fields = (
        "source-term",
        "canonical-spelling",
        "class",
        "target",
        "rule",
        "codepoint",
        "document",
        "clause",
        "page",
        "source-sha256",
    )
    result = {field: value for field in fields if (value := atom(line, field)) is not None}
    return result


def fail(message: str) -> None:
    raise SystemExit(f"oracle failure: {message}")


def main() -> int:
    if len(sys.argv) != 6:
        fail("usage: oracle_l0.py manifest source roundtrip golden generated-schema")
    manifest_path, source_path, roundtrip_path, golden_path, generated_path = map(
        Path, sys.argv[1:]
    )
    manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))

    if manifest.get("boundary") != "standard-new-local-schema-generator-v0":
        fail("L0 boundary is not explicitly the standard-new local generator slice")
    if manifest.get("central_contract") != "none":
        fail("L0 incorrectly claims a central cross-repository contract")

    if digest(Path(source_path)) != manifest["source_sha256"]:
        fail("source fixture hash differs from the pinned manifest")
    if digest(Path(manifest["schema"])) != manifest["schema_sha256"]:
        fail("schema hash differs from the pinned manifest")
    if digest(Path(roundtrip_path)) != manifest["roundtrip_sha256"]:
        fail("roundtrip output hash differs from the reviewed golden hash")
    if Path(roundtrip_path).read_bytes() != Path(golden_path).read_bytes():
        fail("roundtrip output differs from the reviewed golden artifact")
    if digest(Path(generated_path)) != manifest["generated_schema_sha256"]:
        fail("generated schema hash differs from the reviewed artifact")

    source_lines = [line for line in Path(source_path).read_text(encoding="utf-8").splitlines() if line]
    output_lines = [line for line in Path(roundtrip_path).read_text(encoding="utf-8").splitlines() if line]
    if len(source_lines) != len(EXPECTED) or len(output_lines) != len(EXPECTED):
        fail("lexical fact count differs from the reviewed fixture")
    if not all(line.startswith("(lexical-fact ") and line.endswith(")") for line in output_lines):
        fail("output contains a non-lexical-fact record")

    for index, expected in enumerate(EXPECTED):
        actual = parse_fact(output_lines[index])
        for field, value in expected.items():
            if actual.get(field) != value:
                fail(f"record {index + 1} field {field}: {actual.get(field)!r} != {value!r}")
        if actual.get("document") != "J3-24-007":
            fail(f"record {index + 1} has no J3-24-007 source document")
        if actual.get("source-sha256") != SOURCE_DOCUMENT_HASH:
            fail(f"record {index + 1} has the wrong source document hash")

    generated = Path(generated_path).read_text(encoding="utf-8")
    for required in ("module standardir_schema", "type, public :: source_ref_t", "type, public :: semantic_item_t"):
        if required not in generated:
            fail(f"generated schema is missing {required!r}")
    if "TODO" in generated:
        fail("generated schema contains TODO")

    print("oracle: PASS source provenance, canonical output and generated schema")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
