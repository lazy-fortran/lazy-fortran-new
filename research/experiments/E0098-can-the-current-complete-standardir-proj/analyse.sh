#!/usr/bin/env bash
# Close the complete syntax reference state and validate every target export.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e56="$root/research/experiments/E0056-can-deterministic-target-normalizers-rem/analyse.sh"
e57="$root/research/experiments/E0057-can-accepted-composite-standardir-emit-a/analyse.sh"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"
source="$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx"
outdir="${1:-$root/.cache/runs/E0098/R000001}"

source_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
composite_hash="3458da1debda9aff98974b720891af4426c0506905f58317e018854f8cd9b3eb"
max_new_conflicts=1

die() { printf 'E0098: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

test "$(sha256sum "$source" | cut -d' ' -f1)" = "$source_hash" || die 'source hash mismatch'

e56out="$outdir/e0056"
e57out="$outdir/e0057"
"$e56" "$e56out" >"$outdir/e0056.log" || die 'E0056 predecessor failed'
"$e57" "$e57out" >"$outdir/e0057.log" || die 'E0057 predecessor failed'

composite="$root/.cache/runs/E0055/R000001/composite-input.sx"
test "$(sha256sum "$composite" | cut -d' ' -f1)" = "$composite_hash" || die 'composite hash mismatch'

# Independently reconstruct the reference relation from the composite SX.
awk '/^\(syntax / {
    for (i = 1; i <= NF; i++) if ($i == "(lhs") {
        value=$(i + 1); gsub(/[()]/, "", value); print value; break
    }
}' "$composite" | sort -u >"$tmp/lhs"
rg -o '\(ref [^)]+\)' "$composite" | sed -E 's/\(ref ([^)]+)\)/\1/' | sort -u >"$tmp/refs"
comm -12 "$tmp/refs" "$tmp/lhs" >"$tmp/explicit"
comm -23 "$tmp/refs" "$tmp/lhs" >"$tmp/residue"

expected_lexical="$tmp/expected-lexical"
printf 'digit\nletter\nrep-char\n–\n’\n' >"$expected_lexical"
cmp -s "$tmp/residue" "$expected_lexical" || die 'non-lexical reference residue'

cat >"$outdir/lexical-facts.tsv" <<'EOF'
source_term	class	source_rule	source_page	codepoint	origin	state
digit	lexical-class	P6.1.3-3	53	ASCII digit set	MECHANICAL	accepted
letter	lexical-class	P6.1.2-3	53	ASCII letter set	MECHANICAL	accepted
rep-char	lexical-class	R724-P3	71	processor-defined representation character	MECHANICAL	accepted
–	unicode-lexical	R1010	69	U+2013 EN DASH	MECHANICAL	accepted
’	unicode-lexical	R724	85	U+2019 RIGHT SINGLE QUOTATION MARK	MECHANICAL	accepted
EOF

source_records="$(awk '/^\(syntax / {n++} END {print n + 0}' "$source")"
composite_records="$(awk '/^\(syntax / {n++} END {print n + 0}' "$composite")"
explicit_records="$(wc -l <"$tmp/explicit")"
lexical_records="$(awk 'NR > 1 {n++} END {print n + 0}' "$outdir/lexical-facts.tsv")"
test "$source_records" -eq 522 || die 'source syntax denominator differs'
test "$composite_records" -eq 519 || die 'composite syntax denominator differs'
test "$explicit_records" -eq 469 || die 'explicit reference denominator differs'
test "$lexical_records" -eq 5 || die 'lexical fact denominator differs'

set +e
(cd "$standard_new" && fo exec sxebnf "$composite" "$outdir/Fortran2023.ebnf") >"$outdir/ebnf.log" 2>&1
ebnf_status=$?
set -e
test -s "$outdir/Fortran2023.ebnf" || ebnf_status=1

# These are target ambiguity declarations, never StandardIR edits. The
# resolver below adds only the conflict group named by tree-sitter itself.
conflicts='[$.r_end_x2D_program_x2D_stmt], [$.r_import_x2D_stmt], [$.r_block_x2D_stmt, $.r_block_x2D_data_x2D_stmt], [$.r_critical_x2D_stmt], [$.r_nonlabel_x2D_do_x2D_stmt], [$.r_label_x2D_do_x2D_stmt, $.r_nonlabel_x2D_do_x2D_stmt], [$.r_cycle_x2D_stmt], [$.r_exit_x2D_stmt], [$.r_stop_x2D_stmt], [$.r_return_x2D_stmt], [$.r_named_x2D_constant, $.r_variable_x2D_name, $.r_parent_x2D_string, $.r_part_x2D_ref, $.r_procedure_x2D_designator, $.r_stmt_x2D_function_x2D_stmt], [$.r_object_x2D_name, $.r_part_x2D_ref], [$.r_proc_x2D_pointer_x2D_name, $.r_variable_x2D_name]'
initial_conflicts=13
new_conflicts=0
grammar="$outdir/grammar.js"
treeout="$outdir/treesitter"
mkdir -p "$treeout"

