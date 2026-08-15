#!/usr/bin/env python3
"""Independent regression checks for exact witness comparison."""

from __future__ import annotations

import csv
import importlib.util
import sys
import tempfile
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("compare-statement-sequence-witness.py")
SPEC = importlib.util.spec_from_file_location("compare_statement_sequence_witness", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules["compare_statement_sequence_witness"] = MODULE
SPEC.loader.exec_module(MODULE)


def write(path: Path, rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=MODULE.FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def test_duplicate_rows_are_counted() -> None:
    row = {field: field for field in MODULE.FIELDS}
    with tempfile.TemporaryDirectory() as directory:
        left = Path(directory) / "left.tsv"
        right = Path(directory) / "right.tsv"
        write(left, [row, row])
        write(right, [row])
        assert sum((MODULE.read_rows(left) - MODULE.read_rows(right)).values()) == 1


if __name__ == "__main__":
    test_duplicate_rows_are_counted()
    print("statement-sequence comparison tests passed")
