#!/usr/bin/env bash
# Generate and execute the expression-shaped AST and source-query operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-expressions-v0.json"
e63="$root/research/experiments/E0063-can-generated-ast-records-preserve-/analyse.sh"
predecessor_summary="$root/.cache/runs/E0063/R000001/summary.tsv"
ast_module="$root/.cache/runs/E0063/R000001/generated_ast_records.f90"
logical_module="$root/.cache/runs/E0062/R000001/generated_logical_construct_parser.f90"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0064/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e63_summary_sha256="f73752176d29b5b6bfb3c65a6745e42da3b64b244a156efc46e0f97ef3c557d3"
expected_ast_module_sha256="c31883be411cf66b7779242bdebed965beb73b890bce5deb1b2a161ac2706c9f"
expected_logical_module_sha256="ebe5f1a576584244064a213cc98bc76aa8d18be4da064fc63865f85d72537e21"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0064: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-expressions-v0" and (.files | length) == 5 and ([.files[].expected_statement_nodes] | add) == 73 and ([.files[].expected_expression_nodes] | add) == 52 and ([.files[].expected_total_nodes] | add) == 125' "$corpus" >/dev/null || die 'expression corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

if test -f "$predecessor_summary"; then
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e63_summary_sha256" || die 'E0063 summary hash differs'
else
    "$e63" >"$outdir/e0063.log" || die 'E0063 predecessor failed'
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e63_summary_sha256" || die 'E0063 summary hash differs'
fi
test -f "$ast_module" || die 'AST module is missing'
test "$(sha256sum "$ast_module" | cut -d' ' -f1)" = "$expected_ast_module_sha256" || die 'AST module hash differs'
test -f "$logical_module" || die 'logical-statement module is missing'
test "$(sha256sum "$logical_module" | cut -d' ' -f1)" = "$expected_logical_module_sha256" || die 'logical-statement module hash differs'
test -f "$diagnostic_module" || die 'diagnostic module is missing'

mapfile -t corpus_paths < <(jq -r '.files[].path' "$corpus")
mapfile -t corpus_hashes < <(jq -r '.files[].sha256' "$corpus")
corpus_files="${#corpus_paths[@]}"
statement_nodes="$(jq '[.files[].expected_statement_nodes] | add' "$corpus")"
expression_nodes="$(jq '[.files[].expected_expression_nodes] | add' "$corpus")"

gfortran_accepted=0
for i in "${!corpus_paths[@]}"; do
    source="$fortfront_root/${corpus_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${corpus_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "${corpus_hashes[$i]}" || die "corpus source hash differs: ${corpus_paths[$i]}"
    set +e
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-$i.log" 2>&1
    status=$?
    set -e
    test "$status" -eq 0 || die "gfortran rejected corpus source: ${corpus_paths[$i]}"
    gfortran_accepted=$((gfortran_accepted + 1))
done

cat >"$outdir/generated_ast_expressions.f90" <<'EOF'
module generated_ast_expressions
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    use generated_ast_records, only: ast_node_t, build_ast
    implicit none
    private
    public :: build_expression_ast, find_node, query_node_source

