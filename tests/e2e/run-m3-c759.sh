#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVIDENCE_ROOT="${C759_EVIDENCE_ROOT:-/home/ert/code/lazy-fortran-new}"
STANDARD="${STANDARD_NEW_ROOT:-$(cd "$ROOT/../standard-new" 2>/dev/null && pwd)}"
EXPECTED_CENTRAL_COMMIT="${M3_C759_EXPECTED_CENTRAL_COMMIT:-}"
EXPECTED_STANDARD_COMMIT="f94c4c51b51fce22b533b7eeda08741970320913"
EXPECTED_FO_VERSION="0.3.2"
EXPECTED_FO_SHA256="0e9ac6a20523f9919b75569e15e830011e8b69fa649e7a8c71b54ba18f131a68"
RUN_ROOT="$ROOT/.cache/runs/E0226"
if [ "${1:-}" = "--fresh" ]; then
  n=1; while [ -e "$RUN_ROOT/R$(printf '%06d' "$n")" ]; do n=$((n+1)); done
  RUN_DIR="$RUN_ROOT/R$(printf '%06d' "$n")"
elif [ "$#" = 1 ] && [[ "$1" == .cache/runs/E0226/* ]]; then
  RUN_DIR="$ROOT/$1"
else
  echo "usage: $0 --fresh|.cache/runs/E0226/R<run>" >&2; exit 2
fi
[ ! -e "$RUN_DIR" ] || { echo "run exists: $RUN_DIR" >&2; exit 1; }
mkdir -p "$RUN_DIR"
command -v fo >/dev/null; command -v python3 >/dev/null; command -v sha256sum >/dev/null
bash -n "$0"
central_commit="$(git -C "$ROOT" rev-parse HEAD)"
[ -z "$EXPECTED_CENTRAL_COMMIT" ] || [ "$central_commit" = "$EXPECTED_CENTRAL_COMMIT" ] || { echo "central revision differs: $central_commit" >&2; exit 1; }
standard_commit="$(git -C "$STANDARD" rev-parse HEAD)"
[ "$standard_commit" = "$EXPECTED_STANDARD_COMMIT" ] || { echo "standard-new revision differs: $standard_commit" >&2; exit 1; }
fo_path="$(command -v fo)"; fo_version="$(fo version | awk 'NR == 1 { print $2 }')"; fo_sha256="$(sha256sum "$fo_path" | awk '{print $1}')"
[ "$fo_version" = "$EXPECTED_FO_VERSION" ] || { echo "fo version differs: $fo_version" >&2; exit 1; }
[ "$fo_sha256" = "$EXPECTED_FO_SHA256" ] || { echo "fo hash differs: $fo_sha256" >&2; exit 1; }
scripts/check_pins.sh >"$RUN_DIR/check-pins.log"
scripts/check-contracts.sh >"$RUN_DIR/check-contracts.log"
scripts/check-contracts.sh --self-test >"$RUN_DIR/check-contracts-self-test.log"
python3 - "$ROOT/contracts/m3-c759-type-param-value-v0.sxs" "$ROOT/contracts/fixtures/m3-c759-type-param-value-v0.sx" >"$RUN_DIR/contract-structure.log" <<'PY'
import sys
from pathlib import Path
for name in sys.argv[1:]:
    text = Path(name).read_text(encoding="utf-8")
    if text.count("(") != text.count(")"):
        raise SystemExit(f"unbalanced contract file: {name}")
    if name.endswith(".sxs") and "(schema m3-c759-type-param-value-v0" not in text:
        raise SystemExit("schema root missing")
    if name.endswith(".sx") and "(contract-witness" not in text:
        raise SystemExit("witness root missing")
print("C759 contract structure PASS")
PY
scripts/fetch.sh j3-24-007 >"$RUN_DIR/fetch.log"
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-clean.log" 2>&1
(cd "$STANDARD" && fo) >"$RUN_DIR/fo.log" 2>&1
(cd "$STANDARD" && fo exec --no-build sxsemantic "$ROOT/tests/fixtures/m3-c759-semantic-items.sx" "$RUN_DIR/semantic-items.canonical.sx") >"$RUN_DIR/sxsemantic.log" 2>&1
cmp "$RUN_DIR/semantic-items.canonical.sx" "$ROOT/tests/golden/m3-c759-semantic-items.sx"
C759_EVIDENCE_ROOT="$EVIDENCE_ROOT" C759_CONSTRAINT_SPANS="$EVIDENCE_ROOT/.cache/runs/E0081/R000001/constraint-spans.tsv" python3 "$ROOT/tests/e2e/validate_m3_c759.py" --self-test >"$RUN_DIR/oracle-self-test.log"
C759_EVIDENCE_ROOT="$EVIDENCE_ROOT" C759_CONSTRAINT_SPANS="$EVIDENCE_ROOT/.cache/runs/E0081/R000001/constraint-spans.tsv" python3 "$ROOT/tests/e2e/validate_m3_c759.py" \
  "$ROOT/tests/fixtures/m3-c759-source-backed-v0.json" "$ROOT/tests/fixtures/m3-c759-expected-outcomes-v0.json" \
  "$RUN_DIR/semantic-items.canonical.sx" "$EVIDENCE_ROOT/.cache/runs/E0171/R000433-provenance-replay/standardir.sx" \
  "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" "$EVIDENCE_ROOT/.cache/runs/E0001/R000003/j3-24-007.pages.index" \
  "$EVIDENCE_ROOT/.cache/j3-24-007.pdf" "$ROOT/tests/golden/m3-c759-semantic-items.sx" "$RUN_DIR/result.json" >"$RUN_DIR/oracle.log"
cmp "$RUN_DIR/result.json" "$ROOT/artifacts/traces/m3-c759-source-backed-v0.json"
python3 - "$RUN_DIR/run-environment.json" "$central_commit" "$standard_commit" "$fo_path" "$fo_version" "$fo_sha256" "$ROOT/tests/e2e/validate_m3_c759.py" <<'PY'
import hashlib, json, platform, subprocess, sys
from pathlib import Path
output, central, standard, fo_path, fo_version, fo_sha256, validator = sys.argv[1:]
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def first_line(command):
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    return (result.stdout + result.stderr).splitlines()[0]
record = {"central": {"repository": "lazy-fortran-new", "commit": central}, "standard_new": {"repository": "standard-new", "commit": standard}, "toolchain": {"fo": {"path": str(Path(fo_path).resolve()), "version": fo_version, "sha256": fo_sha256}, "python": first_line(["python3", "--version"]), "git": first_line(["git", "--version"]), "compiler": first_line(["gfortran", "--version"]), "poppler": first_line(["pdftotext", "-v"])}, "environment": {"os": platform.system(), "os_release": platform.release(), "architecture": platform.machine(), "python_version": platform.python_version()}, "oracle_sha256": digest(validator), "commands": ["M3_C759_EXPECTED_CENTRAL_COMMIT=<pinned-central> C759_EVIDENCE_ROOT=<evidence-root> STANDARD_NEW_ROOT=<standard-new-root> tests/e2e/run-m3-c759.sh --fresh", "scripts/check_pins.sh", "scripts/check-contracts.sh", "scripts/check-contracts.sh --self-test", "scripts/fetch.sh j3-24-007", "python3 tests/e2e/validate_m3_c759.py --self-test", "python3 tests/e2e/validate_m3_c759.py ..."]}
Path(output).write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
(cd "$STANDARD" && fo clean) >"$RUN_DIR/fo-final-clean.log" 2>&1
[ ! -e "$STANDARD/build" ]
[ -z "$(git -C "$STANDARD" status --porcelain --untracked-files=normal)" ]
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ]
echo "M3 C759 PASS: $RUN_DIR"
