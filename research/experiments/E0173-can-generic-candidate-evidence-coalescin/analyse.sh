#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
RUN_DIR=${1:-"$ROOT/.cache/runs/E0173/R000001"}
python3 "$ROOT/research/experiments/E0173-can-generic-candidate-evidence-coalescin/validate.py" "$RUN_DIR"