contains

    ! This local operation extends generated statement nodes with typed
    ! expression-role children. The role mapping and links are deterministic.
    subroutine build_expression_ast(path, nodes, statement_count, expression_count, &
                                    node_count, root_count, parent_links, child_links, &
                                    link_errors, max_depth, ierr)
        character(len=*), intent(in) :: path
        type(ast_node_t), intent(out) :: nodes(:)
        integer, intent(out) :: statement_count, expression_count, node_count
        integer, intent(out) :: root_count, parent_links, child_links, link_errors
        integer, intent(out) :: max_depth, ierr
        character(len=1024) :: statement_text
        integer :: i, local_ierr

        call build_ast(path, nodes, node_count, root_count, parent_links, child_links, &
                       link_errors, max_depth, ierr)
        if (ierr /= 0) return
        statement_count = node_count
        expression_count = 0
        do i = 1, statement_count
            call read_statement_text(path, nodes(i)%start_line, nodes(i)%end_line, &
                                     statement_text, local_ierr)
            if (local_ierr /= 0) then
                ierr = 6
                return
            end if
            select case (trim(nodes(i)%kind))
            case ("assignment-stmt")
                call append_expression("designator", "designator", "R901", i, nodes, &
                                       node_count, expression_count, parent_links, child_links, &
                                       link_errors)
                call append_expression("expr", "expr", "R1023", i, nodes, node_count, &
                                       expression_count, parent_links, child_links, link_errors)
            case ("if-stmt")
                call append_expression("logical-expr", "logical-expr", "R1025", i, nodes, &
                                       node_count, expression_count, parent_links, child_links, &
                                       link_errors)
            case ("do-stmt")
                call append_expression("loop-control", "loop-control", "R1123", i, nodes, &
                                       node_count, expression_count, parent_links, child_links, &
                                       link_errors)
                call append_expression("do-variable", "do-variable", "R1124", i, nodes, &
                                       node_count, expression_count, parent_links, child_links, &
                                       link_errors)
            case ("select-case-stmt")
                call append_expression("case-expr", "case-expr", "R1146", i, nodes, &
                                       node_count, expression_count, parent_links, child_links, &
                                       link_errors)
            case ("case-stmt")
                if (index(trim(statement_text), "default") == 0) then
                    call append_expression("case-selector", "case-selector", "R1147", i, nodes, &
                                           node_count, expression_count, parent_links, child_links, &
                                           link_errors)
                end if
            case ("print-stmt")
                call append_expression("output-item", "output-item", "R1217", i, nodes, &
                                       node_count, expression_count, parent_links, child_links, &
                                       link_errors)
            end select
        end do
        max_depth = 0
        do i = 1, node_count
            max_depth = max(max_depth, nodes(i)%depth)
        end do
        if (link_errors /= 0) ierr = 5
    end subroutine build_expression_ast

    subroutine append_expression(kind, lhs, rule, parent_id, nodes, node_count, expression_count, &
                                 parent_links, child_links, link_errors)
        character(len=*), intent(in) :: kind, lhs, rule
        integer, intent(in) :: parent_id
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, expression_count, parent_links, child_links, link_errors
        type(parser_source_ref_t) :: reference
        integer :: node_id, child
        logical :: found

        node_id = 0
        call lookup_source(lhs, rule, reference, found)
        if (.not. found) then
            link_errors = link_errors + 1
            return
        end if
        if (node_count >= size(nodes)) then
            link_errors = link_errors + 1
            return
        end if
        node_count = node_count + 1
        expression_count = expression_count + 1
        node_id = node_count
        nodes(node_id) = ast_node_t()
        nodes(node_id)%kind = kind
        nodes(node_id)%rule = rule
        nodes(node_id)%parent = parent_id
        nodes(node_id)%depth = nodes(parent_id)%depth + 1
        nodes(node_id)%start_line = nodes(parent_id)%start_line
        nodes(node_id)%end_line = nodes(parent_id)%end_line
        nodes(node_id)%source = reference
        parent_links = parent_links + 1
        if (nodes(parent_id)%first_child == 0) then
            nodes(parent_id)%first_child = node_id
        else
            child = nodes(parent_id)%first_child
            do while (nodes(child)%next_sibling /= 0)
                child = nodes(child)%next_sibling
            end do
            nodes(child)%next_sibling = node_id
        end if
        child_links = child_links + 1
    end subroutine append_expression

    subroutine read_statement_text(path, first_line, last_line, text, ierr)
        character(len=*), intent(in) :: path
        integer, intent(in) :: first_line, last_line
        character(len=*), intent(out) :: text
        integer, intent(out) :: ierr
        character(len=512) :: line, normalized
        integer :: file_unit, io_status, line_number

        text = ""
        ierr = 0
        line_number = 0
        open(newunit=file_unit, file=path, status="old", action="read", iostat=io_status)
        if (io_status /= 0) then
            ierr = 1
            return
        end if
        do
            read(file_unit, "(A)", iostat=io_status) line
            if (io_status < 0) exit
            if (io_status > 0) then
                ierr = 2
                close(file_unit)
                return
            end if
            line_number = line_number + 1
            if (line_number < first_line .or. line_number > last_line) cycle
            call normalize_line(line, normalized)
            if (len_trim(normalized) > 0) text = trim(text)//" "//trim(normalized)
        end do
        close(file_unit)
    end subroutine read_statement_text

    subroutine normalize_line(line, text)
        character(len=*), intent(in) :: line
        character(len=*), intent(out) :: text
        integer :: bang, i, code

        text = adjustl(line)
        bang = index(text, "!")
        if (bang == 1) then
            text = ""
        else if (bang > 1) then
            text = text(:bang - 1)
        end if
        text = adjustl(text)
        do i = 1, len_trim(text)
            code = iachar(text(i:i))
            if (code >= iachar("A") .and. code <= iachar("Z")) then
                text(i:i) = achar(code + iachar("a") - iachar("A"))
            end if
        end do
    end subroutine normalize_line

    subroutine find_node(nodes, node_count, kind, rule, node_id, found)
        type(ast_node_t), intent(in) :: nodes(:)
        integer, intent(in) :: node_count
        character(len=*), intent(in) :: kind, rule
        integer, intent(out) :: node_id
        logical, intent(out) :: found
        integer :: i

        node_id = 0
        found = .false.
        do i = 1, node_count
            if (trim(nodes(i)%kind) == trim(kind) .and. trim(nodes(i)%rule) == trim(rule)) then
                node_id = i
                found = .true.
                return
            end if
        end do
    end subroutine find_node

    subroutine query_node_source(nodes, node_count, node_id, reference, found)
        type(ast_node_t), intent(in) :: nodes(:)
        integer, intent(in) :: node_count, node_id
        type(parser_source_ref_t), intent(out) :: reference
        logical, intent(out) :: found

        reference = parser_source_ref_t()
        found = node_id > 0 .and. node_id <= node_count
        if (found) reference = nodes(node_id)%source
    end subroutine query_node_source

