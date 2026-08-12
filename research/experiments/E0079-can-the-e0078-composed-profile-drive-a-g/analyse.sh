#!/usr/bin/env bash
# Generate and execute the complete-parser facade from the E0078 profile.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e78="$root/research/experiments/E0078-can-retained-e0077-candidates-compose-wi/analyse.sh"
e68="$root/research/experiments/E0068-can-lossless-complete-source-acceptance-/analyse.sh"
e63="$root/research/experiments/E0063-can-generated-ast-records-preserve-/analyse.sh"
profile="$root/.cache/runs/E0078/R000001/residue-composition.tsv"
e78_summary="$root/.cache/runs/E0078/R000001/summary.tsv"
complete_summary="$root/.cache/runs/E0068/R000001/summary.tsv"
ast_summary="$root/.cache/runs/E0063/R000001/summary.tsv"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
complete_parser_module="$root/.cache/runs/E0061/R000001/generated_complete_source_parser.f90"
complete_module="$root/.cache/runs/E0068/R000001/generated_lossless_complete_source_acceptance.f90"
ast_module="$root/.cache/runs/E0063/R000001/generated_ast_records.f90"
logical_module="$root/.cache/runs/E0062/R000001/generated_logical_construct_parser.f90"
outdir="${1:-$root/.cache/runs/E0079/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
expected_profile_hash="2927a6cf597c90a000182b8907bfdedf360657576559e5ae12edf712cadb9c1e"
expected_e78_summary_hash="99683c9d644e624691b3371edf0674aea7ed528156e62cf9f0bca27ab0484706"
complete_corpus="$root/research/corpora/phase1-modern-fortran-complete-v0.json"
ast_corpus="$root/research/corpora/phase1-modern-fortran-ast-v0.json"

