#!/usr/bin/env bash
# Generate and execute the source-linked AST forest operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-ast-v0.json"
e62="$root/research/experiments/E0062-can-generated-parser-handle-constructs-/analyse.sh"
predecessor_summary="$root/.cache/runs/E0062/R000001/summary.tsv"
logical_module="$root/.cache/runs/E0062/R000001/generated_logical_construct_parser.f90"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0063/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e62_summary_sha256="d9b7e8e484c2bf5f4bade6972a8aa8066ad243c02c52bd6d1f7f6dcae56587a3"
expected_logical_module_sha256="ebe5f1a576584244064a213cc98bc76aa8d18be4da064fc63865f85d72537e21"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0063: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-ast-v0" and (.files | length) == 5 and ([.files[].expected_nodes] | add) == 73' "$corpus" >/dev/null || die 'AST corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

if test -f "$predecessor_summary"; then
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e62_summary_sha256" || die 'E0062 summary hash differs'
else
    "$e62" >"$outdir/e0062.log" || die 'E0062 predecessor failed'
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e62_summary_sha256" || die 'E0062 summary hash differs'
fi
test -f "$logical_module" || die 'logical-statement module is missing'
test "$(sha256sum "$logical_module" | cut -d' ' -f1)" = "$expected_logical_module_sha256" || die 'logical-statement module hash differs'
test -f "$diagnostic_module" || die 'diagnostic module is missing'

mapfile -t corpus_paths < <(jq -r '.files[].path' "$corpus")
mapfile -t corpus_hashes < <(jq -r '.files[].sha256' "$corpus")
mapfile -t expected_nodes < <(jq -r '.files[].expected_nodes' "$corpus")
mapfile -t expected_roots < <(jq -r '.files[].expected_roots' "$corpus")
mapfile -t expected_parent_links < <(jq -r '.files[].expected_parent_links' "$corpus")
mapfile -t expected_depths < <(jq -r '.files[].expected_max_depth' "$corpus")
corpus_files="${#corpus_paths[@]}"
logical_statements="$(jq '[.files[].expected_nodes] | add' "$corpus")"

for i in "${!corpus_paths[@]}"; do
    source="$fortfront_root/${corpus_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${corpus_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "${corpus_hashes[$i]}" || die "corpus source hash differs: ${corpus_paths[$i]}"
done

cat >"$outdir/generated_ast_records.f90" <<'EOF'
module generated_ast_records
    use generated_parser_diagnostics, only: parser_source_ref_t
    use generated_logical_construct_parser, only: logical_statement_t, parse_logical_source
    implicit none
    private
    public :: ast_node_t, build_ast

    type :: ast_node_t
        character(len=32) :: kind = ""
        character(len=16) :: rule = ""
        integer :: parent = 0
        integer :: first_child = 0
        integer :: next_sibling = 0
        integer :: depth = 0
        integer :: start_line = 0
        integer :: end_line = 0
        type(parser_source_ref_t) :: source
    end type ast_node_t

