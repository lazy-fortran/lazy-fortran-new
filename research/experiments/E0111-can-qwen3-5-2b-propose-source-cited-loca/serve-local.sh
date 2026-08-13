#!/usr/bin/env bash
set -euo pipefail

model_dir="${1:-/mnt/storage/lazy-fortran-models/qwen3.5-2b-q4}"
model="$model_dir/qwen3.5-2b-q4_k_m.gguf"
server="${LLAMA_SERVER:-$HOME/.local/bin/llama-server}"
port="${PORT:-8080}"
test -x "$server" || { echo "E0111: llama-server not executable: $server" >&2; exit 1; }
test -f "$model" || { echo "E0111: model absent; run fetch-model.sh first" >&2; exit 1; }

exec "$server" \
    --model "$model" \
    --alias Qwen/Qwen3.5-2B \
    --host 127.0.0.1 \
    --port "$port" \
    --ctx-size 8192 \
    --parallel 1 \
    --seed 1101 \
    --temp 0 \
    --top-p 1