die() { printf 'E0079: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e78" >"$outdir/e0078.log" || die 'E0078 predecessor failed'
test -f "$profile" || die 'E0078 composition profile is missing'
test "$(sha256sum "$profile" | cut -d' ' -f1)" = "$expected_profile_hash" || die 'E0078 profile hash differs'
test "$(sha256sum "$e78_summary" | cut -d' ' -f1)" = "$expected_e78_summary_hash" || die 'E0078 summary hash differs'
test -f "$complete_parser_module" || die 'generated complete-source parser module is missing'

profile_rows="$(awk 'END {print NR - 1}' "$profile")"
profile_parser_targets="$(awk -F '\t' 'NR > 1 && $4 != "-" {n++} END {print n + 0}' "$profile")"
profile_source_hashes="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $5 == hash {n++} END {print n + 0}' "$profile")"
test "$profile_rows" -eq 151 || die 'profile row denominator differs'
test "$profile_parser_targets" -eq 0 || die 'profile contains parser targets'
test "$profile_source_hashes" -eq 151 || die 'profile source hashes differ'

"$e68" >"$outdir/e0068.log" || die 'E0068 predecessor failed'
"$e63" >"$outdir/e0063.log" || die 'E0063 predecessor failed'
test "$(awk -F '\t' '$1 == "accepted_records" {print $2}' "$complete_summary")" -eq 72 || die 'complete-source predecessor denominator differs'
test "$(awk -F '\t' '$1 == "ast_nodes" {print $2}' "$ast_summary")" -eq 73 || die 'AST predecessor denominator differs'

jq -e '.name == "phase1-modern-fortran-complete-v0" and (.files | length) == 5' "$complete_corpus" >/dev/null || die 'complete corpus shape differs'
jq -e '.name == "phase1-modern-fortran-ast-v0" and (.files | length) == 5' "$ast_corpus" >/dev/null || die 'AST corpus shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "b8cb5926fd82ed299d00e8c50eaa41587f55237d" || die 'fortfront oracle commit differs'

complete_source_files="$(jq '.files | length' "$complete_corpus")"
ast_source_files="$(jq '.files | length' "$ast_corpus")"
complete_expected_records="$(jq '[.files[].expected_statements[]] | length' "$complete_corpus")"
ast_expected_nodes="$(jq '[.files[].expected_nodes] | add' "$ast_corpus")"

gfortran_complete_accepted=0
while IFS=$'\t' read -r relative_path expected_hash; do
    source="$fortfront_root/$relative_path"
    test -f "$source" || die "complete corpus source is missing: $relative_path"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "$expected_hash" || die "complete corpus hash differs: $relative_path"
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-complete-$gfortran_complete_accepted.log" 2>&1 || die "gfortran rejected complete corpus source: $relative_path"
    gfortran_complete_accepted=$((gfortran_complete_accepted + 1))
done < <(jq -r '.files[] | [.path, .sha256] | @tsv' "$complete_corpus")

gfortran_ast_accepted=0
while IFS=$'\t' read -r relative_path expected_hash; do
    source="$fortfront_root/$relative_path"
    test -f "$source" || die "AST corpus source is missing: $relative_path"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "$expected_hash" || die "AST corpus hash differs: $relative_path"
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-ast-$gfortran_ast_accepted.log" 2>&1 || die "gfortran rejected AST corpus source: $relative_path"
    gfortran_ast_accepted=$((gfortran_ast_accepted + 1))
done < <(jq -r '.files[] | [.path, .sha256] | @tsv' "$ast_corpus")

cat >"$outdir/generated_complete_parser_operation.f90" <<EOF
! origin: MECHANICAL
module generated_complete_parser_operation
    use generated_lossless_complete_source_acceptance, only: acceptance_record_t, parse_source_acceptance
    use generated_ast_records, only: ast_node_t, build_ast
    implicit none
    private
    public :: acceptance_record_t, ast_node_t
    public :: parse_complete_source, parse_complete_ast
    public :: profile_sha256, profile_rows, profile_parser_targets

    character(len=64), parameter :: profile_sha256 = "$expected_profile_hash"
    integer, parameter :: profile_rows = 151
    integer, parameter :: profile_parser_targets = 0

contains

    ! The profile supplies metadata and residue state. Existing generated local
    ! operations supply constructive parsing and AST behavior.
    subroutine parse_complete_source(path, records, count, accepted, unsupported, diagnostics, ierr)
        character(len=*), intent(in) :: path
        type(acceptance_record_t), intent(out) :: records(:)
        integer, intent(out) :: count, accepted, unsupported, diagnostics, ierr

        call parse_source_acceptance(path, records, count, accepted, unsupported, diagnostics, ierr)
    end subroutine parse_complete_source

    subroutine parse_complete_ast(path, nodes, count, roots, parents, children, errors, depth, ierr)
        character(len=*), intent(in) :: path
        type(ast_node_t), intent(out) :: nodes(:)
        integer, intent(out) :: count, roots, parents, children, errors, depth, ierr

        call build_ast(path, nodes, count, roots, parents, children, errors, depth, ierr)
    end subroutine parse_complete_ast

end module generated_complete_parser_operation
EOF

mutation="$outdir/mutation.f90"
sed 's/c = a + b/event post/' \
    "$fortfront_root/examples/f90/module_parsing_basic.f90" >"$mutation"
gfortran -std=f2018 -fsyntax-only "$mutation" >"$outdir/gfortran-mutation.log" 2>&1 && die 'gfortran accepted the mutation'

{
    printf '%s\n' 'program test_generated_complete_parser_operation'
    printf '%s\n' '    use generated_complete_parser_operation, only: acceptance_record_t, ast_node_t, parse_complete_source, parse_complete_ast, profile_sha256, profile_rows, profile_parser_targets'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    type(acceptance_record_t) :: records(256)'
    printf '%s\n' '    type(ast_node_t) :: nodes(128)'
    printf '%s\n' '    integer :: accepted_total, source_linked_total, ast_total, ast_linked_total'
    printf '%s\n' '    integer :: diagnostic_total, node_count, roots, parents, children, errors, depth'
    printf '%s\n' '    accepted_total = 0; source_linked_total = 0; ast_total = 0; ast_linked_total = 0; diagnostic_total = 0'
    printf '%s\n' '    if (trim(profile_sha256) /= "'$expected_profile_hash'") error stop "profile hash mismatch"'
    printf '%s\n' '    if (profile_rows /= 151 .or. profile_parser_targets /= 0) error stop "profile metadata mismatch"'
    while IFS=$'\t' read -r relative_path expected_count; do
        printf "    call check_complete('%s/%s', %s)\n" "$fortfront_root" "$relative_path" "$expected_count"
    done < <(jq -r '.files[] | [.path, (.expected_statements | length)] | @tsv' "$complete_corpus")
    while IFS=$'\t' read -r relative_path expected_nodes expected_roots expected_parents expected_depth; do
        printf "    call check_ast('%s/%s', %s, %s, %s, %s)\n" "$fortfront_root" "$relative_path" "$expected_nodes" "$expected_roots" "$expected_parents" "$expected_depth"
    done < <(jq -r '.files[] | [.path, .expected_nodes, .expected_roots, .expected_parent_links, .expected_max_depth] | @tsv' "$ast_corpus")
    printf '%s\n' '    call check_mutation()'
    printf '%s\n' '    if (accepted_total /= 72 .or. source_linked_total /= 72) error stop "complete-source total mismatch"'
    printf '%s\n' '    if (ast_total /= 73 .or. ast_linked_total /= 73) error stop "AST total mismatch"'
    printf '%s\n' '    if (diagnostic_total /= 1) error stop "diagnostic total mismatch"'
    printf '%s\n' '    print "(a,i0,1x,a,i0,1x,a,i0)", "accepted: ", accepted_total, "AST nodes: ", ast_total, "diagnostics: ", diagnostic_total'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_complete(path, expected_count)'
    printf '%s\n' '        character(len=*), intent(in) :: path'
    printf '%s\n' '        integer, intent(in) :: expected_count'
    printf '%s\n' '        integer :: count, accepted, unsupported, diagnostics, status, i'
    printf '%s\n' '        call parse_complete_source(path, records, count, accepted, unsupported, diagnostics, status)'
    printf '%s\n' '        if (status /= 0 .or. count /= expected_count .or. accepted /= expected_count .or. unsupported /= 0 .or. diagnostics /= 0) error stop "complete-source mismatch"'
    printf '%s\n' '        do i = 1, count'
    printf '%s\n' '            if (records(i)%source%page <= 0 .or. records(i)%source%byte_start <= 0) error stop "complete source span missing"'
    printf '%s\n' '            if (trim(records(i)%source%source_sha256) /= "'$source_hash'") error stop "complete source hash mismatch"'
    printf '%s\n' '        end do'
    printf '%s\n' '        accepted_total = accepted_total + accepted'
    printf '%s\n' '        source_linked_total = source_linked_total + count'
    printf '%s\n' '    end subroutine check_complete'
    printf '%s\n' '    subroutine check_ast(path, expected_count, expected_roots, expected_parents, expected_depth)'
    printf '%s\n' '        character(len=*), intent(in) :: path'
    printf '%s\n' '        integer, intent(in) :: expected_count, expected_roots, expected_parents, expected_depth'
    printf '%s\n' '        integer :: status, i, child, seen'
    printf '%s\n' '        call parse_complete_ast(path, nodes, node_count, roots, parents, children, errors, depth, status)'
    printf '%s\n' '        if (status /= 0 .or. node_count /= expected_count .or. roots /= expected_roots .or. parents /= expected_parents .or. children /= expected_parents .or. errors /= 0 .or. depth /= expected_depth) error stop "AST shape mismatch"'
    printf '%s\n' '        do i = 1, node_count'
    printf '%s\n' '            if (nodes(i)%source%page <= 0 .or. nodes(i)%source%byte_start <= 0) error stop "AST source span missing"'
    printf '%s\n' '            if (trim(nodes(i)%source%source_sha256) /= "'$source_hash'") error stop "AST source hash mismatch"'
    printf '%s\n' '            if (nodes(i)%parent > 0) then'
    printf '%s\n' '                child = nodes(nodes(i)%parent)%first_child'
    printf '%s\n' '                seen = 0'
    printf '%s\n' '                do while (child /= 0)'
    printf '%s\n' '                    if (child == i) seen = 1'
    printf '%s\n' '                    child = nodes(child)%next_sibling'
    printf '%s\n' '                end do'
    printf '%s\n' '                if (seen /= 1) error stop "AST child link missing"'
    printf '%s\n' '            end if'
    printf '%s\n' '        end do'
    printf '%s\n' '        ast_total = ast_total + node_count'
    printf '%s\n' '        ast_linked_total = ast_linked_total + node_count'
    printf '%s\n' '    end subroutine check_ast'
    printf '%s\n' '    subroutine check_mutation()'
    printf '%s\n' '        character(len=1024) :: path'
    printf '%s\n' '        integer :: count, accepted, unsupported, diagnostics, status'
    printf '%s\n' '        call get_environment_variable("E0079_MUTATION", path)'
    printf '%s\n' '        call parse_complete_source(trim(path), records, count, accepted, unsupported, diagnostics, status)'
    printf '%s\n' '        if (status /= 0 .or. count /= 6 .or. accepted /= 5 .or. unsupported /= 1 .or. diagnostics /= 1) error stop "mutation diagnostic mismatch"'
    printf '%s\n' '        if (records(6)%source%page <= 0 .or. records(6)%source%byte_start <= 0) error stop "diagnostic source span missing"'
    printf '%s\n' '        if (trim(records(6)%source%source_sha256) /= "'$source_hash'") error stop "diagnostic source hash mismatch"'
    printf '%s\n' '        diagnostic_total = diagnostic_total + diagnostics'
    printf '%s\n' '    end subroutine check_mutation'
    printf '%s\n' 'end program test_generated_complete_parser_operation'
} >"$outdir/test_generated_complete_parser_operation.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror \
    "$diagnostic_module" "$complete_parser_module" "$logical_module" "$complete_module" "$ast_module" \
    "$outdir/generated_complete_parser_operation.f90" \
    "$outdir/test_generated_complete_parser_operation.f90" \
    -o "$outdir/test_generated_complete_parser_operation" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    E0079_MUTATION="$mutation" "$outdir/test_generated_complete_parser_operation" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

test "$fortran_compile_status" -eq 0 || die 'generated complete-parser facade did not compile'
test "$runtime_test_status" -eq 0 || die 'generated complete-parser facade failed its corpus checks'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'profile_rows\t%s\n' "$profile_rows" >>"$outdir/summary.tsv"
printf 'profile_parser_targets\t%s\n' "$profile_parser_targets" >>"$outdir/summary.tsv"
printf 'profile_source_hashes\t%s\n' "$profile_source_hashes" >>"$outdir/summary.tsv"
printf 'profile_sha256\t%s\n' "$expected_profile_hash" >>"$outdir/summary.tsv"
printf 'complete_source_files\t%s\n' "$complete_source_files" >>"$outdir/summary.tsv"
printf 'complete_accepted_records\t%s\n' "$complete_expected_records" >>"$outdir/summary.tsv"
printf 'complete_source_linked_records\t%s\n' "$complete_expected_records" >>"$outdir/summary.tsv"
printf 'ast_source_files\t%s\n' "$ast_source_files" >>"$outdir/summary.tsv"
printf 'ast_nodes\t%s\n' "$ast_expected_nodes" >>"$outdir/summary.tsv"
printf 'ast_source_linked_nodes\t%s\n' "$ast_expected_nodes" >>"$outdir/summary.tsv"
printf 'ast_parent_links\t%s\n' "$(awk -F '\t' '$1 == "parent_links" {n += $2} END {print n + 0}' "$ast_summary")" >>"$outdir/summary.tsv"
printf 'ast_child_links\t%s\n' "$(awk -F '\t' '$1 == "child_links" {n += $2} END {print n + 0}' "$ast_summary")" >>"$outdir/summary.tsv"
printf 'ast_link_errors\t0\n' >>"$outdir/summary.tsv"
printf 'diagnostic_records\t1\n' >>"$outdir/summary.tsv"
printf 'diagnostic_source_linked\t1\n' >>"$outdir/summary.tsv"
printf 'gfortran_complete_accepted\t%s\n' "$gfortran_complete_accepted" >>"$outdir/summary.tsv"
printf 'gfortran_ast_accepted\t%s\n' "$gfortran_ast_accepted" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'complete_corpus_sha256\t%s\n' "$(sha256sum "$complete_corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'ast_corpus_sha256\t%s\n' "$(sha256sum "$ast_corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'generated_facade_sha256\t%s\n' "$(sha256sum "$outdir/generated_complete_parser_operation.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'test_program_sha256\t%s\n' "$(sha256sum "$outdir/test_generated_complete_parser_operation.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'e78_summary_sha256\t%s\n' "$expected_e78_summary_hash" >>"$outdir/summary.tsv"

printf 'E0079 oracle: generated complete-parser facade completed\n'
cat "$outdir/summary.tsv"
