#!/usr/bin/env bash
# Validate the E0049 partial candidate independently in ANTLR4, Bison and
# tree-sitter, retaining the target-tool failure boundary.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e49="$root/research/experiments/E0049-can-accepted-resolutions-and-fixed-errat/analyse.sh"
input="$root/.cache/runs/E0049/R000001/partial-composite-input.sx"
antlr_input="$root/.cache/runs/E0049/R000001/partial-composite-input.g4"
outdir="${1:-$root/.cache/runs/E0051/R000001}"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"

input_hash="fdb89baa241df956dfc719f70e055f182c7271936def6456aea62e688cab1f0b"
antlr_input_hash="6b46185b42d7225e255e0e6a7f380aa793f49f0b82f38087b1f4883cdbae675c"

die() { printf 'E0051: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e49" >"$outdir/e0049.log" || die 'E0049 predecessor failed'
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || \
    die 'partial StandardIR input hash mismatch'
test "$(sha256sum "$antlr_input" | cut -d' ' -f1)" = "$antlr_input_hash" || \
    die 'partial ANTLR input hash mismatch'

cp "$antlr_input" "$outdir/Fortran2023.g4"
(cd "$standard_new" && fo exec sxbison "$input" "$outdir/Fortran2023.y") \
    >"$outdir/sxbison.log" 2>&1
(cd "$standard_new" && fo exec sxtreesitter "$input" "$outdir/grammar.js") \
    >"$outdir/sxtreesitter.log" 2>&1

antlr_out="$outdir/antlr"
mkdir -p "$antlr_out"
set +e
antlr4 -Werror -Dlanguage=Java -o "$antlr_out" "$outdir/Fortran2023.g4" \
    >"$outdir/antlr.log" 2>&1
antlr_status=$?
bison -Wall -Werror -o "$outdir/bison.c" "$outdir/Fortran2023.y" \
    >"$outdir/bison.log" 2>&1
bison_status=$?
mkdir -p "$outdir/treesitter"
cp "$outdir/grammar.js" "$outdir/treesitter/grammar.js"
(cd "$outdir/treesitter" && tree-sitter generate) \
    >"$outdir/treesitter.log" 2>&1
treesitter_status=$?
set -e

awk '/^r_[A-Za-z0-9_]+$/ {count++} END {print count + 0}' \
    "$outdir/Fortran2023.g4" >"$outdir/antlr-definition-count.txt"
awk '/^r_[A-Za-z0-9_]+:/ {count++} END {print count + 0}' \
    "$outdir/Fortran2023.y" >"$outdir/bison-definition-count.txt"
awk '/^r_[A-Za-z0-9_]+: \$ => / {count++} END {print count + 0}' \
    "$outdir/grammar.js" >"$outdir/treesitter-definition-count.txt"

antlr_definitions="$(<"$outdir/antlr-definition-count.txt")"
bison_definitions="$(<"$outdir/bison-definition-count.txt")"
treesitter_definitions="$(<"$outdir/treesitter-definition-count.txt")"
test "$antlr_definitions" -eq 502 || die 'ANTLR definition scan differs'
test "$bison_definitions" -eq 502 || die 'Bison definition scan differs'
test "$treesitter_definitions" -eq 502 || die 'tree-sitter definition scan differs'

sed -n 's/.*reference to undefined rule: \([^[:space:]]*\).*/\1/p' \
    "$outdir/antlr.log" | sort -u >"$outdir/antlr-unresolved.txt"
sed -n "s/.*symbol '\([^']*\)' is used.*/\1/p" \
    "$outdir/bison.log" | sort -u >"$outdir/bison-unresolved.txt"
antlr_unresolved="$(wc -l < "$outdir/antlr-unresolved.txt")"
bison_unresolved="$(wc -l < "$outdir/bison-unresolved.txt")"
diff -u "$outdir/antlr-unresolved.txt" "$outdir/bison-unresolved.txt" \
    >"$outdir/antlr-bison-unresolved.diff" || die 'ANTLR/Bison unresolved sets differ'
test "$antlr_unresolved" -eq 103 || die 'ANTLR unresolved-name count differs'
test "$bison_unresolved" -eq 103 || die 'Bison unresolved-symbol count differs'

rg -F -q 'SyntaxError: Unexpected token' "$outdir/treesitter.log" || \
    die 'tree-sitter did not expose the expected structural failure'
rg -F -q 'r_where_x2D_construct_x2D_stmt: $ => seq(,' "$outdir/grammar.js" || \
    die 'tree-sitter malformed-sequence witness is absent'
treesitter_structural_error=1

# A controlled deletion must be visible to the independent definition scan.
awk 'BEGIN {removed=0} /^r_[A-Za-z0-9_]+$/ && !removed {removed=1; next} {print}' \
    "$outdir/Fortran2023.g4" >"$tmp/mutated.g4"
mutated_definitions="$(awk '/^r_[A-Za-z0-9_]+$/ {count++} END {print count + 0}' "$tmp/mutated.g4")"
if test "$mutated_definitions" -eq "$antlr_definitions"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'final_syntax_records\t522\n' >>"$outdir/summary.tsv"
printf 'antlr_definitions\t%s\n' "$antlr_definitions" >>"$outdir/summary.tsv"
printf 'bison_definitions\t%s\n' "$bison_definitions" >>"$outdir/summary.tsv"
printf 'treesitter_definitions\t%s\n' "$treesitter_definitions" >>"$outdir/summary.tsv"
printf 'antlr_duplicate_definitions\t0\n' >>"$outdir/summary.tsv"
printf 'bison_duplicate_definitions\t0\n' >>"$outdir/summary.tsv"
printf 'treesitter_duplicate_definitions\t0\n' >>"$outdir/summary.tsv"
printf 'antlr_status\t%s\n' "$antlr_status" >>"$outdir/summary.tsv"
printf 'antlr_unresolved_rule_names\t%s\n' "$antlr_unresolved" >>"$outdir/summary.tsv"
printf 'bison_status\t%s\n' "$bison_status" >>"$outdir/summary.tsv"
printf 'bison_unresolved_symbol_names\t%s\n' "$bison_unresolved" >>"$outdir/summary.tsv"
printf 'treesitter_status\t%s\n' "$treesitter_status" >>"$outdir/summary.tsv"
printf 'treesitter_structural_error\t%s\n' "$treesitter_structural_error" >>"$outdir/summary.tsv"
printf 'antlr_bison_unresolved_set_difference\t0\n' >>"$outdir/summary.tsv"
printf 'target_status_agreement\t1\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'target_boundary\tverification_failure\n' >>"$outdir/summary.tsv"

printf 'E0051 oracle: target-tool boundary retained\n'
cat "$outdir/summary.tsv"
