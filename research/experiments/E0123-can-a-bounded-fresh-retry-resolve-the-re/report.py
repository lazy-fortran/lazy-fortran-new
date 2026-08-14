#!/usr/bin/env python3
"""Summarize the deterministic E0123 merge, replay and witness gates."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def read_tsv(path: Path):
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines()[1:]:
        if not line:
            continue
        key, value = line.split("\t", 1)
        values[key] = int(value) if value.isdigit() else value
    return values


def read_retry_rows(path: Path):
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line:
            rows.append(json.loads(line))
    return rows


def optional_json(path: Path):
    return read_json(path) if path.exists() else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("analysis_dir", type=Path)
    parser.add_argument("retry_rows", type=Path)
    args = parser.parse_args()

    retry_rows = read_retry_rows(args.retry_rows)
    report = {
        "experiment": "E0123",
        "retry_rows": len(retry_rows),
        "retry_status": {
            status: sum(row.get("status") == status for row in retry_rows)
            for status in ("accepted", "unresolved", "hard_failure", "reference-only")
        },
        "retry_summary": optional_json(args.retry_rows.parent / "summary.json"),
        "retry_config": optional_json(args.retry_rows.parent / "run-config.json"),
        "merge": read_json(args.analysis_dir / "merged" / "summary.json"),
        "validation": read_tsv(args.analysis_dir / "validate" / "summary.tsv"),
        "witness": read_json(args.analysis_dir / "witness" / "summary.json"),
    }
    output = args.analysis_dir / "report.json"
    output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
