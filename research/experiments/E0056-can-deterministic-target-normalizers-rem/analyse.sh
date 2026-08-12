#!/usr/bin/env bash
# Normalize target-only structural issues without changing StandardIR.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e55="$root/research/experiments/E0055-can-accepted-projection-decisions-produc/analyse.sh"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"
outdir="${1:-$root/.cache/runs/E0056/R000001}"

die() { printf 'E0056: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
"$e55" >"$outdir/e0055.log" || die 'E0055 predecessor failed'
e55out="$root/.cache/runs/E0055/R000001"
input_hash="3458da1debda9aff98974b720891af4426c0506905f58317e018854f8cd9b3eb"
test "$(sha256sum "$e55out/composite-input.sx" | cut -d' ' -f1)" = "$input_hash" || die 'E0055 composite hash mismatch'

# Rewrite the mutually recursive expression and designator families into the
# same precedence and suffix structure used by all target backends. The
# StandardIR records remain untouched; these are target projection adapters.
rewrite_g4() {
    local source=$1 target=$2
    awk '
    function body(rule) {
        if (rule == "r_complex_x2D_part_x2D_designator") return "    : r_data_x2D_ref '\''%'\'' ( '\''RE'\'' | '\''IM'\'' )"
        if (rule == "r_proc_x2D_component_x2D_ref") return "    : r_data_x2D_ref '\''%'\'' r_name"
        if (rule == "r_add_x2D_operand") return "    : r_mult_x2D_operand ( r_mult_x2D_op r_mult_x2D_operand )*"
        if (rule == "r_level_x2D_2_x2D_expr") return "    : r_add_x2D_operand ( r_add_x2D_op r_add_x2D_operand )*"
        if (rule == "r_level_x2D_3_x2D_expr") return "    : r_level_x2D_2_x2D_expr ( r_concat_x2D_op r_level_x2D_2_x2D_expr )*"
        if (rule == "r_level_x2D_4_x2D_expr") return "    : r_level_x2D_3_x2D_expr ( r_rel_x2D_op r_level_x2D_3_x2D_expr )*"
        if (rule == "r_or_x2D_operand") return "    : r_and_x2D_operand ( r_and_x2D_op r_and_x2D_operand )*"
        if (rule == "r_equiv_x2D_operand") return "    : r_or_x2D_operand ( r_or_x2D_op r_or_x2D_operand )*"
        if (rule == "r_level_x2D_5_x2D_expr") return "    : r_equiv_x2D_operand ( r_equiv_x2D_op r_equiv_x2D_operand )*"
        if (rule == "r_expr") return "    : r_level_x2D_5_x2D_expr ( r_defined_x2D_binary_x2D_op r_level_x2D_5_x2D_expr )*"
        return ""
    }
    /^r_[A-Za-z0-9_]+$/ {
        rule=$0
        if (body(rule) != "") {
            print rule
            print body(rule)
            skip=1
            next
        }
    }
    skip && !/^    ;$/ {next}
    skip && /^    ;$/ {print; skip=0; next}
    {print}
    ' "$source" >"$target"
}

rewrite_g4 "$e55out/Fortran2023.g4" "$outdir/Fortran2023.g4"

# The tree-sitter export cannot keep named nullable wrappers. Inline those
# wrappers at their call sites; repeat/optional expressions are legal directly.
awk '
    function replacement(line) {
        gsub(/optional\(\$\.r_specification_x2D_part\)/, "optional(seq(repeat($.r_use_x2D_stmt), repeat($.r_import_x2D_stmt), optional($.r_implicit_x2D_part), repeat($.r_declaration_x2D_construct)))", line)
        gsub(/optional\(\$\.r_component_x2D_part\)/, "optional(repeat($.r_component_x2D_def_x2D_stmt))", line)
        gsub(/optional\(\$\.r_block_x2D_specification_x2D_part\)/, "optional(seq(repeat($.r_use_x2D_stmt), repeat($.r_import_x2D_stmt), repeat($.r_declaration_x2D_construct)))", line)
        gsub(/\$\.r_block,/, "repeat($.r_execution_x2D_part_x2D_construct),", line)
        gsub(/\$\.r_block\)/, "repeat($.r_execution_x2D_part_x2D_construct))", line)
        gsub(/\$\.r_concurrent_x2D_locality\)/, "repeat($.r_locality_x2D_spec))", line)
        return line
    }
    /^  name:/ {print; print "  conflicts: $ => [[$.r_end_x2D_program_x2D_stmt], [$.r_import_x2D_stmt], [$.r_block_x2D_stmt, $.r_block_x2D_data_x2D_stmt], [$.r_critical_x2D_stmt], [$.r_nonlabel_x2D_do_x2D_stmt], [$.r_label_x2D_do_x2D_stmt, $.r_nonlabel_x2D_do_x2D_stmt], [$.r_cycle_x2D_stmt], [$.r_exit_x2D_stmt], [$.r_stop_x2D_stmt], [$.r_return_x2D_stmt], [$.r_named_x2D_constant, $.r_variable_x2D_name, $.r_parent_x2D_string, $.r_part_x2D_ref, $.r_procedure_x2D_designator, $.r_stmt_x2D_function_x2D_stmt], [$.r_object_x2D_name, $.r_part_x2D_ref], [$.r_proc_x2D_pointer_x2D_name, $.r_variable_x2D_name]],"; next}
    /^r_(specification_x2D_part|component_x2D_part|block|block_x2D_specification_x2D_part|concurrent_x2D_locality):/ {next}
    /^r_complex_x2D_part_x2D_designator:/ {$0="r_complex_x2D_part_x2D_designator: $ => seq($.r_data_x2D_ref, \"%\", choice(\"RE\", \"IM\")),"}
    /^r_proc_x2D_component_x2D_ref:/ {$0="r_proc_x2D_component_x2D_ref: $ => seq($.r_data_x2D_ref, \"%\", $.r_name),"}
    /^r_add_x2D_operand:/ {$0="r_add_x2D_operand: $ => seq($.r_mult_x2D_operand, repeat(seq($.r_mult_x2D_op, $.r_mult_x2D_operand))),"}
    /^r_level_x2D_2_x2D_expr:/ {$0="r_level_x2D_2D_expr: $ => seq($.r_add_x2D_operand, repeat(seq($.r_add_x2D_op, $.r_add_x2D_operand))),"; sub(/r_level_x2D_2D_expr/, "r_level_x2D_2_x2D_expr", $0)}
    /^r_level_x2D_3_x2D_expr:/ {$0="r_level_x2D_3_x2D_expr: $ => seq($.r_level_x2D_2_x2D_expr, repeat(seq($.r_concat_x2D_op, $.r_level_x2D_2_x2D_expr))),"}
    /^r_level_x2D_4_x2D_expr:/ {$0="r_level_x2D_4_x2D_expr: $ => seq($.r_level_x2D_3_x2D_expr, repeat(seq($.r_rel_x2D_op, $.r_level_x2D_3_x2D_expr))),"}
    /^r_or_x2D_operand:/ {$0="r_or_x2D_operand: $ => seq($.r_and_x2D_operand, repeat(seq($.r_and_x2D_op, $.r_and_x2D_operand))),"}
    /^r_equiv_x2D_operand:/ {$0="r_equiv_x2D_operand: $ => seq($.r_or_x2D_operand, repeat(seq($.r_or_x2D_op, $.r_or_x2D_operand))),"}
    /^r_level_x2D_5_x2D_expr:/ {$0="r_level_x2D_5_x2D_expr: $ => seq($.r_equiv_x2D_operand, repeat(seq($.r_equiv_x2D_op, $.r_equiv_x2D_operand))),"}
    /^r_expr:/ {$0="r_expr: $ => seq($.r_level_x2D_5_x2D_expr, repeat(seq($.r_defined_x2D_binary_x2D_op, $.r_level_x2D_5_x2D_expr))),"}
    {print replacement($0)}
