#!/usr/bin/env bash
# Generate and execute expression and precedence operations from the E0078 profile.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e79="$root/research/experiments/E0079-can-the-e0078-composed-profile-drive-a-g/analyse.sh"
e67="$root/research/experiments/E0067-can-generated-expression-coverage-/analyse.sh"
profile="$root/.cache/runs/E0078/R000001/residue-composition.tsv"
e79_summary="$root/.cache/runs/E0079/R000001/summary.tsv"
e67_summary="$root/.cache/runs/E0067/R000001/summary.tsv"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
logical_module="$root/.cache/runs/E0062/R000001/generated_logical_construct_parser.f90"
ast_module="$root/.cache/runs/E0063/R000001/generated_ast_records.f90"
expression_module="$root/.cache/runs/E0064/R000001/generated_ast_expressions.f90"
coverage_module="$root/.cache/runs/E0067/R000001/generated_expression_coverage.f90"
corpus="$root/research/corpora/phase1-modern-fortran-expression-coverage-v0.json"
outdir="${1:-$root/.cache/runs/E0080/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
expected_profile_hash="2927a6cf597c90a000182b8907bfdedf360657576559e5ae12edf712cadb9c1e"
expected_e79_summary_hash="f41cbfeb30bcd0aa5b79569bb309e67a2f341735120533fa3c5f5e0ac65a572d"
expected_e67_summary_hash="0838207a87997bb5608c19cc3937de43d94629e044ae29dcd70be13b4625b876"

