#!/usr/bin/env bash
# Execute the source-backed StandardIR and four-format grammar gate.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
export LC_ALL=C
export LANG=C
need python3
need sha256sum
need git
need jq

"$ROOT/scripts/check_pins.sh" >/dev/null

manifest="$ROOT/tests/fixtures/m1m2-source-backed-v0.toml"
standard="$(resolve_repo standard-new)"
run_dir="$(mktemp -d "${TMPDIR:-/tmp}/lazy-fortran-m1m2.XXXXXX")"
cleanup() {
    local status=$?
    if [ "$status" -eq 0 ]; then
        rm -rf -- "$run_dir"
    else
        printf 'M1-M2 failure artifacts retained at %s\n' "$run_dir" >&2
    fi
    exit "$status"
}
trap cleanup EXIT

mget() {
    python3 - "$manifest" "$1" <<'PY'
import sys
import tomllib
from pathlib import Path

document = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
value = document[sys.argv[2]]
if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)
PY
}

source_manifest="$ROOT/$(mget source_manifest)"
source_cache="$ROOT/$(mget source_cache)"
standard_commit="$(mget standard_component_commit)"
trace="$ROOT/$(mget trace)"
oracle="$ROOT/$(mget oracle)"
golden="$ROOT/$(mget golden)"
negative_fixture="$ROOT/$(mget negative_fixture)"
negative_golden="$ROOT/$(mget negative_golden)"

"$ROOT/scripts/fetch.sh" --verify j3-24-007 >/dev/null
[ -f "$source_cache" ]
[ "$(git -C "$standard" rev-parse HEAD)" = "$standard_commit" ]
[ -z "$(git -C "$standard" status --porcelain --untracked-files=normal)" ]

(cd "$standard" && fo) >"$run_dir/standard-fo.log" 2>&1
(cd "$standard" && fo exec --no-build pdfcanonical "$source_cache" \
    "$run_dir/canonical.txt" "$run_dir/pages.index") >"$run_dir/canonical.log" 2>&1
(cd "$standard" && fo exec --no-build pdfproductions "$run_dir/canonical.txt" \
    "$run_dir/pages.index" "$run_dir/all.jsonl" 1 688) \
    >"$run_dir/all-productions.log" 2>&1
(cd "$standard" && fo exec --no-build pdfproductions "$run_dir/canonical.txt" \
    "$run_dir/pages.index" "$run_dir/selected.jsonl" 45 580) \
    >"$run_dir/selected-productions.log" 2>&1
source_hash="$(sha256sum "$source_cache" | awk '{print $1}')"
(cd "$standard" && fo exec --no-build pdfstandardir "$run_dir/selected.jsonl" \
    "$run_dir/standardir.sx" "$source_hash" 5-15) >"$run_dir/standardir.log" 2>&1
(cd "$standard" && fo exec --no-build sxroundtrip "$run_dir/standardir.sx" \
    "$run_dir/standardir.roundtrip.sx") >"$run_dir/roundtrip.log" 2>&1
cmp "$run_dir/standardir.sx" "$run_dir/standardir.roundtrip.sx"

python3 "$ROOT/tests/e2e/generate_m1m2_sidecars.py" "$run_dir/standardir.sx" \
    "$standard/specs/lexical-facts-v0.sx" "$run_dir/classifications.sx" \
    "$run_dir/roots.sx"

# This source oracle is deliberately before any grammar generator runs.
python3 "$oracle" "$manifest" "$source_cache" "$run_dir/all.jsonl" \
    "$run_dir/selected.jsonl" "$run_dir/standardir.sx" "$run_dir/classifications.sx" \
    "$run_dir/roots.sx" >"$run_dir/source-oracle.log"

set +e
(cd "$standard" && fo exec --no-build sxroundtrip "$negative_fixture" \
    "$run_dir/negative.roundtrip.sx") >"$run_dir/negative-parser.log" 2>&1
negative_status=$?
set -e
[ "$negative_status" -ne 0 ]
python3 - "$run_dir/negative-parser.log" "$negative_golden" <<'PY'
import sys
import tomllib
from pathlib import Path

log = Path(sys.argv[1]).read_text(encoding="utf-8")
expected = tomllib.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
if expected.get("diagnostic") != "unclosed-sx-list":
    raise SystemExit("negative golden diagnostic is not unclosed-sx-list")
if "unclosed SX list" not in log:
    raise SystemExit("negative parser diagnostic did not match golden class")
PY

