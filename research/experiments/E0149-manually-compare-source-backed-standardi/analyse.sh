#!/usr/bin/env bash
set -euo pipefail

if (($# < 1 || $# > 2)); then
    printf 'usage: %s RUN-DIRECTORY [STANDARDIR-RUN]\n' "$0" >&2
    exit 2
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
lab_root=$(cd "$script_dir/../../.." && pwd)
standardir_run=${2-E0147/R000016}
exec python3 "$script_dir/analyse.py" --lab-root "$lab_root" --run-dir "$1" \
    --standard-run "$standardir_run"
