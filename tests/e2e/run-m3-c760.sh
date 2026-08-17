#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVIDENCE_ROOT="${C760_EVIDENCE_ROOT:-/home/ert/code/lazy-fortran-new}"
STANDARD="${STANDARD_NEW_ROOT:-$(cd "$ROOT/../standard-new" 2>/dev/null && pwd)}"
RUN_ROOT="$ROOT/.cache/runs/E0225"
if [ "${1:-}" = "--fresh" ]; then
  n=1; while [ -e "$RUN_ROOT/R$(printf '%06d' "$n")" ]; do n=$((n+1)); done
  RUN_DIR="$RUN_ROOT/R$(printf '%06d' "$n")"
elif [ "$#" = 1 ] && [[ "$1" == .cache/runs/E0225/* ]]; then RUN_DIR="$ROOT/$1"
else echo "usage: $0 --fresh|.cache/runs/E0225/R<run>" >&2; exit 2; fi
[ ! -e "$RUN_DIR" ] || { echo "run exists: $RUN_DIR" >&2; exit 1; }
mkdir -p "$RUN_DIR"
command -v fo >/dev/null; command -v python3 >/dev/null; command -v sha256sum >/dev/null
bash -n "$0"
scripts/check-contracts.sh >"$RUN_DIR/check-contracts.log"
scripts/fetch.sh j3-24-007 >"$RUN_DIR/fetch.log"
[ -d "$STANDARD" ] || { echo "missing standard-new: $STANDARD" >&2; exit 1; }
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-clean.log" 2>&1
(cd "$STANDARD" && fo) >"$RUN_DIR/fo.log" 2>&1
(cd "$STANDARD" && fo exec --no-build sxsemantic "$ROOT/tests/fixtures/m3-c760-semantic-items.sx" "$RUN_DIR/semantic-items.canonical.sx") >"$RUN_DIR/sxsemantic.log" 2>&1
cmp "$RUN_DIR/semantic-items.canonical.sx" "$ROOT/tests/golden/m3-c760-semantic-items.sx"
C760_EVIDENCE_ROOT="$EVIDENCE_ROOT" C760_CONSTRAINT_SPANS="$EVIDENCE_ROOT/.cache/runs/E0081/R000001/constraint-spans.tsv" python3 "$ROOT/tests/e2e/validate_m3_c760.py" --self-test >"$RUN_DIR/oracle-self-test.log"
C760_EVIDENCE_ROOT="$EVIDENCE_ROOT" C760_CONSTRAINT_SPANS="$EVIDENCE_ROOT/.cache/runs/E0081/R000001/constraint-spans.tsv" python3 "$ROOT/tests/e2e/validate_m3_c760.py" \
  "$ROOT/tests/fixtures/m3-c760-source-backed-v0.json" "$ROOT/tests/fixtures/m3-c760-expected-outcomes-v0.json" \
  "$RUN_DIR/semantic-items.canonical.sx" "$EVIDENCE_ROOT/.cache/runs/E0171/R000433-provenance-replay/standardir.sx" \
  "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.pages.index" \
  "$EVIDENCE_ROOT/.cache/j3-24-007.pdf" "$ROOT/tests/golden/m3-c760-semantic-items.sx" "$RUN_DIR/result.json" >"$RUN_DIR/oracle.log"
TRACE="$ROOT/artifacts/traces/m3-c760-source-backed-v0.json"
[ -f "$TRACE" ] || { echo "missing committed C760 trace: $TRACE" >&2; exit 1; }
cmp "$RUN_DIR/result.json" "$TRACE"
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-final-clean.log" 2>&1
[ ! -e "$STANDARD/build" ]
[ -z "$(git -C "$STANDARD" status --porcelain --untracked-files=normal)" ]
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ]
echo "M3 C760 PASS: $RUN_DIR"
