#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
standard_root=$(cd -- "$lab_root/../standard-new" && pwd)
source_run=${3:-"$lab_root/.cache/runs/E0147/R000022"}
run_dir=${1:?usage: run-selected.sh <run-directory> [root] [source-run]}
selected_root=${2:-program}
run_dir="$(cd -- "$(dirname -- "$run_dir")" && pwd)/$(basename -- "$run_dir")"

if [[ -e "$run_dir" ]]; then
    printf 'refusing to overwrite run directory: %s\n' "$run_dir" >&2
    exit 2
fi
for file in standardir.sx classifications.sx roots.sx lexical-facts-v0.sx; do
    if [[ ! -f "$source_run/input/$file" ]]; then
        printf 'missing source evidence: %s/input/%s\n' "$source_run" "$file" >&2
        exit 2
    fi
done

mkdir -p "$run_dir/input"
for file in standardir.sx classifications.sx roots.sx lexical-facts-v0.sx; do
    cp "$source_run/input/$file" "$run_dir/input/$file"
done

preflight_status=0
python3 "$script_dir/preflight_source.py" "$run_dir/input/standardir.sx" \
    >"$run_dir/source-preflight.log" 2>&1 || preflight_status=$?
cat "$run_dir/source-preflight.log"
if (( preflight_status != 0 )); then
    printf 'source preflight failed; no grammar generator was invoked\n' >&2
    exit "$preflight_status"
fi

(cd "$standard_root" && fo)
for format in ebnf antlr bison treesitter; do
    case "$format" in
        ebnf) output="$run_dir/grammar.ebnf" ;;
        antlr) output="$run_dir/Fortran2023.g4" ;;
        bison) output="$run_dir/fortran2023.y" ;;
        treesitter) output="$run_dir/grammar.js" ;;
    esac
    (
        cd "$standard_root"
        /usr/bin/time -f 'elapsed_seconds=%e' fo exec --no-build sxgrammar \
            "$run_dir/input/standardir.sx" \
            "$run_dir/input/classifications.sx" \
            "$run_dir/input/roots.sx" \
            "$run_dir/input/lexical-facts-v0.sx" \
            "$format" "$output" --selected-root "$selected_root"
    ) >"$run_dir/generate-$format.log" 2>&1
done

{
    printf 'field\tvalue\n'
    printf 'experiment\tE0154\n'
    printf 'standard-new-commit\t%s\n' "$(git -C "$standard_root" rev-parse HEAD)"
    printf 'lazy-fortran-new-commit\t%s\n' "$(git -C "$lab_root" rev-parse HEAD)"
    printf 'source-run\t%s\n' "$source_run"
    printf 'selected-root\t%s\n' "$selected_root"
printf 'source-syntax-records\t%s\n' "$(grep -c '^(syntax ' "$run_dir/input/standardir.sx")"
printf 'source_preflight_status\t%s\n' "$preflight_status"
} >"$run_dir/metadata.tsv"

identity_status=0
"$script_dir/analyse.sh" "$run_dir" "$run_dir/input/standardir.sx" >"$run_dir/identity.log" 2>&1 || identity_status=$?
cat "$run_dir/identity.log"

if (( identity_status != 0 )); then
    printf 'independent identity gate failed; parser oracles were not invoked\n' >&2
    printf 'identity_status\t%s\n' "$identity_status" >>"$run_dir/metadata.tsv"
    exit "$identity_status"
fi

validator_status=0
"$lab_root/research/experiments/E0147-can-source-backed-standardir-validity-close/validate-grammar-exports.sh" \
    "$run_dir" "$run_dir/grammar-oracles.tsv" >"$run_dir/target-oracles.log" 2>&1 || validator_status=$?
cat "$run_dir/target-oracles.log"

printf 'identity_status\t%s\n' "$identity_status" >>"$run_dir/metadata.tsv"
printf 'target_validator_status\t%s\n' "$validator_status" >>"$run_dir/metadata.tsv"
if (( validator_status != 0 )); then
    exit 1
fi
