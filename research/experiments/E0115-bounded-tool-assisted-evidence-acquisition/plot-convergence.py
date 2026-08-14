#!/usr/bin/env python3
"""Render the initial-to-retry convergence of an E0115 model cell."""

import argparse
import csv
import math
from pathlib import Path

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt


REQUIRED = {
    "model",
    "stage",
    "residue_rows",
    "resolved_rows",
    "abstained_after_budget",
    "hard_failures",
    "oracle_rows",
    "oracle_exact_matches",
    "wall_s_total",
}


def read_rows(path):
    with Path(path).open(encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        missing = REQUIRED - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(f"E0115 convergence plot: missing columns: {sorted(missing)}")
        rows = []
        for line, row in enumerate(reader, 2):
            for field in REQUIRED - {"model", "stage"}:
                try:
                    row[field] = float(row[field])
                except ValueError as exc:
                    raise SystemExit(
                        f"E0115 convergence plot: non-numeric row {line}: {field}"
                    ) from exc
            rows.append(row)
    if not rows:
        raise SystemExit("E0115 convergence plot: no rows")
    return rows


def family_color(model):
    lower = model.lower()
    if "qwen" in lower:
        return "#35608d"
    if "gemma" in lower:
        return "#b05a3c"
    raise ValueError(f"E0115 convergence plot: non-local model is not allowed: {model}")


def fraction(row, numerator, denominator):
    value = row[numerator]
    total = row[denominator]
    return value / total if total else math.nan


def render(rows, outdir):
    mpl.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 8.5,
            "axes.labelsize": 9,
            "axes.titlesize": 9.5,
            "xtick.labelsize": 7,
            "ytick.labelsize": 8,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "axes.spines.top": False,
            "axes.spines.right": False,
        }
    )
    models = list(dict.fromkeys(row["model"] for row in rows))
    stages = list(dict.fromkeys(row["stage"] for row in rows))
    x = list(range(len(models)))
    stage_width = 0.78 / max(len(stages), 1)
    fig, axes = plt.subplots(3, 1, figsize=(max(8.0, len(models) * 0.72), 7.2), sharex=True)
    fig.subplots_adjust(left=0.09, right=0.99, top=0.91, bottom=0.20, hspace=0.52)
    for stage_index, stage in enumerate(stages):
        stage_rows = {row["model"]: row for row in rows if row["stage"] == stage}
        offsets = [value - 0.39 + stage_width / 2 + stage_index * stage_width for value in x]
        values = [
            fraction(stage_rows[model], "resolved_rows", "residue_rows")
            if model in stage_rows
            else math.nan
            for model in models
        ]
        axes[0].bar(offsets, values, width=stage_width, label=stage)
        oracle_values = [
            fraction(stage_rows[model], "oracle_exact_matches", "oracle_rows")
            if model in stage_rows
            else math.nan
            for model in models
        ]
        axes[1].bar(offsets, oracle_values, width=stage_width)
        failure_values = [
            (
                stage_rows[model]["abstained_after_budget"]
                + stage_rows[model]["hard_failures"]
            )
            / stage_rows[model]["residue_rows"]
            if model in stage_rows and stage_rows[model]["residue_rows"]
            else math.nan
            for model in models
        ]
        axes[2].bar(offsets, failure_values, width=stage_width)
    axes[0].set_ylim(0, 1)
    axes[0].set_ylabel("Resolved / residue")
    axes[0].set_title("E0115 convergence: deterministic gate acceptance")
    axes[1].set_ylim(0, 1)
    axes[1].set_ylabel("Exact / oracle")
    axes[1].set_title("Solved-translation oracle accuracy")
    axes[2].set_ylim(0, 1)
    axes[2].set_ylabel("Terminal failures / residue")
    axes[2].set_title("Abstentions plus hard failures")
    axes[2].set_xticks(x, models, rotation=35, ha="right")
    axes[2].set_xlabel("Local model; bars are initial and bounded-retry stages")
    axes[0].legend(frameon=False, ncol=min(3, len(stages)), loc="upper right")
    for axis, letter in zip(axes, "abc"):
        axis.text(-0.06, 1.04, letter, transform=axis.transAxes, weight="bold")
    outdir.mkdir(parents=True, exist_ok=True)
    for suffix, kwargs in (("pdf", {}), ("svg", {}), ("png", {"dpi": 320})):
        fig.savefig(outdir / f"e0115-convergence.{suffix}", bbox_inches="tight", **kwargs)
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data", help="convergence TSV")
    parser.add_argument("--outdir", required=True)
    args = parser.parse_args()
    render(read_rows(args.data), Path(args.outdir))


if __name__ == "__main__":
    main()
