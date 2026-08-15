#!/usr/bin/env python3
"""Validate a producer-emitted StandardIR transformation witness.

This is a lab-side evidence gate. It compares the witness lineage set with
the source-lineage annotations in the same generated target file; it does not
infer language equivalence or approve a target lowering.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter
from pathlib import Path


HEX64 = re.compile(r"^[0-9a-f]{64}$")


def lineages_from_target(path: Path) -> set[str]:
    values: set[str] = set()
    for annotation in re.findall(
        r"source-lineage=([^\s*/]+)", path.read_text(encoding="utf-8")
    ):
        values.update(annotation.split(","))
    if not values:
        raise SystemExit(f"target has no source-lineage annotations: {path}")
    return values


def read_witness(path: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        try:
            value = json.loads(line)
        except json.JSONDecodeError as error:
            raise SystemExit(f"invalid JSON at {path}:{line_number}: {error}") from error
        if not isinstance(value, dict):
            raise SystemExit(f"witness row is not an object at {path}:{line_number}")
        rows.append(value)
    if not rows or rows[0] != {
        "kind": "transformation-witness-header",
        "format": 1,
        "origin": "MECHANICAL",
    }:
        raise SystemExit("witness header is missing or not the declared mechanical format")
    return rows[1:]


def validate(rows: list[dict[str, object]], expected: set[str]) -> dict[str, object]:
    seen: set[str] = set()
    transformations: Counter[str] = Counter()
    profiles: set[str] = set()
    for index, row in enumerate(rows, 2):
        if row.get("kind") != "transformation-witness":
            raise SystemExit(f"row {index}: unexpected kind {row.get('kind')!r}")
        row_kind = row.get("row_kind")
        if row_kind not in {"target", "omitted", "role"}:
            raise SystemExit(f"row {index}: unexpected row_kind {row_kind!r}")
        transformation = row.get("transformation")
        if not isinstance(transformation, str) or not transformation:
            raise SystemExit(f"row {index}: missing transformation")
        transformations[transformation] += 1
        profile = row.get("profile")
        if not isinstance(profile, str) or not profile:
            raise SystemExit(f"row {index}: missing profile")
        profiles.add(profile)
        lineage = row.get("source_lineage")
        if not isinstance(lineage, str) or not lineage or lineage == "none":
            raise SystemExit(f"row {index}: missing source lineage")
        seen.update(lineage.split(","))
        target_hash = row.get("target_expression_sha256")
        if not isinstance(target_hash, str) or not HEX64.fullmatch(target_hash):
            raise SystemExit(f"row {index}: invalid target expression hash")
        source_hash = row.get("source_expression_sha256")
        if not isinstance(source_hash, str) or not source_hash:
            raise SystemExit(f"row {index}: missing source expression hash field")
        source_hashes = source_hash.split(",")
        if any(value == "none" for value in source_hashes):
            if transformation != "generated-helper":
                raise SystemExit(f"row {index}: source-less non-helper transformation")
        if any(value != "none" and not HEX64.fullmatch(value) for value in source_hashes):
            raise SystemExit(f"row {index}: invalid source expression hash")
    missing = sorted(expected - seen)
    extra = sorted(seen - expected)
    result = {
        "status": "PASS" if not missing and not extra else "FAIL",
        "witness_rows": len(rows),
        "target_lineages": len(expected),
        "witness_lineages": len(seen),
        "missing_lineages": missing,
        "extra_lineages": extra,
        "profiles": sorted(profiles),
        "transformations": dict(sorted(transformations.items())),
    }
    if result["status"] != "PASS":
        raise SystemExit(json.dumps(result, indent=2))
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("target", type=Path)
    parser.add_argument("witness", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    expected = lineages_from_target(args.target)
    rows = read_witness(args.witness)
    result = validate(rows, expected)
    result["target_sha256"] = hashlib.sha256(args.target.read_bytes()).hexdigest()
    result["witness_sha256"] = hashlib.sha256(args.witness.read_bytes()).hexdigest()
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
