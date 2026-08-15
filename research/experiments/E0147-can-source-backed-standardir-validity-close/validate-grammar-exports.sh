#!/usr/bin/env bash
set -u

usage() {
    printf '%s\n' "usage: $0 RUN-DIRECTORY [REPORT.tsv]" >&2
    exit 2
}

run_dir=${1-}
if [[ -z "$run_dir" ]]; then
    usage
fi
report=${2:-"$run_dir/grammar-oracles.tsv"}

for file in \
    "$run_dir/Fortran2023.g4" \
    "$run_dir/fortran2023.y" \
    "$run_dir/grammar.js"; do
    if [[ ! -f "$file" ]]; then
        printf 'missing input: %s\n' "$file" >&2
        exit 2
    fi
done

for tool in antlr4 bison tree-sitter; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'missing tool: %s\n' "$tool" >&2
        exit 2
    fi
done

count_matches() {
    pattern=$1
    file=$2
    count=$(grep -E -c "$pattern" "$file" || true)
    printf '%s' "${count:-0}"
}

work=$(mktemp -d /tmp/e0147-grammar-oracles.XXXXXX)
cleanup() {
    rm -rf -- "$work"
}
trap cleanup EXIT
mkdir "$work/antlr" "$work/bison" "$work/tree-sitter"

antlr4 >"$work/antlr-version.txt" 2>&1 || true
antlr_version=$(head -n 1 "$work/antlr-version.txt")
bison_version=$(bison --version | head -n 1)
tree_sitter_version=$(tree-sitter --version)

run_antlr=0
antlr4 -Werror -o "$work/antlr" "$run_dir/Fortran2023.g4" \
    >"$work/antlr.log" 2>&1 || run_antlr=$?

run_bison=0
bison --warnings=all -o "$work/bison/fortran2023.c" "$run_dir/fortran2023.y" \
    >"$work/bison.log" 2>&1 || run_bison=$?

cp "$run_dir/grammar.js" "$work/tree-sitter/grammar.js"
printf '%s\n' '{"grammars":["grammar.js"],"metadata":{"version":"1.0.0"}}' \
    >"$work/tree-sitter/tree-sitter.json"
run_tree_sitter=0
(cd "$work/tree-sitter" && tree-sitter generate) \
    >"$work/tree-sitter.log" 2>&1 || run_tree_sitter=$?

first_reference=$(grep -oE 'r_[A-Za-z0-9_]+' "$run_dir/Fortran2023.g4" | head -n 1 || true)
if [[ -z "$first_reference" ]]; then
    printf 'could not find a grammar reference for the negative control\n' >&2
    exit 2
fi
mutated_reference=r_e0147_unknown_control
mkdir "$work/mutated"
sed "0,/${first_reference}/s//${mutated_reference}/" "$run_dir/Fortran2023.g4" \
    >"$work/mutated/Fortran2023.g4"
sed "0,/${first_reference}/s//${mutated_reference}/" "$run_dir/fortran2023.y" \
    >"$work/mutated/fortran2023.y"
sed "0,/${first_reference}/s//${mutated_reference}/" "$run_dir/grammar.js" \
    >"$work/mutated/grammar.js"
mkdir "$work/mutated/antlr" "$work/mutated/bison" "$work/mutated/tree-sitter"
negative_antlr=0
antlr4 -Werror -o "$work/mutated/antlr" "$work/mutated/Fortran2023.g4" \
    >"$work/mutated/antlr.log" 2>&1 || negative_antlr=$?
negative_bison=0
bison --warnings=all -o "$work/mutated/bison/fortran2023.c" \
    "$work/mutated/fortran2023.y" >"$work/mutated/bison.log" 2>&1 || negative_bison=$?
cp "$work/mutated/grammar.js" "$work/mutated/tree-sitter/grammar.js"
printf '%s\n' '{"grammars":["grammar.js"],"metadata":{"version":"1.0.0"}}' \
    >"$work/mutated/tree-sitter/tree-sitter.json"
negative_tree_sitter=0
(cd "$work/mutated/tree-sitter" && tree-sitter generate) \
    >"$work/mutated/tree-sitter.log" 2>&1 || negative_tree_sitter=$?
negative_mentions=$((
    $(count_matches "$mutated_reference" "$work/mutated/antlr.log") +
    $(count_matches "$mutated_reference" "$work/mutated/bison.log") +
    $(count_matches "$mutated_reference" "$work/mutated/tree-sitter.log")
))
negative_control=$([[ $negative_antlr -ne 0 && $negative_bison -ne 0 && \
    $negative_tree_sitter -ne 0 && $negative_mentions -gt 0 ]] && \
    printf observed_failure || printf FAILED)

