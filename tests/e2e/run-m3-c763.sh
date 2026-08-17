#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVIDENCE_ROOT="${C763_EVIDENCE_ROOT:-/home/ert/code/lazy-fortran-new}"
STANDARD="${STANDARD_NEW_ROOT:-$(cd "$ROOT/../standard-new" 2>/dev/null && pwd)}"
EXPECTED_CENTRAL_COMMIT="${M3_C763_EXPECTED_CENTRAL_COMMIT:-}"
EXPECTED_STANDARD_COMMIT="f94c4c51b51fce22b533b7eeda08741970320913"
RUN_ROOT="$ROOT/.cache/runs/E0231"
if [ "${1:-}" = "--fresh" ]; then
  n=1; while [ -e "$RUN_ROOT/R$(printf '%06d' "$n")" ]; do n=$((n + 1)); done
  RUN_DIR="$RUN_ROOT/R$(printf '%06d' "$n")"
elif [ "$#" = 1 ] && [[ "$1" == .cache/runs/E0231/* ]]; then
  RUN_DIR="$ROOT/$1"
else
  echo "usage: $0 --fresh|.cache/runs/E0231/R<run>" >&2; exit 2
fi
[ ! -e "$RUN_DIR" ] || { echo "run exists: $RUN_DIR" >&2; exit 1; }
mkdir -p "$RUN_DIR"
command -v fo >/dev/null; command -v python3 >/dev/null; command -v sha256sum >/dev/null
bash -n "$0"
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ] || { echo "checkout is not clean" >&2; exit 1; }
central_commit="$(git -C "$ROOT" rev-parse HEAD)"
[ -z "$EXPECTED_CENTRAL_COMMIT" ] || [ "$central_commit" = "$EXPECTED_CENTRAL_COMMIT" ] || { echo "central revision differs: $central_commit" >&2; exit 1; }
standard_commit="$(git -C "$STANDARD" rev-parse HEAD)"
[ "$standard_commit" = "$EXPECTED_STANDARD_COMMIT" ] || { echo "standard-new revision differs: $standard_commit" >&2; exit 1; }
scripts/check-contracts.sh >"$RUN_DIR/check-contracts.log"
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-clean.log" 2>&1
(cd "$STANDARD" && fo) >"$RUN_DIR/fo.log" 2>&1
(cd "$STANDARD" && fo exec --no-build sxsemantic "$ROOT/tests/fixtures/m3-c763-semantic-items.sx" "$RUN_DIR/semantic-items.canonical.sx") >"$RUN_DIR/sxsemantic.log" 2>&1
cmp "$RUN_DIR/semantic-items.canonical.sx" "$ROOT/tests/fixtures/m3-c763-semantic-items.sx"
C763_EVIDENCE_ROOT="$EVIDENCE_ROOT" python3 "$ROOT/tests/e2e/validate_m3_c763.py" --self-test >"$RUN_DIR/oracle-self-test.log"
C763_EVIDENCE_ROOT="$EVIDENCE_ROOT" python3 "$ROOT/tests/e2e/validate_m3_c763.py" "$ROOT/tests/fixtures/m3-c763-source-backed-v0.json" "$ROOT/tests/fixtures/m3-c763-expected-outcomes-v0.json" "$RUN_DIR/semantic-items.canonical.sx" "$EVIDENCE_ROOT/.cache/runs/E0171/R000433-provenance-replay/standardir.sx" "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.pages.index" "$EVIDENCE_ROOT/.cache/j3-24-007.pdf" "$ROOT/tests/fixtures/m3-c763-semantic-items.sx" "$RUN_DIR/result.json" >"$RUN_DIR/oracle.log"
[ -f "$ROOT/artifacts/traces/m3-c763-source-backed-v0.json" ]
cmp "$RUN_DIR/result.json" "$ROOT/artifacts/traces/m3-c763-source-backed-v0.json"
python3 - "$RUN_DIR/run-environment.json" "$central_commit" "$standard_commit" "$ROOT/tests/e2e/validate_m3_c763.py" <<'PY'
import hashlib, json, platform, subprocess, sys
from pathlib import Path
output, central, standard, validator = sys.argv[1:]
def first(command):
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    return (result.stdout + result.stderr).splitlines()[0]
record = {"central": {"repository": "lazy-fortran-new", "commit": central}, "standard_new": {"repository": "standard-new", "commit": standard}, "toolchain": {"python": first(["python3", "--version"]), "git": first(["git", "--version"]), "compiler": first(["gfortran", "--version"]), "poppler": first(["pdftotext", "-v"])}, "environment": {"os": platform.system(), "architecture": platform.machine(), "python_version": platform.python_version()}, "oracle_sha256": hashlib.sha256(Path(validator).read_bytes()).hexdigest(), "commands": ["M3_C763_EXPECTED_CENTRAL_COMMIT=<pinned-central> C763_EVIDENCE_ROOT=<evidence-root> STANDARD_NEW_ROOT=<standard-new-root> tests/e2e/run-m3-c763.sh --fresh", "scripts/check-contracts.sh", "python3 tests/e2e/validate_m3_c763.py --self-test", "python3 tests/e2e/validate_m3_c763.py ..."]}
Path(output).write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-final-clean.log" 2>&1
[ ! -e "$STANDARD/build" ]
[ -z "$(git -C "$STANDARD" status --porcelain --untracked-files=normal)" ]
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ]
echo "M3 C763 PASS: $RUN_DIR"
