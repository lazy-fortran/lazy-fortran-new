#!/usr/bin/env python3
"""Coalesce duplicate source-boundary sites without losing candidate evidence.

The candidate generator records derivations, while target insertion needs one
structural source site. This projection keeps one deterministic representative
row per candidate site and writes every contributing candidate to an evidence
sidecar. Non-candidate rows are preserved unchanged because their failures are
part of the witness denominator.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from collections import defaultdict
from pathlib import Path


FIELDS = (
    "rule",
    "container",
    "source_document",
    "source_clause",
    "page",
    "byte_start",
    "source_sha256",
    "kind",
    "path",
    "item",
    "derivation",
    "status",
)
STRUCTURAL_FIELDS = (
    "rule",
    "container",
    "source_document",
    "source_clause",
    "page",
    "byte_start",
    "source_sha256",
    "path",
)
EVIDENCE_FIELDS = STRUCTURAL_FIELDS + (
    "evidence_ordinal",
    "evidence_kind",
    "evidence_item",
    "evidence_derivation",
    "evidence_status",
)
ACTIVE_STATUS = "candidate"


def fail(message: str) -> None:
    raise SystemExit(f"error: {message}")


def read_candidates(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if tuple(reader.fieldnames or ()) != FIELDS:
            fail(f"{path}: expected candidate fields {FIELDS}")
        rows = list(reader)
    if not rows:
        fail(f"{path}: empty candidate witness")
    for ordinal, row in enumerate(rows, 2):
        if any(not row[field] for field in FIELDS):
            fail(f"{path}:{ordinal}: candidate field is empty")
        if row["status"] not in {"candidate", "suppressed", "unsupported"}:
            fail(f"{path}:{ordinal}: unknown candidate status {row['status']!r}")
    return rows


def structural_key(row: dict[str, str]) -> tuple[str, ...]:
    return tuple(row[field] for field in STRUCTURAL_FIELDS)


def evidence_sort_key(row: dict[str, str]) -> tuple[str, ...]:
    return tuple(row[field] for field in ("kind", "item", "derivation", "status"))


def project(
    rows: list[dict[str, str]],
) -> tuple[list[dict[str, str]], list[dict[str, str]], dict[str, int]]:
    active: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    output: list[dict[str, str]] = []
    evidence: list[dict[str, str]] = []
    non_candidate_rows = 0
    for row in rows:
        if row["status"] == ACTIVE_STATUS:
            active[structural_key(row)].append(row)
        else:
            output.append(row)
            non_candidate_rows += 1

    exact_duplicate_groups = 0
    duplicate_groups = 0
    duplicate_rows = 0
    for key in sorted(active):
        group = sorted(active[key], key=evidence_sort_key)
        identities = {
            tuple(row[field] for field in FIELDS)
            for row in group
        }
        if len(identities) != len(group):
            exact_duplicate_groups += 1
            fail(f"candidate evidence is duplicated for structural key {key!r}")
        if len(group) > 1:
            duplicate_groups += 1
            duplicate_rows += len(group)
        output.append(group[0])
        for ordinal, row in enumerate(group, 1):
            evidence.append(
                {
                    **{field: row[field] for field in STRUCTURAL_FIELDS},
                    "evidence_ordinal": str(ordinal),
                    "evidence_kind": row["kind"],
                    "evidence_item": row["item"],
                    "evidence_derivation": row["derivation"],
                    "evidence_status": row["status"],
                }
            )

    output.sort(key=lambda row: (structural_key(row), row["status"], evidence_sort_key(row)))
    summary = {
        "input_rows": len(rows),
        "output_rows": len(output),
        "candidate_input_rows": sum(row["status"] == ACTIVE_STATUS for row in rows),
        "candidate_structural_sites": len(active),
        "candidate_duplicate_groups": duplicate_groups,
        "candidate_duplicate_rows": duplicate_rows,
        "candidate_evidence_rows": len(evidence),
        "non_candidate_rows": non_candidate_rows,
        "exact_duplicate_groups": exact_duplicate_groups,
    }
    return output, evidence, summary


def write_tsv(path: Path, fields: tuple[str, ...], rows: list[dict[str, str]]) -> None:
    if path.exists():
        fail(f"refusing to overwrite {path}")
    with path.open("x", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("candidates", type=Path)
    parser.add_argument("sites", type=Path)
    parser.add_argument("evidence", type=Path)
    parser.add_argument("summary", type=Path)
    args = parser.parse_args()
    rows = read_candidates(args.candidates)
    sites, evidence, summary = project(rows)
    write_tsv(args.sites, FIELDS, sites)
    write_tsv(args.evidence, EVIDENCE_FIELDS, evidence)
    summary["input_sha256"] = hashlib.sha256(args.candidates.read_bytes()).hexdigest()
    summary["sites_sha256"] = hashlib.sha256(args.sites.read_bytes()).hexdigest()
    summary["evidence_sha256"] = hashlib.sha256(args.evidence.read_bytes()).hexdigest()
    if args.summary.exists():
        fail(f"refusing to overwrite {args.summary}")
    args.summary.write_text(json.dumps(summary, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
