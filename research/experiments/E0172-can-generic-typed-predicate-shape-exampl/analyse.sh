#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
experiment="$root/research/experiments/E0172-can-generic-typed-predicate-shape-exampl"
predecessor="$root/research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re"
base_rows="${E0172_BASE_ROWS:-$root/.cache/runs/E0117/R000003-full/rows.jsonl}"
base_trajectory="${E0172_BASE_TRAJECTORY:-$root/.cache/runs/E0117/R000003-full/trajectory.jsonl}"
retry_rows="${E0172_RETRY_ROWS:-$root/.cache/runs/E0172/R000001/rows.jsonl}"
retry_trajectory="${E0172_RETRY_TRAJECTORY:-$root/.cache/runs/E0172/R000001/trajectory.jsonl}"
analysis_dir="${E0172_ANALYSIS_OUTDIR:-$root/.cache/runs/E0172/R000001/analysis}"

E0123_BASE_ROWS="$base_rows" \
E0123_BASE_TRAJECTORY="$base_trajectory" \
E0123_RETRY_ROWS="$retry_rows" \
E0123_RETRY_TRAJECTORY="$retry_trajectory" \
E0123_ANALYSIS_OUTDIR="$analysis_dir" \
    "$predecessor/analyse.sh"

python3 "$experiment/compare.py" \
    "$analysis_dir/report.json" \
    "$root/.cache/runs/E0123/R000001/analysis/report.json" \
    "$retry_rows" \
    "$root/.cache/runs/E0123/R000001/rows.jsonl" \
    "$retry_trajectory" \
    "$root/.cache/runs/E0123/R000001/trajectory.jsonl" \
    "$analysis_dir/comparison.json"