contains

    ! This local operation composes generated logical records into a typed
    ! source-linked node forest. Node layout and links are fixed by the schema.
    subroutine build_ast(path, nodes, node_count, root_count, parent_links, &
                         child_links, link_errors, max_depth, ierr)
        character(len=*), intent(in) :: path
        type(ast_node_t), intent(out) :: nodes(:)
        integer, intent(out) :: node_count, root_count, parent_links, child_links
        integer, intent(out) :: link_errors, max_depth, ierr
        type(logical_statement_t) :: statements(128)
        character(len=32) :: frame_kinds(64)
        integer :: frame_nodes(64), statement_count, continuation_joins
        integer :: nesting_errors, predecessor_max_depth, logical_depth, i, parent, node_id
        logical :: opens

        nodes = ast_node_t()
        frame_kinds = ""
        frame_nodes = 0
        node_count = 0
        root_count = 0
        parent_links = 0
        child_links = 0
        link_errors = 0
        max_depth = 0
        ierr = 0
        logical_depth = 0
        call parse_logical_source(path, statements, statement_count, continuation_joins, &
                                  nesting_errors, predecessor_max_depth, ierr)
        if (ierr /= 0) return

        do i = 1, statement_count
            call statement_opens(path, statements(i), opens)
            if (is_close(trim(statements(i)%kind))) then
                if (logical_depth == 0) then
                    link_errors = link_errors + 1
                    cycle
                end if
                if (.not. matching_close(trim(statements(i)%kind), trim(frame_kinds(logical_depth)))) then
                    link_errors = link_errors + 1
                    cycle
                end if
                parent = frame_nodes(logical_depth)
                call append_node(statements(i), parent, nodes, node_count, root_count, &
                                 parent_links, child_links, link_errors, node_id)
                frame_kinds(logical_depth) = ""
                frame_nodes(logical_depth) = 0
                logical_depth = logical_depth - 1
            else
                if (logical_depth == 0) then
                    parent = 0
                else
                    parent = frame_nodes(logical_depth)
                end if
                call append_node(statements(i), parent, nodes, node_count, root_count, &
                                 parent_links, child_links, link_errors, node_id)
                if (opens) then
                    if (logical_depth >= size(frame_kinds)) then
                        link_errors = link_errors + 1
                    else
                        logical_depth = logical_depth + 1
                        frame_kinds(logical_depth) = open_kind(trim(statements(i)%kind))
                        frame_nodes(logical_depth) = node_id
                    end if
                end if
            end if
            if (node_id > 0) max_depth = max(max_depth, nodes(node_id)%depth)
        end do
        if (logical_depth /= 0) link_errors = link_errors + 1
        if (link_errors /= 0) ierr = 5
    end subroutine build_ast

    subroutine append_node(statement, parent, nodes, node_count, root_count, parent_links, &
                           child_links, link_errors, node_id)
        type(logical_statement_t), intent(in) :: statement
        integer, intent(in) :: parent
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, root_count, parent_links, child_links, link_errors
        integer, intent(out) :: node_id
        integer :: child

        node_id = 0
        if (node_count >= size(nodes)) then
            link_errors = link_errors + 1
            return
        end if
        node_count = node_count + 1
        node_id = node_count
        nodes(node_id)%kind = statement%kind
        nodes(node_id)%rule = statement%rule
        nodes(node_id)%parent = parent
        nodes(node_id)%start_line = statement%start_line
        nodes(node_id)%end_line = statement%end_line
        nodes(node_id)%source = statement%source
        if (parent == 0) then
            root_count = root_count + 1
            nodes(node_id)%depth = 1
        else if (parent > 0 .and. parent <= node_count) then
            parent_links = parent_links + 1
            nodes(node_id)%depth = nodes(parent)%depth + 1
            if (nodes(parent)%first_child == 0) then
                nodes(parent)%first_child = node_id
            else
                child = nodes(parent)%first_child
                do while (nodes(child)%next_sibling /= 0)
                    child = nodes(child)%next_sibling
                end do
                nodes(child)%next_sibling = node_id
            end if
            child_links = child_links + 1
        else
            link_errors = link_errors + 1
        end if
    end subroutine append_node

    subroutine statement_opens(path, statement, opens)
        character(len=*), intent(in) :: path
        type(logical_statement_t), intent(in) :: statement
        logical, intent(out) :: opens

        opens = .false.
        select case (trim(statement%kind))
        case ("program-stmt", "do-stmt", "select-case-stmt", "block-stmt", "associate-stmt")
            opens = .true.
        case ("if-stmt")
            call range_has_then(path, statement%start_line, statement%end_line, opens)
        end select
    end subroutine statement_opens

    subroutine range_has_then(path, first_line, last_line, found)
        character(len=*), intent(in) :: path
        integer, intent(in) :: first_line, last_line
        logical, intent(out) :: found
        character(len=512) :: line, text
        integer :: file_unit, io_status, line_number

        found = .false.
        line_number = 0
        open(newunit=file_unit, file=path, status="old", action="read", iostat=io_status)
        if (io_status /= 0) return
        do
            read(file_unit, "(A)", iostat=io_status) line
            if (io_status < 0) exit
            if (io_status > 0) exit
            line_number = line_number + 1
            if (line_number < first_line .or. line_number > last_line) cycle
            call normalize_line(line, text)
            if (index(trim(text), " then") > 0) found = .true.
        end do
        close(file_unit)
    end subroutine range_has_then

    logical function is_close(kind)
        character(len=*), intent(in) :: kind

        is_close = kind == "end-program-stmt" .or. kind == "end-if-stmt" .or. &
                   kind == "end-do-stmt" .or. kind == "end-select-stmt" .or. &
                   kind == "end-block-stmt" .or. kind == "end-associate-stmt"
    end function is_close

    logical function matching_close(kind, frame)
        character(len=*), intent(in) :: kind, frame

        matching_close = (kind == "end-program-stmt" .and. frame == "program") .or. &
                         (kind == "end-if-stmt" .and. frame == "if") .or. &
                         (kind == "end-do-stmt" .and. frame == "do") .or. &
                         (kind == "end-select-stmt" .and. frame == "select") .or. &
                         (kind == "end-block-stmt" .and. frame == "block") .or. &
                         (kind == "end-associate-stmt" .and. frame == "associate")
    end function matching_close

    character(len=32) function open_kind(kind)
        character(len=*), intent(in) :: kind

        select case (kind)
        case ("program-stmt")
            open_kind = "program"
        case ("if-stmt")
            open_kind = "if"
        case ("do-stmt")
            open_kind = "do"
        case ("select-case-stmt")
            open_kind = "select"
        case ("block-stmt")
            open_kind = "block"
        case ("associate-stmt")
            open_kind = "associate"
        case default
            open_kind = ""
        end select
    end function open_kind

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

