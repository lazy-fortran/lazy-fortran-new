#!/usr/bin/env bash
set -euo pipefail

model_path="${MODEL_PATH:?MODEL_PATH is required}"
mmproj_path="${MMPROJ_PATH:?MMPROJ_PATH is required}"
port="${PORT:-8080}"
ctx="${CTX_SIZE:-8192}"

exec llama-server \
    --model "$model_path" \
    --mmproj "$mmproj_path" \
    --host 127.0.0.1 \
    --port "$port" \
    --ctx-size "$ctx" \
    --no-webui \
    --reasoning off
