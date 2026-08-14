#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
experiment="$root/research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re"
protocol="$root/research/experiments/E0116-can-bounded-qwen-semantic-proposals-clos"
base_rows="${E0123_BASE_ROWS:-$root/.cache/runs/E0117/R000003-full/rows.jsonl}"
retry_rows="${E0123_RETRY_ROWS:?set E0123_RETRY_ROWS to the completed retry rows.jsonl}"
base_trajectory="${E0123_BASE_TRAJECTORY:-$root/.cache/runs/E0117/R000003-full/trajectory.jsonl}"
retry_trajectory="${E0123_RETRY_TRAJECTORY:?set E0123_RETRY_TRAJECTORY to the retry trajectory.jsonl}"
constraints="${E0123_CONSTRAINTS:-$root/.cache/runs/E0081/R000001/constraint-spans.tsv}"
prior="${E0123_PRIOR:-$root/.cache/runs/E0087/R000001/formalizations.tsv}"
outdir="${E0123_ANALYSIS_OUTDIR:-$root/.cache/runs/E0123/R000001/analysis}"

mkdir -p "$outdir"
python3 "$protocol/merge-retry.py" "$base_rows" "$retry_rows" \
    --replace-status unresolved --replace-status hard_failure \
    --outdir "$outdir/merged"
python3 "$protocol/validate.py" "$outdir/merged/selected-rows.jsonl" \
    --constraints "$constraints" --prior "$prior" \
    --trajectory "$base_trajectory" --trajectory "$retry_trajectory" \
    --outdir "$outdir/validate"
python3 "$protocol/witness.py" "$outdir/merged/selected-rows.jsonl" \
    --constraints "$constraints" --prior "$prior" \
    --outdir "$outdir/witness"
python3 "$experiment/report.py" "$outdir" "$retry_rows"
