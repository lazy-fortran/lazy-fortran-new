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
need fo

"$ROOT/scripts/check_pins.sh" >/dev/null
"$ROOT/scripts/check-contracts.sh" >/dev/null

manifest="$ROOT/tests/fixtures/m1m2-source-backed-v0.toml"
standard="$(resolve_repo standard-new)"
central_commit="$(git -C "$ROOT" rev-parse HEAD)"
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
regression_corpus="$ROOT/$(mget regression_corpus)"
expected_fo_version="$(mget fo_version)"
expected_fo_sha256="$(mget fo_sha256)"
fo_path="$(command -v fo)"
fo_version="$(fo version | awk 'NR == 1 { print $2 }')"
fo_sha256="$(sha256sum "$fo_path" | awk '{print $1}')"
[ "$fo_version" = "$expected_fo_version" ]
[ "$fo_sha256" = "$expected_fo_sha256" ]

"$ROOT/scripts/fetch.sh" j3-24-007 >/dev/null
[ -f "$source_cache" ]
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ]
[ "$(git -C "$standard" rev-parse HEAD)" = "$standard_commit" ]
[ -z "$(git -C "$standard" status --porcelain --untracked-files=normal)" ]
(cd "$standard" && fo clean) >"$run_dir/standard-fo-clean.log" 2>&1
[ ! -e "$standard/build" ]
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

python3 "$ROOT/tests/e2e/validate_m1m2_contracts.py" "$manifest" \
    "$run_dir/standardir.sx" "$run_dir/contract-standardir.sx" \
    "$run_dir/contract-grammar.sx" >"$run_dir/contract-oracle.log"
python3 "$ROOT/tests/e2e/validate_m1m2_regression.py" "$regression_corpus" \
    "$manifest" "$ROOT" >"$run_dir/regression-oracle.json"

# This source oracle is deliberately before any grammar generator runs.
python3 "$oracle" "$manifest" "$source_cache" "$run_dir/all.jsonl" \
    "$run_dir/selected.jsonl" "$run_dir/standardir.sx" "$run_dir/classifications.sx" \
    "$run_dir/roots.sx" "$standard/specs/lexical-facts-v0.sx" \
    >"$run_dir/source-oracle.log"

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
awk '/error: unclosed SX list/ { print; found = 1 } END { exit(found ? 0 : 1) }' \
    "$run_dir/negative-parser.log" >"$run_dir/negative-diagnostic.txt"

generate() {
    local suffix="${1:-}" format output status pid
    local -a pids=()
    for format in ebnf antlr bison treesitter; do
        case "$format" in
            ebnf) output="$run_dir/grammar.ebnf" ;;
            antlr) output="$run_dir/Fortran2023.g4" ;;
            bison) output="$run_dir/fortran2023.y" ;;
            treesitter) output="$run_dir/grammar.js" ;;
        esac
        if [ -n "$suffix" ]; then
            output="${output%.*}.two.${output##*.}"
        fi
        (cd "$standard" && fo exec --no-build sxgrammar "$run_dir/standardir.sx" \
            "$run_dir/classifications.sx" "$run_dir/roots.sx" \
            specs/lexical-facts-v0.sx "$format" "$output") \
            >"$run_dir/generate-${format}${suffix}.log" 2>&1 &
        pids+=("$!")
    done

    status=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            status=1
        fi
    done
    return "$status"
}

generate
generate "-two"
cmp "$run_dir/grammar.ebnf" "$run_dir/grammar.two.ebnf"
cmp "$run_dir/Fortran2023.g4" "$run_dir/Fortran2023.two.g4"
cmp "$run_dir/fortran2023.y" "$run_dir/fortran2023.two.y"
cmp "$run_dir/grammar.js" "$run_dir/grammar.two.js"
[ -z "$(git -C "$standard" status --porcelain --untracked-files=normal)" ]

python3 "$oracle" "$manifest" "$source_cache" "$run_dir/all.jsonl" \
    "$run_dir/selected.jsonl" "$run_dir/standardir.sx" "$run_dir/classifications.sx" \
    "$run_dir/roots.sx" "$standard/specs/lexical-facts-v0.sx" \
    "$run_dir/grammar.ebnf" "$run_dir/Fortran2023.g4" "$run_dir/fortran2023.y" \
    "$run_dir/grammar.js" --negative "$negative_fixture" "$negative_golden" \
    >"$run_dir/final-oracle.log"
python3 "$ROOT/tests/e2e/validate_m1m2_grammars.py" "$run_dir" "$manifest" \
    >"$run_dir/validators.log"

python3 - "$run_dir/trace.json" "$manifest" "$run_dir" "$source_cache" \
    "$regression_corpus" "$standard" "$standard/specs/lexical-facts-v0.sx" "$source_hash" \
    "$run_dir/contract-standardir.sx" "$run_dir/contract-grammar.sx" \
    "$central_commit" "$standard_commit" "$fo_version" "$fo_sha256" "$fo_path" <<'PY'
import hashlib
import json
import platform
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path


(
    trace_path,
    manifest_path,
    run_directory,
    source_cache,
    regression_corpus,
    standard,
    lexical_path,
    source_hash,
    contract_standardir,
    contract_grammar,
    central_commit,
    standard_commit,
    fo_version,
    fo_sha256,
    fo_path,
) = sys.argv[1:]
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
run_dir = Path(run_directory)
repository_root = Path(manifest_path).resolve().parents[2]
fixture_path = Path(manifest_path).resolve()
validation = json.loads((run_dir / "validators" / "result.json").read_text(encoding="utf-8"))
regression = json.loads(
    (run_dir / "regression-oracle.json").read_text(encoding="utf-8")
)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


