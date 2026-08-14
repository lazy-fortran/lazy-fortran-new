#!/usr/bin/env python3
"""Select validated retry rows without rewriting either append-only attempt."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def read_rows(path):
    return [json.loads(line) for line in Path(path).read_text(encoding="utf-8").splitlines() if line]


def parse_args():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("base")
    result.add_argument("retry")
    result.add_argument("--outdir", required=True)
    result.add_argument(
        "--replace-status",
        action="append",
        default=[],
        help="require the retry set to replace every base row with this status; repeatable",
    )
    return result.parse_args()


def main():
    args = parse_args()
    base = read_rows(args.base)
    retry = read_rows(args.retry)
    base_keys = [row["row_key"] for row in base]
    retry_keys = [row["row_key"] for row in retry]
    if len(set(base_keys)) != len(base_keys) or len(set(retry_keys)) != len(retry_keys):
        raise SystemExit("E0116 merge: duplicate row key")
    if not set(retry_keys) <= set(base_keys):
        raise SystemExit("E0116 merge: retry contains an unknown row")
    base_by_key = {row["row_key"]: row for row in base}
    if args.replace_status:
        expected_keys = {
            row["row_key"] for row in base if row.get("status") in set(args.replace_status)
        }
        if set(retry_keys) != expected_keys:
            raise SystemExit(
                "E0116 merge: retry set does not exactly replace the requested base statuses"
            )
        if any(base_by_key[key].get("status") not in set(args.replace_status) for key in retry_keys):
            raise SystemExit("E0116 merge: retry replaces a base row outside requested statuses")
    if any(row.get("status") not in {"accepted", "unresolved", "hard_failure", "reference-only"}
           for row in retry):
        raise SystemExit("E0116 merge: retry contains a nonterminal row")
    replacement = {row["row_key"]: row for row in retry}
    selected = [replacement.get(row["row_key"], row) for row in base]
    if [row["row_key"] for row in selected] != base_keys:
        raise SystemExit("E0116 merge: selected order differs")
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    with (outdir / "selected-rows.jsonl").open("w", encoding="utf-8") as stream:
        for row in selected:
            stream.write(json.dumps(row, sort_keys=True) + "\n")
    summary = {
        "base_rows": len(base),
        "retry_rows": len(retry),
        "selected_rows": len(selected),
        "replaced_rows": len(retry),
        "selected_accepted": sum(row["status"] == "accepted" for row in selected),
        "selected_unresolved": sum(row["status"] == "unresolved" for row in selected),
        "selected_hard_failure": sum(row["status"] == "hard_failure" for row in selected),
        "expected_retry_rows": (
            sum(row.get("status") in set(args.replace_status) for row in base)
            if args.replace_status else None
        ),
        "replacement_set_exact": (
            set(retry_keys) == {
                row["row_key"] for row in base if row.get("status") in set(args.replace_status)
            }
            if args.replace_status else None
        ),
        "negative_control": "observed_failure" if set(retry_keys) != set(base_keys) else "not-applicable",
    }
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
