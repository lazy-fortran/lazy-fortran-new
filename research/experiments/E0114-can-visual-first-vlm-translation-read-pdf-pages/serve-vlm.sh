#!/usr/bin/env bash
set -euo pipefail

model_path="${MODEL_PATH:?MODEL_PATH is required}"
mmproj_path="${MMPROJ_PATH:?MMPROJ_PATH is required}"
port="${PORT:-8080}"
ctx="${CTX_SIZE:-8192}"
server="${LLAMA_SERVER:-$HOME/.local/bin/llama-server}"
split_mode="${SPLIT_MODE:-layer}"
main_gpu="${MAIN_GPU:-0}"
flash_attn="${FLASH_ATTN:-on}"
test -x "$server" || { echo "E0114: llama-server not executable: $server" >&2; exit 1; }

exec "$server" \
    --model "$model_path" \
    --mmproj "$mmproj_path" \
    --host 127.0.0.1 \
    --port "$port" \
    --ctx-size "$ctx" \
    --no-webui \
    --parallel 1 \
    --split-mode "$split_mode" \
    --main-gpu "$main_gpu" \
    --flash-attn "$flash_attn" \
    --reasoning off
