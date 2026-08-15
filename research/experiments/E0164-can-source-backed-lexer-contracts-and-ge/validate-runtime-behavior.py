#!/usr/bin/env python3
"""Check the selected generated-parser positive/negative behavior witness."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


EXPECTED = {
    "positive_end": "accepted",
    "positive_end_program": "accepted",
    "negative_unknown": "rejected",
    "negative_incomplete": "rejected",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("behavior", type=Path)
    args = parser.parse_args()
    with args.behavior.open(newline="", encoding="utf-8") as handle:
        rows = {row["case"]: row for row in csv.DictReader(handle, delimiter="\t")}
    failures = [
        f"{name}={rows.get(name, {}).get('outcome', 'missing')}"
        for name, expected in EXPECTED.items()
        if rows.get(name, {}).get("outcome") != expected
    ]
    print("field\tvalue")
    print(f"cases\t{len(rows)}")
    print(f"positive_cases\t2")
    print(f"negative_cases\t2")
    print(f"failures\t{','.join(failures)}")
    print(f"status\t{'PASS' if not failures and set(rows) == set(EXPECTED) else 'FAIL'}")
    return 1 if failures or set(rows) != set(EXPECTED) else 0


if __name__ == "__main__":
    raise SystemExit(main())
