#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
script="$root/research/experiments/E0118-can-independently-generated-source-deriv/analyze.py"
rows="${E0117_ROWS:-$root/.cache/runs/E0117/R000003-full/rows.jsonl}"
outdir="${E0118_OUTDIR:-$root/.cache/runs/E0118/R000001}"

exec python3 "$script" "$rows" --outdir "$outdir" "$@"
