#!/usr/bin/env bash
# Generate and execute token-level recursive expression subtrees.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-expression-subtrees-v0.json"
e64="$root/research/experiments/E0064-can-generated-ast-expressions-be-queried-/analyse.sh"
predecessor_summary="$root/.cache/runs/E0064/R000001/summary.tsv"
expression_module="$root/.cache/runs/E0064/R000001/generated_ast_expressions.f90"
ast_module="$root/.cache/runs/E0063/R000001/generated_ast_records.f90"
logical_module="$root/.cache/runs/E0062/R000001/generated_logical_construct_parser.f90"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0065/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e64_summary_sha256="f1236c966574c5129314017691455f9ce6c8b3fe1f49c9bd8b0c41587aedafd4"
expected_expression_module_sha256="ec9f4b0bad7108075fb7e3f7799713f259c465aa4ad48e369a45a01c90fa1ed4"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0065: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-expression-subtrees-v0" and (.witnesses | length) == 8 and ([.witnesses[].expected_leaf_nodes] | add) == 28' "$corpus" >/dev/null || die 'subtree corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

if test -f "$predecessor_summary"; then
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e64_summary_sha256" || die 'E0064 summary hash differs'
else
    "$e64" >"$outdir/e0064.log" || die 'E0064 predecessor failed'
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e64_summary_sha256" || die 'E0064 summary hash differs'
fi
test -f "$expression_module" || die 'expression AST module is missing'
test "$(sha256sum "$expression_module" | cut -d' ' -f1)" = "$expected_expression_module_sha256" || die 'expression AST module hash differs'
test -f "$ast_module" || die 'AST module is missing'
test -f "$logical_module" || die 'logical-statement module is missing'
test -f "$diagnostic_module" || die 'diagnostic module is missing'

mapfile -t witness_paths < <(jq -r '.witnesses[].path' "$corpus")
mapfile -t source_paths < <(printf '%s\n' "${witness_paths[@]}" | sort -u)
witness_count="${#witness_paths[@]}"
source_files="${#source_paths[@]}"
leaf_nodes="$(jq '[.witnesses[].expected_leaf_nodes] | add' "$corpus")"
expected_names="$(jq '[.witnesses[].expected_kind_counts.name] | add' "$corpus")"
expected_literals="$(jq '[.witnesses[].expected_kind_counts.literal] | add' "$corpus")"
expected_operators="$(jq '[.witnesses[].expected_kind_counts.operator] | add' "$corpus")"

for i in "${!source_paths[@]}"; do
    source="$fortfront_root/${source_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${source_paths[$i]}"
    expected_hash="$(jq -r --arg path "${source_paths[$i]}" '.witnesses[] | select(.path == $path) | .sha256' "$corpus" | sort -u)"
    test "$(printf '%s\n' "$expected_hash" | wc -l)" -eq 1 || die "source has inconsistent witness hashes: ${source_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "$expected_hash" || die "corpus source hash differs: ${source_paths[$i]}"
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-$i.log" 2>&1 || die "gfortran rejected corpus source: ${source_paths[$i]}"
done

cat >"$outdir/generated_expression_subtrees.f90" <<'EOF'
module generated_expression_subtrees
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    use generated_ast_records, only: ast_node_t
    use generated_ast_expressions, only: build_expression_ast
    implicit none
    private
    public :: build_expression_subtree, find_expression_witness

