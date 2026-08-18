#!/usr/bin/env bash
# Replay the bounded source-derived program-root-name AST v1 contract.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
export LC_ALL=C
export LANG=C

if [ "${1:-}" != "--fresh" ] || [ "$#" -ne 1 ]; then
    printf '%s\n' "usage: $0 --fresh" >&2
    exit 2
fi

need python3
need git
"$ROOT/scripts/check_pins.sh" >/dev/null
"$ROOT/scripts/check-contracts.sh" >/dev/null

manifest="${AST_MANIFEST:-$ROOT/tests/fixtures/frontend-ast-v1-program-root-name-replay.toml}"
validator="$ROOT/tests/e2e/validate_frontend_ast_v1_program_root_name.py"
trace_writer="$ROOT/tests/e2e/write_frontend_ast_v1_program_root_name_trace.py"
frontend="$(resolve_repo fortfront-new)"
run_root="${AST_RUN_ROOT:-$ROOT/.cache/runs/E0241}"
mkdir -p "$run_root"
run_number=1
while [ -e "$run_root/R$(printf '%06d' "$run_number")" ]; do
    run_number=$((run_number + 1))
done
run_dir="$run_root/R$(printf '%06d' "$run_number")"
mkdir -p "$run_dir"

[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ] || { printf '%s\n' 'laboratory checkout is not clean' >&2; exit 1; }
central_commit="$(git -C "$ROOT" rev-parse HEAD)"
expected_central_commit="${AST_EXPECTED_CENTRAL_COMMIT:-}"
[ -z "$expected_central_commit" ] || [ "$central_commit" = "$expected_central_commit" ] || { printf 'central revision differs: %s\n' "$central_commit" >&2; exit 1; }
[ -z "$(git -C "$frontend" status --porcelain --untracked-files=normal)" ] || { printf 'component checkout is not clean: %s\n' "$frontend" >&2; exit 1; }

python3 - "$manifest" "$ROOT" <<'PY'
import hashlib
import sys
import tomllib
from pathlib import Path
manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
for field in ("contract_manifest", "runner", "validator", "trace_writer"):
    path = root / manifest[field]
    if not path.is_file():
        raise SystemExit(f"missing replay input: {manifest[field]}")
    expected = manifest.get(field + "_sha256")
    if expected and hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise SystemExit(f"{field} hash differs")
if manifest["validator"] != "tests/e2e/validate_frontend_ast_v1_program_root_name.py":
    raise SystemExit("validator path is not the frozen validator")
if manifest["trace_writer"] != "tests/e2e/write_frontend_ast_v1_program_root_name_trace.py":
    raise SystemExit("trace-writer path is not the frozen trace writer")
trace = root / manifest["trace"]
if trace.is_file() and manifest.get("trace_sha256"):
    if hashlib.sha256(trace.read_bytes()).hexdigest() != manifest["trace_sha256"]:
        raise SystemExit("committed trace hash differs")
contract = tomllib.loads((root / manifest["contract_manifest"]).read_text(encoding="utf-8"))
for case in contract["case"]:
    path = root / case["source"]
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != case["source_sha256"]:
        raise SystemExit(f"source case hash differs: {case['id']}")
negative = root / contract["negative"]
if not negative.is_file() or hashlib.sha256(negative.read_bytes()).hexdigest() != contract["negative_sha256"]:
    raise SystemExit("negative source hash differs")
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

mapfile -t cases < <(python3 - "$manifest" "$ROOT" <<'PY'
import sys
import tomllib
from pathlib import Path
manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
contract = tomllib.loads((root / manifest["contract_manifest"]).read_text(encoding="utf-8"))
for case in contract["case"]:
    print(case["id"] + "\t" + case["source"])
PY
)
for entry in "${cases[@]}"; do
    case_id="${entry%%$'\t'*}"
    source_rel="${entry#*$'\t'}"
    source="$ROOT/$source_rel"
    output="$run_dir/case-$case_id.ast.sx"
    repeat="$run_dir/case-$case_id.repeat.ast.sx"
    (cd "$frontend" && fo exec fortfront-source-ast-v1 "$source" "$output") >"$run_dir/case-$case_id.log" 2>&1
    (cd "$frontend" && fo exec fortfront-source-ast-v1 "$source" "$repeat") >"$run_dir/case-$case_id-repeat.log" 2>&1
    cmp "$output" "$repeat"
done

negative_rel="$(python3 - "$manifest" "$ROOT" <<'PY'
import sys
import tomllib
from pathlib import Path
manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
contract = tomllib.loads((root / manifest["contract_manifest"]).read_text(encoding="utf-8"))
print(contract["negative"])
PY
)"
negative="$ROOT/$negative_rel"
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative" "$run_dir/negative.ast.sx") >"$run_dir/negative.log" 2>&1; then
    printf '%s\n' 'mismatched end-program name was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative.ast.sx" ]
grep -Fq 'typed frontend rejected source:' "$run_dir/negative.log" || {
    printf '%s\n' 'negative did not produce the frozen typed-frontend rejection marker' >&2
    exit 1
}
python3 "$validator" "$manifest" "$run_dir" "$actual_frontend"
python3 "$trace_writer" "$manifest" "$run_dir" "$actual_frontend"
trace_rel="$(python3 - "$manifest" <<'PY'
import sys
import tomllib
from pathlib import Path
print(tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["trace"])
PY
)"
committed_trace="$ROOT/$trace_rel"
if [ -f "$committed_trace" ]; then
    cmp "$run_dir/trace.json" "$committed_trace"
else
    [ "${AST_BOOTSTRAP_TRACE:-}" = 1 ] || { printf '%s\n' 'missing committed AST v1 trace; use AST_BOOTSTRAP_TRACE=1 once' >&2; exit 1; }
    cp "$run_dir/trace.json" "$committed_trace"
fi
printf 'frontend AST v1 program-root-name PASS: %s\n' "$run_dir"