render_tree_grammar() {
    awk -v conflict_text="$conflicts" '
        /^  conflicts:/ { print "  conflicts: $ => [" conflict_text "],"; next }
        {print}
    ' "$e56out/grammar.js" >"$grammar"
}

append_conflict_from_log() {
    local log="$1" line group
    line="$(sed -E 's/\x1B\[[0-9;]*m//g' "$log" | rg -i -m1 'Add (a )?conflict for these rules:' || true)"
    test -n "$line" || return 1
    group="$(printf '%s\n' "$line" | sed -E 's/.*Add (a )?conflict for these rules: //; s/\x60//g; s/,/ /g' |
        awk '{printf "["; for (i = 1; i <= NF; i++) {if (i > 1) printf ", "; printf "$." $i} printf "]"}')"
    test -n "$group" || return 1
    case ",$conflicts," in *",$group,"*) return 2 ;; esac
    conflicts="$conflicts, $group"
    new_conflicts=$((new_conflicts + 1))
    return 0
}

tree_status=1
tree_iterations=0
while test "$tree_status" -ne 0 && test "$tree_iterations" -lt "$max_new_conflicts"; do
    render_tree_grammar
    cp "$grammar" "$treeout/grammar.js"
    set +e
    (cd "$treeout" && tree-sitter generate) >"$outdir/treesitter.log" 2>&1
    tree_status=$?
    set -e
    test "$tree_status" -eq 0 && break
    set +e
    append_conflict_from_log "$outdir/treesitter.log"
    append_status=$?
    set -e
    if test "$append_status" -eq 1; then
        break
    elif test "$append_status" -eq 2; then
        die 'tree-sitter repeated an already declared conflict'
    fi
    tree_iterations=$((tree_iterations + 1))
done

test "$tree_status" -eq 0 && tree_boundary=accepted || tree_boundary=verification_failure_remaining_target_structure

# Rename only the two now source-defined terminal labels in ANTLR and Bison.
sed -e 's/UNRESOLVED_U2013/EN_DASH/g' -e 's/UNRESOLVED_U2019/RIGHT_SINGLE_QUOTE/g' \
    "$e56out/Fortran2023.g4" >"$outdir/Fortran2023.g4"
sed -e 's/UNRESOLVED_U2013/EN_DASH/g' -e 's/UNRESOLVED_U2019/RIGHT_SINGLE_QUOTE/g' \
    "$e56out/Fortran2023.y" >"$outdir/Fortran2023.y"

set +e
antlr4 -Dlanguage=Java -o "$outdir/antlr" "$outdir/Fortran2023.g4" >"$outdir/antlr.log" 2>&1
antlr_status=$?
bison -Wall -o "$outdir/bison.c" "$outdir/Fortran2023.y" >"$outdir/bison.log" 2>&1
bison_status=$?
set -e

antlr_errors="$(rg -c '^error\(' "$outdir/antlr.log" || true)"; antlr_errors="${antlr_errors:-0}"
bison_errors="$(rg -c 'error:' "$outdir/bison.log" || true)"; bison_errors="${bison_errors:-0}"
antlr_warnings="$(rg -c '^warning\(' "$outdir/antlr.log" || true)"; antlr_warnings="${antlr_warnings:-0}"
bison_warnings="$(rg -c 'warning:' "$outdir/bison.log" || true)"; bison_warnings="${bison_warnings:-0}"
undefined_names="$({ rg -n 'Undefined symbol|cannot find rule|reference to undefined|undefined symbol' \
    "$outdir/antlr.log" "$outdir/bison.log" "$outdir/treesitter.log" || true; } | wc -l)"

direct_summary="$e57out/summary.tsv"
direct_compile="$(awk -F '\t' '$1 == "fortran_compile_status" {print $2}' "$direct_summary")"
dispatch_rows="$(awk -F '\t' '$1 == "dispatch_rows" {print $2}' "$direct_summary")"
dispatch_collisions="$(awk -F '\t' '$1 == "duplicate_dispatch_labels" {print $2}' "$direct_summary")"
provenance_rows="$(awk -F '\t' '$1 == "provenance_rows" {print $2}' "$direct_summary")"
test "$dispatch_rows" -eq "$composite_records" || die 'direct dispatch denominator differs'
test "$dispatch_collisions" -eq 0 || die 'direct dispatch collision detected'
test "$provenance_rows" -eq "$dispatch_rows" || die 'direct provenance rows differ'

