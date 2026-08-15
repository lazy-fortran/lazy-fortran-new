#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
run_dir=${1:-"$lab_root/.cache/runs/E0154/R000001"}
source_sx=${2:-"$lab_root/.cache/runs/E0147/R000022/input/standardir.sx"}
mkdir -p "$run_dir"
python3 "$script_dir/validate_identity.py" \
    --source "$source_sx" --run "$run_dir" \
    --report "$run_dir/source-expression-identity.tsv"
