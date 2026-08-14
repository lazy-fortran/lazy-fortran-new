#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard_new="$root/../standard-new"
input="${E0134_INPUT:-$root/.cache/runs/E0055/R000001/composite-input.sx}"
source_input="${E0134_SOURCE_INPUT:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
outdir="${1:-$root/.cache/runs/E0134/R000001}"

die() { printf 'E0134: %s\n' "$1" >&2; exit 1; }
test -d "$standard_new" || die 'standard-new checkout is missing'
test -f "$input" || die "composite input is missing: $input"
test -f "$source_input" || die "source input is missing: $source_input"
mkdir -p "$outdir"

source_records="$(rg -c '^\(syntax ' "$source_input")"
composite_records="$(rg -c '^\(syntax ' "$input")"
test "$source_records" -eq 522 || die 'source record denominator changed'
test "$composite_records" -eq 519 || die 'composite record denominator changed'

(
    cd "$standard_new"
    fo exec sxebnf "$input" "$outdir/grammar.ebnf"
    fo exec sxantlr "$input" "$outdir/grammar.g4"
    fo exec sxbison "$input" "$outdir/grammar.y"
    fo exec sxtreesitter "$input" "$outdir/grammar.js"
) >"$outdir/export.log" 2>&1 || die 'one of the four exporters failed'

# EBNF keeps alternatives in one production and may place a later annotation
# after the preceding expression on the same line. Count provenance tokens,
# not physical lines, for every format.
ebnf_records="$(rg -o 'rule=' "$outdir/grammar.ebnf" | wc -l | tr -d ' ')"
antlr_records="$(rg -o 'rule=' "$outdir/grammar.g4" | wc -l | tr -d ' ')"
bison_records="$(rg -o 'rule=' "$outdir/grammar.y" | wc -l | tr -d ' ')"
treesitter_records="$(rg -o 'rule=' "$outdir/grammar.js" | wc -l | tr -d ' ')"
test "$ebnf_records" -eq "$composite_records" || die 'EBNF provenance count differs'
test "$antlr_records" -eq "$composite_records" || die 'ANTLR provenance count differs'
test "$bison_records" -eq "$composite_records" || die 'Bison provenance count differs'
test "$treesitter_records" -eq "$composite_records" || die 'tree-sitter provenance count differs'

mutated="$outdir/mutated.sx"
sed '1s/(syntax R501 /(syntax R501_MUTATED /' "$input" >"$mutated"
(
    cd "$standard_new"
    fo exec sxebnf "$mutated" "$outdir/mutated.ebnf"
) >>"$outdir/export.log" 2>&1 || die 'mutated control could not be exported'
cmp -s "$outdir/grammar.ebnf" "$outdir/mutated.ebnf" && die 'LHS mutation did not change EBNF'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'source_record_count\t%s\n' "$source_records" >>"$outdir/summary.tsv"
printf 'composite_record_count\t%s\n' "$composite_records" >>"$outdir/summary.tsv"
printf 'deferred_source_records\t%s\n' "$((source_records - composite_records))" >>"$outdir/summary.tsv"
printf 'ebnf_provenance_records\t%s\n' "$ebnf_records" >>"$outdir/summary.tsv"
printf 'antlr4_provenance_records\t%s\n' "$antlr_records" >>"$outdir/summary.tsv"
printf 'bison_provenance_records\t%s\n' "$bison_records" >>"$outdir/summary.tsv"
printf 'tree_sitter_provenance_records\t%s\n' "$treesitter_records" >>"$outdir/summary.tsv"
printf 'mutation_control\tchanged\n' >>"$outdir/summary.tsv"
printf 'format_count\t4\n' >>"$outdir/summary.tsv"
printf 'E0134 corpus export regression: accepted\n'
cat "$outdir/summary.tsv"
