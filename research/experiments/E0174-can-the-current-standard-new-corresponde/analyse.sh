#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
RUN_DIR=${1:-"$ROOT/.cache/runs/E0174/R000001"}
if [[ "$RUN_DIR" != /* ]]; then RUN_DIR="$ROOT/$RUN_DIR"; fi
python3 "$ROOT/research/experiments/E0174-can-the-current-standard-new-corresponde/validate.py" "$RUN_DIR"
