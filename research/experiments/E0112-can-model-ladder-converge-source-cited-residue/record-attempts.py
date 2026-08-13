#!/usr/bin/env python3
"""Assemble the E0112 plot table from immutable validation summaries."""

import argparse
import csv
import json
import math
from pathlib import Path


FIELDS = [
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
]


RUNS = [
    {
        "family": "Qwen",
        "candidate": "qwen35-2b-raw",
        "model": "Qwen/Qwen3.5-2B",
        "quantization": "Q4_K_M",
        "thinking": "off",
        "attempt": 1,
        "summary": ".cache/runs/E0111/R000001/validated/summary.tsv",
    },
    {
        "family": "Qwen",
        "candidate": "qwen35-2b-raw",
        "model": "Qwen/Qwen3.5-2B",
        "quantization": "Q4_K_M",
        "thinking": "off",
        "attempt": 2,
        "summary": ".cache/runs/E0111/R000002/validated/summary.tsv",
    },
    {
        "family": "Qwen",
        "candidate": "qwen35-4b-raw",
        "model": "Qwen/Qwen3.5-4B",
        "quantization": "Q4_K_M",
        "thinking": "off",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/qwen35-4b-q4-off-a1/validated/summary.tsv",
    },
    {
        "family": "Qwen",
        "candidate": "qwen35-4b-raw-thinking",
        "model": "Qwen/Qwen3.5-4B",
        "quantization": "Q4_K_M",
        "thinking": "on",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/qwen35-4b-q4-on-a1/validated/summary.tsv",
    },
    {
        "family": "Qwen",
        "candidate": "qwen35-4b-raw-thinking-corrected",
        "model": "Qwen/Qwen3.5-4B",
        "quantization": "Q4_K_M",
        "thinking": "on",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/qwen35-4b-q4-on-a1-correct/validated/summary.tsv",
    },
    {
        "family": "Qwen",
        "candidate": "qwen35-4b-pointer",
        "model": "Qwen/Qwen3.5-4B",
        "quantization": "Q4_K_M",
        "thinking": "off",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/qwen35-4b-q4-pointer-off-a1/validated/summary.tsv",
    },
    {
        "family": "Qwen",
        "candidate": "qwen36-35b-a3b-pointer",
        "model": "Qwen/Qwen3.6-35B-A3B",
        "quantization": "UD-Q4_K_XL",
        "thinking": "off",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/qwen36-35b-a3b-udq4xl-pointer-off-a1/validation/summary.tsv",
        "wall": ".cache/runs/E0112/R000001/qwen36-35b-a3b-udq4xl-pointer-off-a1/wall-seconds.txt",
    },
    {
        "family": "Qwen",
        "candidate": "qwen36-35b-a3b-pointer",
        "model": "Qwen/Qwen3.6-35B-A3B",
        "quantization": "UD-Q4_K_XL",
        "thinking": "off",
        "attempt": 2,
        "summary": ".cache/runs/E0112/R000001/qwen36-35b-a3b-udq4xl-pointer-off-a2/validation/summary.tsv",
        "wall": ".cache/runs/E0112/R000001/qwen36-35b-a3b-udq4xl-pointer-off-a2/wall-seconds.txt",
    },
    {
        "family": "Qwen",
        "candidate": "qwen36-27b-pointer",
        "model": "Qwen/Qwen3.6-27B",
        "quantization": "UD-Q4_K_XL",
        "thinking": "off",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/qwen36-27b-udq4xl-pointer-off-a1/validation/summary.tsv",
        "wall": ".cache/runs/E0112/R000001/qwen36-27b-udq4xl-pointer-off-a1/wall-seconds.txt",
    },
    {
        "family": "Gemma",
        "candidate": "gemma4-26b-a4b-pointer",
        "model": "google/gemma-4-26B-A4B-it",
        "quantization": "UD-Q4_K_XL",
        "thinking": "off",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/gemma4-26b-a4b-udq4xl-pointer-off-a1/validation/summary.tsv",
        "wall": ".cache/runs/E0112/R000001/gemma4-26b-a4b-udq4xl-pointer-off-a1/wall-seconds.txt",
    },
    {
        "family": "DeepSeek",
        "candidate": "deepseek-v4-flash-cloud",
        "model": "deepseek-v4-flash",
        "quantization": "cloud-api",
        "thinking": "off",
        "attempt": 1,
        "summary": ".cache/runs/E0112/R000001/deepseek-v4-flash-cloud-pointer-off-a1/validation/summary.tsv",
        "wall": ".cache/runs/E0112/R000001/deepseek-v4-flash-cloud-pointer-off-a1/wall-seconds.txt",
    },
]


def read_metrics(path):
    values = {}
    with Path(path).open(encoding="utf-8") as stream:
        for row in csv.reader(stream, delimiter="\t"):
            if len(row) == 2 and row[0] != "metric":
                values[row[0]] = int(row[1])
    required = {
        "residue_rows",
        "strict_validator_accepts",
        "strict_validator_rejects",
        "abstentions",
        "model_errors",
        "overlap_agreements",
        "overlap_disagreements",
    }
    missing = required - values.keys()
    if missing:
        raise SystemExit(f"missing metrics in {path}: {sorted(missing)}")
    return values


def wall_seconds(run):
    path = run.get("wall")
    if not path or not Path(path).exists():
        return math.nan
    return float(Path(path).read_text(encoding="utf-8").strip())


def make_row(run):
    metrics = read_metrics(run["summary"])
    accepted = metrics["strict_validator_accepts"]
    overlaps = metrics["overlap_agreements"]
    return {
        "family": run["family"],
        "candidate": run["candidate"],
        "model": run["model"],
        "quantization": run["quantization"],
        "thinking": run["thinking"],
        "attempt": run["attempt"],
        "residue_rows": metrics["residue_rows"],
        "accepted": accepted,
        "rejected": metrics["strict_validator_rejects"],
        "errors": metrics["model_errors"],
        "abstentions": metrics["abstentions"],
        "overlap_agreements": overlaps,
        "overlap_disagreements": metrics["overlap_disagreements"],
        "novel": accepted - overlaps,
        "repeat_key_agreement": 0,
        "wall_s": wall_seconds(run),
        "output_tokens": 0,
        "reliable": "no",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    rows = [make_row(run) for run in RUNS]
    path = Path(args.out)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"recorded {len(rows)} E0112 configurations in {path}")


if __name__ == "__main__":
    main()