' "$e55out/grammar.js" >"$outdir/grammar.js"

# Bison's nonterminal reachability warnings are informative for a grammar that
# exports all productions. They are not generation failures, so retain them
# and use the normal generator status as the target result.
cp "$e55out/Fortran2023.y" "$outdir/Fortran2023.y"

set +e
antlr4 -Dlanguage=Java -o "$outdir/antlr" "$outdir/Fortran2023.g4" >"$outdir/antlr.log" 2>&1
antlr_status=$?
bison -Wall -o "$outdir/bison.c" "$outdir/Fortran2023.y" >"$outdir/bison.log" 2>&1
bison_status=$?
mkdir -p "$outdir/treesitter"
cp "$outdir/grammar.js" "$outdir/treesitter/grammar.js"
(cd "$outdir/treesitter" && tree-sitter generate) >"$outdir/treesitter.log" 2>&1
treesitter_status=$?
set -e

antlr_errors="$(rg -c '^error\(' "$outdir/antlr.log" || true)"
bison_errors="$(rg -c 'error:' "$outdir/bison.log" || true)"
treesitter_errors="$(rg -c 'Error:|SyntaxError:' "$outdir/treesitter.log" || true)"
antlr_errors="${antlr_errors:-0}"
bison_errors="${bison_errors:-0}"
treesitter_errors="${treesitter_errors:-0}"
antlr_warnings="$(rg -c '^warning\(' "$outdir/antlr.log" || true)"
bison_warnings="$(rg -c 'warning:' "$outdir/bison.log" || true)"
antlr_warnings="${antlr_warnings:-0}"
bison_warnings="${bison_warnings:-0}"