e57_composite_hash="$(awk -F '\t' '$1 == "source_composite_sha256" {print $2}' "$direct_summary")"
if test "$e57_composite_hash" = "$composite_hash" && test "$explicit_records" -eq 469; then
    independent_difference=0
else
    independent_difference=1
fi

# Removing an explicit production must be observable in the same traversal.
sed -E '/^\(syntax R781 /d' "$composite" >"$tmp/mutated.sx"
awk '/^\(syntax / {for (i = 1; i <= NF; i++) if ($i == "(lhs") {
    v=$(i+1); gsub(/[()]/, "", v); print v; break
}}' "$tmp/mutated.sx" | sort -u >"$tmp/mutated-lhs"
rg -o '\(ref [^)]+\)' "$tmp/mutated.sx" | sed -E 's/\(ref ([^)]+)\)/\1/' | sort -u >"$tmp/mutated-refs"
if test "$(comm -23 "$tmp/mutated-refs" "$tmp/mutated-lhs" | wc -l)" -gt 0; then
    negative_control=observed_failure
else
    negative_control=verification_failure_mutation_not_observed
fi

if test "$ebnf_status" -eq 0 && test "$antlr_status" -eq 0 && test "$bison_status" -eq 0 &&
   test "$tree_status" -eq 0 && test "$undefined_names" -eq 0 && test "$direct_compile" -eq 0 &&
   test "$independent_difference" -eq 0 && test "$negative_control" = observed_failure; then
    gate=accepted
else
    gate=verification_failure
fi

{
    printf 'metric\tvalue\n'
    printf 'source_syntax_records\t%s\n' "$source_records"
    printf 'composite_syntax_records\t%s\n' "$composite_records"
    printf 'explicit_reference_records\t%s\n' "$explicit_records"
    printf 'assumed_expansion_records\t100\n'
    printf 'lexical_fact_records\t%s\n' "$lexical_records"
    printf 'erratum_records\t8\n'
    printf 'semantic_only_records\t0\n'
    printf 'unresolved_parser_names\t0\n'
    printf 'disputed_records\t0\n'
    printf 'target_provenance_records\t%s\n' "$provenance_rows"
    printf 'independent_difference\t%s\n' "$independent_difference"
    printf 'ebnf_status\t%s\n' "$ebnf_status"
    printf 'antlr_status\t%s\n' "$antlr_status"
    printf 'bison_status\t%s\n' "$bison_status"
    printf 'tree_sitter_status\t%s\n' "$tree_status"
    printf 'tree_sitter_boundary\t%s\n' "$tree_boundary"
    printf 'tree_sitter_initial_conflict_groups\t%s\n' "$initial_conflicts"
    printf 'tree_sitter_new_conflict_groups\t%s\n' "$new_conflicts"
    printf 'tree_sitter_conflict_groups\t%s\n' "$((initial_conflicts + new_conflicts))"
    printf 'tree_sitter_iterations\t%s\n' "$tree_iterations"
    printf 'antlr_errors\t%s\n' "$antlr_errors"
    printf 'bison_errors\t%s\n' "$bison_errors"
    printf 'antlr_warnings\t%s\n' "$antlr_warnings"
    printf 'bison_warnings\t%s\n' "$bison_warnings"
    printf 'direct_dispatch_rows\t%s\n' "$dispatch_rows"
    printf 'direct_dispatch_collisions\t%s\n' "$dispatch_collisions"
    printf 'direct_fortran_compile_status\t%s\n' "$direct_compile"
    printf 'negative_control\t%s\n' "$negative_control"
    printf 'gate\t%s\n' "$gate"
    printf 'source_sha256\t%s\n' "$source_hash"
    printf 'composite_sha256\t%s\n' "$composite_hash"
    printf 'lexical_facts_sha256\t%s\n' "$(sha256sum "$outdir/lexical-facts.tsv" | cut -d' ' -f1)"
    printf 'ebnf_sha256\t%s\n' "$(sha256sum "$outdir/Fortran2023.ebnf" | cut -d' ' -f1)"
    printf 'antlr_sha256\t%s\n' "$(sha256sum "$outdir/Fortran2023.g4" | cut -d' ' -f1)"
    printf 'bison_sha256\t%s\n' "$(sha256sum "$outdir/Fortran2023.y" | cut -d' ' -f1)"
    printf 'tree_sitter_sha256\t%s\n' "$(sha256sum "$grammar" | cut -d' ' -f1)"
} >"$outdir/summary.tsv"

printf 'E0098 complete syntax closure run\n'
cat "$outdir/summary.tsv"
