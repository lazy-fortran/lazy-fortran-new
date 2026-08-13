#!/usr/bin/env bash
set -euo pipefail

model_dir="${1:-/mnt/storage/lazy-fortran-models/qwen3.5-2b-q4}"
model_file="$model_dir/qwen3.5-2b-q4_k_m.gguf"
expected_sha256=b452184be7339c85516c6c468f4f3dcedd7491b40af19750f971ed8d0090800d
mkdir -p "$model_dir"

if [[ ! -f "$model_file" ]]; then
    hf download enacimie/Qwen3.5-2B-Q4_K_M-GGUF \
        --local-dir "$model_dir" \
        --include qwen3.5-2b-q4_k_m.gguf
fi
actual_sha256="$(sha256sum "$model_file" | cut -d' ' -f1)"
[[ "$actual_sha256" == "$expected_sha256" ]] || {
    echo "E0111: Qwen3.5-2B GGUF hash mismatch" >&2
    exit 1
}
printf 'model=%s\nsha256=%s\nquantization=Q4_K_M\n' "$model_file" "$actual_sha256"
