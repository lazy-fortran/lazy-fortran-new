#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
protocol="$root/research/experiments/E0116-can-bounded-qwen-semantic-proposals-clos"
outdir="${E0172_OUTDIR:-$root/.cache/runs/E0172/R000001}"
base_rows="${E0172_BASE_ROWS:-$root/.cache/runs/E0117/R000003-full/rows.jsonl}"

mkdir -p "$outdir"
exec python3 "$protocol/run-semantic.py" \
    --outdir "$outdir" \
    --retry-from "$base_rows" \
    --model qwen36-35b-a3b \
    --api-url "${E0172_API_URL:-http://10.77.0.10:8080/v1/chat/completions}" \
    --require-witnesses \
    --escalate-thinking \
    --max-turns 32 \
    --max-tokens 4096 \
    --finalization-turns 3
