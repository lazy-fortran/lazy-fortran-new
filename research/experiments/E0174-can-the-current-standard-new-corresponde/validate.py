#!/usr/bin/env python3
"""Independently validate a current source-boundary correspondence replay."""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CANDIDATES = ROOT / ".cache/runs/E0171/R000435-correspondence-replay/candidates.tsv"
EXPECTED_COMMIT = "f94c4c51b51fce22b533b7eeda08741970320913"
EXPECTED_SOURCE_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
EXPECTED_CANDIDATE_SHA256 = "6f9c0f416b76c502bec18cc27362587e0ce03ff0b40c0c1e1a38afd0410236e5"
FIELDS = (
    "rule", "container", "source_document", "source_clause", "page",
    "byte_start", "source_sha256", "kind", "path", "item", "derivation",
    "status",
)
MAPPING_FIELDS = tuple(
    "rule container source_document source_clause page byte_start source_sha256 kind path item derivation status disposition source_node_index source_node_kind source_node_name alternative alternatives evidence_count evidence_kinds evidence_items evidence_derivations evidence_statuses reason".split()
)
EVIDENCE_FIELDS = tuple(
    "rule container source_document source_clause page byte_start source_sha256 path evidence_ordinal evidence_kind evidence_item evidence_derivation evidence_status".split()
)


def fail(message: str) -> None:
    raise SystemExit(f"error: {message}")


def read_tsv(path: Path, fields: tuple[str, ...]) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if tuple(reader.fieldnames or ()) != fields:
            fail(f"{path}: fields differ from the contract")
        rows = list(reader)
    if not rows:
        fail(f"{path}: empty table")
    return rows


def candidate_key(row: dict[str, str]) -> tuple[str, ...]:
    return tuple(row[field] for field in FIELDS)


def structural_key(row: dict[str, str]) -> tuple[str, ...]:
    return (
        row["rule"], row["container"], row["source_document"], row["source_clause"],
        row["page"], row["byte_start"], row["source_sha256"], row["path"],
    )


def producer_structural_key(row: dict[str, str]) -> tuple[str, ...]:
    return structural_key(row) + (row["source_node_kind"],)


def trace_key(row: dict[str, object]) -> tuple[str, ...]:
    return (
        str(row["source_rule"]), str(row["source_document"]), str(row["source_clause"]),
        str(row["source_page"]), str(row["source_byte_start"]), str(row["source_hash"]),
        str(row["source_alternative"]), str(row["raw_source_path"]),
        str(row["source_node_kind"]),
    )


def load_trace_contract(path: Path) -> list[dict[str, object]]:
    module_path = ROOT / "research/experiments/E0171-can-current-standardir-grammar-projectio/audit-correspondence-witness.py"
    spec = importlib.util.spec_from_file_location("e0171_audit", module_path)
    if not spec or not spec.loader:
        fail("could not load the correspondence contract validator")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.read_trace(path)


