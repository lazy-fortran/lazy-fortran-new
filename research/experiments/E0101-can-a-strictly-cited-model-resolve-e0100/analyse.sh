#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
python3 "$(dirname "${BASH_SOURCE[0]}")/harness.py" \
  "${E0100_CLASSIFICATIONS:-$root/.cache/runs/E0100/R000001/classifications.tsv}" \
  "${E0100_SPANS:-$root/.cache/runs/E0100/R000001/candidate-spans.tsv}" \
  "${1:-$root/.cache/runs/E0101/R000001}"
