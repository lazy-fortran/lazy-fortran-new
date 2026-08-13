#!/usr/bin/env python3
"""Render the publication figure from the append-only E0112 summary table."""

import argparse
import csv
import math
from collections import defaultdict
from pathlib import Path

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D


REQUIRED = {
    "family",
    "candidate",
    "model",
    "quantization",
    "thinking",
    "attempt",
    "residue_rows",
    "accepted",
    "rejected",
    "errors",
    "abstentions",
    "overlap_agreements",
    "overlap_disagreements",
    "novel",
    "repeat_key_agreement",
    "wall_s",
    "output_tokens",
    "reliable",
}
NUMERIC = {
    "attempt",
    "residue_rows",
    "accepted",
    "rejected",
    "errors",
    "abstentions",
    "overlap_agreements",
    "overlap_disagreements",
    "novel",
    "repeat_key_agreement",
    "wall_s",
    "output_tokens",
}


def args_parser():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data", help="E0112 attempt summary TSV")
    parser.add_argument("--outdir", required=True, help="ignored output directory")
    return parser


def read_rows(path):
    try:
        with Path(path).open(encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream, delimiter="\t")
            missing = REQUIRED - set(reader.fieldnames or [])
            if missing:
                raise SystemExit(f"E0112 plot: missing columns: {sorted(missing)}")
            rows = []
            for line_number, row in enumerate(reader, 2):
                try:
                    for field in NUMERIC:
                        row[field] = float(row[field])
                except ValueError as exc:
                    raise SystemExit(f"E0112 plot: non-numeric row {line_number}") from exc
                rows.append(row)
    except OSError as exc:
        raise SystemExit(f"E0112 plot: cannot read {path}: {exc}") from exc
    if not rows:
        raise SystemExit("E0112 plot: no attempt rows")
    return rows


def aggregate(rows):
    groups = defaultdict(list)
    for row in rows:
        key = (row["family"], row["candidate"], row["model"], row["quantization"], row["thinking"])
        groups[key].append(row)
    result = []
    for key, values in groups.items():
        family, candidate, model, quantization, thinking = key
        item = {
            "family": family,
            "candidate": candidate,
            "model": model,
            "quantization": quantization,
            "thinking": thinking,
            "attempts": len(values),
            "reliable": all(row["reliable"].lower() == "yes" for row in values),
        }
        for field in NUMERIC - {"attempt", "repeat_key_agreement"}:
            item[field] = sum(row[field] for row in values) / len(values)
        item["repeat_key_agreement"] = min(row["repeat_key_agreement"] for row in values)
        result.append(item)
    result.sort(key=lambda row: (0 if row["family"].lower() == "qwen" else 1, row["candidate"], row["quantization"], row["thinking"]))
    return result


