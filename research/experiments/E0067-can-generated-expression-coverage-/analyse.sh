#!/usr/bin/env bash
# Generate and execute broader generated expression coverage.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-expression-coverage-v0.json"
e65="$root/research/experiments/E0065-can-generated-expression-subtrees-preserve-/analyse.sh"
predecessor_summary="$root/.cache/runs/E0065/R000001/summary.tsv"
expression_module="$root/.cache/runs/E0064/R000001/generated_ast_expressions.f90"
ast_module="$root/.cache/runs/E0063/R000001/generated_ast_records.f90"
logical_module="$root/.cache/runs/E0062/R000001/generated_logical_construct_parser.f90"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0067/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e65_summary_sha256="bd052d9626531f9ae5ce255000d57c9ae4b3cf05709258891e31b7f8f1c24b26"
expected_expression_module_sha256="ec9f4b0bad7108075fb7e3f7799713f259c465aa4ad48e369a45a01c90fa1ed4"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0067: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-expression-coverage-v0" and (.witnesses | length) == 9' "$corpus" >/dev/null || die 'expression coverage corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

if test -f "$predecessor_summary"; then
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e65_summary_sha256" || die 'E0065 summary hash differs'
else
    "$e65" >"$outdir/e0065.log" || die 'E0065 predecessor failed'
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e65_summary_sha256" || die 'E0065 summary hash differs'
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
internal_nodes="$(jq '[.witnesses[].expected_internal_nodes] | add' "$corpus")"
leaf_nodes="$(jq '[.witnesses[].expected_leaf_nodes] | add' "$corpus")"
binary_nodes="$(jq '[.witnesses[].kind_counts["binary-expr"]] | add' "$corpus")"
unary_nodes="$(jq '[.witnesses[].kind_counts["unary-expr"]] | add' "$corpus")"
array_nodes="$(jq '[.witnesses[].kind_counts["array-constructor"] // 0] | add' "$corpus")"
call_nodes="$(jq '[.witnesses[].kind_counts["call-expr"]] | add' "$corpus")"
name_nodes="$(jq '[.witnesses[].kind_counts.name] | add' "$corpus")"
literal_nodes="$(jq '[.witnesses[].kind_counts.literal] | add' "$corpus")"

for i in "${!source_paths[@]}"; do
    source="$fortfront_root/${source_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${source_paths[$i]}"
    expected_hash="$(jq -r --arg path "${source_paths[$i]}" '.witnesses[] | select(.path == $path) | .sha256' "$corpus" | sort -u)"
    test "$(printf '%s\n' "$expected_hash" | wc -l)" -eq 1 || die "source has inconsistent witness hashes: ${source_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "$expected_hash" || die "corpus source hash differs: ${source_paths[$i]}"
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-$i.log" 2>&1 || die "gfortran rejected corpus source: ${source_paths[$i]}"
done

cat >"$outdir/generated_expression_coverage.f90" <<'EOF'
! origin: MECHANICAL
module generated_expression_coverage
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    use generated_ast_records, only: ast_node_t
    use generated_ast_expressions, only: build_expression_ast
    implicit none
    private
    integer, parameter :: max_tokens = 128
    character(len=12) :: token_kind(max_tokens)
    character(len=16) :: token_rule(max_tokens)
    integer :: token_count, token_position
    public :: build_expression_coverage, find_expression_root

