#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
RUN_DIR=${1:-"$ROOT/.cache/runs/E0174/R000001"}
if [[ "$RUN_DIR" != /* ]]; then RUN_DIR="$ROOT/$RUN_DIR"; fi
REUSE_DIR=${2:-}
if [[ -n "$REUSE_DIR" && "$REUSE_DIR" != /* ]]; then REUSE_DIR="$ROOT/$REUSE_DIR"; fi
STANDARD_NEW=/home/ert/code/standard-new
EXPECTED_COMMIT=f94c4c51b51fce22b533b7eeda08741970320913
EXPECTED_SOURCE_SHA256=106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2
INPUT="$ROOT/.cache/runs/E0171/R000433-provenance-replay"
CLASS_INPUT="$ROOT/.cache/runs/E0171/R000404-clean-witness-replay/input"
CANDIDATES="$ROOT/.cache/runs/E0171/R000435-correspondence-replay/candidates.tsv"
COALESCER="$ROOT/research/experiments/E0171-can-current-standardir-grammar-projectio/coalesce-boundary-candidates.py"

trace_input_hash() {
    local path=$1
    sha256sum "$path" | awk '{print $1}'
}

check_trace_cache() {
    local cache_dir=$1
    local label path expected actual

    test -s "$cache_dir/fo.log" || { echo "E0174: cached component gate log is missing" >&2; exit 2; }
    test -s "$cache_dir/component-gate.json" || {
        echo "E0174: cached machine-readable component gate is missing" >&2
        exit 2
    }
    python3 - "$cache_dir/component-gate.json" "$cache_dir/fo.log" "$EXPECTED_COMMIT" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

gate_path, log_path, expected_commit = map(Path, sys.argv[1:])
gate = json.loads(gate_path.read_text(encoding="utf-8"))
if gate.get("status") != "PASS":
    raise SystemExit("E0174: cached component gate is not PASS")
if gate.get("standard_new_commit") != str(expected_commit):
    raise SystemExit("E0174: cached component gate commit differs")
if gate.get("command") != ["fo"] or gate.get("checkout_clean") is not True:
    raise SystemExit("E0174: cached component gate metadata is incomplete")
if gate.get("fo_log_sha256") != hashlib.sha256(log_path.read_bytes()).hexdigest():
    raise SystemExit("E0174: cached component gate log hash differs")
PY
    test -s "$cache_dir/fortran2023.y" || { echo "E0174: cached grammar is missing" >&2; exit 2; }
    test -s "$cache_dir/correspondence.jsonl" || { echo "E0174: cached correspondence trace is missing" >&2; exit 2; }
    test -f "$cache_dir/trace-outputs.sha256" || {
        echo "E0174: cached trace output manifest is missing" >&2
        exit 2
    }
    test -f "$cache_dir/trace-inputs.sha256" || {
        echo "E0174: cached trace input manifest is missing" >&2
        exit 2
    }
    grep -Fx "standard-new $EXPECTED_COMMIT" "$cache_dir/trace-inputs.sha256" >/dev/null || {
        echo "E0174: cached trace standard-new pin differs" >&2
        exit 2
    }
    grep -Fx 'format bison' "$cache_dir/trace-inputs.sha256" >/dev/null || {
        echo "E0174: cached trace format differs" >&2
        exit 2
    }
    grep -Fx 'selected-root program' "$cache_dir/trace-inputs.sha256" >/dev/null || {
        echo "E0174: cached trace root differs" >&2
        exit 2
    }
    while read -r label path; do
        [[ "$label" == "standard-new" || "$label" == "format" || "$label" == "selected-root" ]] && continue
        expected=$(awk -v key="$label" '$1 == key { print $2 }' "$cache_dir/trace-inputs.sha256")
        actual=$(trace_input_hash "$path")
        if [[ -z "$expected" || "$actual" != "$expected" ]]; then
            echo "E0174: cached trace input differs for $label" >&2
            exit 2
        fi
    done <<EOF
source-input $INPUT/standardir.sx
classifications $CLASS_INPUT/classifications.sx
roots $CLASS_INPUT/roots.sx
lexical-facts $CLASS_INPUT/lexical-facts-v0.sx
EOF
    while read -r label expected; do
        actual=$(trace_input_hash "$cache_dir/$label")
        if [[ ! "$expected" =~ ^[0-9a-f]{64}$ || "$actual" != "$expected" ]]; then
            echo "E0174: cached trace output differs for $label" >&2
            exit 2
        fi
    done < "$cache_dir/trace-outputs.sha256"
    test "$(awk 'NF { count += 1 } END { print count + 0 }' "$cache_dir/trace-outputs.sha256")" = 2 || {
        echo "E0174: cached trace output manifest must contain exactly two entries" >&2
        exit 2
    }
    for label in fortran2023.y correspondence.jsonl; do
        test "$(awk -v key="$label" '$1 == key { count += 1 } END { print count + 0 }' \
            "$cache_dir/trace-outputs.sha256")" = 1 || {
            echo "E0174: cached trace output manifest is incomplete" >&2
            exit 2
        }
    done
}

test -d "$STANDARD_NEW" || { echo "E0174: standard-new checkout is missing" >&2; exit 2; }
test "$(git -C "$STANDARD_NEW" rev-parse HEAD)" = "$EXPECTED_COMMIT" || {
    echo "E0174: standard-new is not at $EXPECTED_COMMIT" >&2
    exit 2
}
test -z "$(git -C "$STANDARD_NEW" status --porcelain)" || {
    echo "E0174: standard-new checkout is dirty" >&2
    exit 2
}
test -f "$INPUT/standardir.sx" || { echo "E0174: source input is missing" >&2; exit 2; }
test "$(sha256sum "$INPUT/standardir.sx" | awk '{print $1}')" = "$EXPECTED_SOURCE_SHA256" || {
    echo "E0174: source input hash differs" >&2
    exit 2
}
test -f "$CANDIDATES" || { echo "E0174: candidate witness is missing" >&2; exit 2; }
test ! -e "$RUN_DIR" || { echo "E0174: refusing to overwrite $RUN_DIR" >&2; exit 2; }
if [[ -n "$REUSE_DIR" ]]; then check_trace_cache "$REUSE_DIR"; fi

mkdir -p "$RUN_DIR"
printf '%s\n' "$EXPECTED_COMMIT" > "$RUN_DIR/standard-new-commit.txt"
printf '%s\n' "$EXPECTED_SOURCE_SHA256" > "$RUN_DIR/source-input-sha256.txt"
if [[ -n "$REUSE_DIR" ]]; then
    cp "$REUSE_DIR/component-gate.json" "$RUN_DIR/component-gate.json"
    printf 'reused full fo gate from %s\n' "$REUSE_DIR" > "$RUN_DIR/fo.log"
else
    (cd "$STANDARD_NEW" && fo) > "$RUN_DIR/fo.log" 2>&1
    python3 - "$RUN_DIR/component-gate.json" "$RUN_DIR/fo.log" "$EXPECTED_COMMIT" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

gate_path, log_path, commit = map(Path, sys.argv[1:])
gate_path.write_text(json.dumps({
    "status": "PASS",
    "standard_new_commit": str(commit),
    "command": ["fo"],
    "checkout_clean": True,
    "fo_log_sha256": hashlib.sha256(log_path.read_bytes()).hexdigest(),
}, sort_keys=True) + "\n", encoding="utf-8")
PY
fi
(cd "$STANDARD_NEW" && fo exec --no-build sxstatementboundarymap \
    "$INPUT/standardir.sx" "$CANDIDATES" "$RUN_DIR/mapping.tsv") \
    > "$RUN_DIR/statement-boundary-map.log" 2>&1
if [[ -n "$REUSE_DIR" ]]; then
    cp "$REUSE_DIR/fortran2023.y" "$RUN_DIR/fortran2023.y"
    cp "$REUSE_DIR/correspondence.jsonl" "$RUN_DIR/correspondence.jsonl"
    printf 'reused from %s\n' "$REUSE_DIR" > "$RUN_DIR/sxgrammar.log"
    printf '%s\n' "$REUSE_DIR" > "$RUN_DIR/trace-reused-from.txt"
else
    (cd "$STANDARD_NEW" && fo exec --no-build sxgrammar \
        "$INPUT/standardir.sx" "$CLASS_INPUT/classifications.sx" "$CLASS_INPUT/roots.sx" \
        "$CLASS_INPUT/lexical-facts-v0.sx" bison "$RUN_DIR/fortran2023.y" \
        --selected-root program --correspondence-witness "$RUN_DIR/correspondence.jsonl") \
        > "$RUN_DIR/sxgrammar.log" 2>&1
fi
{
    printf 'standard-new %s\n' "$EXPECTED_COMMIT"
    printf 'source-input %s\n' "$(trace_input_hash "$INPUT/standardir.sx")"
    printf 'classifications %s\n' "$(trace_input_hash "$CLASS_INPUT/classifications.sx")"
    printf 'roots %s\n' "$(trace_input_hash "$CLASS_INPUT/roots.sx")"
    printf 'lexical-facts %s\n' "$(trace_input_hash "$CLASS_INPUT/lexical-facts-v0.sx")"
    printf 'format bison\nselected-root program\n'
} > "$RUN_DIR/trace-inputs.sha256"
{
    printf 'fortran2023.y %s\n' "$(trace_input_hash "$RUN_DIR/fortran2023.y")"
    printf 'correspondence.jsonl %s\n' "$(trace_input_hash "$RUN_DIR/correspondence.jsonl")"
} > "$RUN_DIR/trace-outputs.sha256"
python3 "$COALESCER" \
    "$CANDIDATES" "$RUN_DIR/sites.tsv" "$RUN_DIR/evidence.tsv" \
    "$RUN_DIR/coalesce-summary.json" > "$RUN_DIR/coalesce.stdout"

printf 'E0174 deterministic replay written to %s\n' "$RUN_DIR"
