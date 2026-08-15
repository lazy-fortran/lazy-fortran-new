#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
run_dir_arg=${1:?usage: run-language-gate.sh <run-directory> <baseline-run> <candidate-run>}
baseline=${2:?usage: run-language-gate.sh <run-directory> <baseline-run> <candidate-run>}
candidate=${3:?usage: run-language-gate.sh <run-directory> <baseline-run> <candidate-run>}
run_dir=$(cd -- "$(dirname -- "$run_dir_arg")" && pwd)/$(basename -- "$run_dir_arg")
baseline=$(cd -- "$baseline" && pwd)
candidate=$(cd -- "$candidate" && pwd)

if [[ -e "$run_dir" ]]; then
    printf 'refusing to overwrite run directory: %s\n' "$run_dir" >&2
    exit 2
fi
for directory in "$baseline" "$candidate"; do
    for file in grammar.ebnf Fortran2023.g4 fortran2023.y grammar.js; do
        if [[ ! -f "$directory/$file" ]]; then
            printf 'missing grammar output: %s/%s\n' "$directory" "$file" >&2
            exit 2
        fi
    done
done

mkdir -p "$run_dir"
compare=(python3 "$script_dir/compare_language.py" "$baseline/grammar.ebnf" \
    "$candidate/grammar.ebnf" --root program --root data-ref \
    --role-family-file "$candidate/grammar.ebnf" \
    --corpus "$run_dir/language-corpus.jsonl" \
    --report "$run_dir/language-report.json" --max-depth 8 --max-tokens 4 \
    --max-words 256 --max-negative 64 --repeat-limit 1)
set +e
"${compare[@]}" >"$run_dir/language-check.log" 2>&1
status=$?
set -e
cat "$run_dir/language-check.log"

{
    printf 'field\tvalue\n'
    printf 'experiment\tE0161\n'
    printf 'baseline-run\t%s\n' "$baseline"
    printf 'candidate-run\t%s\n' "$candidate"
    printf 'baseline-grammar-sha256\t%s\n' "$(sha256sum "$baseline/grammar.ebnf" | awk '{print $1}')"
    printf 'candidate-grammar-sha256\t%s\n' "$(sha256sum "$candidate/grammar.ebnf" | awk '{print $1}')"
    printf 'command\t%s\n' "${compare[*]}"
    printf 'status\t%s\n' "$status"
} >"$run_dir/metadata.tsv"

exit "$status"