def write_aggregate(path, rows):
    fields = [
        "family", "candidate", "model", "quantization", "thinking", "attempts",
        "accepted", "rejected", "errors", "abstentions", "overlap_agreements",
        "overlap_disagreements", "novel", "repeat_key_agreement", "wall_s",
        "output_tokens", "reliable",
    ]
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def render(rows, outdir):
    mpl.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.size": 8.5,
        "axes.labelsize": 9,
        "axes.titlesize": 9.5,
        "xtick.labelsize": 7,
        "ytick.labelsize": 8,
        "legend.fontsize": 8,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.spines.top": False,
        "axes.spines.right": False,
    })
    short_labels = {
        "qwen35-2b-raw": "Qwen 3.5\n2B raw",
        "qwen35-4b-raw": "Qwen 3.5\n4B raw",
        "qwen35-4b-raw-thinking": "Qwen 3.5\n4B raw + think",
        "qwen35-4b-raw-thinking-corrected": "Qwen 3.5\n4B raw + think*",
        "qwen35-4b-pointer": "Qwen 3.5\n4B pointer",
        "qwen36-35b-a3b-pointer": "Qwen 3.6\n35B-A3B pointer",
        "qwen36-27b-pointer": "Qwen 3.6\n27B pointer",
        "gemma4-26b-a4b-pointer": "Gemma 4\n26B-A4B pointer",
    }
    labels = [short_labels.get(row["candidate"], row["candidate"]) for row in rows]
    x = list(range(len(rows)))
    qwen = [row["family"].lower() == "qwen" for row in rows]
    colors = [
        "#35608d" if row["family"].lower() == "qwen"
        else "#6f4a8e" if row["family"].lower() == "deepseek"
        else "#b05a3c"
        for row in rows
    ]
    width = 9.5
    fig, axes = plt.subplots(3, 1, figsize=(width, 7.4), sharex=True)
    fig.subplots_adjust(left=0.08, right=0.99, top=0.88, bottom=0.22, hspace=0.62)

    accepted = [row["accepted"] for row in rows]
    novel = [row["novel"] for row in rows]
    axes[0].bar(x, accepted, color=colors, width=0.72, alpha=0.86, label="strictly accepted")
    axes[0].scatter(x, novel, color="#1f1f1f", marker="o", s=18, zorder=3, label="novel accepted")
    axes[0].set_ylabel("Rows / 127")
    axes[0].set_title("Source-cited residue resolution")
    axes[0].set_ylim(bottom=0)
    axes[0].legend(loc="upper left", bbox_to_anchor=(0.0, 0.98), frameon=False, ncol=2)

    rejected = [row["rejected"] for row in rows]
    errors = [row["errors"] for row in rows]
    abstentions = [max(0.0, row["abstentions"] - row["rejected"] - row["errors"]) for row in rows]
    axes[1].bar(x, abstentions, color="#d9d9d9", width=0.72, label="abstentions")
    axes[1].bar(x, rejected, bottom=abstentions, color="#e6a33a", width=0.72, label="validator rejects")
    axes[1].bar(x, errors, bottom=[a + r for a, r in zip(abstentions, rejected)], color="#9c2f2f", width=0.72, label="model errors")
    axes[1].set_ylabel("Rows / 127")
    axes[1].set_title("Why a residue row was not accepted")
    axes[1].set_ylim(0, 127)
    axes[1].legend(loc="upper left", bbox_to_anchor=(0.0, 0.98), frameon=False, ncol=3)

    finite_wall = [
        row["wall_s"] / max(row["residue_rows"], 1)
        for row in rows
        if math.isfinite(row["wall_s"])
    ]
    floor = min(finite_wall) * 0.5 if finite_wall else 1e-3
    wall = [
        row["wall_s"] / max(row["residue_rows"], 1)
        if math.isfinite(row["wall_s"])
        else math.nan
        for row in rows
    ]
    axes[2].bar(x, wall, color=colors, width=0.72, alpha=0.86)
    axes[2].set_yscale("log")
    axes[2].set_ylim(bottom=floor)
    axes[2].set_ylabel("Seconds / row")
    axes[2].set_title("Measured local inference cost")
    axes[2].set_xticks(x, labels, rotation=32, ha="right")
    axes[2].set_xlabel("Candidate, quantization, reasoning mode")
    for index, value in enumerate(wall):
        if not math.isfinite(value):
            axes[2].text(index, floor * 1.15, "n/a", ha="center", va="bottom", rotation=90, fontsize=7)
    for index, row in enumerate(rows):
        if row["reliable"]:
            axes[2].scatter(index, wall[index], marker="*", s=56, color="#111111", zorder=4)

    axes[0].text(-0.075, 1.04, "a", transform=axes[0].transAxes, weight="bold")
    axes[1].text(-0.075, 1.04, "b", transform=axes[1].transAxes, weight="bold")
    axes[2].text(-0.075, 1.04, "c", transform=axes[2].transAxes, weight="bold")
    handles = [
        Line2D([0], [0], color="#35608d", lw=6, label="Qwen"),
        Line2D([0], [0], color="#b05a3c", lw=6, label="Gemma"),
        Line2D([0], [0], color="#6f4a8e", lw=6, label="DeepSeek cloud"),
        Line2D([0], [0], marker="*", color="#111111", lw=0, markersize=8, label="reliable configuration"),
    ]
    fig.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, 0.965), ncol=3, frameon=False)
    outdir.mkdir(parents=True, exist_ok=True)
    fig.savefig(outdir / "convergence.pdf", bbox_inches="tight")
    fig.savefig(outdir / "convergence.svg", bbox_inches="tight")
    fig.savefig(outdir / "convergence.png", dpi=320, bbox_inches="tight")
    plt.close(fig)


def main():
    args = args_parser().parse_args()
    rows = aggregate(read_rows(args.data))
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    write_aggregate(outdir / "aggregated.tsv", rows)
    render(rows, outdir)
    print(f"rendered {len(rows)} configurations to {outdir}")


if __name__ == "__main__":
    main()
