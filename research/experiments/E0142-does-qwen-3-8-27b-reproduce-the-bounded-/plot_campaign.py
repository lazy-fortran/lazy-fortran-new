#!/usr/bin/env python3
"""Collect terminal experiment summaries and render one comparison figure."""

import argparse
import csv
import json
import math
from pathlib import Path

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch


ROOT = Path(__file__).resolve().parents[3]
RUNS = ROOT / ".cache" / "runs"
MISSING = {"", None, "NA", "N/A", "not_applicable"}


def number(value):
    if value in MISSING:
        return math.nan
    try:
        return float(value)
    except (TypeError, ValueError):
        return math.nan


def first(row, *names):
    for name in names:
        if name in row and row[name] not in MISSING:
            return row[name]
    return ""


def family(model):
    lower = str(model).lower()
    if "gemma" in lower:
        return "Gemma"
    if "deepseek" in lower:
        return "DeepSeek"
    if "gpt" in lower or "luna" in lower:
        return "Codex"
    if "qwen" in lower:
        return "Qwen"
    return "Other"


def normalize(row, experiment, modality, source, default_protocol):
    model = str(first(row, "model", "candidate") or "unknown")
    candidate = str(first(row, "candidate", "model") or model)
    protocol = str(first(row, "protocol") or default_protocol)
    reasoning = str(first(row, "thinking", "reasoning") or "off")
    denominator = number(first(row, "residue_rows", "eligible_constraints", "oracle_rows", "overlap_rows"))
    accepted = number(first(row, "accepted", "resolved_rows", "schema_accepted_rows",
                            "strict_validator_accepts", "exact_target_matches"))
    unresolved = number(first(row, "unresolved_rows", "abstained_after_budget", "abstentions"))
    failures = number(first(row, "hard_failures", "errors", "strict_validator_rejects"))
    model_errors = number(first(row, "model_errors"))
    oracle_rows = number(first(row, "oracle_rows"))
    oracle_exact = number(first(row, "oracle_exact_matches", "exact_target_matches", "overlap_agreements"))
    wall = number(first(row, "wall_s_total", "wall_s"))
    tokens = number(first(row, "total_tokens", "output_tokens"))
    return {
        "experiment": experiment,
        "modality": modality,
        "family": family(model),
        "candidate": candidate,
        "model": model,
        "protocol": protocol,
        "reasoning": reasoning,
        "denominator": denominator,
        "accepted": accepted,
        "unresolved": unresolved,
        "hard_failures": failures,
        "model_errors": model_errors,
        "oracle_rows": oracle_rows,
        "oracle_exact": oracle_exact,
        "wall_s": wall,
        "tokens": tokens,
        "source": str(source),
    }


def read_tsv(path, experiment, modality, default_protocol):
    with path.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    if experiment == "E0112" and path.name == "aggregated.tsv":
        for row in rows:
            # The historical aggregate predates the common schema and omits
            # the fixed E0112 denominator. It is still a valid terminal table.
            row.setdefault("residue_rows", "127")
    return [normalize(row, experiment, modality, path, default_protocol)
            for row in rows]


