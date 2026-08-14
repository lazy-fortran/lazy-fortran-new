#!/usr/bin/env python3
"""Assemble first-pass and bounded-retry E0115 rows without losing duplicates."""

import argparse
import csv
import json
import subprocess
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SUMMARY = HERE / "summarize.py"


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cell",
        action="append",
        required=True,
        help="MODEL|BASE_ROWS|RETRY_ROOTS|- or MODEL|BASE_ROWS|-|FINAL_ROWS",
    )
    parser.add_argument("--outdir", required=True)
    return parser.parse_args()


def parse_cell(spec):
    fields = spec.split("|")
    if len(fields) != 4 or not all(fields[:2]):
        raise SystemExit(f"E0115 assemble: invalid cell: {spec}")
    return fields[0], Path(fields[1]), fields[2], None if fields[3] == "-" else Path(fields[3])


def read_rows(path):
    return [json.loads(line) for line in Path(path).read_text(encoding="utf-8").splitlines() if line]


def retry_rows(roots):
    rows = {}
    if roots == "-":
        return rows
    for root_name in roots.split(","):
        root = Path(root_name)
        candidates = []
        if root.is_file():
            candidates.append(root)
        elif root.is_dir():
            candidates.extend(root.rglob("rows.jsonl"))
            candidates.extend(root.rglob("*.rows.jsonl"))
        for path in candidates:
            for row in read_rows(path):
                rows[row["name"]] = row
    return rows


def combine(base, retry):
    return [retry.get(row["name"], row) for row in base]


def summarize(rows_path, summary_path):
    subprocess.run(
        [sys.executable, str(SUMMARY), "--rows", str(rows_path), "--out", str(summary_path)],
        cwd=ROOT,
        check=True,
    )
    return json.loads(summary_path.read_text(encoding="utf-8"))


def matrix_row(model, protocol, summary):
    return {
        "model": model,
        "protocol": protocol,
        "reasoning": "off",
        "modality": "text",
        "residue_rows": summary["residue_rows"],
        "resolved_rows": summary["accepted"],
        "abstained_after_budget": summary["abstentions"],
        "hard_failures": summary["hard_failures"],
        "model_errors": summary["model_errors"],
        "oracle_rows": summary["oracle_rows"],
        "oracle_exact_matches": summary["oracle_exact_matches"],
        "wall_s_total": summary["wall_s_total"],
    }


def write_tsv(path, rows, fields):
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main():
    args = parse_args()
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    matrix = []
    convergence = []
    for spec in args.cell:
        model, base_path, retry_root, final_path = parse_cell(spec)
        base = read_rows(base_path)
        initial_rows = outdir / f"{model}-initial.rows.jsonl"
        initial_rows.write_text(
            "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in base),
            encoding="utf-8",
        )
        initial_summary = summarize(initial_rows, outdir / f"{model}-initial.summary.json")
        if final_path is None:
            selected = combine(base, retry_rows(retry_root))
            final_rows = outdir / f"{model}-adaptive-final.rows.jsonl"
            final_rows.write_text(
                "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in selected),
                encoding="utf-8",
            )
        else:
            final_rows = final_path
        final_summary = summarize(final_rows, outdir / f"{model}-adaptive-final.summary.json")
        matrix.append(matrix_row(model, "bounded-tools-adaptive", final_summary))
        convergence.append(matrix_row(model, "initial", initial_summary))
        convergence.append(matrix_row(model, "adaptive-final", final_summary))
    fields = [
        "model", "protocol", "reasoning", "modality", "residue_rows", "resolved_rows",
        "abstained_after_budget", "hard_failures", "model_errors", "oracle_rows",
        "oracle_exact_matches", "wall_s_total",
    ]
    write_tsv(outdir / "matrix.tsv", matrix, fields)
    convergence_fields = [
        "model", "stage", "residue_rows", "resolved_rows", "abstained_after_budget",
        "hard_failures", "oracle_rows", "oracle_exact_matches", "wall_s_total",
    ]
    convergence_rows = []
    for row in convergence:
        convergence_rows.append({"model": row["model"], "stage": row["protocol"], **{field: row[field] for field in convergence_fields[2:]}})
    write_tsv(outdir / "convergence.tsv", convergence_rows, convergence_fields)


if __name__ == "__main__":
    main()
