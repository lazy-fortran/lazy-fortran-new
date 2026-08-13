#!/usr/bin/env bash
set -euo pipefail

model="${MODEL_PATH:-/mnt/storage/lazy-fortran-models/qwen3.5-2b-q4/qwen3.5-2b-q4_k_m.gguf}"
alias="${MODEL_ALIAS:-Qwen/Qwen3.5-2B}"
server="${LLAMA_SERVER:-$HOME/.local/bin/llama-server}"
port="${PORT:-8080}"
ctx_size="${CTX_SIZE:-4096}"
reasoning="${REASONING:-off}"
split_mode="${SPLIT_MODE:-layer}"
main_gpu="${MAIN_GPU:-0}"
flash_attn="${FLASH_ATTN:-on}"
test -x "$server" || { echo "E0111: llama-server not executable: $server" >&2; exit 1; }
test -f "$model" || { echo "E0111: model absent; run fetch-model.sh first" >&2; exit 1; }

exec "$server" \
    --model "$model" \
    --alias "$alias" \
    --host 127.0.0.1 \
    --port "$port" \
    --ctx-size "$ctx_size" \
    --parallel 1 \
    --seed 1101 \
    --temp 0 \
    --top-p 1 \
    --fit off \
    --split-mode "$split_mode" \
    --main-gpu "$main_gpu" \
    --flash-attn "$flash_attn" \
    --reasoning "$reasoning"