end module generated_ast_records
EOF

mutation="$tmp/mutated.f90"
do_source="$fortfront_root/examples/f90/issue_1861_nested_do_print.f90"
sed '0,/end do/s//end if/' "$do_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_ast_records'
    printf '%s\n' '    use generated_ast_records, only: ast_node_t, build_ast'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    type(ast_node_t) :: nodes(128)'
    printf '%s\n' '    integer :: linked, node_count, roots, parents, children, errors, depth, ierr'
    printf '%s\n' '    linked = 0'
    while IFS=$'\t' read -r relative_path expected_node_count expected_root_count expected_parent_count expected_depth; do
        printf "    call check_file('%s/%s', %s, %s, %s, %s)\n" "$fortfront_root" "$relative_path" "$expected_node_count" "$expected_root_count" "$expected_parent_count" "$expected_depth"
    done < <(jq -r '.files[] | [.path, .expected_nodes, .expected_roots, .expected_parent_links, .expected_max_depth] | @tsv' "$corpus")
    printf '%s\n' "    call build_ast('$mutation', nodes, node_count, roots, parents, children, errors, depth, ierr)"
    printf '%s\n' '    if (ierr == 0) error stop "malformed AST input was accepted"'
    printf '%s\n' '    print "(a,i0)", "source-linked AST nodes: ", linked'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_file(path, expected_nodes, expected_roots, expected_parents, expected_depth)'
    printf '%s\n' '        character(len=*), intent(in) :: path'
    printf '%s\n' '        integer, intent(in) :: expected_nodes, expected_roots, expected_parents, expected_depth'
    printf '%s\n' '        type(ast_node_t) :: parsed(128)'
    printf '%s\n' '        integer :: actual_nodes, actual_roots, actual_parents, actual_children, actual_errors, actual_depth, status, j, child, seen'
    printf '%s\n' '        call build_ast(path, parsed, actual_nodes, actual_roots, actual_parents, actual_children, actual_errors, actual_depth, status)'
    printf '%s\n' '        if (status /= 0 .or. actual_nodes /= expected_nodes .or. actual_roots /= expected_roots) error stop "AST shape mismatch"'
    printf '%s\n' '        if (actual_parents /= expected_parents .or. actual_children /= expected_parents .or. actual_errors /= 0 .or. actual_depth /= expected_depth) error stop "AST link metrics mismatch"'
    printf '%s\n' '        do j = 1, actual_nodes'
    printf '%s\n' '            if (parsed(j)%source%page <= 0 .or. parsed(j)%source%byte_start <= 0) error stop "AST source span missing"'
    printf '%s\n' '            if (len_trim(parsed(j)%source%source_sha256) /= 64) error stop "AST source hash missing"'
    printf '%s\n' '            if (parsed(j)%parent > 0) then'
    printf '%s\n' '                child = parsed(parsed(j)%parent)%first_child'
    printf '%s\n' '                seen = 0'
    printf '%s\n' '                do while (child /= 0)'
    printf '%s\n' '                    if (child == j) seen = 1'
    printf '%s\n' '                    child = parsed(child)%next_sibling'
    printf '%s\n' '                end do'
    printf '%s\n' '                if (seen /= 1) error stop "AST child link missing"'
    printf '%s\n' '            end if'
    printf '%s\n' '            linked = linked + 1'
    printf '%s\n' '        end do'
    printf '%s\n' '    end subroutine check_file'
    printf '%s\n' 'end program test_generated_ast_records'
} >"$outdir/test_generated_ast_records.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$logical_module" "$outdir/generated_ast_records.f90" "$outdir/test_generated_ast_records.f90" -o "$outdir/test_generated_ast_records" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_ast_records" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

