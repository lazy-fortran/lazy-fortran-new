#!/usr/bin/env bash
# Replay the first raw-source-to-executable Fortran slice.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
export LC_ALL=C
export LANG=C

if [ "${1:-}" != "--fresh" ] || [ "$#" -ne 1 ]; then
    printf '%s\n' "usage: $0 --fresh" >&2
    exit 2
fi

need python3
need sha256sum
need git
need readelf
need qemu-riscv64

"$ROOT/scripts/check_pins.sh" >/dev/null
"$ROOT/scripts/check-contracts.sh" >/dev/null

manifest="$ROOT/tests/fixtures/l3-raw-program-v0.toml"
standard="$(resolve_repo standard-new)"
frontend="$(resolve_repo fortfront-new)"
compiler="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
run_root="$ROOT/.cache/runs/E0234"
mkdir -p "$run_root"
run_number=1
while [ -e "$run_root/R$(printf '%06d' "$run_number")" ]; do
    run_number=$((run_number + 1))
done
run_dir="$run_root/R$(printf '%06d' "$run_number")"
mkdir -p "$run_dir"

[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ] || {
    printf '%s\n' 'laboratory checkout is not clean' >&2
    exit 1
}
for repo in "$standard" "$frontend" "$compiler" "$backend"; do
    [ -z "$(git -C "$repo" status --porcelain --untracked-files=normal)" ] || {
        printf 'component checkout is not clean: %s\n' "$repo" >&2
        exit 1
    }
done

python3 - "$manifest" "$ROOT" <<'PY'
import hashlib
import sys
import tomllib
from pathlib import Path

manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
for field in ("contract_schema", "contract_witness", "source", "negative",
              "frontend_golden", "mir_golden", "oracle"):
    path = root / manifest[field]
    if not path.is_file():
        raise SystemExit(f"missing L3 input: {manifest[field]}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    expected = manifest[field + "_sha256"]
    if digest != expected:
        raise SystemExit(f"{field} hash differs")
PY

for repo in "$standard" "$frontend" "$compiler" "$backend"; do
    (cd "$repo" && fo clean) >"$run_dir/$(basename "$repo")-clean.log" 2>&1
    (cd "$repo" && fo) >"$run_dir/$(basename "$repo")-build.log" 2>&1
done

actual_standard_commit="$(git -C "$standard" rev-parse HEAD)"
actual_frontend_commit="$(git -C "$frontend" rev-parse HEAD)"
actual_compiler_commit="$(git -C "$compiler" rev-parse HEAD)"
actual_backend_commit="$(git -C "$backend" rev-parse HEAD)"
python3 - "$manifest" "$actual_standard_commit" "$actual_frontend_commit" \
    "$actual_compiler_commit" "$actual_backend_commit" <<'PY'
import sys
import tomllib
from pathlib import Path

manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
fields = ("standard_component_commit", "frontend_component_commit",
          "compiler_component_commit", "backend_component_commit")
for field, actual in zip(fields, sys.argv[2:]):
    if manifest[field] != actual:
        raise SystemExit(f"{field} differs: {actual}")
PY

positive="$ROOT/$(python3 - "$manifest" <<'PY'
import sys, tomllib
from pathlib import Path
print(tomllib.loads(Path(sys.argv[1]).read_text())['source'])
PY
)"
negative="$ROOT/$(python3 - "$manifest" <<'PY'
import sys, tomllib
from pathlib import Path
print(tomllib.loads(Path(sys.argv[1]).read_text())['negative'])
PY
)"

positive_frontend="$run_dir/positive.frontend.sx"
positive_frontend_repeat="$run_dir/positive.frontend.repeat.sx"
negative_frontend="$run_dir/negative.frontend.sx"
negative_frontend_repeat="$run_dir/negative.frontend.repeat.sx"
(cd "$frontend" && fo exec fortfront-source-v0 "$positive" "$positive_frontend") \
    >"$run_dir/fortfront-positive.log" 2>&1
(cd "$frontend" && fo exec fortfront-source-v0 "$positive" "$positive_frontend_repeat") \
    >"$run_dir/fortfront-positive-repeat.log" 2>&1
(cd "$frontend" && fo exec fortfront-source-v0 "$negative" "$negative_frontend") \
    >"$run_dir/fortfront-negative.log" 2>&1
(cd "$frontend" && fo exec fortfront-source-v0 "$negative" "$negative_frontend_repeat") \
    >"$run_dir/fortfront-negative-repeat.log" 2>&1
cmp "$positive_frontend" "$positive_frontend_repeat"
cmp "$negative_frontend" "$negative_frontend_repeat"
python3 - "$positive_frontend" "$ROOT/tests/golden/l3-raw-program-v0.frontend.sx" <<'PY'
import sys
from pathlib import Path
actual, expected = map(Path, sys.argv[1:])
if actual.read_bytes().rstrip(b"\n") != expected.read_bytes().rstrip(b"\n"):
    raise SystemExit("positive frontend result differs from golden")
