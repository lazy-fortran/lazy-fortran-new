#!/usr/bin/env python3
"""Independent fixtures for the boundary-candidate coalescing projection."""

from __future__ import annotations

import csv
import tempfile
from pathlib import Path

import importlib.util


MODULE_PATH = Path(__file__).with_name("coalesce-boundary-candidates.py")
SPEC = importlib.util.spec_from_file_location("coalesce_boundary_candidates", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def row(kind: str, item: str = "statement", status: str = "candidate") -> dict[str, str]:
    return {
        "rule": "R1",
        "container": "construct",
        "source_document": "DOC",
        "source_clause": "5",
        "page": "1",
        "byte_start": "10",
        "source_sha256": "a" * 64,
        "kind": kind,
        "path": "rhs/2",
        "item": item,
        "derivation": item,
        "status": status,
    }


def main() -> None:
    sites, evidence, summary = MODULE.project(
        [row("first-plus-repeat"), row("repeat-item")]
    )
    assert len(sites) == 1
    assert len(evidence) == 2
    assert summary["candidate_structural_sites"] == 1
    assert summary["candidate_duplicate_groups"] == 1
    assert [item["evidence_kind"] for item in evidence] == [
        "first-plus-repeat",
        "repeat-item",
    ]
    mixed_sites, mixed_evidence, mixed_summary = MODULE.project(
        [row("first-plus-repeat"), row("repeat-item"), row("ignored", status="unsupported")]
    )
    assert len(mixed_sites) == 2
    assert len(mixed_evidence) == 2
    assert mixed_summary["non_candidate_rows"] == 1
    assert mixed_sites[-1]["status"] == "unsupported"
    try:
        MODULE.project([row("repeat-item"), row("repeat-item")])
    except SystemExit as error:
        assert "duplicated" in str(error)
    else:
        raise AssertionError("exact duplicate candidate evidence was accepted")
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "candidates.tsv"
        with path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=MODULE.FIELDS, delimiter="\t")
            writer.writeheader()
            writer.writerow(row("repeat-item"))
        assert len(MODULE.read_candidates(path)) == 1
    print("boundary candidate coalescing tests passed")


if __name__ == "__main__":
    main()