generate() {
    local suffix format output
    for format in ebnf antlr bison treesitter; do
        case "$format" in
            ebnf) output="$run_dir/grammar.ebnf" ;;
            antlr) output="$run_dir/Fortran2023.g4" ;;
            bison) output="$run_dir/fortran2023.y" ;;
            treesitter) output="$run_dir/grammar.js" ;;
        esac
        suffix="${1:-}"
        if [ -n "$suffix" ]; then
            output="${output%.*}.two.${output##*.}"
        fi
        (cd "$standard" && fo exec --no-build sxgrammar "$run_dir/standardir.sx" \
            "$run_dir/classifications.sx" "$run_dir/roots.sx" \
            specs/lexical-facts-v0.sx "$format" "$output") \
            >"$run_dir/generate-${format}${suffix}.log" 2>&1
    done
}

generate
generate "-two"
cmp "$run_dir/grammar.ebnf" "$run_dir/grammar.two.ebnf"
cmp "$run_dir/Fortran2023.g4" "$run_dir/Fortran2023.two.g4"
cmp "$run_dir/fortran2023.y" "$run_dir/fortran2023.two.y"
cmp "$run_dir/grammar.js" "$run_dir/grammar.two.js"

python3 "$oracle" "$manifest" "$source_cache" "$run_dir/all.jsonl" \
    "$run_dir/selected.jsonl" "$run_dir/standardir.sx" "$run_dir/classifications.sx" \
    "$run_dir/roots.sx" "$run_dir/Fortran2023.g4" "$run_dir/fortran2023.y" \
    "$run_dir/grammar.js" --negative "$negative_fixture" "$negative_golden" \
    >"$run_dir/final-oracle.log"
python3 "$ROOT/tests/e2e/validate_m1m2_grammars.py" "$run_dir" \
    >"$run_dir/validators.log"

python3 - "$run_dir/trace.json" "$manifest" "$run_dir" "$source_cache" \
    "$standard" "$source_hash" "$standard_commit" <<'PY'
import hashlib
import json
import subprocess
import sys
import tomllib
from pathlib import Path


trace_path, manifest_path, run_directory, source_cache, standard, source_hash, standard_commit = sys.argv[1:]
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
run_dir = Path(run_directory)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def version(command: list[str]) -> str:
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    return (result.stdout + result.stderr).splitlines()[0]


trace = {
    "milestone": "M1-M2",
    "fixture": manifest["id"],
    "source": {
        "manifest": manifest["source_manifest"],
        "sha256": source_hash,
        "bytes": Path(source_cache).stat().st_size,
    },
    "component": {"repository": "standard-new", "commit": standard_commit},
    "inputs": {
        name: {"sha256": digest(run_dir / filename)}
        for name, filename in {
            "all_productions": "all.jsonl",
            "selected_productions": "selected.jsonl",
            "standardir": "standardir.sx",
            "classifications": "classifications.sx",
            "roots": "roots.sx",
        }.items()
    },
    "outputs": {
        name: {"sha256": digest(run_dir / name)}
        for name in ("grammar.ebnf", "Fortran2023.g4", "fortran2023.y", "grammar.js")
    },
    "toolchain": {
        "fo": version(["fo", "version"]),
        "antlr4": version(["antlr4"]),
        "bison": version(["bison", "--version"]),
        "tree_sitter": version(["tree-sitter", "--version"]),
        "standard_new_path": standard,
    },
    "oracles": {
        "source": manifest["oracle"],
        "grammar": "tests/e2e/validate_m1m2_grammars.py",
        "negative": manifest["negative_fixture"],
        "negative_result": "PASS",
        "negative_parser": "standard-new sxroundtrip",
        "negative_parser_log_sha256": digest(run_dir / "negative-parser.log"),
        "source_result": "PASS",
        "grammar_result": "PASS",
        "mutation_control": "observed_failure",
    },
    "reproducibility": {
        "locale": {"LC_ALL": "C", "LANG": "C"},
        "commands": ["scripts/verify_active_milestone.sh", "tests/e2e/run-m1m2.sh"],
        "negative_command": "(cd standard-new && fo exec --no-build sxroundtrip tests/negative/m1m2-source-backed-v0-unclosed.sx <run-dir>/negative.roundtrip.sx)",
    },
    "origin": "MECHANICAL",
}
Path(trace_path).write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
print(json.dumps(trace, sort_keys=True))
PY

install -D -m 0644 "$run_dir/trace.json" "$trace"
printf 'M1-M2 PASS\ntrace %s\n' "$trace"
