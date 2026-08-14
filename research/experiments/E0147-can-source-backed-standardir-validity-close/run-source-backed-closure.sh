#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
standard_root=$(cd -- "$lab_root/../standard-new" && pwd)
base_run="$lab_root/.cache/runs/E0147/R000002"
run_dir="${1:-$lab_root/.cache/runs/E0147/R000003}"

if [[ ! -d "$base_run" ]]; then
    printf 'missing source-backed base run: %s\n' "$base_run" >&2
    exit 2
fi
if [[ -e "$run_dir" ]]; then
    printf 'refusing to overwrite run directory: %s\n' "$run_dir" >&2
    exit 2
fi
for file in standardir.sx classifications.sx roots.sx productions.jsonl audit.txt; do
    if [[ ! -f "$base_run/$file" ]]; then
        printf 'missing base-run evidence: %s\n' "$base_run/$file" >&2
        exit 2
    fi
done

mkdir -p "$run_dir/input"
cp "$base_run/standardir.sx" "$run_dir/input/standardir.sx"
cp "$base_run/productions.jsonl" "$run_dir/input/productions.jsonl"
cp "$base_run/audit.txt" "$run_dir/input/audit.txt"

source_hash=$(grep -m 1 -oE 'source-(sha256|hash) [0-9a-f]{64}' \
    "$run_dir/input/standardir.sx" | sed -E 's/.* //')
if [[ -z "$source_hash" ]]; then
    printf 'could not recover source hash from StandardIR input\n' >&2
    exit 2
fi

# R402 is a source-backed definition: every *-name is a name.  The five
# listed names are the same source-defined family but have no syntax record;
# they are retained as explicit implicit aliases rather than guessed parser
# rules.  This is the fixed closure policy under D0086.
sed -E '/\(kind alias\)/ s/\(target [^)]*\)/(target name)/' \
    "$base_run/classifications.sx" >"$run_dir/input/classifications.sx"
for name in enumerator-name external-name final-subroutine-name import-name \
    intrinsic-procedure-name; do
    printf '%s\n' \
        "(classification (name $name) (kind alias) (target name) (family R402) (suffix -name) (source (document J3-24-007) (clause 4.1.3) (rule R402) (page 45) (source-hash $source_hash)))" \
        >>"$run_dir/input/classifications.sx"
done

# The historical roots record is one oversized SX list.  Normalize it to one
# record per line so the bounded command-line reader never sees a truncated
# Fortran character record.
grep -o '(root [^)]*)' "$base_run/roots.sx" >"$run_dir/input/roots.sx"
cp "$standard_root/specs/lexical-facts-v0.sx" "$run_dir/input/lexical-facts-v0.sx"

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
            "$format" "$output"
    ) >"$run_dir/generate-$format.log" 2>&1
done

"$script_dir/validate-grammar-exports.sh" "$run_dir" \
    "$run_dir/grammar-oracles.tsv" >"$run_dir/validate.log" 2>&1

{
    printf 'field\tvalue\n'
    printf 'experiment\tE0147\n'
    printf 'standard-new-commit\t%s\n' "$(git -C "$standard_root" rev-parse HEAD)"
    printf 'lazy-fortran-new-commit\t%s\n' "$(git -C "$lab_root" rev-parse HEAD)"
    printf 'source-sha256\t%s\n' "$source_hash"
    printf 'standardir-records\t%s\n' "$(grep -c '^(syntax ' "$run_dir/input/standardir.sx")"
    printf 'classifications\t%s\n' "$(grep -c '^(classification ' "$run_dir/input/classifications.sx")"
    printf 'roots\t%s\n' "$(grep -c '^(root ' "$run_dir/input/roots.sx")"
} >"$run_dir/metadata.tsv"

cat "$run_dir/validate.log"
