#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
run_dir=${1-}
if [[ -z "$run_dir" ]]; then
    printf 'usage: %s RUN-DIRECTORY\n' "$0" >&2
    exit 2
fi
run_dir=$(cd -- "$(dirname -- "$run_dir")" && pwd)/$(basename -- "$run_dir")
mkdir -p "$run_dir"
args=(
    python3 "$script_dir/factor.py" \
    --lab-root "$lab_root" \
    --run-dir "$run_dir" \
    --grammar "$lab_root/.cache/runs/E0147/R000022/fortran2023.y"
)
if [[ -n "${2-}" ]]; then
    args+=(--representative "$2")
fi
exec "${args[@]}"