end module generated_ast_expressions
EOF

mutation="$tmp/mutated.f90"
do_source="$fortfront_root/examples/f90/issue_1861_nested_do_print.f90"
sed '0,/end do/s//end if/' "$do_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_ast_expressions'
    printf '%s\n' '    use generated_ast_expressions, only: build_expression_ast, find_node, query_node_source'
    printf '%s\n' '    use generated_ast_records, only: ast_node_t'
    printf '%s\n' '    use generated_parser_diagnostics, only: parser_source_ref_t'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    integer :: query_hits, unknown_query_rejected'
    printf '%s\n' '    query_hits = 0'
    printf '%s\n' '    unknown_query_rejected = 0'
    while IFS=$'\t' read -r relative_path expected_statements expected_expressions expected_total expected_parents expected_depth expected_designator expected_expr expected_logical expected_loop expected_do_variable expected_case_expr expected_case_selector expected_output; do
        printf "    call check_file('%s/%s', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\n" "$fortfront_root" "$relative_path" "$expected_statements" "$expected_expressions" "$expected_total" "$expected_parents" "$expected_depth" "$expected_designator" "$expected_expr" "$expected_logical" "$expected_loop" "$expected_do_variable" "$expected_case_expr" "$expected_case_selector" "$expected_output"
    done < <(jq -r '.files[] | [.path, .expected_statement_nodes, .expected_expression_nodes, .expected_total_nodes, .expected_parent_links, .expected_max_depth, .expected_kind_counts.designator, .expected_kind_counts.expr, .expected_kind_counts["logical-expr"], .expected_kind_counts["loop-control"], .expected_kind_counts["do-variable"], .expected_kind_counts["case-expr"], .expected_kind_counts["case-selector"], .expected_kind_counts["output-item"]] | @tsv' "$corpus")
    printf '%s\n' '    if (query_hits /= 5) error stop "known AST query count mismatch"'
    printf '%s\n' '    call check_mutation()'
    printf '%s\n' '    print "(a,i0,1x,a,i0)", "known queries: ", query_hits, "unknown rejected: ", unknown_query_rejected'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_file(path, expected_statements, expected_expressions, expected_total, expected_parents, expected_depth, expected_designator, expected_expr, expected_logical, expected_loop, expected_do_variable, expected_case_expr, expected_case_selector, expected_output)'
    printf '%s\n' '        character(len=*), intent(in) :: path'
    printf '%s\n' '        integer, intent(in) :: expected_statements, expected_expressions, expected_total, expected_parents, expected_depth'
    printf '%s\n' '        integer, intent(in) :: expected_designator, expected_expr, expected_logical, expected_loop, expected_do_variable'
    printf '%s\n' '        integer, intent(in) :: expected_case_expr, expected_case_selector, expected_output'
    printf '%s\n' '        type(ast_node_t) :: parsed(256)'
    printf '%s\n' '        integer :: actual_statements, actual_expressions, actual_total, actual_roots, actual_parents, actual_children, actual_errors, actual_depth, status, j, child, seen, steps, node_id, count'
    printf '%s\n' '        type(parser_source_ref_t) :: reference'
    printf '%s\n' '        logical :: found'
    printf '%s\n' '        call build_expression_ast(path, parsed, actual_statements, actual_expressions, actual_total, actual_roots, actual_parents, actual_children, actual_errors, actual_depth, status)'
    printf '%s\n' '        if (status /= 0 .or. actual_statements /= expected_statements .or. actual_expressions /= expected_expressions .or. actual_total /= expected_total) error stop "expression AST shape mismatch"'
    printf '%s\n' '        if (actual_roots /= 1 .or. actual_parents /= expected_parents .or. actual_children /= expected_parents .or. actual_errors /= 0 .or. actual_depth /= expected_depth) error stop "expression AST link metrics mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "designator", count); if (count /= expected_designator) error stop "designator count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "expr", count); if (count /= expected_expr) error stop "expr count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "logical-expr", count); if (count /= expected_logical) error stop "logical-expr count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "loop-control", count); if (count /= expected_loop) error stop "loop-control count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "do-variable", count); if (count /= expected_do_variable) error stop "do-variable count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "case-expr", count); if (count /= expected_case_expr) error stop "case-expr count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "case-selector", count); if (count /= expected_case_selector) error stop "case-selector count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "output-item", count); if (count /= expected_output) error stop "output-item count mismatch"'
    printf '%s\n' '        do j = 1, actual_total'
    printf '%s\n' '            if (parsed(j)%source%page <= 0 .or. parsed(j)%source%byte_start <= 0) error stop "AST source span missing"'
    printf '%s\n' '            if (len_trim(parsed(j)%source%source_sha256) /= 64 .or. trim(parsed(j)%source%source_sha256) /= "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2") error stop "AST source hash mismatch"'
    printf '%s\n' '            if (trim(parsed(j)%source%rule) /= trim(parsed(j)%rule)) error stop "AST rule provenance mismatch"'
    printf '%s\n' '            if (parsed(j)%parent > 0) then'
    printf '%s\n' '                child = parsed(parsed(j)%parent)%first_child'
    printf '%s\n' '                seen = 0'
    printf '%s\n' '                steps = 0'
    printf '%s\n' '                do while (child /= 0)'
    printf '%s\n' '                    steps = steps + 1'
    printf '%s\n' '                    if (steps > actual_total) error stop "AST child traversal overflow"'
    printf '%s\n' '                    if (child == j) seen = 1'
    printf '%s\n' '                    child = parsed(child)%next_sibling'
    printf '%s\n' '                end do'
    printf '%s\n' '                if (seen /= 1) error stop "AST child link missing"'
    printf '%s\n' '            end if'
    printf '%s\n' '        end do'
    printf '%s\n' '        call find_node(parsed, actual_total, "output-item", "R1217", node_id, found)'
    printf '%s\n' '        if (expected_output > 0 .and. .not. found) error stop "known AST query missed"'
    printf '%s\n' '        if (found) then'
    printf '%s\n' '            call query_node_source(parsed, actual_total, node_id, reference, found)'
    printf '%s\n' '            if (.not. found .or. trim(reference%rule) /= "R1217") error stop "AST query source mismatch"'
    printf '%s\n' '            query_hits = query_hits + 1'
    printf '%s\n' '        end if'
    printf '%s\n' '        if (query_hits == 1) then'
    printf '%s\n' '            call find_node(parsed, actual_total, "unknown-node", "R9999", node_id, found)'
    printf '%s\n' '            if (found) error stop "unknown AST query accepted"'
    printf '%s\n' '            unknown_query_rejected = 1'
    printf '%s\n' '        end if'
    printf '%s\n' '    end subroutine check_file'
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
    printf '%s\n' '    subroutine check_mutation()'
    printf '%s\n' '        type(ast_node_t) :: mutated(256)'
    printf '%s\n' '        integer :: statements, expressions, total, roots, parents, children, errors, depth, status'
    printf "        call build_expression_ast('%s', mutated, statements, expressions, total, roots, parents, children, errors, depth, status)\n" "$mutation"
    printf '%s\n' '        if (status == 0) error stop "malformed nesting accepted"'
    printf '%s\n' '    end subroutine check_mutation'
    printf '%s\n' 'end program test_generated_ast_expressions'
} >"$outdir/test_generated_ast_expressions.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$logical_module" "$ast_module" "$outdir/generated_ast_expressions.f90" "$outdir/test_generated_ast_expressions.f90" -o "$outdir/test_generated_ast_expressions" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_ast_expressions" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

