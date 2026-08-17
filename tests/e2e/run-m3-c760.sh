#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVIDENCE_ROOT="${C760_EVIDENCE_ROOT:-/home/ert/code/lazy-fortran-new}"
STANDARD="${STANDARD_NEW_ROOT:-$(cd "$ROOT/../standard-new" 2>/dev/null && pwd)}"
EXPECTED_CENTRAL_COMMIT="${C760_EXPECTED_CENTRAL_COMMIT:-0d64c0c2e3ab98b1b54a023690c33fc82f41a567}"
EXPECTED_STANDARD_COMMIT="f94c4c51b51fce22b533b7eeda08741970320913"
EXPECTED_FO_VERSION="0.3.2"
EXPECTED_FO_SHA256="0e9ac6a20523f9919b75569e15e830011e8b69fa649e7a8c71b54ba18f131a68"
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
central_commit="$(git -C "$ROOT" rev-parse HEAD)"
[ "$central_commit" = "$EXPECTED_CENTRAL_COMMIT" ] || { echo "central revision differs: $central_commit" >&2; exit 1; }
standard_commit="$(git -C "$STANDARD" rev-parse HEAD)"
[ "$standard_commit" = "$EXPECTED_STANDARD_COMMIT" ] || { echo "standard-new revision differs: $standard_commit" >&2; exit 1; }
fo_path="$(command -v fo)"
fo_version="$(fo version | awk 'NR == 1 { print $2 }')"
fo_sha256="$(sha256sum "$fo_path" | awk '{print $1}')"
[ "$fo_version" = "$EXPECTED_FO_VERSION" ] || { echo "fo version differs: $fo_version" >&2; exit 1; }
[ "$fo_sha256" = "$EXPECTED_FO_SHA256" ] || { echo "fo hash differs: $fo_sha256" >&2; exit 1; }
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
python3 - "$RUN_DIR/run-environment.json" "$central_commit" "$standard_commit" "$fo_path" "$fo_version" "$fo_sha256" <<'PY'
import hashlib
import json
import platform
import subprocess
import sys
from pathlib import Path

output, central, standard, fo_path, fo_version, fo_sha256 = sys.argv[1:]
def first_line(command):
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    return (result.stdout + result.stderr).splitlines()[0]
def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
record = {
    "central": {"repository": "lazy-fortran-new", "commit": central},
    "standard_new": {"repository": "standard-new", "commit": standard},
    "toolchain": {
        "fo": {"path": str(Path(fo_path).resolve()), "version": fo_version, "sha256": fo_sha256},
        "python": first_line(["python3", "--version"]),
        "git": first_line(["git", "--version"]),
        "compiler": first_line(["gfortran", "--version"]),
        "poppler": first_line(["pdftotext", "-v"]),
    },
    "environment": {"os": platform.system(), "os_release": platform.release(), "architecture": platform.machine(), "python_version": platform.python_version()},
    "oracle_sha256": digest("tests/e2e/validate_m3_c760.py"),
    "commands": ["C760_EXPECTED_CENTRAL_COMMIT=<pinned-central> tests/e2e/run-m3-c760.sh --fresh", "scripts/check-contracts.sh", "scripts/fetch.sh j3-24-007", "python3 tests/e2e/validate_m3_c760.py --self-test", "python3 tests/e2e/validate_m3_c760.py ..."],
}
Path(output).write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-final-clean.log" 2>&1
[ ! -e "$STANDARD/build" ]
[ -z "$(git -C "$STANDARD" status --porcelain --untracked-files=normal)" ]
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ]
echo "M3 C760 PASS: $RUN_DIR"