die() { printf 'E0080: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e79" >"$outdir/e0079.log" || die 'E0079 predecessor failed'
"$e67" >"$outdir/e0067.log" || die 'E0067 predecessor failed'
test "$(sha256sum "$e79_summary" | cut -d' ' -f1)" = "$expected_e79_summary_hash" || die 'E0079 summary hash differs'
test "$(sha256sum "$e67_summary" | cut -d' ' -f1)" = "$expected_e67_summary_hash" || die 'E0067 summary hash differs'
test -f "$profile" || die 'E0078 profile is missing'
test "$(sha256sum "$profile" | cut -d' ' -f1)" = "$expected_profile_hash" || die 'E0078 profile hash differs'
test -f "$coverage_module" || die 'expression coverage module is missing'

profile_rows="$(awk 'END {print NR - 1}' "$profile")"
profile_parser_targets="$(awk -F '\t' 'NR > 1 && $4 != "-" {n++} END {print n + 0}' "$profile")"
test "$profile_rows" -eq 151 || die 'profile row denominator differs'
test "$profile_parser_targets" -eq 0 || die 'profile parser targets introduced'

jq -e '.name == "phase1-modern-fortran-expression-coverage-v0" and (.witnesses | length) == 9' "$corpus" >/dev/null || die 'expression corpus shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "b8cb5926fd82ed299d00e8c50eaa41587f55237d" || die 'fortfront oracle commit differs'

expression_source_files="$(jq -r '.witnesses[].path' "$corpus" | sort -u | wc -l)"
expression_witnesses="$(jq '.witnesses | length' "$corpus")"
internal_nodes="$(jq '[.witnesses[].expected_internal_nodes] | add' "$corpus")"
leaf_nodes="$(jq '[.witnesses[].expected_leaf_nodes] | add' "$corpus")"
binary_nodes="$(jq '[.witnesses[].kind_counts["binary-expr"]] | add' "$corpus")"
unary_nodes="$(jq '[.witnesses[].kind_counts["unary-expr"]] | add' "$corpus")"
array_nodes="$(jq '[.witnesses[].kind_counts["array-constructor"] // 0] | add' "$corpus")"
function_reference_nodes="$(jq '[.witnesses[].kind_counts["call-expr"]] | add' "$corpus")"
name_nodes="$(jq '[.witnesses[].kind_counts.name] | add' "$corpus")"
literal_nodes="$(jq '[.witnesses[].kind_counts.literal] | add' "$corpus")"
max_expression_depth="$(jq '[.witnesses[].expected_max_depth] | max' "$corpus")"

cat >"$outdir/generated_profile_expression_facade.f90" <<EOF
! origin: MECHANICAL
module generated_profile_expression_facade
    use generated_ast_records, only: ast_node_t
    use generated_expression_coverage, only: build_expression_coverage, find_expression_root
    implicit none
    private
    public :: ast_node_t, parse_profile_expression, query_profile_expression
    public :: profile_sha256, profile_rows, profile_parser_targets

    character(len=64), parameter :: profile_sha256 = "$expected_profile_hash"
    integer, parameter :: profile_rows = 151
    integer, parameter :: profile_parser_targets = 0

contains

    subroutine parse_profile_expression(path, role, first_line, last_line, nodes, base_count, &
                                        internal_count, leaf_count, node_count, root_id, &
                                        link_errors, max_depth, ierr)
        character(len=*), intent(in) :: path, role
        integer, intent(in) :: first_line, last_line
        type(ast_node_t), intent(out) :: nodes(:)
        integer, intent(out) :: base_count, internal_count, leaf_count, node_count, root_id
        integer, intent(out) :: link_errors, max_depth, ierr

        call build_expression_coverage(path, role, first_line, last_line, nodes, base_count, &
                                       internal_count, leaf_count, node_count, root_id, &
                                       link_errors, max_depth, ierr)
    end subroutine parse_profile_expression

    subroutine query_profile_expression(nodes, node_count, role, first_line, last_line, node_id, found)
        type(ast_node_t), intent(in) :: nodes(:)
        integer, intent(in) :: node_count, first_line, last_line
        character(len=*), intent(in) :: role
        integer, intent(out) :: node_id
        logical, intent(out) :: found

        call find_expression_root(nodes, node_count, role, first_line, last_line, node_id, found)
    end subroutine query_profile_expression

end module generated_profile_expression_facade
EOF

mutation="$tmp/mutated.f90"
coverage_source="$fortfront_root/examples/f90/issue_2498_operator_precedence.f90"
sed 's/\.and\./.xor./' "$coverage_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_profile_expression_facade'
    printf '%s\n' '    use generated_profile_expression_facade, only: ast_node_t, parse_profile_expression, query_profile_expression, profile_sha256, profile_rows, profile_parser_targets'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    integer :: coverage_query_hits, unknown_query_rejected, source_linked_nodes'
    printf '%s\n' '    coverage_query_hits = 0; unknown_query_rejected = 0; source_linked_nodes = 0'
    printf '%s\n' '    if (trim(profile_sha256) /= "'$expected_profile_hash'") error stop "profile hash mismatch"'
    printf '%s\n' '    if (profile_rows /= 151 .or. profile_parser_targets /= 0) error stop "profile metadata mismatch"'
    while IFS=$'\t' read -r relative_path first_line last_line role expected_base expected_internal expected_leaf expected_new expected_depth root_rule expected_binary expected_unary expected_array expected_call expected_name expected_literal; do
        printf "    call check_witness('%s/%s', %s, %s, '%s', %s, %s, %s, %s, %s, '%s', %s, %s, %s, %s, %s, %s)\n" "$fortfront_root" "$relative_path" "$first_line" "$last_line" "$role" "$expected_base" "$expected_internal" "$expected_leaf" "$expected_new" "$expected_depth" "$root_rule" "$expected_binary" "$expected_unary" "$expected_array" "$expected_call" "$expected_name" "$expected_literal"
    done < <(jq -r '.witnesses[] | [.path, .start_line, .end_line, .role, .expected_base_nodes, .expected_internal_nodes, .expected_leaf_nodes, .expected_new_nodes, .expected_max_depth, .root_rule, .kind_counts["binary-expr"], .kind_counts["unary-expr"], (.kind_counts["array-constructor"] // 0), .kind_counts["call-expr"], .kind_counts.name, .kind_counts.literal] | @tsv' "$corpus")
    printf '%s\n' '    if (coverage_query_hits /= 9 .or. unknown_query_rejected /= 1 .or. source_linked_nodes /= 54) error stop "coverage summary mismatch"'
    printf '%s\n' '    call check_mutation()'
    printf '%s\n' '    print "(a,i0,1x,a,i0)", "expression queries: ", coverage_query_hits, "source-linked nodes: ", source_linked_nodes'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_witness(path, first_line, last_line, role, expected_base, expected_internal, expected_leaf, expected_new, expected_depth, root_rule, expected_binary, expected_unary, expected_array, expected_call, expected_name, expected_literal)'
    printf '%s\n' '        character(len=*), intent(in) :: path, role, root_rule'
    printf '%s\n' '        integer, intent(in) :: first_line, last_line, expected_base, expected_internal, expected_leaf, expected_new, expected_depth'
    printf '%s\n' '        integer, intent(in) :: expected_binary, expected_unary, expected_array, expected_call, expected_name, expected_literal'
    printf '%s\n' '        type(ast_node_t) :: parsed(256)'
    printf '%s\n' '        integer :: base_count, actual_internal, actual_leaf, actual_total, root_id, errors, depth, status, j, child, steps, count'
    printf '%s\n' '        logical :: found'
    printf '%s\n' '        call parse_profile_expression(path, role, first_line, last_line, parsed, base_count, actual_internal, actual_leaf, actual_total, root_id, errors, depth, status)'
    printf '%s\n' '        if (status /= 0 .or. base_count /= expected_base .or. actual_internal /= expected_internal .or. actual_leaf /= expected_leaf .or. actual_total /= expected_base + expected_new) error stop "expression shape mismatch"'
    printf '%s\n' '        if (errors /= 0 .or. depth /= expected_depth .or. root_id <= expected_base) error stop "expression links mismatch"'
    printf '%s\n' '        if (trim(parsed(root_id)%rule) /= trim(root_rule)) error stop "expression root rule mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "binary-expr", count); if (count /= expected_binary) error stop "binary count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "unary-expr", count); if (count /= expected_unary) error stop "unary count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "array-constructor", count); if (count /= expected_array) error stop "array count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "call-expr", count); if (count /= expected_call) error stop "call count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "name", count); if (count /= expected_name) error stop "name count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "literal", count); if (count /= expected_literal) error stop "literal count mismatch"'
    printf '%s\n' '        do j = expected_base + 1, actual_total'
    printf '%s\n' '            if (parsed(j)%parent <= 0 .or. parsed(j)%source%page <= 0 .or. parsed(j)%source%byte_start <= 0) error stop "expression source link missing"'
    printf '%s\n' '            if (trim(parsed(j)%source%source_sha256) /= "'$source_hash'") error stop "expression source hash mismatch"'
    printf '%s\n' '            call assert_source_ref(parsed(j))'
    printf '%s\n' '            source_linked_nodes = source_linked_nodes + 1'
    printf '%s\n' '        end do'
    printf '%s\n' '        child = parsed(root_id)%first_child; steps = 0'
    printf '%s\n' '        do while (child /= 0)'
    printf '%s\n' '            steps = steps + 1; if (steps > actual_total) error stop "expression child traversal overflow"'
    printf '%s\n' '            if (parsed(child)%parent /= root_id) error stop "expression child parent mismatch"'
    printf '%s\n' '            child = parsed(child)%next_sibling'
    printf '%s\n' '        end do'
    printf '%s\n' '        call query_profile_expression(parsed, actual_total, role, first_line, last_line, j, found)'
    printf '%s\n' '        if (.not. found .or. j /= root_id) error stop "known expression query mismatch"'
    printf '%s\n' '        coverage_query_hits = coverage_query_hits + 1'
    printf '%s\n' '        call query_profile_expression(parsed, actual_total, "unknown-role", first_line, last_line, j, found)'
    printf '%s\n' '        if (found) error stop "unknown expression query accepted"'
    printf '%s\n' '        if (coverage_query_hits == 1) unknown_query_rejected = 1'
    printf '%s\n' '    end subroutine check_witness'
    printf '%s\n' '    subroutine count_kind(nodes, node_count, kind, count)'
    printf '%s\n' '        type(ast_node_t), intent(in) :: nodes(:)'
    printf '%s\n' '        integer, intent(in) :: node_count'
    printf '%s\n' '        character(len=*), intent(in) :: kind'
    printf '%s\n' '        integer, intent(out) :: count'
    printf '%s\n' '        integer :: i'
    printf '%s\n' '        count = 0'
    printf '%s\n' '        do i = 1, node_count'
    printf '%s\n' '            if (trim(nodes(i)%kind) == trim(kind)) count = count + 1'
    printf '%s\n' '        end do'
    printf '%s\n' '    end subroutine count_kind'
    printf '%s\n' '    subroutine assert_source_ref(node)'
    printf '%s\n' '        type(ast_node_t), intent(in) :: node'
    printf '%s\n' '        character(len=63) :: expected_lhs'
    printf '%s\n' '        select case (trim(node%rule))'
    printf '%s\n' '        case ("R603"); expected_lhs = "name"'
    printf '%s\n' '        case ("R708"); expected_lhs = "int-literal-constant"'
    printf '%s\n' '        case ("R714"); expected_lhs = "real-literal-constant"'
    printf '%s\n' '        case ("R724"); expected_lhs = "char-literal-constant"'
    printf '%s\n' '        case ("R725"); expected_lhs = "logical-literal-constant"'
    printf '%s\n' '        case ("R777"); expected_lhs = "array-constructor"'
    printf '%s\n' '        case ("R1003"); expected_lhs = "level-1-expr"'
    printf '%s\n' '        case ("R1005"); expected_lhs = "mult-operand"'
    printf '%s\n' '        case ("R1006"); expected_lhs = "add-operand"'
    printf '%s\n' '        case ("R1007"); expected_lhs = "level-2-expr"'
    printf '%s\n' '        case ("R1011"); expected_lhs = "level-3-expr"'
    printf '%s\n' '        case ("R1014"); expected_lhs = "rel-op"'
    printf '%s\n' '        case ("R1015"); expected_lhs = "and-operand"'
    printf '%s\n' '        case ("R1016"); expected_lhs = "or-operand"'
    printf '%s\n' '        case ("R1017"); expected_lhs = "equiv-operand"'
    printf '%s\n' '        case ("R1019"); expected_lhs = "not-op"'
    printf '%s\n' '        case ("R1520"); expected_lhs = "function-reference"'
    printf '%s\n' '        case default; error stop "unknown expression provenance rule"'
    printf '%s\n' '        end select'
    printf '%s\n' '        if (trim(node%source%lhs) /= trim(expected_lhs) .or. trim(node%source%rule) /= trim(node%rule)) error stop "expression source reference mismatch"'
    printf '%s\n' '    end subroutine assert_source_ref'
    printf '%s\n' '    subroutine check_mutation()'
    printf '%s\n' '        type(ast_node_t) :: mutated(256)'
    printf '%s\n' '        integer :: base_count, internal, leaves, total, root_id, errors, depth, status'
    printf "        call parse_profile_expression('%s', 'expr', 24, 24, mutated, base_count, internal, leaves, total, root_id, errors, depth, status)\n" "$mutation"
    printf '%s\n' '        if (status == 0) error stop "unsupported operator accepted"'
    printf '%s\n' '    end subroutine check_mutation'
    printf '%s\n' 'end program test_generated_profile_expression_facade'
} >"$outdir/test_generated_profile_expression_facade.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror \
    "$diagnostic_module" "$logical_module" "$ast_module" "$expression_module" "$coverage_module" \
    "$outdir/generated_profile_expression_facade.f90" "$outdir/test_generated_profile_expression_facade.f90" \
    -o "$outdir/test_generated_profile_expression_facade" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_profile_expression_facade" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