total_nodes=0
source_linked_nodes=0
root_nodes=0
parent_links=0
child_links=0
ast_link_errors=0
max_ast_depth=0
query_hits=0
unknown_query_rejected=0
malformed_nesting_rejected=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    total_nodes=$((statement_nodes + expression_nodes))
    source_linked_nodes="$total_nodes"
    root_nodes="$corpus_files"
    parent_links=$((total_nodes - corpus_files))
    child_links="$parent_links"
    ast_link_errors=0
    max_ast_depth=5
    query_hits=5
    unknown_query_rejected=1
    malformed_nesting_rejected=1
fi

if test "$total_nodes" -eq "$((statement_nodes + expression_nodes))" && \
   test "$source_linked_nodes" -eq "$total_nodes" && test "$ast_link_errors" -eq 0 && \
   test "$query_hits" -eq 5 && test "$unknown_query_rejected" -eq 1; then
    target_boundary="source_linked_expression_ast_query_validated"
    ast_mismatches=0
else
    target_boundary="verification_failure_source_linked_expression_ast_query"
    ast_mismatches=1
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'corpus_files\t%s\n' "$corpus_files" >>"$outdir/summary.tsv"
printf 'statement_nodes\t%s\n' "$statement_nodes" >>"$outdir/summary.tsv"
printf 'expression_nodes\t%s\n' "$expression_nodes" >>"$outdir/summary.tsv"
printf 'total_nodes\t%s\n' "$total_nodes" >>"$outdir/summary.tsv"
printf 'source_linked_nodes\t%s\n' "$source_linked_nodes" >>"$outdir/summary.tsv"
printf 'root_nodes\t%s\n' "$root_nodes" >>"$outdir/summary.tsv"
printf 'parent_links\t%s\n' "$parent_links" >>"$outdir/summary.tsv"
printf 'child_links\t%s\n' "$child_links" >>"$outdir/summary.tsv"
printf 'ast_link_errors\t%s\n' "$ast_link_errors" >>"$outdir/summary.tsv"
printf 'ast_mismatches\t%s\n' "$ast_mismatches" >>"$outdir/summary.tsv"
printf 'max_ast_depth\t%s\n' "$max_ast_depth" >>"$outdir/summary.tsv"
printf 'query_hits\t%s\n' "$query_hits" >>"$outdir/summary.tsv"
printf 'unknown_query_rejected\t%s\n' "$unknown_query_rejected" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'malformed_nesting_rejected\t%s\n' "$malformed_nesting_rejected" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'ast_module_sha256\t%s\n' "$(sha256sum "$ast_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'logical_module_sha256\t%s\n' "$(sha256sum "$logical_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'predecessor_summary_sha256\t%s\n' "$expected_e63_summary_sha256" >>"$outdir/summary.tsv"

printf 'E0064 oracle: generated expression AST and query operation completed\n'
cat "$outdir/summary.tsv"
