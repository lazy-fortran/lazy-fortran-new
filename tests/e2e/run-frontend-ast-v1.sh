#!/usr/bin/env bash
# Replay the bounded raw-source to typed frontend AST v1 slice.

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

"$ROOT/scripts/check_pins.sh" >/dev/null
"$ROOT/scripts/check-contracts.sh" >/dev/null

manifest="$ROOT/tests/fixtures/frontend-ast-v1.toml"
validator="$ROOT/tests/e2e/validate_frontend_ast_v1.py"
frontend="$(resolve_repo fortfront-new)"
run_root="$ROOT/.cache/runs/E0235"
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
central_commit="$(git -C "$ROOT" rev-parse HEAD)"
expected_central_commit="${AST_EXPECTED_CENTRAL_COMMIT:-}"
[ -z "$expected_central_commit" ] || [ "$central_commit" = "$expected_central_commit" ] || {
    printf 'central revision differs: %s\n' "$central_commit" >&2
    exit 1
}
[ -z "$(git -C "$frontend" status --porcelain --untracked-files=normal)" ] || {
    printf 'component checkout is not clean: %s\n' "$frontend" >&2
    exit 1
}

python3 - "$manifest" "$ROOT" <<'PY'
import hashlib
import sys
import tomllib
from pathlib import Path
manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
for field in ("contract_schema", "contract_witness", "source", "negative", "output_golden", "oracle", "validator"):
    path = root / manifest[field]
    if not path.is_file():
        raise SystemExit(f"missing AST v1 input: {manifest[field]}")
    expected = manifest.get(field + "_sha256")
    if expected and hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise SystemExit(f"{field} hash differs")
PY

(cd "$frontend" && fo clean) >"$run_dir/fortfront-clean.log" 2>&1
(cd "$frontend" && fo) >"$run_dir/fortfront-build.log" 2>&1
actual_frontend="$(git -C "$frontend" rev-parse HEAD)"
python3 - "$manifest" "$actual_frontend" <<'PY'
import sys
import tomllib
from pathlib import Path
manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if manifest["frontend_component_commit"] != sys.argv[2]:
    raise SystemExit("frontend component commit differs")
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
positive_output="$run_dir/positive.ast.sx"
repeat_output="$run_dir/positive.ast.repeat.sx"
negative_output="$run_dir/negative.ast.sx"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$positive" "$positive_output") \
    >"$run_dir/positive.log" 2>&1
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$positive" "$repeat_output") \
    >"$run_dir/positive-repeat.log" 2>&1
cmp "$positive_output" "$repeat_output"
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative" "$negative_output") \
    >"$run_dir/negative.log" 2>&1; then
    printf '%s\n' 'malformed declaration was accepted' >&2
    exit 1
fi
[ ! -e "$negative_output" ]

python3 "$validator" "$manifest" "$run_dir" "$actual_frontend"
python3 - "$run_dir/trace.json" "$manifest" "$run_dir" "$actual_frontend" <<'PY'
import hashlib
import json
import subprocess
import sys
import tomllib
from pathlib import Path
trace_path, manifest_path, run_dir, frontend = sys.argv[1:]
run_dir = Path(run_dir)
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
root = Path(manifest_path).resolve().parents[2]
def digest(name):
    path = run_dir / name
    payload = path.read_text(encoding="utf-8")
    if name == "positive.ast.sx":
        source = (root / manifest["source"]).resolve()
        payload = payload.replace(f"(file {source})", "(file SOURCE)")
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()
def tool(command):
    return subprocess.run(command, text=True, capture_output=True, check=False).stdout.splitlines()[0]
trace = {
    "milestone": "L3",
    "fixture": manifest["id"],
    "boundary": manifest["boundary"],
    "source": {"path": manifest["source"], "sha256": manifest["source_sha256"]},
    "positive_ast_sha256": digest("positive.ast.sx"),
    "components": {"fortfront-new": frontend},
    "toolchain": {"fo": tool(["fo", "version"]), "python": tool(["python3", "--version"])},
    "model_calls": 0,
    "semantic_promotions": 0,
}
Path(trace_path).write_text(json.dumps(trace, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

trace_rel="$(python3 - "$manifest" <<'PY'
import sys, tomllib
from pathlib import Path
print(tomllib.loads(Path(sys.argv[1]).read_text())['trace'])
PY
)"
committed_trace="$ROOT/$trace_rel"
if [ -f "$committed_trace" ]; then
    cmp "$run_dir/trace.json" "$committed_trace"
else
    if [ "${AST_BOOTSTRAP_TRACE:-}" != 1 ]; then
        printf '%s\n' 'missing committed AST v1 trace; use AST_BOOTSTRAP_TRACE=1 once' >&2
        exit 1
    fi
    cp "$run_dir/trace.json" "$committed_trace"
fi
printf 'frontend AST v1 PASS: %s\n' "$run_dir"
