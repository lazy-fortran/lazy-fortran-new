#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
standard_root=$(cd -- "$lab_root/../standard-new" && pwd)
source_run=${3:-"$lab_root/.cache/runs/E0147/R000022"}
role_family=${4:-}
run_dir=${1:?usage: run-selected.sh <run-directory> [root|all] [source-run] [role-family]}
selected_root=${2:-program}
run_dir="$(cd -- "$(dirname -- "$run_dir")" && pwd)/$(basename -- "$run_dir")"

selected_mode=true
if [[ "$selected_root" == all ]]; then
    selected_mode=false
fi

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
(
    cd "$standard_root"
    /usr/bin/time -f 'elapsed_seconds=%e' fo exec --no-build sxlexercontract \
        "$run_dir/input/lexical-facts-v0.sx" "$run_dir/lexer-contract.jsonl"
) >"$run_dir/generate-lexer-contract.log" 2>&1
for format in ebnf antlr bison treesitter; do
    case "$format" in
        ebnf) output="$run_dir/grammar.ebnf" ;;
        antlr) output="$run_dir/Fortran2023.g4" ;;
        bison) output="$run_dir/fortran2023.y" ;;
        treesitter) output="$run_dir/grammar.js" ;;
    esac
    generator=(fo exec --no-build sxgrammar \
        "$run_dir/input/standardir.sx" \
        "$run_dir/input/classifications.sx" \
        "$run_dir/input/roots.sx" \
        "$run_dir/input/lexical-facts-v0.sx" \
        "$format" "$output")
    if "$selected_mode"; then
        generator+=(--selected-root "$selected_root")
    fi
    if [[ -n "$role_family" ]]; then
        generator+=(--role-family "$role_family")
    fi
    (
        cd "$standard_root"
        /usr/bin/time -f 'elapsed_seconds=%e' "${generator[@]}"
    ) >"$run_dir/generate-$format.log" 2>&1
done

{
    printf 'field\tvalue\n'
    printf 'experiment\t%s\n' "$(basename "$(dirname "$run_dir")")"
    printf 'standard-new-commit\t%s\n' "$(git -C "$standard_root" rev-parse HEAD)"
    printf 'lazy-fortran-new-commit\t%s\n' "$(git -C "$lab_root" rev-parse HEAD)"
    printf 'source-run\t%s\n' "$source_run"
if "$selected_mode"; then
    printf 'selected-root\t%s\n' "$selected_root"
else
    printf 'selected-root\tall-roots\n'
fi
printf 'source-syntax-records\t%s\n' "$(grep -c '^(syntax ' "$run_dir/input/standardir.sx")"
printf 'source_preflight_status\t%s\n' "$preflight_status"
printf 'role_family\t%s\n' "${role_family:-none}"
} >"$run_dir/metadata.tsv"

identity_status=0
"$script_dir/analyse.sh" "$run_dir" "$run_dir/input/standardir.sx" >"$run_dir/identity.log" 2>&1 || identity_status=$?
cat "$run_dir/identity.log"

if (( identity_status != 0 )); then
    printf 'independent identity gate failed; parser oracles were not invoked\n' >&2
    printf 'identity_status\t%s\n' "$identity_status" >>"$run_dir/metadata.tsv"
    exit "$identity_status"
fi

lexical_status=0
"$lab_root/research/experiments/E0156-can-all-grammar-exports-honor-canonical-lexical-spellings/check.sh" \
    "$run_dir" "$run_dir/lexical-witnesses.tsv" >"$run_dir/lexical-witnesses.log" 2>&1 || lexical_status=$?
cat "$run_dir/lexical-witnesses.log"
printf 'lexical_witness_status\t%s\n' "$lexical_status" >>"$run_dir/metadata.tsv"
if (( lexical_status != 0 )); then
    printf 'independent lexical witness gate failed; parser oracles were not invoked\n' >&2
    exit "$lexical_status"
fi

profile_status=0
python3 "$lab_root/research/experiments/E0171-can-current-standardir-grammar-projectio/validate-profile-contract.py" \
    "$run_dir" \
    "$lab_root/research/experiments/E0171-can-current-standardir-grammar-projectio/profile-policy.tsv" \
    "$run_dir/profile-contract.tsv" >"$run_dir/profile-contract.log" 2>&1 || profile_status=$?
cat "$run_dir/profile-contract.log"
printf 'profile_contract_status\t%s\n' "$profile_status" >>"$run_dir/metadata.tsv"
if (( profile_status != 0 )); then
    printf 'selected profile contract failed; parser oracles were not invoked\n' >&2
    exit "$profile_status"
fi

if [[ -n "$role_family" ]]; then
    role_family_status=0
    python3 "$lab_root/research/experiments/E0160-can-generic-role-family-specialization-preserve-language/check_role_family.py" \
        "$run_dir/input/standardir.sx" "$run_dir" "$run_dir/role-family-witnesses.tsv" \
        >"$run_dir/role-family-witnesses.log" 2>&1 || role_family_status=$?
    cat "$run_dir/role-family-witnesses.log"
    printf 'role_family_witness_status\t%s\n' "$role_family_status" >>"$run_dir/metadata.tsv"
    if (( role_family_status != 0 )); then
        printf 'independent role-family witness gate failed; parser oracles were not invoked\n' >&2
        exit "$role_family_status"
    fi
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