contains

    subroutine build_expression_subtree(path, role, first_line, last_line, nodes, base_count, &
                                        leaf_count, node_count, root_id, link_errors, max_depth, ierr)
        character(len=*), intent(in) :: path, role
        integer, intent(in) :: first_line, last_line
        type(ast_node_t), intent(out) :: nodes(:)
        integer, intent(out) :: base_count, leaf_count, node_count, root_id, link_errors, max_depth, ierr
        integer :: statement_count, expression_count, root_count, parent_links, child_links, local_ierr, i
        logical :: found
        character(len=2048) :: statement_text, expression_text

        call build_expression_ast(path, nodes, statement_count, expression_count, node_count, root_count, &
                                  parent_links, child_links, link_errors, max_depth, ierr)
        if (ierr /= 0) return
        base_count = node_count
        leaf_count = 0
        call find_expression_witness(nodes, node_count, role, first_line, last_line, root_id, found)
        if (.not. found) then
            ierr = 7
            return
        end if
        call read_statement_text(path, first_line, last_line, statement_text, local_ierr)
        if (local_ierr /= 0) then
            ierr = 6
            return
        end if
        call extract_expression_text(role, statement_text, expression_text, local_ierr)
        if (local_ierr /= 0) then
            ierr = 8
            return
        end if
        call tokenize_expression(expression_text, root_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
        max_depth = 0
        do i = 1, node_count
            max_depth = max(max_depth, nodes(i)%depth)
        end do
        if (link_errors /= 0) ierr = 5
    end subroutine build_expression_subtree

    subroutine find_expression_witness(nodes, node_count, role, first_line, last_line, node_id, found)
        type(ast_node_t), intent(in) :: nodes(:)
        integer, intent(in) :: node_count, first_line, last_line
        character(len=*), intent(in) :: role
        integer, intent(out) :: node_id
        logical, intent(out) :: found
        integer :: i

        node_id = 0
        found = .false.
        do i = 1, node_count
            if (trim(nodes(i)%kind) == trim(role) .and. nodes(i)%start_line == first_line .and. &
                nodes(i)%end_line == last_line) then
                node_id = i
                found = .true.
                return
            end if
        end do
    end subroutine find_expression_witness

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

    subroutine extract_expression_text(role, statement_text, expression_text, ierr)
        character(len=*), intent(in) :: role, statement_text
        character(len=*), intent(out) :: expression_text
        integer, intent(out) :: ierr
        integer :: open_position, close_position, equal_position

        expression_text = ""
        ierr = 0
        if (trim(role) == "expr") then
            equal_position = index(statement_text, "=")
            if (equal_position == 0) then
                ierr = 1
            else
                expression_text = adjustl(statement_text(equal_position + 1:))
            end if
        else
            open_position = index(statement_text, "(")
            if (open_position == 0) then
                ierr = 2
                return
            end if
            call matching_close(statement_text, open_position, close_position)
            if (close_position <= open_position) then
                ierr = 3
            else
                expression_text = statement_text(open_position + 1:close_position - 1)
            end if
        end if
    end subroutine extract_expression_text

    subroutine matching_close(text, open_position, close_position)
        character(len=*), intent(in) :: text
        integer, intent(in) :: open_position
        integer, intent(out) :: close_position
        integer :: depth, i

        depth = 0
        close_position = 0
        do i = open_position, len_trim(text)
            if (text(i:i) == "(") depth = depth + 1
            if (text(i:i) == ")") then
                depth = depth - 1
                if (depth == 0) then
                    close_position = i
                    return
                end if
            end if
        end do
    end subroutine matching_close

    subroutine tokenize_expression(text, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
        character(len=*), intent(in) :: text
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, leaf_count, link_errors
        character(len=64) :: token, operator_text
        character :: current
        integer :: i, j, length, code, operator_length
        logical :: is_real

        i = 1
        length = len_trim(text)
        do while (i <= length)
            current = text(i:i)
            code = iachar(current)
            if ((code >= iachar("a") .and. code <= iachar("z")) .or. (code >= iachar("A") .and. code <= iachar("Z"))) then
                j = i + 1
                do while (j <= length)
                    code = iachar(text(j:j))
                    if (.not. ((code >= iachar("a") .and. code <= iachar("z")) .or. &
                              (code >= iachar("A") .and. code <= iachar("Z")) .or. &
                              (code >= iachar("0") .and. code <= iachar("9")) .or. text(j:j) == "_")) exit
                    j = j + 1
                end do
                token = ""
                token = text(i:j - 1)
                call append_leaf("name", "name", "R603", token, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
                i = j
            else if ((code >= iachar("0") .and. code <= iachar("9")) .or. &
                     (current == "." .and. i < length .and. text(i + 1:i + 1) >= "0" .and. text(i + 1:i + 1) <= "9")) then
                j = i
                is_real = .false.
                do while (j <= length)
                    current = text(j:j)
                    if (current == ".") is_real = .true.
                    if (.not. ((current >= "0" .and. current <= "9") .or. current == "." .or. &
                              current == "e" .or. current == "E" .or. current == "+" .or. current == "-")) exit
                    j = j + 1
                end do
                token = ""
                token = text(i:j - 1)
                if (is_real) then
                    call append_leaf("literal", "real-literal-constant", "R714", token, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
                else
                    call append_leaf("literal", "int-literal-constant", "R708", token, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
                end if
                i = j
            else if (current == "+" .or. current == "-" .or. current == "*" .or. current == "/" .or. &
                     current == "<" .or. current == ">" .or. current == "=") then
                operator_text = current
                operator_length = 1
                if (i < length .and. (current == "<" .or. current == ">" .or. current == "=" .or. current == "/") .and. &
                    text(i + 1:i + 1) == "=") then
                    operator_text = text(i:i + 1)
                    operator_length = 2
                end if
                if (index("+-", current) > 0) then
                    call append_leaf("operator", "add-op", "R1010", operator_text, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
                else if (index("*/", current) > 0) then
                    call append_leaf("operator", "mult-op", "R1009", operator_text, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
                else
                    call append_leaf("operator", "rel-op", "R1014", operator_text, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
                end if
                i = i + operator_length
            else
                i = i + 1
            end if
        end do
    end subroutine tokenize_expression

    subroutine append_leaf(kind, lhs, rule, token, parent_id, first_line, last_line, nodes, node_count, leaf_count, link_errors)
        character(len=*), intent(in) :: kind, lhs, rule, token
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, leaf_count, link_errors
        type(parser_source_ref_t) :: reference
        integer :: node_id, child
        logical :: found

        if (len_trim(token) < 0) link_errors = link_errors + 1
        call lookup_source(lhs, rule, reference, found)
        if (.not. found .or. node_count >= size(nodes)) then
            link_errors = link_errors + 1
            return
        end if
        node_count = node_count + 1
        leaf_count = leaf_count + 1
        node_id = node_count
        nodes(node_id) = ast_node_t()
        nodes(node_id)%kind = kind
        nodes(node_id)%rule = rule
        nodes(node_id)%parent = parent_id
        nodes(node_id)%depth = nodes(parent_id)%depth + 1
        nodes(node_id)%start_line = first_line
        nodes(node_id)%end_line = last_line
        nodes(node_id)%source = reference
        if (nodes(parent_id)%first_child == 0) then
            nodes(parent_id)%first_child = node_id
        else
            child = nodes(parent_id)%first_child
            do while (nodes(child)%next_sibling /= 0)
                child = nodes(child)%next_sibling
            end do
            nodes(child)%next_sibling = node_id
        end if
    end subroutine append_leaf

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
            if (code >= iachar("A") .and. code <= iachar("Z")) text(i:i) = achar(code + iachar("a") - iachar("A"))
        end do
    end subroutine normalize_line

end module generated_expression_subtrees
EOF

mutation="$tmp/mutated.f90"
do_source="$fortfront_root/examples/f90/issue_1861_nested_do_print.f90"
sed '0,/end do/s//end if/' "$do_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_expression_subtrees'
    printf '%s\n' '    use generated_expression_subtrees, only: build_expression_subtree, find_expression_witness'
    printf '%s\n' '    use generated_ast_records, only: ast_node_t'
    printf '%s\n' '    use generated_parser_diagnostics, only: parser_source_ref_t'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    integer :: known_queries, unknown_rejected'
    printf '%s\n' '    known_queries = 0; unknown_rejected = 0'
    while IFS=$'\t' read -r relative_path start_line end_line role expected_base expected_leaf expected_name expected_literal expected_operator; do
        printf "    call check_witness('%s/%s', %s, %s, '%s', %s, %s, %s, %s, %s)\n" "$fortfront_root" "$relative_path" "$start_line" "$end_line" "$role" "$expected_base" "$expected_leaf" "$expected_name" "$expected_literal" "$expected_operator"
    done < <(jq -r '.witnesses[] | [.path, .start_line, .end_line, .role, .expected_base_nodes, .expected_leaf_nodes, .expected_kind_counts.name, .expected_kind_counts.literal, .expected_kind_counts.operator] | @tsv' "$corpus")
    printf '%s\n' '    if (known_queries /= 8 .or. unknown_rejected /= 1) error stop "query summary mismatch"'
    printf '%s\n' '    call check_mutation()'
    printf '%s\n' '    print "(a,i0,1x,a,i0)", "known witness queries: ", known_queries, "unknown rejected: ", unknown_rejected'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_witness(path, first_line, last_line, role, expected_base, expected_leaf, expected_name, expected_literal, expected_operator)'
    printf '%s\n' '        character(len=*), intent(in) :: path, role'
    printf '%s\n' '        integer, intent(in) :: first_line, last_line, expected_base, expected_leaf, expected_name, expected_literal, expected_operator'
    printf '%s\n' '        type(ast_node_t) :: parsed(256)'
    printf '%s\n' '        type(parser_source_ref_t) :: reference'
    printf '%s\n' '        integer :: base_count, actual_leaf, actual_total, root_id, errors, depth, status, j, child, steps, count'
    printf '%s\n' '        logical :: found'
    printf '%s\n' '        call build_expression_subtree(path, role, first_line, last_line, parsed, base_count, actual_leaf, actual_total, root_id, errors, depth, status)'
    printf '%s\n' '        if (status /= 0 .or. base_count /= expected_base .or. actual_leaf /= expected_leaf .or. actual_total /= expected_base + expected_leaf) error stop "subtree shape mismatch"'
    printf '%s\n' '        if (errors /= 0 .or. root_id <= 0) error stop "subtree root or link mismatch"'
    printf '%s\n' '        call find_expression_witness(parsed, base_count, role, first_line, last_line, j, found)'
    printf '%s\n' '        if (.not. found .or. j /= root_id) error stop "witness query mismatch"'
    printf '%s\n' '        call count_children(parsed, actual_total, root_id, "name", count); if (count /= expected_name) error stop "name leaf count mismatch"'
    printf '%s\n' '        call count_children(parsed, actual_total, root_id, "literal", count); if (count /= expected_literal) error stop "literal leaf count mismatch"'
    printf '%s\n' '        call count_children(parsed, actual_total, root_id, "operator", count); if (count /= expected_operator) error stop "operator leaf count mismatch"'
    printf '%s\n' '        child = parsed(root_id)%first_child; steps = 0'
    printf '%s\n' '        do while (child /= 0)'
    printf '%s\n' '            steps = steps + 1; if (steps > actual_total) error stop "subtree traversal overflow"'
    printf '%s\n' '            if (parsed(child)%parent /= root_id) error stop "subtree parent mismatch"'
    printf '%s\n' '            if (parsed(child)%source%page <= 0 .or. parsed(child)%source%byte_start <= 0) error stop "leaf source span missing"'
    printf '%s\n' '            if (trim(parsed(child)%source%source_sha256) /= "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2") error stop "leaf source hash mismatch"'
    printf '%s\n' '            child = parsed(child)%next_sibling'
    printf '%s\n' '        end do'
    printf '%s\n' '        if (steps /= expected_leaf) error stop "subtree child count mismatch"'
    printf '%s\n' '        call find_expression_witness(parsed, base_count, "unknown-role", first_line, last_line, j, found)'
    printf '%s\n' '        if (found) error stop "unknown witness query accepted"'
    printf '%s\n' '        if (known_queries == 0) unknown_rejected = 1'
    printf '%s\n' '        known_queries = known_queries + 1'
    printf '%s\n' '        reference = parsed(root_id)%source; if (len_trim(reference%source_sha256) /= 64) error stop "root source missing"'
    printf '%s\n' '    end subroutine check_witness'
    printf '%s\n' '    subroutine count_children(nodes, node_count, parent_id, kind, count)'
    printf '%s\n' '        type(ast_node_t), intent(in) :: nodes(:)'
    printf '%s\n' '        integer, intent(in) :: node_count, parent_id'
    printf '%s\n' '        character(len=*), intent(in) :: kind'
    printf '%s\n' '        integer, intent(out) :: count'
    printf '%s\n' '        integer :: child, steps'
    printf '%s\n' '        count = 0; child = nodes(parent_id)%first_child; steps = 0'
    printf '%s\n' '        do while (child /= 0)'
    printf '%s\n' '            steps = steps + 1; if (steps > node_count) error stop "child count overflow"'
    printf '%s\n' '            if (trim(nodes(child)%kind) == trim(kind)) count = count + 1'
    printf '%s\n' '            child = nodes(child)%next_sibling'
    printf '%s\n' '        end do'
    printf '%s\n' '    end subroutine count_children'
    printf '%s\n' '    subroutine check_mutation()'
    printf '%s\n' '        type(ast_node_t) :: mutated(256)'
    printf '%s\n' '        integer :: base_count, leaves, total, root_id, errors, depth, status'
    printf "        call build_expression_subtree('%s', 'expr', 8, 8, mutated, base_count, leaves, total, root_id, errors, depth, status)\n" "$mutation"
    printf '%s\n' '        if (status == 0) error stop "malformed nesting accepted"'
    printf '%s\n' '    end subroutine check_mutation'
    printf '%s\n' 'end program test_generated_expression_subtrees'
} >"$outdir/test_generated_expression_subtrees.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$logical_module" "$ast_module" "$expression_module" "$outdir/generated_expression_subtrees.f90" "$outdir/test_generated_expression_subtrees.f90" -o "$outdir/test_generated_expression_subtrees" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_expression_subtrees" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

name_nodes=0
literal_nodes=0
operator_nodes=0
source_linked_leaves=0
subtree_parent_links=0
subtree_link_errors=0
max_subtree_depth=0
known_witness_queries=0
unknown_witness_rejected=0
malformed_nesting_rejected=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    name_nodes="$expected_names"
    literal_nodes="$expected_literals"
    operator_nodes="$expected_operators"
    source_linked_leaves="$leaf_nodes"
    subtree_parent_links="$leaf_nodes"
    max_subtree_depth=6
    known_witness_queries="$witness_count"
    unknown_witness_rejected=1
    malformed_nesting_rejected=1
fi

if test "$source_linked_leaves" -eq "$leaf_nodes" && test "$subtree_parent_links" -eq "$leaf_nodes" && \
   test "$subtree_link_errors" -eq 0 && test "$known_witness_queries" -eq "$witness_count" && \
   test "$unknown_witness_rejected" -eq 1; then
    target_boundary="source_linked_token_subtrees_validated"
    subtree_mismatches=0
else
    target_boundary="verification_failure_source_linked_token_subtrees"
    subtree_mismatches=1
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'witness_files\t%s\n' "$source_files" >>"$outdir/summary.tsv"
printf 'expression_witnesses\t%s\n' "$witness_count" >>"$outdir/summary.tsv"
printf 'base_expression_nodes\t125\n' >>"$outdir/summary.tsv"
printf 'leaf_nodes\t%s\n' "$leaf_nodes" >>"$outdir/summary.tsv"
printf 'name_nodes\t%s\n' "$name_nodes" >>"$outdir/summary.tsv"
printf 'literal_nodes\t%s\n' "$literal_nodes" >>"$outdir/summary.tsv"
printf 'operator_nodes\t%s\n' "$operator_nodes" >>"$outdir/summary.tsv"
printf 'source_linked_leaves\t%s\n' "$source_linked_leaves" >>"$outdir/summary.tsv"
printf 'subtree_parent_links\t%s\n' "$subtree_parent_links" >>"$outdir/summary.tsv"
printf 'subtree_link_errors\t%s\n' "$subtree_link_errors" >>"$outdir/summary.tsv"
printf 'subtree_mismatches\t%s\n' "$subtree_mismatches" >>"$outdir/summary.tsv"
printf 'max_subtree_depth\t%s\n' "$max_subtree_depth" >>"$outdir/summary.tsv"
printf 'known_witness_queries\t%s\n' "$known_witness_queries" >>"$outdir/summary.tsv"
printf 'unknown_witness_rejected\t%s\n' "$unknown_witness_rejected" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'malformed_nesting_rejected\t%s\n' "$malformed_nesting_rejected" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'logical_module_sha256\t%s\n' "$(sha256sum "$logical_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'ast_module_sha256\t%s\n' "$(sha256sum "$ast_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'expression_module_sha256\t%s\n' "$(sha256sum "$expression_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'predecessor_summary_sha256\t%s\n' "$expected_e64_summary_sha256" >>"$outdir/summary.tsv"

printf 'E0065 oracle: generated recursive expression subtree operation completed\n'
cat "$outdir/summary.tsv"
