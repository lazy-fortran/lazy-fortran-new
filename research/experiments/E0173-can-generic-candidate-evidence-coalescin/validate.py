#!/usr/bin/env python3
"""Validate the E0173 coalescing cell and its frozen trace relation."""

from __future__ import annotations

import csv
import hashlib
import json
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
INPUT = ROOT / ".cache/runs/E0171/R000435-correspondence-replay/candidates.tsv"
MAPPING = ROOT / ".cache/runs/E0171/R000435-correspondence-replay/mapping.tsv"
TRACE = ROOT / ".cache/runs/E0171/R000435-correspondence-replay/correspondence.jsonl"
EXPECTED_INPUT_SHA256 = "6f9c0f416b76c502bec18cc27362587e0ce03ff0b40c0c1e1a38afd0410236e5"
FIELDS = (
    "rule", "container", "source_document", "source_clause", "page",
    "byte_start", "source_sha256", "kind", "path", "item", "derivation",
    "status",
)
STRUCTURAL_FIELDS = (
    "rule", "container", "source_document", "source_clause", "page",
    "byte_start", "source_sha256", "path",
)
EVIDENCE_FIELDS = STRUCTURAL_FIELDS + (
    "evidence_ordinal", "evidence_kind", "evidence_item",
    "evidence_derivation", "evidence_status",
)


def fail(message: str) -> None:
    raise SystemExit(f"error: {message}")


def read_tsv(path: Path, fields: tuple[str, ...]) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if tuple(reader.fieldnames or ()) != fields:
            fail(f"{path}: fields differ from the pinned contract")
        rows = list(reader)
    if not rows:
        fail(f"{path}: empty table")
    return rows


def candidate_key(row: dict[str, str]) -> tuple[str, ...]:
    return tuple(row[field] for field in FIELDS)


def structural_key(row: dict[str, str]) -> tuple[str, ...]:
    return tuple(row[field] for field in STRUCTURAL_FIELDS)


def trace_key(row: dict[str, str]) -> tuple[str, ...]:
    return (
        row["rule"], row["source_document"], row["source_clause"], row["page"],
        row["byte_start"], row["source_sha256"], row["alternative"],
        row["path"], row["source_node_kind"],
    )


def main() -> int:
    run_dir = Path(sys.argv[1]) if len(sys.argv) == 2 else ROOT / ".cache/runs/E0173/R000001"
    input_rows = read_tsv(INPUT, FIELDS)
    sites = read_tsv(run_dir / "sites.tsv", FIELDS)
    evidence = read_tsv(run_dir / "evidence.tsv", EVIDENCE_FIELDS)
    summary = json.loads((run_dir / "coalesce-summary.json").read_text(encoding="utf-8"))
    input_hash = hashlib.sha256(INPUT.read_bytes()).hexdigest()
    if input_hash != EXPECTED_INPUT_SHA256:
        fail(f"candidate witness hash changed: {input_hash}")

    input_groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    site_groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    evidence_groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in input_rows:
        input_groups[structural_key(row)].append(row)
    for row in sites:
        site_groups[structural_key(row)].append(row)
    for row in evidence:
        evidence_groups[structural_key(row)].append(row)
    if any(len(rows) != 1 for rows in site_groups.values()):
        fail("coalesced sites contain duplicate structural identities")
    if set(site_groups) != set(input_groups):
        fail("coalesced site identities do not cover the input identities")
    if len(evidence) != len(input_rows):
        fail("candidate evidence rows were dropped")
    for key, rows in input_groups.items():
        evidence_rows = sorted(evidence_groups[key], key=lambda row: int(row["evidence_ordinal"]))
        expected = sorted(rows, key=lambda row: (row["kind"], row["item"], row["derivation"], row["status"]))
        observed = [
            (row["evidence_kind"], row["evidence_item"], row["evidence_derivation"], row["evidence_status"])
            for row in evidence_rows
        ]
        expected_values = [(row["kind"], row["item"], row["derivation"], row["status"]) for row in expected]
        if observed != expected_values:
            fail(f"evidence sidecar differs for structural key {key!r}")

    mapping_rows = read_tsv(
        MAPPING,
        tuple(
            "rule container source_document source_clause page byte_start source_sha256 kind path item derivation status disposition source_node_index source_node_kind source_node_name alternative alternatives reason".split()
        ),
    )
    mapping_by_candidate: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in mapping_rows:
        mapping_by_candidate[candidate_key(row)].append(row)
    source_nodes: dict[tuple[str, ...], str] = {}
    for key, rows in input_groups.items():
        mapped = [mapping_by_candidate[candidate_key(row)] for row in rows]
        flat = [item for group in mapped for item in group]
        if len(flat) != len(rows):
            fail(f"candidate-to-mapping relation is not one-to-one for {key!r}")
        node_kinds = {row["source_node_kind"] for row in flat}
        if len(node_kinds) != 1:
            fail(f"structural site has multiple source node kinds for {key!r}")
        source_nodes[key] = next(iter(node_kinds))

    trace_rows = []
    for line_number, line in enumerate(TRACE.read_text(encoding="utf-8").splitlines(), 1):
        try:
            trace_rows.append(json.loads(line))
        except json.JSONDecodeError as exc:
            fail(f"{TRACE}:{line_number}: invalid JSON: {exc}")
    trace_by_key: defaultdict[tuple[str, ...], list[dict[str, object]]] = defaultdict(list)
    for row in trace_rows:
        trace_by_key[trace_key({
            "rule": str(row["source_rule"]),
            "source_document": str(row["source_document"]),
            "source_clause": str(row["source_clause"]),
            "page": str(row["source_page"]),
            "byte_start": str(row["source_byte_start"]),
            "source_sha256": str(row["source_hash"]),
            "alternative": str(row["source_alternative"]),
            "path": str(row["raw_source_path"]),
            "source_node_kind": str(row["source_node_kind"]),
        })].append(row)
    for key, rows in input_groups.items():
        representative = rows[0]
        trace_matches = trace_by_key[
            (representative["rule"], representative["source_document"], representative["source_clause"],
             representative["page"], representative["byte_start"], representative["source_sha256"],
             next(row["alternative"] for row in mapping_by_candidate[candidate_key(representative)]),
             representative["path"], source_nodes[key])
        ]
        if len(trace_matches) != 1:
            fail(f"structural site has {len(trace_matches)} trace relations for {key!r}")

    expected = {
        "input_rows": len(input_rows),
        "output_rows": len(sites),
        "candidate_input_rows": len(input_rows),
        "candidate_structural_sites": len(site_groups),
        "candidate_duplicate_groups": sum(len(rows) > 1 for rows in input_groups.values()),
        "candidate_duplicate_rows": sum(len(rows) for rows in input_groups.values() if len(rows) > 1),
        "candidate_evidence_rows": len(evidence),
        "non_candidate_rows": 0,
        "exact_duplicate_groups": 0,
    }
    for field, value in expected.items():
        if summary.get(field) != value:
            fail(f"coalescer summary {field}={summary.get(field)!r}, expected {value!r}")
    report = {
        "origin": "MECHANICAL",
        "input_sha256": input_hash,
        "candidate_input_rows": len(input_rows),
        "structural_boundary_sites": len(sites),
        "duplicate_groups": expected["candidate_duplicate_groups"],
        "duplicate_rows": expected["candidate_duplicate_rows"],
        "evidence_rows": len(evidence),
        "trace_join_rows": len(sites),
        "trace_join_failures": 0,
        "exact_duplicate_groups": 0,
        "model_calls": 0,
        "semantic_promotions": 0,
    }
    (run_dir / "report.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