PY

positive_mir="$run_dir/positive.mir.sx"
positive_mir_repeat="$run_dir/positive.mir.repeat.sx"
if ! (cd "$compiler" && fo exec ffc-lower-frontend-v0 "$positive_frontend" "$positive_mir") \
    >"$run_dir/ffc-positive.log" 2>&1; then
    printf '%s\n' 'positive frontend was rejected by ffc' >&2
    exit 1
fi
(cd "$compiler" && fo exec ffc-lower-frontend-v0 "$positive_frontend" "$positive_mir_repeat") \
    >"$run_dir/ffc-positive-repeat.log" 2>&1
cmp "$positive_mir" "$positive_mir_repeat"
python3 - "$positive_mir" "$ROOT/tests/golden/l3-raw-program-v0.mir.sx" <<'PY'
import sys
from pathlib import Path
actual, expected = map(Path, sys.argv[1:])
if actual.read_bytes().rstrip(b"\n") != expected.read_bytes().rstrip(b"\n"):
    raise SystemExit("positive MIR differs from golden")
PY

negative_mir="$run_dir/negative.mir.sx"
if (cd "$compiler" && fo exec ffc-lower-frontend-v0 "$negative_frontend" "$negative_mir") \
    >"$run_dir/ffc-negative.log" 2>&1; then
    printf '%s\n' 'negative frontend was accepted by ffc' >&2
    exit 1
fi
[ ! -e "$negative_mir" ]
grep -Fq 'ffc-lower-frontend-v0: invalid frontend-v0 input' "$run_dir/ffc-negative.log"

artifact="$run_dir/l3.elf"
artifact_repeat="$run_dir/l3.repeat.elf"
(cd "$backend" && fo exec fortback-mir-v0 "$positive_mir" "$artifact") \
    >"$run_dir/fortback.log" 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$positive_mir" "$artifact_repeat") \
    >"$run_dir/fortback-repeat.log" 2>&1
cmp "$artifact" "$artifact_repeat"
[ -x "$artifact" ]
readelf -h "$artifact" >"$run_dir/readelf.log"
if qemu-riscv64 "$artifact" >"$run_dir/qemu.log" 2>&1; then
    runtime_status=0
else
    runtime_status=$?
fi
[ "$runtime_status" -eq 0 ]

python3 "$ROOT/tests/e2e/validate_l3.py" "$manifest" "$run_dir" \
    "$actual_standard_commit" "$actual_frontend_commit" \
    "$actual_compiler_commit" "$actual_backend_commit" "$runtime_status"

python3 - "$run_dir/trace.json" "$manifest" "$ROOT" "$run_dir" \
    "$actual_standard_commit" "$actual_frontend_commit" \
    "$actual_compiler_commit" "$actual_backend_commit" "$runtime_status" <<'PY'
import hashlib
import json
import subprocess
import sys
import tomllib
from pathlib import Path

trace_path, manifest_path, root, run_dir, standard, frontend, compiler, backend, runtime = sys.argv[1:]
root = Path(root)
run_dir = Path(run_dir)
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
def digest(name):
    return hashlib.sha256((run_dir / name).read_bytes()).hexdigest()
def tool(command):
    return subprocess.run(command, text=True, capture_output=True, check=False).stdout.splitlines()[0]
trace = {
    "milestone": "L3",
    "fixture": manifest["id"],
    "boundary": manifest["boundary"],
    "contracts": manifest["central_contracts"],
    "source": {"path": manifest["source"], "sha256": manifest["source_sha256"]},
    "negative": {"path": manifest["negative"], "sha256": manifest["negative_sha256"],
                 "frontend_sha256": digest("negative.frontend.sx"), "result": "rejected"},
    "positive": {"frontend_sha256": digest("positive.frontend.sx"),
                 "mir_sha256": digest("positive.mir.sx"), "artifact_sha256": digest("l3.elf"),
                 "runtime_exit_status": int(runtime), "result": "accepted"},
    "components": {"standard-new": standard, "fortfront-new": frontend,
                   "ffc-new": compiler, "fortback-new": backend},
    "toolchain": {"fo": tool(["fo", "version"]), "python": tool(["python3", "--version"]),
                   "qemu": tool(["qemu-riscv64", "--version"]),
                   "readelf": tool(["readelf", "--version"])},
    "model_calls": 0,
    "semantic_promotions": 0,
}
Path(trace_path).write_text(json.dumps(trace, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

committed_trace="$ROOT/artifacts/traces/l3-raw-program-v0.json"
if [ -f "$committed_trace" ]; then
    cmp "$run_dir/trace.json" "$committed_trace"
else
    if [ "${L3_BOOTSTRAP_TRACE:-}" != 1 ]; then
        printf '%s\n' 'missing committed L3 trace; use L3_BOOTSTRAP_TRACE=1 once to create it' >&2
        exit 1
    fi
    cp "$run_dir/trace.json" "$committed_trace"
fi

printf 'L3 PASS: %s\n' "$run_dir"