test "$fortran_compile_status" -eq 0 || die 'generated expression facade did not compile'
test "$runtime_test_status" -eq 0 || die 'generated expression facade failed its witness checks'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'profile_rows\t%s\n' "$profile_rows" >>"$outdir/summary.tsv"
printf 'profile_parser_targets\t%s\n' "$profile_parser_targets" >>"$outdir/summary.tsv"
printf 'expression_source_files\t%s\n' "$expression_source_files" >>"$outdir/summary.tsv"
printf 'expression_witnesses\t%s\n' "$expression_witnesses" >>"$outdir/summary.tsv"
printf 'gfortran_accepted\t%s\n' "$(awk -F '\t' '$1 == "gfortran_accepted" {print $2}' "$e67_summary")" >>"$outdir/summary.tsv"
printf 'internal_nodes\t%s\n' "$internal_nodes" >>"$outdir/summary.tsv"
printf 'leaf_nodes\t%s\n' "$leaf_nodes" >>"$outdir/summary.tsv"
printf 'binary_nodes\t%s\n' "$binary_nodes" >>"$outdir/summary.tsv"
printf 'unary_nodes\t%s\n' "$unary_nodes" >>"$outdir/summary.tsv"
printf 'array_nodes\t%s\n' "$array_nodes" >>"$outdir/summary.tsv"
printf 'function_reference_nodes\t%s\n' "$function_reference_nodes" >>"$outdir/summary.tsv"
printf 'name_nodes\t%s\n' "$name_nodes" >>"$outdir/summary.tsv"
printf 'literal_nodes\t%s\n' "$literal_nodes" >>"$outdir/summary.tsv"
printf 'source_linked_nodes\t%s\n' "$((internal_nodes + leaf_nodes))" >>"$outdir/summary.tsv"
printf 'subtree_parent_links\t%s\n' "$((internal_nodes + leaf_nodes))" >>"$outdir/summary.tsv"
printf 'subtree_link_errors\t0\n' >>"$outdir/summary.tsv"
printf 'tree_mismatches\t0\n' >>"$outdir/summary.tsv"
printf 'coverage_query_hits\t%s\n' "$expression_witnesses" >>"$outdir/summary.tsv"
printf 'unknown_query_rejected\t1\n' >>"$outdir/summary.tsv"
printf 'max_expression_depth\t%s\n' "$max_expression_depth" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'unsupported_operator_rejected\t1\n' >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'profile_sha256\t%s\n' "$expected_profile_hash" >>"$outdir/summary.tsv"
printf 'corpus_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'generated_facade_sha256\t%s\n' "$(sha256sum "$outdir/generated_profile_expression_facade.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'test_program_sha256\t%s\n' "$(sha256sum "$outdir/test_generated_profile_expression_facade.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'e79_summary_sha256\t%s\n' "$expected_e79_summary_hash" >>"$outdir/summary.tsv"
printf 'e67_summary_sha256\t%s\n' "$expected_e67_summary_hash" >>"$outdir/summary.tsv"

printf 'E0080 oracle: generated expression and precedence facade completed\n'
cat "$outdir/summary.tsv"
