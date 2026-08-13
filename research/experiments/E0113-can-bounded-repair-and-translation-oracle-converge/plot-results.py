#!/usr/bin/env python3
"""Render publication-quality E0113 text and E0114 visual figures."""

import argparse
import csv
from pathlib import Path

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt


def rows(path):
    with Path(path).open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def color(family):
    return {"Qwen": "#35608d", "Gemma": "#b05a3c", "DeepSeek": "#6f4a8e", "Codex": "#4f7854"}[family]


def number(row, field):
    return float(row[field]) if row[field] else 0.0


def setup():
    mpl.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.size": 8.5,
        "axes.labelsize": 9,
        "axes.titlesize": 10,
        "xtick.labelsize": 7,
        "ytick.labelsize": 8,
        "legend.fontsize": 8,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.spines.top": False,
        "axes.spines.right": False,
    })


def text_plot(data, outdir):
    labels = [r["candidate"] for r in data]
    x = list(range(len(data)))
    colours = [color(r["family"]) for r in data]
    fig, axes = plt.subplots(3, 1, figsize=(12, 7.5), sharex=True)
    fig.subplots_adjust(left=0.08, right=0.99, top=0.91, bottom=0.25, hspace=0.55)
    axes[0].bar(x, [number(r, "accepted") for r in data], color=colours, width=0.72)
    axes[0].set_ylabel("Rows / 127")
    axes[0].set_title("E0113 full-retrieval text protocol: accepted residue rows")
    max_total = max(number(r, "residue_rows") + number(r, "hard_failures") for r in data)
    axes[0].set_ylim(0, max(8, max_total))
    for i, r in enumerate(data):
        axes[0].bar(x[i], number(r, "abstentions"), bottom=number(r, "accepted"), color="#d9d9d9", width=0.72)
        if number(r, "hard_failures"):
            axes[0].bar(x[i], number(r, "hard_failures"), bottom=number(r, "accepted") + number(r, "abstentions"), color="#9c2f2f", width=0.72)
    axes[1].bar(x, [number(r, "oracle_accuracy") for r in data], color=colours, width=0.72)
    axes[1].set_ylabel("Exact / 6")
    axes[1].set_title("Solved-translation oracle accuracy")
    axes[1].set_ylim(0, 1)
    axes[2].bar(x, [number(r, "wall_s_total") / max(number(r, "residue_rows"), 1) for r in data], color=colours, width=0.72)
    axes[2].set_ylabel("Seconds / row")
    axes[2].set_title("Measured total wall time")
    axes[2].set_xticks(x, labels, rotation=38, ha="right")
    axes[2].set_xlabel("Candidate; all runs use the same E0113 pointer-only protocol, reasoning off")
    for axis, letter in zip(axes, "abc"):
        axis.text(-0.06, 1.04, letter, transform=axis.transAxes, weight="bold")
    fig.legend(
        [plt.Rectangle((0, 0), 1, 1, color=c) for c in ("#35608d", "#b05a3c", "#6f4a8e", "#4f7854")],
        ["Qwen", "Gemma", "DeepSeek cloud", "Codex Luna"],
        loc="upper center", bbox_to_anchor=(0.5, 0.965), ncol=4, frameon=False,
    )
    for suffix, kwargs in (("pdf", {}), ("svg", {}), ("png", {"dpi": 320})):
        fig.savefig(outdir / f"e0113-text.{suffix}", bbox_inches="tight", **kwargs)
    plt.close(fig)


def visual_plot(data, outdir):
    labels = [r["candidate"] for r in data]
    x = list(range(len(data)))
    fig, axis = plt.subplots(figsize=(11, 4.6))
    fig.subplots_adjust(left=0.08, right=0.99, top=0.86, bottom=0.34)
    axis.bar(x, [number(r, "oracle_accuracy") for r in data], color=[color(r["family"]) for r in data], width=0.72)
    axis.set_ylim(0, 1)
    axis.set_ylabel("Exact target matches / 6")
    axis.set_title("E0114 visual-first PDF-page control")
    axis.set_xticks(x, labels, rotation=38, ha="right")
    axis.set_xlabel("Image-capable checkpoint; rendered page only, reasoning off")
    for i, r in enumerate(data):
        axis.text(i, number(r, "oracle_accuracy") + 0.03, f"{int(number(r, 'oracle_exact_matches'))}/6", ha="center", va="bottom", fontsize=8)
    for suffix, kwargs in (("pdf", {}), ("svg", {}), ("png", {"dpi": 320})):
        fig.savefig(outdir / f"e0114-visual.{suffix}", bbox_inches="tight", **kwargs)
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--text", required=True)
    parser.add_argument("--visual", required=True)
    parser.add_argument("--outdir", required=True)
    args = parser.parse_args()
    setup()
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    text_plot(rows(args.text), outdir)
    visual_plot(rows(args.visual), outdir)
    print(f"rendered figures to {outdir}")


if __name__ == "__main__":
    main()
