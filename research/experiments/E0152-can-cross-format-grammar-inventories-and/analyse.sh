#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
run_dir=${1:-"$lab_root/.cache/runs/E0152/R000001"}
mkdir -p "$run_dir"
python3 "$script_dir/analyse.py" --run-dir "$run_dir"