def read_metric_tsv(path, experiment, modality, default_protocol):
    metrics = {}
    with path.open(encoding="utf-8", newline="") as stream:
        for row in csv.reader(stream, delimiter="\t"):
            if len(row) == 2 and row[0] != "metric":
                metrics[row[0]] = row[1]
    config_path = path.parent.parent / "api-config.json"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        config = {}
    row = {**metrics, **config}
    wall_path = path.parent.parent / "wall-seconds.txt"
    if wall_path.exists():
        row["wall_s_total"] = wall_path.read_text(encoding="utf-8").strip()
    else:
        progress_path = path.parent.parent / "progress.json"
        try:
            progress = json.loads(progress_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            progress = {}
        if "elapsed_s" in progress:
            row["wall_s_total"] = progress["elapsed_s"]
    return [normalize(row, experiment, modality, path, default_protocol)]


def read_json(path, experiment, modality, default_protocol):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if not isinstance(data, dict):
        return []
    if experiment == "E0116" and "eligible_constraints" not in data:
        return []
    if experiment in {"E0117", "E0123"} and "schema_accepted_rows" not in data:
        return []
    return [normalize(data, experiment, modality, path, default_protocol)]


def collect(experiment):
    root = RUNS / experiment
    if not root.exists():
        return []
    rows = []
    if experiment == "E0112":
        for path in sorted(root.rglob("aggregated.tsv")):
            rows.extend(read_tsv(path, experiment, "text", "fixed-pointer"))
        for path in sorted(root.rglob("validation/summary.tsv")):
            rows.extend(read_metric_tsv(path, experiment, "text", "fixed-pointer"))
    elif experiment == "E0113":
        for path in sorted(root.rglob("analysis/text.tsv")):
            rows.extend(read_tsv(path, experiment, "text", "full-retrieval"))
        for path in sorted(root.rglob("summary.json")):
            rows.extend(read_json(path, experiment, "text", "full-retrieval"))
    elif experiment == "E0114":
        for path in sorted((RUNS / "E0113").rglob("analysis/visual.tsv")):
            rows.extend(read_tsv(path, experiment, "visual", "visual-first"))
        for path in sorted(root.rglob("summary.json")):
            rows.extend(read_json(path, experiment, "visual", "visual-first"))
    elif experiment == "E0115":
        for path in sorted(root.rglob("matrix.tsv")):
            rows.extend(read_tsv(path, experiment, "text", "bounded-tools"))
    elif experiment == "E0116":
        for path in sorted(root.rglob("summary.json")):
            rows.extend(read_json(path, experiment, "semantic", "typed-predicate"))
    elif experiment == "E0117":
        for path in sorted(root.rglob("summary.json")):
            if (path.parent / "rows.jsonl").exists():
                rows.extend(read_json(path, experiment, "semantic", "required-witness"))
    elif experiment == "E0123":
        for path in sorted(root.rglob("summary.json")):
            if (path.parent / "rows.jsonl").exists():
                rows.extend(read_json(path, experiment, "semantic", "residual-retry"))
    else:
        raise SystemExit(f"unknown experiment: {experiment}")

    unique = {}
    for row in rows:
        key = (row["candidate"], row["model"], row["protocol"], row["reasoning"], row["modality"])
        unique[key] = row
    return list(unique.values())


def write_normalized(path, rows):
    fields = [
        "experiment", "modality", "family", "candidate", "model", "protocol",
        "reasoning", "denominator", "accepted", "unresolved", "hard_failures",
        "model_errors", "oracle_rows", "oracle_exact", "wall_s", "tokens", "source",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def render(experiment, rows, outdir):
    if not rows:
        raise SystemExit(f"{experiment}: no terminal summaries found")
    mpl.rcParams.update({
        "font.family": "DejaVu Sans", "font.size": 8.5,
        "axes.labelsize": 9, "axes.titlesize": 10,
        "xtick.labelsize": 7, "ytick.labelsize": 8,
        "pdf.fonttype": 42, "ps.fonttype": 42,
        "axes.spines.top": False, "axes.spines.right": False,
    })
    palette = {"Qwen": "#0072B2", "Gemma": "#E69F00", "DeepSeek": "#009E73",
               "Codex": "#CC79A7", "Other": "#666666"}
    labels = [f"{r['candidate']}\n{r['protocol']} / {r['reasoning']}" for r in rows]
    x = list(range(len(rows)))
    rates = []
    failures = []
    oracle = []
    cost = []
    for row in rows:
        denominator = row["denominator"]
        rates.append(row["accepted"] / denominator if denominator and math.isfinite(denominator) else math.nan)
        # These protocol counters are not mutually exclusive: a rejected
        # proposal can also be counted in the row's abstention/error tally.
        # Use the disjoint complement of strict acceptance rather than adding
        # overlapping counters and producing rates above 100 percent.
        failures.append((denominator - row["accepted"]) / denominator
                         if denominator and math.isfinite(denominator)
                         and math.isfinite(row["accepted"]) else math.nan)
        oracle.append(row["oracle_exact"] / row["oracle_rows"]
                      if row["oracle_rows"] and math.isfinite(row["oracle_rows"]) else math.nan)
        cost.append(row["wall_s"] / denominator
                    if denominator and math.isfinite(row["wall_s"]) else math.nan)
    colors = [palette.get(row["family"], palette["Other"]) for row in rows]
    fig, axes = plt.subplots(4, 1, figsize=(max(10, len(rows) * 0.26), 9.5), sharex=True)
    fig.subplots_adjust(left=0.09, right=0.99, top=0.93, bottom=0.30, hspace=0.62)
    axes[0].bar(x, rates, color=colors, width=0.78)
    axes[0].set_ylim(0, 1); axes[0].set_ylabel("Accepted / eligible")
    axes[0].set_title(f"{experiment} comparison: strict accepted rate")
    axes[1].bar(x, failures, color="#999999", width=0.78)
    axes[1].set_ylim(bottom=0); axes[1].set_ylabel("Failure / eligible")
    axes[1].set_title("Not accepted / eligible (all terminal failure modes)")
    axes[2].bar(x, oracle, color=colors, width=0.78)
    axes[2].set_ylim(0, 1); axes[2].set_ylabel("Exact / oracle")
    axes[2].set_title("Independent solved-oracle accuracy; unavailable cells remain gaps")
    axes[3].bar(x, cost, color=colors, width=0.78)
    axes[3].set_yscale("log"); axes[3].set_ylabel("Seconds / eligible row")
    axes[3].set_title("Measured wall time")
    axes[3].set_xticks(x, labels, rotation=58, ha="right")
    axes[3].set_xlabel("Model / protocol / reasoning; colors identify model family")
    for axis, letter in zip(axes, "abcd"):
        axis.text(-0.065, 1.04, letter, transform=axis.transAxes, weight="bold")
    present = [name for name in ("Qwen", "Gemma", "DeepSeek", "Codex", "Other")
               if any(row["family"] == name for row in rows)]
    fig.legend(
        [Patch(facecolor=palette[name], edgecolor="none") for name in present],
        present, loc="upper center", bbox_to_anchor=(0.5, 0.985),
        ncol=min(5, len(present)), frameon=False,
    )
    outdir.mkdir(parents=True, exist_ok=True)
    stem = f"{experiment.lower()}-comparison"
    fig.savefig(outdir / f"{stem}.png", dpi=320, bbox_inches="tight")
    fig.savefig(outdir / f"{stem}.pdf", bbox_inches="tight")
    fig.savefig(outdir / f"{stem}.svg", bbox_inches="tight")
    plt.close(fig)


def main(default_experiment=None):
    global RUNS
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--experiment", default=default_experiment, required=default_experiment is None)
    parser.add_argument("--runs-root", default=str(RUNS))
    parser.add_argument("--outdir", default="")
    args = parser.parse_args()
    RUNS = Path(args.runs_root).resolve()
    rows = collect(args.experiment)
    outdir = Path(args.outdir) if args.outdir else RUNS / "E0142" / "plots" / args.experiment
    write_normalized(outdir / "normalized.tsv", rows)
    render(args.experiment, rows, outdir)
    print(f"{args.experiment}: rendered {len(rows)} comparison rows to {outdir}")


if __name__ == "__main__":
    main()
