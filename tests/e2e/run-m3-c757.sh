#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVIDENCE_ROOT="${C757_EVIDENCE_ROOT:-/home/ert/code/lazy-fortran-new}"
STANDARD="${STANDARD_NEW_ROOT:-$(cd "$ROOT/../standard-new" 2>/dev/null && pwd)}"
EXPECTED_CENTRAL_COMMIT="${M3_C757_EXPECTED_CENTRAL_COMMIT:-8985bac945b6a5cf61cbc1f660482ab5d053ea56}"
EXPECTED_STANDARD_COMMIT="f94c4c51b51fce22b533b7eeda08741970320913"
EXPECTED_FO_VERSION="0.3.2"
EXPECTED_FO_SHA256="0e9ac6a20523f9919b75569e15e830011e8b69fa649e7a8c71b54ba18f131a68"
RUN_ROOT="$ROOT/.cache/runs/E0225"
if [ "${1:-}" = "--fresh" ]; then
  n=1; while [ -e "$RUN_ROOT/R$(printf '%06d' "$n")" ]; do n=$((n+1)); done
  RUN_DIR="$RUN_ROOT/R$(printf '%06d' "$n")"
elif [ "$#" = 1 ] && [[ "$1" == .cache/runs/E0225/* ]]; then
  RUN_DIR="$ROOT/$1"
else
  echo "usage: $0 --fresh|.cache/runs/E0225/R<run>" >&2; exit 2
fi
[ ! -e "$RUN_DIR" ] || { echo "run exists: $RUN_DIR" >&2; exit 1; }
mkdir -p "$RUN_DIR"
command -v fo >/dev/null; command -v python3 >/dev/null; command -v sha256sum >/dev/null
bash -n "$0"
central_commit="$(git -C "$ROOT" rev-parse HEAD)"
[ "$central_commit" = "$EXPECTED_CENTRAL_COMMIT" ] || { echo "central revision differs: $central_commit" >&2; exit 1; }
standard_commit="$(git -C "$STANDARD" rev-parse HEAD)"
[ "$standard_commit" = "$EXPECTED_STANDARD_COMMIT" ] || { echo "standard-new revision differs: $standard_commit" >&2; exit 1; }
fo_path="$(command -v fo)"
fo_version="$(fo version | awk 'NR == 1 { print $2 }')"
fo_sha256="$(sha256sum "$fo_path" | awk '{print $1}')"
[ "$fo_version" = "$EXPECTED_FO_VERSION" ] || { echo "fo version differs: $fo_version" >&2; exit 1; }
[ "$fo_sha256" = "$EXPECTED_FO_SHA256" ] || { echo "fo hash differs: $fo_sha256" >&2; exit 1; }
python3 - "$ROOT/contracts/m3-c757-contiguous-pointer-v0.sxs" "$ROOT/contracts/fixtures/m3-c757-contiguous-pointer-v0.sx" >"$RUN_DIR/contract-structure.log" <<'PY'
import sys
from pathlib import Path
for name in sys.argv[1:]:
    text = Path(name).read_text(encoding="utf-8")
    if text.count("(") != text.count(")"):
        raise SystemExit(f"unbalanced contract file: {name}")
    if name.endswith(".sxs") and "(schema m3-c757-contiguous-pointer-v0" not in text:
        raise SystemExit("schema root missing")
    if name.endswith(".sx") and "(contract-witness" not in text:
        raise SystemExit("witness root missing")
print("C757 contract structure PASS")
PY
scripts/fetch.sh j3-24-007 >"$RUN_DIR/fetch.log"
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-clean.log" 2>&1
(cd "$STANDARD" && fo) >"$RUN_DIR/fo.log" 2>&1
(cd "$STANDARD" && fo exec --no-build sxsemantic "$ROOT/tests/fixtures/m3-c757-semantic-items.sx" "$RUN_DIR/semantic-items.canonical.sx") >"$RUN_DIR/sxsemantic.log" 2>&1
cmp "$RUN_DIR/semantic-items.canonical.sx" "$ROOT/tests/golden/m3-c757-semantic-items.sx"
C757_EVIDENCE_ROOT="$EVIDENCE_ROOT" C757_CONSTRAINT_SPANS="$EVIDENCE_ROOT/.cache/runs/E0081/R000001/constraint-spans.tsv" python3 "$ROOT/tests/e2e/validate_m3_c757.py" --self-test >"$RUN_DIR/oracle-self-test.log"
C757_EVIDENCE_ROOT="$EVIDENCE_ROOT" C757_CONSTRAINT_SPANS="$EVIDENCE_ROOT/.cache/runs/E0081/R000001/constraint-spans.tsv" python3 "$ROOT/tests/e2e/validate_m3_c757.py" \
  "$ROOT/tests/fixtures/m3-c757-source-backed-v0.json" "$ROOT/tests/fixtures/m3-c757-expected-outcomes-v0.json" \
  "$RUN_DIR/semantic-items.canonical.sx" "$EVIDENCE_ROOT/.cache/runs/E0171/R000433-provenance-replay/standardir.sx" \
  "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.pages.index" \
  "$EVIDENCE_ROOT/.cache/j3-24-007.pdf" "$ROOT/tests/golden/m3-c757-semantic-items.sx" "$RUN_DIR/result.json" >"$RUN_DIR/oracle.log"
cmp "$RUN_DIR/result.json" "$ROOT/artifacts/traces/m3-c757-source-backed-v0.json"
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-final-clean.log" 2>&1
[ ! -e "$STANDARD/build" ]
[ -z "$(git -C "$STANDARD" status --porcelain --untracked-files=normal)" ]
echo "M3 C757 PASS: $RUN_DIR"
