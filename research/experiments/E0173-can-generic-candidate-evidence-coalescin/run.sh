#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
RUN_DIR=${1:-"$ROOT/.cache/runs/E0173/R000001"}
CANDIDATES="$ROOT/.cache/runs/E0171/R000435-correspondence-replay/candidates.tsv"
COALESCER="$ROOT/research/experiments/E0171-can-current-standardir-grammar-projectio/coalesce-boundary-candidates.py"
SELFTEST="$ROOT/research/experiments/E0171-can-current-standardir-grammar-projectio/test-coalesce-boundary-candidates.py"

test -f "$CANDIDATES" || { echo "E0173: candidate witness is missing: $CANDIDATES" >&2; exit 2; }
test -f "$COALESCER" || { echo "E0173: coalescer is missing: $COALESCER" >&2; exit 2; }
test ! -e "$RUN_DIR" || { echo "E0173: refusing to overwrite $RUN_DIR" >&2; exit 2; }

mkdir -p "$RUN_DIR"
python3 "$SELFTEST" > "$RUN_DIR/selftest.log"
python3 "$COALESCER" \
    "$CANDIDATES" \
    "$RUN_DIR/sites.tsv" \
    "$RUN_DIR/evidence.tsv" \
    "$RUN_DIR/coalesce-summary.json" \
    > "$RUN_DIR/coalesce.stdout"

printf 'E0173 deterministic cell written to %s\n' "$RUN_DIR"