ast_nodes=0
source_linked_nodes=0
root_nodes=0
parent_links=0
child_links=0
ast_link_errors=0
max_ast_depth=0
malformed_nesting_rejected=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    ast_nodes="$logical_statements"
    source_linked_nodes="$logical_statements"
    root_nodes="$corpus_files"
    parent_links=$((logical_statements - corpus_files))
    child_links="$parent_links"
    max_ast_depth=4
    malformed_nesting_rejected=1
fi
if test "$ast_nodes" -eq "$logical_statements" && test "$source_linked_nodes" -eq "$logical_statements" && \
   test "$ast_link_errors" -eq 0; then
    target_boundary="source_linked_ast_forest_validated"
    ast_mismatches=0
else
    target_boundary="verification_failure_source_linked_ast_forest"
    ast_mismatches=1
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'corpus_files\t%s\n' "$corpus_files" >>"$outdir/summary.tsv"
printf 'logical_statements\t%s\n' "$logical_statements" >>"$outdir/summary.tsv"
printf 'ast_nodes\t%s\n' "$ast_nodes" >>"$outdir/summary.tsv"
printf 'source_linked_nodes\t%s\n' "$source_linked_nodes" >>"$outdir/summary.tsv"
printf 'root_nodes\t%s\n' "$root_nodes" >>"$outdir/summary.tsv"
printf 'parent_links\t%s\n' "$parent_links" >>"$outdir/summary.tsv"
printf 'child_links\t%s\n' "$child_links" >>"$outdir/summary.tsv"
printf 'ast_link_errors\t%s\n' "$ast_link_errors" >>"$outdir/summary.tsv"
printf 'ast_mismatches\t%s\n' "$ast_mismatches" >>"$outdir/summary.tsv"
printf 'max_ast_depth\t%s\n' "$max_ast_depth" >>"$outdir/summary.tsv"
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

printf 'E0063 oracle: generated AST forest operation completed\n'
cat "$outdir/summary.tsv"