def main() -> int:
    run_dir = Path(sys.argv[1]) if len(sys.argv) == 2 else ROOT / ".cache/runs/E0174/R000001"
    if (run_dir / "standard-new-commit.txt").read_text(encoding="utf-8").strip() != EXPECTED_COMMIT:
        fail("standard-new commit pin differs")
    source_input = ROOT / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx"
    source_hash_file = run_dir / "source-input-sha256.txt"
    if not source_hash_file.is_file():
        fail("source input hash pin is missing from the run")
    if source_hash_file.read_text(encoding="utf-8").strip() != EXPECTED_SOURCE_SHA256:
        fail("source input hash pin differs")
    if not source_input.is_file() or hashlib.sha256(source_input.read_bytes()).hexdigest() != EXPECTED_SOURCE_SHA256:
        fail("source input hash differs")
    if hashlib.sha256(CANDIDATES.read_bytes()).hexdigest() != EXPECTED_CANDIDATE_SHA256:
        fail("candidate witness hash differs")
    candidates = read_tsv(CANDIDATES, FIELDS)
    sites = read_tsv(run_dir / "sites.tsv", FIELDS)
    evidence = read_tsv(run_dir / "evidence.tsv", EVIDENCE_FIELDS)
    mapping = read_tsv(run_dir / "mapping.tsv", MAPPING_FIELDS)
    summary = json.loads((run_dir / "coalesce-summary.json").read_text(encoding="utf-8"))
    if len(candidates) != 95 or len(mapping) != len(sites):
        fail(f"candidate/site/mapping denominator mismatch: {len(candidates)}/{len(sites)}/{len(mapping)}")

    groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    site_groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in candidates:
        groups[structural_key(row)].append(row)
    for row in sites:
        site_groups[structural_key(row)].append(row)
    mapping_base_groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    mapping_groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in mapping:
        mapping_base_groups[structural_key(row)].append(row)
        mapping_groups[producer_structural_key(row)].append(row)
    if set(groups) != set(site_groups) or set(groups) != set(mapping_base_groups):
        fail("coalesced sites do not represent the candidate structural identities")
    if any(len(rows) != 1 for rows in site_groups.values()):
        fail("coalesced sites contain duplicate structural identities")
    if any(len(rows) != 1 for rows in mapping_groups.values()):
        fail("producer mapping contains duplicate source-node structural identities")
    node_kinds_by_group = {}
    for key, rows in mapping_base_groups.items():
        node_kinds = {row["source_node_kind"] for row in rows}
        if len(rows) != 1 or len(node_kinds) != 1:
            fail(f"producer mapping has inconsistent source-node kinds for {key!r}: {sorted(node_kinds)}")
        node_kinds_by_group[key] = next(iter(node_kinds))
    if len(evidence) != len(candidates):
        fail("coalesced evidence sidecar dropped rows")
    evidence_groups: defaultdict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in evidence:
        evidence_groups[structural_key(row)].append(row)
    for key, rows in groups.items():
        producer = mapping_base_groups[key][0]
        try:
            count = int(producer["evidence_count"])
        except ValueError as exc:
            fail(f"invalid producer evidence count for {key!r}: {exc}")
        producer_values = [producer[field].split(";") for field in (
            "evidence_kinds", "evidence_items", "evidence_derivations", "evidence_statuses"
        )]
        if count < 1 or any(len(values) != count or any(not value for value in values) for values in producer_values):
            fail(f"producer evidence fields do not match evidence_count for {key!r}")
        observed = sorted(zip(*producer_values))
        expected = sorted((row["kind"], row["item"], row["derivation"], row["status"]) for row in rows)
        if observed != expected:
            fail(f"producer evidence differs from candidate evidence for {key!r}")
        if len(evidence_groups[key]) != count:
            fail(f"coalescer evidence count differs from producer for {key!r}")

    trace = load_trace_contract(run_dir / "correspondence.jsonl")
    by_trace: defaultdict[tuple[str, ...], list[dict[str, object]]] = defaultdict(list)
    for row in trace:
        by_trace[trace_key(row)].append(row)
    dispositions = Counter()
    for key, rows in groups.items():
        mapping_row = mapping_base_groups[key][0]
        lookup = (
            mapping_row["rule"], mapping_row["source_document"], mapping_row["source_clause"],
            mapping_row["page"], mapping_row["byte_start"], mapping_row["source_sha256"],
            mapping_row["alternative"], mapping_row["path"], mapping_row["source_node_kind"],
        )
        matches = by_trace[lookup]
        if len(matches) != 1:
            fail(f"structural site has {len(matches)} trace relations for {key!r}")
        dispositions[str(matches[0]["disposition"])] += 1
    if dispositions["ambiguous"] or dispositions["unsupported"]:
        fail(f"selected coalesced sites contain invalid dispositions: {dict(dispositions)}")
    expected_summary = {
        "input_rows": 95,
        "output_rows": len(sites),
        "candidate_input_rows": 95,
        "candidate_structural_sites": len(sites),
        "candidate_duplicate_groups": sum(len(rows) > 1 for rows in groups.values()),
        "candidate_duplicate_rows": sum(len(rows) for rows in groups.values() if len(rows) > 1),
        "candidate_evidence_rows": 95,
        "non_candidate_rows": 0,
        "exact_duplicate_groups": 0,
    }
    for field, expected in expected_summary.items():
        if summary.get(field) != expected:
            fail(f"coalescer summary {field}={summary.get(field)!r}, expected {expected!r}")
    report = {
        "origin": "MECHANICAL",
        "standard_new_commit": EXPECTED_COMMIT,
        "candidate_input_rows": len(candidates),
        "structural_boundary_sites": len(sites),
        "producer_mapping_rows": len(mapping),
        "correspondence_trace_rows": len(trace),
        "trace_join_rows": len(sites),
        "trace_join_failures": 0,
        "duplicate_structural_groups": sum(len(rows) > 1 for rows in groups.values()),
        "source_node_kind_groups": len(node_kinds_by_group),
        "source_node_kind_counts": dict(sorted(Counter(node_kinds_by_group.values()).items())),
        "unsupported_rows": dispositions["unsupported"],
        "ambiguous_rows": dispositions["ambiguous"],
        "selected_dispositions": dict(sorted(dispositions.items())),
        "coalescer_summary": summary,
        "model_calls": 0,
        "semantic_promotions": 0,
    }
    (run_dir / "report.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
