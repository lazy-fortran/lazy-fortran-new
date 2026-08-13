#!/usr/bin/env python3
"""Recompute E0115 row and oracle metrics from durable row records."""

import argparse
import importlib.util
import json
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
spec = importlib.util.spec_from_file_location("e0115_harness", HERE / "e0115_harness.py")
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--rows", required=True)
    result.add_argument("--out", required=True)
    result.add_argument("--canonical", default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"))
    result.add_argument("--pages", default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index"))
    result.add_argument("--e0110", default=str(ROOT / ".cache/runs/E0110/R000001/classifications.tsv"))
    result.add_argument("--source-sha256", default=harness.common.DEFAULT_SOURCE_SHA256)
    return result


def main():
    args = parser().parse_args()
    raw = harness.common.load_canonical(args.canonical, args.source_sha256)
    ranges = harness.common.load_page_index(args.pages, len(raw))
    oracle = harness.load_e0110(args.e0110, raw, ranges, args.source_sha256)
    rows = [json.loads(line) for line in Path(args.rows).read_text(encoding="utf-8").splitlines() if line]
    accepted = [row for row in rows if row["status"] == "accepted"]
    oracle_rows = [row for row in rows if row["name"] in oracle]
    exact = [
        row for row in oracle_rows
        if row["status"] == "accepted"
        and row.get("accepted")
        and row["accepted"]["byte_start"] == oracle[row["name"]]["byte_start"]
    ]
    wrong = [row for row in oracle_rows if row["status"] == "accepted" and row not in exact]
    summary = {
        "residue_rows": len(rows),
        "accepted": len(accepted),
        "abstentions": sum(row["status"] == "abstained_after_budget" for row in rows),
        "hard_failures": sum(row["status"] == "hard_failure" for row in rows),
        "model_errors": sum(len(row.get("model_errors", [])) for row in rows),
        "gate_rejections": sum(row.get("gate_rejections", 0) for row in rows),
        "total_model_calls": sum(row.get("turns", 0) for row in rows),
        "tool_calls": sum(row.get("evidence_calls", 0) for row in rows),
        "submissions": sum(row.get("submissions", 0) for row in rows),
        "source_bytes_returned": sum(row.get("source_bytes", 0) for row in rows),
        "novel_accepted": sum(row["name"] not in oracle for row in accepted),
        "oracle_rows": len(oracle_rows),
        "oracle_exact_matches": len(exact),
        "oracle_wrong_accepts": len(wrong),
        "oracle_abstentions": sum(row["status"] == "abstained_after_budget" for row in oracle_rows),
        "oracle_hard_failures": sum(row["status"] == "hard_failure" for row in oracle_rows),
        "wall_s_total": sum(row.get("wall_s", 0.0) for row in rows),
    }
    Path(args.out).write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