antlr_errors=$(count_matches '^error\(' "$work/antlr.log")
bison_errors=$(count_matches 'error:' "$work/bison.log")
tree_errors=$(count_matches 'Error:|ReferenceError:|SyntaxError:' "$work/tree-sitter.log")
antlr_warnings=$(count_matches '^warning\(' "$work/antlr.log")
bison_warnings=$(count_matches 'warning:' "$work/bison.log")
tree_warnings=$(count_matches 'Warning:' "$work/tree-sitter.log")
bison_shift_reduce_conflicts=$(grep -Eo '[0-9]+ shift/reduce conflicts' "$work/bison.log" | awk 'NR == 1 { print $1 }' || true)
bison_reduce_reduce_conflicts=$(grep -Eo '[0-9]+ reduce/reduce conflicts' "$work/bison.log" | awk 'NR == 1 { print $1 }' || true)
bison_shift_reduce_conflicts=${bison_shift_reduce_conflicts:-0}
bison_reduce_reduce_conflicts=${bison_reduce_reduce_conflicts:-0}
bison_useless_rule_warnings=$(count_matches 'rule useless in parser due to conflicts' "$work/bison.log")
undefined_symbols=$((
    $(count_matches 'undefined rule|undefined symbol|used, but is not defined' "$work/antlr.log") +
    $(count_matches 'undefined rule|undefined symbol|used, but is not defined' "$work/bison.log") +
    $(count_matches 'Undefined symbol|undefined rule' "$work/tree-sitter.log")
))

source_projection_status=0
bash "$(dirname "$0")/audit-source-projection.sh" "$run_dir" \
    >"$run_dir/source-projection.log" 2>&1 || source_projection_status=$?

mkdir -p "$(dirname "$report")"
{
    printf 'oracle\tstatus\texit\tversion\tlog\n'
    printf 'antlr4\t%s\t%s\t%s\t%s\n' \
        "$([[ $run_antlr -eq 0 ]] && printf PASS || printf FAIL)" \
        "$run_antlr" "$antlr_version" "$run_dir/antlr4.log"
    printf 'bison\t%s\t%s\t%s\t%s\n' \
        "$([[ $run_bison -eq 0 ]] && printf PASS || printf FAIL)" \
        "$run_bison" "$bison_version" "$run_dir/bison.log"
    printf 'tree-sitter\t%s\t%s\t%s\t%s\n' \
        "$([[ $run_tree_sitter -eq 0 ]] && printf PASS || printf FAIL)" \
        "$run_tree_sitter" "$tree_sitter_version" "$run_dir/tree-sitter.log"
    printf 'ebnf\tNOT_APPLICABLE\t0\tprojection-only\t%s\n' \
        "$run_dir/grammar.ebnf"
    printf 'source-projection\t%s\t%s\tdeterministic provenance witness\t%s\n' \
        "$([[ $source_projection_status -eq 0 ]] && printf PASS || printf FAIL)" \
        "$source_projection_status" "$run_dir/source-projection.log"
    printf 'overall\t%s\t%s\tsource-backed projection and generated exports\t%s\n' \
        "$([[ $run_antlr -eq 0 && $run_bison -eq 0 && $run_tree_sitter -eq 0 && \
            $undefined_symbols -eq 0 && \
            "$negative_control" == observed_failure && $source_projection_status -eq 0 ]] && \
            printf PASS || printf ORACLE_FAILURE)" \
        "$((run_antlr + run_bison + run_tree_sitter))" \
        "$run_dir"
    printf 'metric\tvalue\t\t\t\n'
    printf 'antlr_errors\t%s\t\t\t\n' "$antlr_errors"
    printf 'bison_errors\t%s\t\t\t\n' "$bison_errors"
    printf 'tree_sitter_errors\t%s\t\t\t\n' "$tree_errors"
    printf 'antlr_warnings\t%s\t\t\t\n' "$antlr_warnings"
    printf 'bison_warnings\t%s\t\t\t\n' "$bison_warnings"
    printf 'bison_shift_reduce_conflicts\t%s\t\t\t\n' "$bison_shift_reduce_conflicts"
    printf 'bison_reduce_reduce_conflicts\t%s\t\t\t\n' "$bison_reduce_reduce_conflicts"
    printf 'bison_useless_rule_warnings\t%s\t\t\t\n' "$bison_useless_rule_warnings"
    printf 'tree_sitter_warnings\t%s\t\t\t\n' "$tree_warnings"
    printf 'undefined_symbol_diagnostics\t%s\t\t\t\n' "$undefined_symbols"
    printf 'negative_control\t%s\t\t\t\n' "$negative_control"
    printf 'negative_control_mentions\t%s\t\t\t\n' "$negative_mentions"
    printf 'source_projection_status\t%s\t\t\t\n' "$source_projection_status"
} >"$report"

cp "$work/antlr.log" "$run_dir/antlr4.log"
cp "$work/bison.log" "$run_dir/bison.log"
cp "$work/tree-sitter.log" "$run_dir/tree-sitter.log"
cp "$work/mutated/antlr.log" "$run_dir/antlr4-negative.log"
cp "$work/mutated/bison.log" "$run_dir/bison-negative.log"
cp "$work/mutated/tree-sitter.log" "$run_dir/tree-sitter-negative.log"

cat "$report"

if [[ $run_antlr -ne 0 || $run_bison -ne 0 || $run_tree_sitter -ne 0 ||
    $undefined_symbols -ne 0 ||
    "$negative_control" != observed_failure || $source_projection_status -ne 0 ]]; then
    exit 1
fi
