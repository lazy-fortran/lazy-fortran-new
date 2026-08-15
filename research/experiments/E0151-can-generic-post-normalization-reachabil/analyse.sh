#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
run_dir=${1:-"$lab_root/.cache/runs/E0151/R000001-baseline"}
grammar=${2:-"$lab_root/.cache/runs/E0147/R000022/fortran2023.y"}
mkdir -p "$run_dir"
python3 "$script_dir/analyse.py" --grammar "$grammar" --output "$run_dir"