input_hashes = {
    name: {"sha256": digest(run_dir / filename)}
    for name, filename in {
        "all_productions": "all.jsonl",
        "selected_productions": "selected.jsonl",
        "standardir": "standardir.sx",
        "classifications": "classifications.sx",
        "roots": "roots.sx",
        "contract_standardir": "contract-standardir.sx",
        "contract_grammar": "contract-grammar.sx",
    }.items()
}
input_hashes["regression_corpus"] = {
    "sha256": digest(repository_root / manifest["regression_corpus"])
}


def version(command: list[str]) -> str:
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    return (result.stdout + result.stderr).splitlines()[0]


def tool_identity(name: str, command: list[str]) -> dict[str, str]:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"missing tool for reproducibility record: {name}")
    resolved = Path(path).resolve()
    return {
        "version": version(command),
        "path": str(resolved),
        "sha256": digest(resolved),
    }


environment = {
    "host": {
        "os": platform.system(),
        "os_release": platform.release(),
        "architecture": platform.machine(),
        "python_version": platform.python_version(),
        "python_path": sys.executable,
    },
    "worktree": {
        "central_root": str(repository_root),
        "central_commit": central_commit,
        "central_state": "clean",
        "component_root": str(Path(standard).resolve()),
        "component_state": "clean",
        "component_build_tree_before": "absent",
    },
    "commands": [
        {
            "argv": ["scripts/verify_active_milestone.sh"],
            "cwd": str(repository_root),
        },
        {
            "argv": ["tests/e2e/run-m1m2.sh"],
            "cwd": str(repository_root),
        },
        {
            "argv": ["fo", "version"],
            "cwd": str(Path(standard).resolve()),
        },
    ],
    "toolchain": {
        "fo": {
            "version": fo_version,
            "path": str(Path(fo_path).resolve()),
            "sha256": fo_sha256,
        },
        "antlr4": tool_identity("antlr4", ["antlr4"]),
        "bison": tool_identity("bison", ["bison", "--version"]),
        "tree_sitter": tool_identity("tree-sitter", ["tree-sitter", "--version"]),
    },
    "locale": {"LC_ALL": "C", "LANG": "C"},
}


trace = {
    "milestone": "M1-M2",
    "fixture": manifest["id"],
    "fixture_manifest": {
        "path": fixture_path.relative_to(repository_root).as_posix(),
        "sha256": digest(fixture_path),
    },
    "source": {
        "manifest": manifest["source_manifest"],
        "sha256": source_hash,
        "bytes": Path(source_cache).stat().st_size,
    },
    "regression": regression,
    "component": {
        "repository": "standard-new",
        "commit": standard_commit,
        "worktree_state": "clean",
        "build_tree_before": "absent",
    },
    "contracts": [
        {
            "id": name,
            "path": path,
            "sha256": digest(repository_root / path),
        }
        for name, path in zip(
            manifest["central_contracts"], manifest["central_contract_paths"]
        )
    ],
    "lexical": {
        "path": "standard-new/specs/lexical-facts-v0.sx",
        "sha256": digest(Path(lexical_path)),
        "witness_count": manifest["expected_lexical_witnesses"],
    },
    "inputs": input_hashes,
    "outputs": {
        name: {"sha256": digest(run_dir / name)}
        for name in ("grammar.ebnf", "Fortran2023.g4", "fortran2023.y", "grammar.js")
    },
    "toolchain": {
        "fo_version": fo_version,
        "fo_sha256": fo_sha256,
        "antlr4": version(["antlr4"]),
        "bison": version(["bison", "--version"]),
        "tree_sitter": version(["tree-sitter", "--version"]),
    },
    "oracles": {
        "source": manifest["oracle"],
        "grammar": "tests/e2e/validate_m1m2_grammars.py",
        "contracts": "tests/e2e/validate_m1m2_contracts.py",
        "contract_result": "PASS",
        "negative": manifest["negative_fixture"],
        "negative_result": "PASS",
        "negative_parser": "standard-new sxroundtrip",
        "negative_diagnostic_sha256": digest(run_dir / "negative-diagnostic.txt"),
        "source_result": "PASS",
        "grammar_result": "PASS",
        "mutation_control": "observed_failure",
    },
    "grammar_policy": {
        "bison": validation["bison"]["conflict_policy"],
        "shift_reduce_conflicts": validation["bison"]["shift_reduce_conflicts"],
        "reduce_reduce_conflicts": validation["bison"]["reduce_reduce_conflicts"],
        "undefined_symbols": validation["bison"]["undefined_symbols"],
    },
    "reproducibility": {
        "environment_record": manifest["environment_record"],
        "environment_compared": False,
        "environment": environment,
        "locale": {"LC_ALL": "C", "LANG": "C"},
        "commands": ["scripts/verify_active_milestone.sh", "tests/e2e/run-m1m2.sh"],
        "fo_clean_command": "(cd standard-new && fo clean)",
        "component_build_tree_before": "absent",
        "negative_command": "(cd standard-new && fo exec --no-build sxroundtrip tests/negative/m1m2-source-backed-v0-unclosed.sx <run-dir>/negative.roundtrip.sx)",
    },
    "origin": "MECHANICAL",
}
Path(trace_path).write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
print(json.dumps(trace, sort_keys=True))
PY

python3 "$ROOT/tests/e2e/compare_m1m2_trace.py" "$run_dir/trace.json" "$trace" \
    >"$run_dir/trace-compare.log"
printf 'M1-M2 PASS\ntrace %s\n' "$trace"