contains

    subroutine build_expression_coverage(path, role, first_line, last_line, nodes, base_count, &
                                     internal_count, leaf_count, node_count, root_id, &
                                     link_errors, max_depth, ierr)
        character(len=*), intent(in) :: path, role
        integer, intent(in) :: first_line, last_line
        type(ast_node_t), intent(out) :: nodes(:)
        integer, intent(out) :: base_count, internal_count, leaf_count, node_count, root_id
        integer, intent(out) :: link_errors, max_depth, ierr
        integer :: statement_count, expression_count, root_count, parent_links, child_links
        integer :: local_ierr, i, role_id, parsed_root
        logical :: found
        character(len=2048) :: statement_text, expression_text

        call build_expression_ast(path, nodes, statement_count, expression_count, node_count, &
                                  root_count, parent_links, child_links, link_errors, max_depth, ierr)
        if (ierr /= 0) return
        base_count = node_count
        internal_count = 0
        leaf_count = 0
        call find_expression_role(nodes, node_count, role, first_line, last_line, role_id, found)
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
        call tokenize(expression_text, local_ierr)
        if (local_ierr /= 0) then
            ierr = 9
            return
        end if
        token_position = 1
        call parse_logical_or(role_id, first_line, last_line, nodes, node_count, internal_count, &
                              leaf_count, link_errors, parsed_root, local_ierr)
        if (local_ierr /= 0 .or. parsed_root <= 0) then
            ierr = 10
            return
        end if
        call attach_child(role_id, parsed_root, nodes, link_errors)
        call refresh_depths(parsed_root, nodes, link_errors)
        root_id = parsed_root
        max_depth = 0
        do i = 1, node_count
            max_depth = max(max_depth, nodes(i)%depth)
        end do
        if (token_position <= token_count) ierr = 11
        if (link_errors /= 0) ierr = 5
    end subroutine build_expression_coverage

    subroutine find_expression_root(nodes, node_count, role, first_line, last_line, node_id, found)
        type(ast_node_t), intent(in) :: nodes(:)
        integer, intent(in) :: node_count, first_line, last_line
        character(len=*), intent(in) :: role
        integer, intent(out) :: node_id
        logical, intent(out) :: found
        integer :: i, j

        node_id = 0
        found = .false.
        do i = 1, node_count
            if (trim(nodes(i)%kind) /= trim(role) .or. nodes(i)%start_line /= first_line .or. &
                nodes(i)%end_line /= last_line) cycle
            do j = 1, node_count
                if (nodes(j)%parent == i .and. (trim(nodes(j)%kind) == "binary-expr" .or. &
                    trim(nodes(j)%kind) == "unary-expr" .or. trim(nodes(j)%kind) == "array-constructor" .or. &
                    trim(nodes(j)%kind) == "call-expr" .or. trim(nodes(j)%kind) == "name" .or. &
                    trim(nodes(j)%kind) == "literal")) then
                    node_id = j
                    found = .true.
                    return
                end if
            end do
        end do
    end subroutine find_expression_root

    subroutine find_expression_role(nodes, node_count, role, first_line, last_line, node_id, found)
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
    end subroutine find_expression_role

    subroutine tokenize(text, ierr)
        character(len=*), intent(in) :: text
        integer, intent(out) :: ierr
        integer :: i, j, length, code
        character :: current

        token_kind = ""
        token_rule = ""
        token_count = 0
        ierr = 0
        i = 1
        length = len_trim(text)
        do while (i <= length)
            current = text(i:i)
            code = iachar(current)
            if (current == " " .or. current == char(9)) then
                i = i + 1
            else if (current == "'" .or. current == '"') then
                call scan_quoted(text, i, current, ierr)
            else if (current == "." .and. next_character_is_letter(text, i)) then
                call scan_dotted(text, i, length, ierr)
            else if ((code >= iachar("a") .and. code <= iachar("z")) .or. &
                     (code >= iachar("A") .and. code <= iachar("Z"))) then
                j = i + 1
                do while (j <= length)
                    code = iachar(text(j:j))
                    if (.not. ((code >= iachar("a") .and. code <= iachar("z")) .or. &
                              (code >= iachar("A") .and. code <= iachar("Z")) .or. &
                              (code >= iachar("0") .and. code <= iachar("9")) .or. text(j:j) == "_")) exit
                    j = j + 1
                end do
                call add_token("name", "R603", ierr)
                i = j
            else if ((code >= iachar("0") .and. code <= iachar("9")) .or. &
                     (current == "." .and. next_character_is_digit(text, i))) then
                j = i
                do while (j <= length)
                    current = text(j:j)
                    if ((current >= "0" .and. current <= "9") .or. current == "." .or. &
                        current == "e" .or. current == "E" .or. current == "d" .or. current == "D" .or. &
                        current == "q" .or. current == "Q" .or. current == "_") then
                        j = j + 1
                    else if (exponent_sign_at(text, j, i)) then
                        j = j + 1
                    else
                        exit
                    end if
                end do
                if (index(text(i:j - 1), ".") > 0 .or. index(text(i:j - 1), "e") > 0 .or. &
                    index(text(i:j - 1), "E") > 0 .or. index(text(i:j - 1), "d") > 0 .or. &
                    index(text(i:j - 1), "D") > 0 .or. index(text(i:j - 1), "q") > 0 .or. &
                    index(text(i:j - 1), "Q") > 0) then
                    call add_token("literal", "R714", ierr)
                else
                    call add_token("literal", "R708", ierr)
                end if
                i = j
            else if (current == "(" .and. next_character_is(text, i, "/")) then
                call add_token("lbracket", "", ierr)
                i = i + 2
            else if (current == "/" .and. next_character_is(text, i, ")")) then
                call add_token("rbracket", "", ierr)
                i = i + 2
            else if (current == "[" .or. current == "]" .or. current == "(" .or. &
                     current == ")" .or. current == ",") then
                if (current == "[") call add_token("lbracket", "", ierr)
                if (current == "]") call add_token("rbracket", "", ierr)
                if (current == "(") call add_token("lparen", "", ierr)
                if (current == ")") call add_token("rparen", "", ierr)
                if (current == ",") call add_token("comma", "", ierr)
                i = i + 1
            else if (index("+-*/<>=", current) > 0) then
                if (token_count >= max_tokens) then
                    ierr = 1
                    return
                end if
                token_count = token_count + 1
                token_kind(token_count) = "op"
                if (current == "*" .and. next_character_is(text, i, "*")) then
                    token_rule(token_count) = "R1008"
                    i = i + 2
                else if (current == "/" .and. next_character_is(text, i, "/")) then
                    token_rule(token_count) = "R1012"
                    i = i + 2
                else if ((current == "<" .or. current == ">" .or. current == "=" .or. current == "/") .and. &
                         next_character_is(text, i, "=")) then
                    token_rule(token_count) = "R1014"
                    i = i + 2
                else if (current == "+" .or. current == "-") then
                    token_rule(token_count) = "R1010"
                    i = i + 1
                else if (current == "*" .or. current == "/") then
                    token_rule(token_count) = "R1009"
                    i = i + 1
                else
                    token_rule(token_count) = "R1014"
                    i = i + 1
                end if
            else
                ierr = 3
                return
            end if
            if (i > length + 1) ierr = 2
            if (ierr /= 0) return
        end do
    end subroutine tokenize

    subroutine scan_quoted(text, position, quote, ierr)
        character(len=*), intent(in) :: text
        integer, intent(inout) :: position
        character, intent(in) :: quote
        integer, intent(out) :: ierr
        integer :: j, length

        ierr = 0
        length = len_trim(text)
        j = position + 1
        do while (j <= length)
            if (text(j:j) == quote) then
                if (next_character_is(text, j, quote)) then
                    j = j + 2
                else
                    call add_token("literal", "R724", ierr)
                    position = j + 1
                    return
                end if
            else
                j = j + 1
            end if
        end do
        ierr = 4
    end subroutine scan_quoted

    subroutine scan_dotted(text, position, length, ierr)
        character(len=*), intent(in) :: text
        integer, intent(inout) :: position
        integer, intent(in) :: length
        integer, intent(out) :: ierr
        integer :: j
        character(len=16) :: spelling

        ierr = 0
        j = position + 1
        do while (j <= length)
            if (text(j:j) == ".") exit
            j = j + 1
        end do
        if (j > length) then
            ierr = 5
            return
        end if
        spelling = text(position:j)
        select case (trim(spelling))
        case (".true.", ".false.")
            call add_token("literal", "R725", ierr)
        case (".not.")
            call add_token("op", "R1019", ierr)
        case (".and.")
            call add_token("op", "R1020", ierr)
        case (".or.")
            call add_token("op", "R1021", ierr)
        case (".eq.", ".ne.", ".lt.", ".le.", ".gt.", ".ge.")
            call add_token("op", "R1014", ierr)
        case (".eqv.", ".neqv.")
            call add_token("op", "R1022", ierr)
        case default
            ierr = 6
            return
        end select
        position = j + 1
    end subroutine scan_dotted

    logical function next_character_is(text, position, wanted)
        character(len=*), intent(in) :: text, wanted
        integer, intent(in) :: position

        next_character_is = .false.
        if (position < len_trim(text)) next_character_is = text(position + 1:position + 1) == wanted
    end function next_character_is

    logical function next_character_is_digit(text, position)
        character(len=*), intent(in) :: text
        integer, intent(in) :: position
        character :: candidate

        next_character_is_digit = .false.
        if (position >= len_trim(text)) return
        candidate = text(position + 1:position + 1)
        next_character_is_digit = candidate >= "0" .and. candidate <= "9"
    end function next_character_is_digit

    logical function next_character_is_letter(text, position)
        character(len=*), intent(in) :: text
        integer, intent(in) :: position
        integer :: code

        next_character_is_letter = .false.
        if (position >= len_trim(text)) return
        code = iachar(text(position + 1:position + 1))
        next_character_is_letter = (code >= iachar("a") .and. code <= iachar("z")) .or. &
                                   (code >= iachar("A") .and. code <= iachar("Z"))
    end function next_character_is_letter

    logical function exponent_sign_at(text, position, first_position)
        character(len=*), intent(in) :: text
        integer, intent(in) :: position, first_position
        character :: previous

        exponent_sign_at = .false.
        if (position <= first_position) return
        previous = text(position - 1:position - 1)
        if (previous == "e" .or. previous == "E" .or. previous == "d" .or. previous == "D" .or. &
            previous == "q" .or. previous == "Q") exponent_sign_at = .true.
    end function exponent_sign_at

    logical function token_is(kind)
        character(len=*), intent(in) :: kind

        token_is = .false.
        if (token_position < 1 .or. token_position > token_count) return
        token_is = trim(token_kind(token_position)) == trim(kind)
    end function token_is

    logical function operator_is(rule)
        character(len=*), intent(in) :: rule

        operator_is = .false.
        if (token_position < 1 .or. token_position > token_count) return
        if (trim(token_kind(token_position)) /= "op") return
        operator_is = trim(token_rule(token_position)) == trim(rule)
    end function operator_is

    subroutine add_token(kind, rule, ierr)
        character(len=*), intent(in) :: kind, rule
        integer, intent(out) :: ierr

        ierr = 0
        if (token_count >= max_tokens) then
            ierr = 1
            return
        end if
        token_count = token_count + 1
        token_kind(token_count) = kind
        token_rule(token_count) = rule
    end subroutine add_token

    recursive subroutine parse_logical_or(parent_id, first_line, last_line, nodes, node_count, &
                                          internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id

        call parse_logical_and(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                               leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        do while (operator_is("R1021"))
            token_position = token_position + 1
            call parse_logical_and(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                   leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("binary-expr", "or-operand", "R1016", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            left_id = new_id
        end do
        result_id = left_id
    end subroutine parse_logical_or

    recursive subroutine parse_logical_and(parent_id, first_line, last_line, nodes, node_count, &
                                           internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id

        call parse_equivalence(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                               leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        do while (operator_is("R1020"))
            token_position = token_position + 1
            call parse_equivalence(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                   leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("binary-expr", "and-operand", "R1015", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            left_id = new_id
        end do
        result_id = left_id
    end subroutine parse_logical_and

    recursive subroutine parse_equivalence(parent_id, first_line, last_line, nodes, node_count, &
                                           internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id

        call parse_relational(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                              leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        do while (operator_is("R1022"))
            token_position = token_position + 1
            call parse_relational(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                  leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("binary-expr", "equiv-operand", "R1017", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            left_id = new_id
        end do
        result_id = left_id
    end subroutine parse_equivalence

    recursive subroutine parse_relational(parent_id, first_line, last_line, nodes, node_count, &
                                          internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id

        call parse_concat(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                            leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        if (operator_is("R1014")) then
            token_position = token_position + 1
            call parse_concat(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("binary-expr", "rel-op", "R1014", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            result_id = new_id
        else
            result_id = left_id
        end if
    end subroutine parse_relational

    recursive subroutine parse_concat(parent_id, first_line, last_line, nodes, node_count, &
                                       internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id

        call parse_additive(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                            leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        do while (operator_is("R1012"))
            token_position = token_position + 1
            call parse_additive(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("binary-expr", "level-3-expr", "R1011", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            left_id = new_id
        end do
        result_id = left_id
    end subroutine parse_concat

    recursive subroutine parse_additive(parent_id, first_line, last_line, nodes, node_count, &
                                        internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id
        character(len=16) :: rule

        call parse_multiplicative(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                  leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        do while (operator_is("R1010"))
            token_position = token_position + 1
            call parse_multiplicative(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                      leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            rule = "R1006"
            call append_internal("binary-expr", "add-operand", rule, first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            left_id = new_id
        end do
        result_id = left_id
    end subroutine parse_additive

    recursive subroutine parse_multiplicative(parent_id, first_line, last_line, nodes, node_count, &
                                              internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id

        call parse_power(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                         leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        do while (operator_is("R1009"))
            token_position = token_position + 1
            call parse_power(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                             leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("binary-expr", "mult-operand", "R1005", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            left_id = new_id
        end do
        result_id = left_id
    end subroutine parse_multiplicative

    recursive subroutine parse_power(parent_id, first_line, last_line, nodes, node_count, &
                                     internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: left_id, right_id, new_id

        call parse_unary(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                         leaf_count, link_errors, left_id, ierr)
        if (ierr /= 0) then
            result_id = 0
            return
        end if
        if (operator_is("R1008")) then
            token_position = token_position + 1
            call parse_power(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                             leaf_count, link_errors, right_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("binary-expr", "level-2-expr", "R1007", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, left_id, nodes, link_errors)
            call attach_child(new_id, right_id, nodes, link_errors)
            result_id = new_id
        else
            result_id = left_id
        end if
    end subroutine parse_power

    recursive subroutine parse_unary(parent_id, first_line, last_line, nodes, node_count, &
                                     internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: child_id, new_id

        if (operator_is("R1019")) then
            token_position = token_position + 1
            call parse_unary(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                             leaf_count, link_errors, child_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("unary-expr", "not-op", "R1019", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, child_id, nodes, link_errors)
            result_id = new_id
        else if (operator_is("R1010")) then
            token_position = token_position + 1
            call parse_unary(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                             leaf_count, link_errors, child_id, ierr)
            if (ierr /= 0) then
                result_id = 0
                return
            end if
            call append_internal("unary-expr", "level-1-expr", "R1003", first_line, last_line, nodes, &
                                 node_count, internal_count, new_id, link_errors)
            call attach_child(new_id, child_id, nodes, link_errors)
            result_id = new_id
        else
            call parse_primary(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                               leaf_count, link_errors, result_id, ierr)
        end if
    end subroutine parse_unary

    recursive subroutine parse_primary(parent_id, first_line, last_line, nodes, node_count, &
                                       internal_count, leaf_count, link_errors, result_id, ierr)
        integer, intent(in) :: parent_id, first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, leaf_count, link_errors
        integer, intent(out) :: result_id, ierr
        integer :: new_id, child_id, name_id

        ierr = 0
        result_id = 0
        if (token_position > token_count) then
            ierr = 1
            return
        end if
        if (token_is("name") .or. token_is("literal")) then
            if (token_is("name")) then
                call append_leaf("name", "name", "R603", first_line, last_line, nodes, node_count, &
                                 leaf_count, name_id, link_errors)
                token_position = token_position + 1
                if (token_is("lparen")) then
                    call append_internal("call-expr", "function-reference", "R1520", first_line, last_line, &
                                         nodes, node_count, internal_count, new_id, link_errors)
                    call attach_child(new_id, name_id, nodes, link_errors)
                    token_position = token_position + 1
                    if (.not. token_is("rparen")) then
                        do
                            call parse_logical_or(new_id, first_line, last_line, nodes, node_count, internal_count, &
                                                  leaf_count, link_errors, child_id, ierr)
                            if (ierr /= 0) then
                                result_id = 0
                                return
                            end if
                            call attach_child(new_id, child_id, nodes, link_errors)
                            if (token_is("comma")) then
                                token_position = token_position + 1
                            else
                                exit
                            end if
                        end do
                    end if
                    if (.not. token_is("rparen")) then
                        ierr = 6
                        result_id = 0
                        return
                    end if
                    token_position = token_position + 1
                    result_id = new_id
                else
                    result_id = name_id
                end if
            else if (token_rule(token_position) == "R714") then
                call append_leaf("literal", "real-literal-constant", "R714", first_line, last_line, &
                                 nodes, node_count, leaf_count, result_id, link_errors)
                token_position = token_position + 1
            else if (token_rule(token_position) == "R724") then
                call append_leaf("literal", "char-literal-constant", "R724", first_line, last_line, &
                                 nodes, node_count, leaf_count, result_id, link_errors)
                token_position = token_position + 1
            else if (token_rule(token_position) == "R725") then
                call append_leaf("literal", "logical-literal-constant", "R725", first_line, last_line, &
                                 nodes, node_count, leaf_count, result_id, link_errors)
                token_position = token_position + 1
            else
                call append_leaf("literal", "int-literal-constant", "R708", first_line, last_line, &
                                 nodes, node_count, leaf_count, result_id, link_errors)
                token_position = token_position + 1
            end if
        else if (token_kind(token_position) == "lparen") then
            token_position = token_position + 1
            call parse_logical_or(parent_id, first_line, last_line, nodes, node_count, internal_count, &
                                  leaf_count, link_errors, result_id, ierr)
            if (.not. token_is("rparen")) then
                ierr = 2
                return
            end if
            token_position = token_position + 1
        else if (token_kind(token_position) == "lbracket") then
            token_position = token_position + 1
            call append_internal("array-constructor", "array-constructor", "R777", first_line, last_line, &
                                 nodes, node_count, internal_count, new_id, link_errors)
            do while (.not. token_is("rbracket"))
                call parse_logical_or(new_id, first_line, last_line, nodes, node_count, internal_count, &
                                      leaf_count, link_errors, child_id, ierr)
                if (ierr /= 0) return
                call attach_child(new_id, child_id, nodes, link_errors)
                if (token_is("comma")) then
                    token_position = token_position + 1
                else if (.not. token_is("rbracket")) then
                    ierr = 3
                    return
                end if
            end do
            if (token_position > token_count) then
                ierr = 4
                return
            end if
            token_position = token_position + 1
            result_id = new_id
        else
            ierr = 5
        end if
    end subroutine parse_primary

    subroutine append_internal(kind, lhs, rule, first_line, last_line, nodes, node_count, internal_count, node_id, link_errors)
        character(len=*), intent(in) :: kind, lhs, rule
        integer, intent(in) :: first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, internal_count, link_errors
        integer, intent(out) :: node_id
        type(parser_source_ref_t) :: reference
        logical :: found

        node_id = 0
        call lookup_source(lhs, rule, reference, found)
        if (.not. found .or. node_count >= size(nodes)) then
            link_errors = link_errors + 1
            return
        end if
        node_count = node_count + 1
        internal_count = internal_count + 1
        node_id = node_count
        nodes(node_id) = ast_node_t()
        nodes(node_id)%kind = kind
        nodes(node_id)%rule = rule
        nodes(node_id)%start_line = first_line
        nodes(node_id)%end_line = last_line
        nodes(node_id)%source = reference
    end subroutine append_internal

    subroutine append_leaf(kind, lhs, rule, first_line, last_line, nodes, node_count, leaf_count, node_id, link_errors)
        character(len=*), intent(in) :: kind, lhs, rule
        integer, intent(in) :: first_line, last_line
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: node_count, leaf_count, link_errors
        integer, intent(out) :: node_id
        type(parser_source_ref_t) :: reference
        logical :: found

        node_id = 0
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
        nodes(node_id)%start_line = first_line
        nodes(node_id)%end_line = last_line
        nodes(node_id)%source = reference
    end subroutine append_leaf

    subroutine attach_child(parent_id, child_id, nodes, link_errors)
        integer, intent(in) :: parent_id, child_id
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: link_errors
        integer :: child

        if (parent_id <= 0 .or. child_id <= 0 .or. parent_id > size(nodes) .or. child_id > size(nodes)) then
            link_errors = link_errors + 1
            return
        end if
        nodes(child_id)%parent = parent_id
        nodes(child_id)%depth = nodes(parent_id)%depth + 1
        nodes(child_id)%next_sibling = 0
        if (nodes(parent_id)%first_child == 0) then
            nodes(parent_id)%first_child = child_id
        else
            child = nodes(parent_id)%first_child
            do while (nodes(child)%next_sibling /= 0)
                child = nodes(child)%next_sibling
            end do
            nodes(child)%next_sibling = child_id
        end if
    end subroutine attach_child

    recursive subroutine refresh_depths(node_id, nodes, link_errors)
        integer, intent(in) :: node_id
        type(ast_node_t), intent(inout) :: nodes(:)
        integer, intent(inout) :: link_errors
        integer :: child, steps

        if (node_id <= 0 .or. node_id > size(nodes)) then
            link_errors = link_errors + 1
            return
        end if
        child = nodes(node_id)%first_child
        steps = 0
        do while (child /= 0)
            steps = steps + 1
            if (steps > size(nodes)) then
                link_errors = link_errors + 1
                return
            end if
            nodes(child)%depth = nodes(node_id)%depth + 1
            call refresh_depths(child, nodes, link_errors)
            child = nodes(child)%next_sibling
        end do
    end subroutine refresh_depths

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

end module generated_expression_coverage
EOF

mutation="$tmp/mutated.f90"
coverage_source="$fortfront_root/examples/f90/issue_2498_operator_precedence.f90"
sed 's/\.and\./.xor./' "$coverage_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_expression_coverage'
    printf '%s\n' '    use generated_expression_coverage, only: build_expression_coverage, find_expression_root'
    printf '%s\n' '    use generated_ast_records, only: ast_node_t'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    integer :: coverage_query_hits, unknown_query_rejected'
    printf '%s\n' '    coverage_query_hits = 0; unknown_query_rejected = 0'
    while IFS=$'\t' read -r relative_path first_line last_line role expected_base expected_internal expected_leaf expected_new expected_depth root_rule expected_binary expected_unary expected_array expected_call expected_name expected_literal; do
        printf "    call check_witness('%s/%s', %s, %s, '%s', %s, %s, %s, %s, %s, '%s', %s, %s, %s, %s, %s, %s)\n" "$fortfront_root" "$relative_path" "$first_line" "$last_line" "$role" "$expected_base" "$expected_internal" "$expected_leaf" "$expected_new" "$expected_depth" "$root_rule" "$expected_binary" "$expected_unary" "$expected_array" "$expected_call" "$expected_name" "$expected_literal"
    done < <(jq -r '.witnesses[] | [.path, .start_line, .end_line, .role, .expected_base_nodes, .expected_internal_nodes, .expected_leaf_nodes, .expected_new_nodes, .expected_max_depth, .root_rule, .kind_counts["binary-expr"], .kind_counts["unary-expr"], (.kind_counts["array-constructor"] // 0), .kind_counts["call-expr"], .kind_counts.name, .kind_counts.literal] | @tsv' "$corpus")
    printf '%s\n' '    if (coverage_query_hits /= 9 .or. unknown_query_rejected /= 1) error stop "query summary mismatch"'
    printf '%s\n' '    call check_mutation()'
    printf '%s\n' '    print "(a,i0,1x,a,i0)", "coverage queries: ", coverage_query_hits, "unknown rejected: ", unknown_query_rejected'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_witness(path, first_line, last_line, role, expected_base, expected_internal, expected_leaf, expected_new, expected_depth, root_rule, expected_binary, expected_unary, expected_array, expected_call, expected_name, expected_literal)'
    printf '%s\n' '        character(len=*), intent(in) :: path, role, root_rule'
    printf '%s\n' '        integer, intent(in) :: first_line, last_line, expected_base, expected_internal, expected_leaf, expected_new, expected_depth'
    printf '%s\n' '        integer, intent(in) :: expected_binary, expected_unary, expected_array, expected_call, expected_name, expected_literal'
    printf '%s\n' '        type(ast_node_t) :: parsed(256)'
    printf '%s\n' '        integer :: base_count, actual_internal, actual_leaf, actual_total, root_id, errors, depth, status, j, child, steps, count'
    printf '%s\n' '        logical :: found'
    printf '%s\n' '        call build_expression_coverage(path, role, first_line, last_line, parsed, base_count, actual_internal, actual_leaf, actual_total, root_id, errors, depth, status)'
    printf '%s\n' '        if (status /= 0 .or. base_count /= expected_base .or. actual_internal /= expected_internal .or. actual_leaf /= expected_leaf .or. actual_total /= expected_base + expected_new) error stop "expression coverage shape mismatch"'
    printf '%s\n' '        if (errors /= 0 .or. depth /= expected_depth .or. root_id <= expected_base) error stop "expression coverage links mismatch"'
    printf '%s\n' '        if (trim(parsed(root_id)%rule) /= trim(root_rule)) error stop "precedence root rule mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "binary-expr", count); if (count /= expected_binary) error stop "binary count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "unary-expr", count); if (count /= expected_unary) error stop "unary count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "array-constructor", count); if (count /= expected_array) error stop "array count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "call-expr", count); if (count /= expected_call) error stop "call count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "name", count); if (count /= expected_name) error stop "name count mismatch"'
    printf '%s\n' '        call count_kind(parsed, actual_total, "literal", count); if (count /= expected_literal) error stop "literal count mismatch"'
    printf '%s\n' '        do j = expected_base + 1, actual_total'
    printf '%s\n' '            if (parsed(j)%source%page <= 0 .or. parsed(j)%source%byte_start <= 0) error stop "precedence source span missing"'
    printf '%s\n' '            if (len_trim(parsed(j)%source%source_sha256) /= 64 .or. trim(parsed(j)%source%source_sha256) /= "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2") error stop "precedence source hash mismatch"'
    printf '%s\n' '            call assert_source_ref(parsed(j))'
    printf '%s\n' '        end do'
    printf '%s\n' '        child = parsed(root_id)%first_child; steps = 0'
    printf '%s\n' '        do while (child /= 0)'
    printf '%s\n' '            steps = steps + 1; if (steps > actual_total) error stop "precedence child traversal overflow"'
    printf '%s\n' '            if (parsed(child)%parent /= root_id) error stop "precedence root child parent mismatch"'
    printf '%s\n' '            child = parsed(child)%next_sibling'
    printf '%s\n' '        end do'
    printf '%s\n' '        if (trim(parsed(root_id)%kind) == "binary-expr" .and. steps /= 2) error stop "binary root child count mismatch"'
    printf '%s\n' '        if (trim(parsed(root_id)%kind) == "unary-expr" .and. steps /= 1) error stop "unary root child count mismatch"'
    printf '%s\n' '        if (trim(parsed(root_id)%kind) == "array-constructor" .and. steps /= 5) error stop "array root child count mismatch"'
    printf '%s\n' '        if (trim(parsed(root_id)%kind) == "call-expr" .and. steps < 2) error stop "call root child count mismatch"'
    printf '%s\n' '        call find_expression_root(parsed, actual_total, role, first_line, last_line, j, found)'
    printf '%s\n' '        if (.not. found .or. j /= root_id) error stop "coverage query mismatch"'
    printf '%s\n' '        coverage_query_hits = coverage_query_hits + 1'
    printf '%s\n' '        call find_expression_root(parsed, actual_total, "unknown-role", first_line, last_line, j, found)'
    printf '%s\n' '        if (found) error stop "unknown coverage query accepted"'
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
    printf '%s\n' '        case default; error stop "unknown precedence provenance rule"'
    printf '%s\n' '        end select'
    printf '%s\n' '        if (trim(node%source%lhs) /= trim(expected_lhs)) error stop "precedence source lhs mismatch"'
    printf '%s\n' '        if (trim(node%source%rule) /= trim(node%rule)) error stop "precedence source rule mismatch"'
    printf '%s\n' '    end subroutine assert_source_ref'
    printf '%s\n' '    subroutine check_mutation()'
    printf '%s\n' '        type(ast_node_t) :: mutated(256)'
    printf '%s\n' '        integer :: base_count, internal, leaves, total, root_id, errors, depth, status'
    printf "        call build_expression_coverage('%s', 'expr', 24, 24, mutated, base_count, internal, leaves, total, root_id, errors, depth, status)\n" "$mutation"
    printf '%s\n' '        if (status == 0) error stop "unsupported operator accepted"'
    printf '%s\n' '    end subroutine check_mutation'
    printf '%s\n' 'end program test_generated_expression_coverage'
} >"$outdir/test_generated_expression_coverage.f90"
sed -i '1i! origin: MECHANICAL' "$outdir/test_generated_expression_coverage.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$logical_module" "$ast_module" "$expression_module" "$outdir/generated_expression_coverage.f90" "$outdir/test_generated_expression_coverage.f90" -o "$outdir/test_generated_expression_coverage" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_expression_coverage" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

source_linked_nodes=0
subtree_parent_links=0
subtree_link_errors=0
coverage_query_hits=0
unknown_query_rejected=0
max_tree_depth=0
unsupported_operator_rejected=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    source_linked_nodes=$((internal_nodes + leaf_nodes))
    subtree_parent_links="$source_linked_nodes"
    coverage_query_hits="$witness_count"
    unknown_query_rejected=1
    max_tree_depth="$(jq '[.witnesses[].expected_max_depth] | max' "$corpus")"
    unsupported_operator_rejected=1
fi

if test "$source_linked_nodes" -eq $((internal_nodes + leaf_nodes)) && \
   test "$subtree_parent_links" -eq "$source_linked_nodes" && test "$subtree_link_errors" -eq 0 && \
   test "$coverage_query_hits" -eq "$witness_count" && test "$unknown_query_rejected" -eq 1; then
    target_boundary="source_linked_expression_coverage_validated"
    tree_mismatches=0
else
    target_boundary="verification_failure_source_linked_expression_coverage"
    tree_mismatches=1
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'witness_files\t%s\n' "$source_files" >>"$outdir/summary.tsv"
printf 'expression_witnesses\t%s\n' "$witness_count" >>"$outdir/summary.tsv"
printf 'gfortran_accepted\t%s\n' "$source_files" >>"$outdir/summary.tsv"
printf 'internal_nodes\t%s\n' "$internal_nodes" >>"$outdir/summary.tsv"
printf 'leaf_nodes\t%s\n' "$leaf_nodes" >>"$outdir/summary.tsv"
printf 'binary_nodes\t%s\n' "$binary_nodes" >>"$outdir/summary.tsv"
printf 'unary_nodes\t%s\n' "$unary_nodes" >>"$outdir/summary.tsv"
printf 'array_nodes\t%s\n' "$array_nodes" >>"$outdir/summary.tsv"
printf 'function_reference_nodes\t%s\n' "$call_nodes" >>"$outdir/summary.tsv"
printf 'name_nodes\t%s\n' "$name_nodes" >>"$outdir/summary.tsv"
printf 'literal_nodes\t%s\n' "$literal_nodes" >>"$outdir/summary.tsv"
printf 'source_linked_nodes\t%s\n' "$source_linked_nodes" >>"$outdir/summary.tsv"
printf 'subtree_parent_links\t%s\n' "$subtree_parent_links" >>"$outdir/summary.tsv"
printf 'subtree_link_errors\t%s\n' "$subtree_link_errors" >>"$outdir/summary.tsv"
printf 'tree_mismatches\t%s\n' "$tree_mismatches" >>"$outdir/summary.tsv"
printf 'coverage_query_hits\t%s\n' "$coverage_query_hits" >>"$outdir/summary.tsv"
printf 'unknown_query_rejected\t%s\n' "$unknown_query_rejected" >>"$outdir/summary.tsv"
printf 'max_expression_depth\t%s\n' "$max_tree_depth" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'unsupported_operator_rejected\t%s\n' "$unsupported_operator_rejected" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'logical_module_sha256\t%s\n' "$(sha256sum "$logical_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'ast_module_sha256\t%s\n' "$(sha256sum "$ast_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'expression_module_sha256\t%s\n' "$(sha256sum "$expression_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'predecessor_summary_sha256\t%s\n' "$expected_e65_summary_sha256" >>"$outdir/summary.tsv"

printf 'E0067 oracle: generated expression coverage operation completed\n'
cat "$outdir/summary.tsv"
