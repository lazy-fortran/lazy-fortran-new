#!/usr/bin/env python3
"""Render E0115's complete model/protocol matrix without dropping failures."""

import argparse
import csv
import math
from pathlib import Path

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt


REQUIRED = {
    "model",
    "protocol",
    "reasoning",
    "modality",
    "residue_rows",
    "resolved_rows",
    "abstained_after_budget",
    "hard_failures",
    "model_errors",
    "oracle_rows",
    "oracle_exact_matches",
    "wall_s_total",
}


def number(value):
    if value in (None, "", "NA", "N/A", "not_applicable"):
        return math.nan
    return float(value)


def read_rows(path):
    with Path(path).open(encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        missing = REQUIRED - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(f"E0115 plot: missing columns: {sorted(missing)}")
        rows = []
        for line, row in enumerate(reader, 2):
            for field in REQUIRED - {"model", "protocol", "reasoning", "modality"}:
                try:
                    row[field] = number(row[field])
                except ValueError as exc:
                    raise SystemExit(f"E0115 plot: non-numeric row {line}: {field}") from exc
            rows.append(row)
    if not rows:
        raise SystemExit("E0115 plot: no matrix rows")
    return rows


def family_color(model):
    lower = model.lower()
    if "qwen" in lower:
        return "#35608d"
    if "gemma" in lower:
        return "#b05a3c"
    raise ValueError(f"E0115 plot: non-local model is not allowed: {model}")


def render(rows, outdir):
    mpl.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.size": 8.5,
        "axes.labelsize": 9,
        "axes.titlesize": 9.5,
        "xtick.labelsize": 6.5,
        "ytick.labelsize": 8,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.spines.top": False,
        "axes.spines.right": False,
    })
    labels = [f"{r['model']}\n{r['protocol']} / {r['reasoning']}" for r in rows]
    x = list(range(len(rows)))
    colors = [family_color(r["model"]) for r in rows]
    resolution = [
        r["resolved_rows"] / r["residue_rows"] if r["residue_rows"] else math.nan
        for r in rows
    ]
    oracle = [
        r["oracle_exact_matches"] / r["oracle_rows"] if r["oracle_rows"] else math.nan
        for r in rows
    ]
    seconds = [
        r["wall_s_total"] / r["residue_rows"]
        if r["residue_rows"] and math.isfinite(r["wall_s_total"])
        else math.nan
        for r in rows
    ]
    fig, axes = plt.subplots(3, 1, figsize=(max(10, len(rows) * 0.24), 8.0), sharex=True)
    fig.subplots_adjust(left=0.08, right=0.99, top=0.92, bottom=0.28, hspace=0.58)
    axes[0].bar(x, resolution, color=colors, width=0.8)
    axes[0].set_ylim(0, 1)
    axes[0].set_ylabel("Resolved / residue")
    axes[0].set_title("E0115 complete matrix: residue resolution")
    axes[1].bar(x, oracle, color=colors, width=0.8)
    axes[1].set_ylim(0, 1)
    axes[1].set_ylabel("Exact / oracle")
    axes[1].set_title("Solved-translation oracle accuracy")
    axes[2].bar(x, seconds, color=colors, width=0.8)
    axes[2].set_ylabel("Seconds / residue row")
    axes[2].set_title("Measured total wall time")
    axes[2].set_xticks(x, labels, rotation=55, ha="right")
    axes[2].set_xlabel("Model / protocol / reasoning; unavailable cells remain visible as gaps")
    for axis, letter in zip(axes, "abc"):
        axis.text(-0.06, 1.04, letter, transform=axis.transAxes, weight="bold")
    outdir.mkdir(parents=True, exist_ok=True)
    for suffix, kwargs in (("pdf", {}), ("svg", {}), ("png", {"dpi": 320})):
        fig.savefig(outdir / f"e0115-matrix.{suffix}", bbox_inches="tight", **kwargs)
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data", help="aggregated E0115 matrix TSV")
    parser.add_argument("--outdir", required=True)
    args = parser.parse_args()
    render(read_rows(args.data), Path(args.outdir))


if __name__ == "__main__":
    main()
