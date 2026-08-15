#!/usr/bin/env python3
"""Compare independent lab and production statement-sequence TSV witnesses."""

from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path


FIELDS = [
    "rule", "container", "source_document", "source_clause", "page",
    "byte_start", "source_sha256", "kind", "path", "item", "derivation",
    "status",
]


def read_rows(path: Path) -> Counter[tuple[str, ...]]:
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames != FIELDS:
            raise ValueError(f"{path}: fields differ: {reader.fieldnames!r}")
        rows = []
        for row in reader:
            rows.append(tuple(row[field] for field in FIELDS))
        return Counter(rows)


def describe(label: str, rows: Counter[tuple[str, ...]]) -> None:
    print(f"{label}_rows={sum(rows.values())}")
    print(f"{label}_distinct={len(rows)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("lab_tsv", type=Path)
    parser.add_argument("production_tsv", type=Path)
    args = parser.parse_args()
    try:
        lab = read_rows(args.lab_tsv)
        production = read_rows(args.production_tsv)
    except (OSError, ValueError) as exc:
        print(f"compare-statement-sequence-witness: {exc}", file=sys.stderr)
        return 2
    describe("lab", lab)
    describe("production", production)
    missing = lab - production
    extra = production - lab
    print(f"missing_rows={sum(missing.values())}")
    print(f"extra_rows={sum(extra.values())}")
    if not missing and not extra:
        print("parity=PASS")
        return 0
    for label, values in (("missing", missing), ("extra", extra)):
        for row, count in list(values.items())[:10]:
            print(f"{label}\t{count}\t" + "\t".join(row), file=sys.stderr)
    print("parity=FAIL")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