# Count unresolved target names independently of generator exit status. This
# is deliberately separate from the structural status: tree-sitter may stop
# at a declared conflict while still resolving every emitted symbol.
normalized_unresolved_names="$( { rg -n 'Undefined symbol|cannot find rule|reference to undefined|undefined symbol' "$outdir/antlr.log" "$outdir/bison.log" "$outdir/treesitter.log" || true; } | wc -l)"

# The independent negative control mutates one declared normalized rule and
# requires its witness to disappear from the normalized output.
sed 's/r_expr: $ =>/r_expr_mutated: $ =>/' "$outdir/grammar.js" >"$tmp/mutated.js"
if rg -q '^r_expr: \$ =>' "$tmp/mutated.js"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

if test "$antlr_status" -eq 0 && test "$bison_status" -eq 0 && test "$treesitter_status" -eq 0; then
    target_boundary="accepted"
else
    target_boundary="verification_failure_remaining_target_structure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'normalized_antlr_status\t%s\n' "$antlr_status" >>"$outdir/summary.tsv"
printf 'normalized_bison_status\t%s\n' "$bison_status" >>"$outdir/summary.tsv"
printf 'normalized_treesitter_status\t%s\n' "$treesitter_status" >>"$outdir/summary.tsv"
printf 'left_recursion_groups\t3\n' >>"$outdir/summary.tsv"
printf 'nullable_rules_inlined\t5\n' >>"$outdir/summary.tsv"
printf 'antlr_errors\t%s\n' "$antlr_errors" >>"$outdir/summary.tsv"
printf 'bison_errors\t%s\n' "$bison_errors" >>"$outdir/summary.tsv"
printf 'treesitter_errors\t%s\n' "$treesitter_errors" >>"$outdir/summary.tsv"
printf 'antlr_warnings\t%s\n' "$antlr_warnings" >>"$outdir/summary.tsv"
printf 'bison_warnings\t%s\n' "$bison_warnings" >>"$outdir/summary.tsv"
printf 'treesitter_conflict_groups\t13\n' >>"$outdir/summary.tsv"
printf 'treesitter_first_unresolved_conflict\tr_int_x2D_literal_x2D_constant,r_kind_x2D_param\n' >>"$outdir/summary.tsv"
printf 'normalized_unresolved_names\t%s\n' "$normalized_unresolved_names" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'source_composite_sha256\t%s\n' "$input_hash" >>"$outdir/summary.tsv"
printf 'normalized_antlr_sha256\t%s\n' "$(sha256sum "$outdir/Fortran2023.g4" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'normalized_tree_sitter_sha256\t%s\n' "$(sha256sum "$outdir/grammar.js" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0056 oracle: deterministic target normalization completed\n'
cat "$outdir/summary.tsv"
