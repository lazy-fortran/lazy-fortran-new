#!/usr/bin/env bash
# Validate grouped StandardIR syntax exports with their target tools.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
outdir="${2:-$root/.cache/runs/E0021/R000001}"
standard="${STANDARD_REPO:-$root/../standard-new}"
standard_commit="7344c6559cfae4be0b31afd3876731b327863430"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash"
test "$(git -C "$standard" rev-parse HEAD)" = "$standard_commit"
test -z "$(git -C "$standard" status --porcelain)"
command -v antlr4 >/dev/null
command -v bison >/dev/null
command -v tree-sitter >/dev/null
mkdir -p "$outdir/exports" "$outdir/tree-sitter"

(cd "$standard" && fo exec sxebnf "$input" "$outdir/exports/Fortran2023.ebnf")
(cd "$standard" && fo exec sxantlr "$input" "$outdir/exports/Fortran2023.g4")
(cd "$standard" && fo exec sxbison "$input" "$outdir/exports/Fortran2023.y")
(cd "$standard" && fo exec sxtreesitter "$input" "$outdir/exports/grammar.js")

syntax_records="$(awk '/^\(syntax / {count++} END {print count+0}' "$input")"
unique_lhs="$(awk '/^\(syntax / {x=$4; gsub(/[()]/,"",x); print x}' "$input" | sort -u | wc -l)"
duplicate_lhs_records=$((syntax_records - unique_lhs))

antlr_definitions="$(awk '/^r_[A-Za-z0-9_]+$/ {print}' "$outdir/exports/Fortran2023.g4" | sort -u | wc -l)"
antlr_duplicate_definitions="$(awk '/^r_[A-Za-z0-9_]+$/ {print}' "$outdir/exports/Fortran2023.g4" | sort | uniq -d | wc -l)"
bison_definitions="$(awk '/^r_[A-Za-z0-9_]+:/ {sub(/:$/,"",$1); print $1}' "$outdir/exports/Fortran2023.y" | sort -u | wc -l)"
bison_duplicate_definitions="$(awk '/^r_[A-Za-z0-9_]+:/ {sub(/:$/,"",$1); print $1}' "$outdir/exports/Fortran2023.y" | sort | uniq -d | wc -l)"
treesitter_definitions="$(awk '/^r_[A-Za-z0-9_]+: \$ =>/ {sub(/:.*$/,"",$1); print $1}' "$outdir/exports/grammar.js" | sort -u | wc -l)"
treesitter_duplicate_definitions="$(awk '/^r_[A-Za-z0-9_]+: \$ =>/ {sub(/:.*$/,"",$1); print $1}' "$outdir/exports/grammar.js" | sort | uniq -d | wc -l)"

set +e
LC_ALL=C antlr4 -Werror -Dlanguage=Java -o "$outdir/antlr" \
    "$outdir/exports/Fortran2023.g4" >"$outdir/antlr.log" 2>&1
antlr_status=$?
LC_ALL=C bison -Wall -Werror -o "$outdir/bison.c" \
    "$outdir/exports/Fortran2023.y" >"$outdir/bison.log" 2>&1
bison_status=$?
cp "$outdir/exports/grammar.js" "$outdir/tree-sitter/grammar.js"
(cd "$outdir/tree-sitter" && tree-sitter generate) >"$outdir/tree-sitter.log" 2>&1
treesitter_status=$?
set -e

antlr_unresolved_rule_names="$(sed -n 's/.*reference to undefined rule: \([^ ]*\).*/\1/p' \
    "$outdir/antlr.log" | sort -u | wc -l)"
bison_unresolved_symbol_names="$(sed -n "s/.*symbol '\([^']*\)' is used.*/\1/p" \
    "$outdir/bison.log" | sort -u | wc -l)"
treesitter_first_unresolved_symbol="$(grep -v '\${propertyName}' "$outdir/tree-sitter.log" | \
    sed -n "s/.*Undefined symbol '\([^']*\)'.*/\1/p" | head -n 1)"

test "$syntax_records" -eq 522
test "$unique_lhs" -eq 502
test "$duplicate_lhs_records" -eq 20
test "$antlr_definitions" -eq 502
test "$bison_definitions" -eq 502
test "$treesitter_definitions" -eq 502
test "$antlr_duplicate_definitions" -eq 0
test "$bison_duplicate_definitions" -eq 0
test "$treesitter_duplicate_definitions" -eq 0
test "$antlr_status" -eq 1
test "$bison_status" -eq 1
test "$treesitter_status" -eq 1
test "$antlr_unresolved_rule_names" -eq 181
test "$bison_unresolved_symbol_names" -eq 181
test "$treesitter_first_unresolved_symbol" = r_xyz

printf 'target\tdefinitions\tduplicate_definitions\tstatus\tunresolved\n' >"$outdir/summary.tsv"
printf 'antlr4\t%s\t%s\t%s\t%s\n' "$antlr_definitions" \
    "$antlr_duplicate_definitions" "$antlr_status" "$antlr_unresolved_rule_names" >>"$outdir/summary.tsv"
printf 'bison\t%s\t%s\t%s\t%s\n' "$bison_definitions" \
    "$bison_duplicate_definitions" "$bison_status" "$bison_unresolved_symbol_names" >>"$outdir/summary.tsv"
printf 'tree-sitter\t%s\t%s\t%s\t%s\n' "$treesitter_definitions" \
    "$treesitter_duplicate_definitions" "$treesitter_status" "$treesitter_first_unresolved_symbol" >>"$outdir/summary.tsv"

printf 'E0021 validator result: duplicate lhs definitions are normalized; lexical/full-source references remain unresolved\n'
cat "$outdir/summary.tsv"
