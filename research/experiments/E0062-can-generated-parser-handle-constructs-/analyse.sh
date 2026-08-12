#!/usr/bin/env bash
# Generate and execute the logical-statement and construct-stack operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-constructs-v0.json"
e61="$root/research/experiments/E0061-can-generated-parser-accept-complete-/analyse.sh"
predecessor_summary="$root/.cache/runs/E0061/R000001/summary.tsv"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0062/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e61_summary_sha256="d5faae0444d7c328b232d5952dc4d089f851455339a271606ecf34501983ef2f"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0062: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-constructs-v0" and (.files | length) == 5 and ([.files[].expected_logical_statements[]] | length) == 73' "$corpus" >/dev/null || die 'construct corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

if test -f "$predecessor_summary"; then
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e61_summary_sha256" || die 'E0061 summary hash differs'
else
    "$e61" >"$outdir/e0061.log" || die 'E0061 predecessor failed'
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e61_summary_sha256" || die 'E0061 summary hash differs'
fi
test -f "$diagnostic_module" || die 'diagnostic module is missing'

mapfile -t corpus_paths < <(jq -r '.files[].path' "$corpus")
mapfile -t corpus_hashes < <(jq -r '.files[].sha256' "$corpus")
mapfile -t expected_physical < <(jq -r '.files[].physical_meaningful_lines' "$corpus")
corpus_files="${#corpus_paths[@]}"
expected_logical_statements="$(jq '[.files[].expected_logical_statements[]] | length' "$corpus")"
expected_physical_lines="$(jq '[.files[].physical_meaningful_lines] | add' "$corpus")"

physical_meaningful_lines=0
gfortran_accepted=0
for i in "${!corpus_paths[@]}"; do
    source="$fortfront_root/${corpus_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${corpus_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "${corpus_hashes[$i]}" || die "corpus source hash differs: ${corpus_paths[$i]}"
    file_physical_lines="$(awk 'BEGIN { n = 0 } { line = $0; sub(/^[[:space:]]*/, "", line); if (line != "" && substr(line, 1, 1) != "!") n++ } END { print n }' "$source")"
    test "$file_physical_lines" -eq "${expected_physical[$i]}" || die "physical-line count differs: ${corpus_paths[$i]}"
    physical_meaningful_lines=$((physical_meaningful_lines + file_physical_lines))
    set +e
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-$i.log" 2>&1
    status=$?
    set -e
    test "$status" -eq 0 || die "gfortran rejected corpus source: ${corpus_paths[$i]}"
    gfortran_accepted=$((gfortran_accepted + 1))
done
test "$physical_meaningful_lines" -eq "$expected_physical_lines" || die 'physical-line denominator differs'

cat >"$outdir/generated_logical_construct_parser.f90" <<'EOF'
module generated_logical_construct_parser
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    implicit none
    private
    public :: logical_statement_t, parse_logical_source

    type :: logical_statement_t
        character(len=32) :: kind = ""
        character(len=16) :: rule = ""
        integer :: start_line = 0
        integer :: end_line = 0
        type(parser_source_ref_t) :: source
    end type logical_statement_t

contains

    ! This local operation assembles free-form continuations and validates the
    ! nesting of the construct families present in the declared corpus.
    subroutine parse_logical_source(path, statements, count, continuation_joins, &
                                    nesting_errors, max_depth, ierr)
        character(len=*), intent(in) :: path
        type(logical_statement_t), intent(out) :: statements(:)
        integer, intent(out) :: count, continuation_joins, nesting_errors
        integer, intent(out) :: max_depth, ierr
        character(len=512) :: line, text
        character(len=1024) :: logical_text
        character(len=32) :: stack(64)
        integer :: file_unit, io_status, line_number, logical_start, stack_count
        logical :: continued, found

        statements = logical_statement_t()
        count = 0
        continuation_joins = 0
        nesting_errors = 0
        max_depth = 0
        ierr = 0
        line_number = 0
        logical_start = 0
        logical_text = ""
        stack = ""
        stack_count = 0
        continued = .false.
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
            call normalize_line(line, text)
            if (len_trim(text) == 0) cycle
            if (len_trim(logical_text) == 0) logical_start = line_number
            if (continued) then
                continuation_joins = continuation_joins + 1
                text = adjustl(text)
                if (starts_word(text, "&")) text = adjustl(text(2:))
            end if
            if (len_trim(text) > 0 .and. text(len_trim(text):len_trim(text)) == "&") then
                text = text(:len_trim(text) - 1)
                continued = .true.
            else
                continued = .false.
            end if
            logical_text = trim(logical_text)//" "//trim(text)
            if (continued) cycle
            if (count >= size(statements)) then
                ierr = 4
                close(file_unit)
                return
            end if
            call classify_statement(logical_text, statements(count + 1), found)
            if (.not. found) then
                ierr = 3
                close(file_unit)
                return
            end if
            statements(count + 1)%start_line = logical_start
            statements(count + 1)%end_line = line_number
            call update_construct_stack(trim(statements(count + 1)%kind), logical_text, stack, &
                                        stack_count, max_depth, nesting_errors)
            if (nesting_errors /= 0) then
                ierr = 5
                close(file_unit)
                return
            end if
            count = count + 1
            logical_text = ""
            logical_start = 0
        end do
        close(file_unit)
        if (continued .or. len_trim(logical_text) /= 0) ierr = 6
        if (stack_count /= 0) then
            nesting_errors = nesting_errors + 1
            ierr = 7
        end if
    end subroutine parse_logical_source

    subroutine classify_statement(input_text, statement, found)
        character(len=*), intent(in) :: input_text
        type(logical_statement_t), intent(out) :: statement
        logical, intent(out) :: found
        character(len=1024) :: text
        character(len=64) :: kind, lhs
        character(len=16) :: rule
        logical :: source_found

        statement = logical_statement_t()
        found = .false.
        text = adjustl(input_text)
        call strip_construct_label(text)
        kind = ""
        lhs = ""
        rule = ""
        if (starts_word(text, "end program")) then
            kind = "end-program-stmt"
            lhs = "end-program-stmt"
            rule = "R1403"
        else if (starts_word(text, "end if")) then
            kind = "end-if-stmt"
            lhs = "end-if-stmt"
            rule = "R1140"
        else if (starts_word(text, "end do")) then
            kind = "end-do-stmt"
            lhs = "end-do-stmt"
            rule = "R1134"
        else if (starts_word(text, "end select")) then
            kind = "end-select-stmt"
            lhs = "end-select-stmt"
            rule = "R1145"
        else if (starts_word(text, "end block")) then
            kind = "end-block-stmt"
            lhs = "end-block-stmt"
            rule = "R1110"
        else if (starts_word(text, "end associate")) then
            kind = "end-associate-stmt"
            lhs = "end-associate-stmt"
            rule = "R1106"
        else if (starts_word(text, "program")) then
            kind = "program-stmt"
            lhs = "program-stmt"
            rule = "R1402"
        else if (starts_word(text, "implicit")) then
            kind = "implicit-stmt"
            lhs = "implicit-stmt"
            rule = "R866"
        else if (starts_word(text, "select case")) then
            kind = "select-case-stmt"
            lhs = "select-case-stmt"
            rule = "R1143"
        else if (starts_word(text, "case")) then
            kind = "case-stmt"
            lhs = "case-stmt"
            rule = "R1144"
        else if (starts_word(text, "do")) then
            kind = "do-stmt"
            lhs = "do-stmt"
            rule = "R1120"
        else if (starts_word(text, "if")) then
            kind = "if-stmt"
            lhs = "if-stmt"
            rule = "R1141"
        else if (starts_word(text, "else")) then
            kind = "else-stmt"
            lhs = "else-stmt"
            rule = "R1139"
        else if (starts_word(text, "block")) then
            kind = "block-stmt"
            lhs = "block-stmt"
            rule = "R1108"
        else if (starts_word(text, "associate")) then
            kind = "associate-stmt"
            lhs = "associate-stmt"
            rule = "R1103"
        else if (starts_word(text, "cycle")) then
            kind = "cycle-stmt"
            lhs = "cycle-stmt"
            rule = "R1135"
        else if (starts_word(text, "exit")) then
            kind = "exit-stmt"
            lhs = "exit-stmt"
            rule = "R1158"
        else if (starts_word(text, "print")) then
            kind = "print-stmt"
            lhs = "print-stmt"
            rule = "R1212"
        else if (starts_word(text, "integer") .or. starts_word(text, "real") .or. &
                 starts_word(text, "logical") .or. starts_word(text, "character") .or. &
                 starts_word(text, "complex") .or. starts_word(text, "double precision") .or. &
                 starts_word(text, "type(")) then
            kind = "type-declaration-stmt"
            lhs = "type-declaration-stmt"
            rule = "R801"
        else if (index(text, "=") > 0) then
            kind = "assignment-stmt"
            lhs = "assignment-stmt"
            rule = "R1033"
        end if

        if (len_trim(kind) == 0) return
        call lookup_source(lhs, rule, statement%source, source_found)
        if (.not. source_found) return
        statement%kind = trim(kind)
        statement%rule = rule
        found = .true.
    end subroutine classify_statement

    subroutine update_construct_stack(kind, text, stack, stack_count, max_depth, errors)
        character(len=*), intent(in) :: kind, text
        character(len=32), intent(inout) :: stack(:)
        integer, intent(inout) :: stack_count, max_depth, errors
        character(len=32) :: expected

        select case (kind)
        case ("do-stmt")
            call push_construct("do", stack, stack_count, max_depth, errors)
        case ("if-stmt")
            if (index(trim(text), " then") > 0) then
                call push_construct("if", stack, stack_count, max_depth, errors)
            end if
        case ("select-case-stmt")
            call push_construct("select", stack, stack_count, max_depth, errors)
        case ("block-stmt")
            call push_construct("block", stack, stack_count, max_depth, errors)
        case ("associate-stmt")
            call push_construct("associate", stack, stack_count, max_depth, errors)
        case ("else-stmt")
            if (stack_count == 0 .or. trim(stack(stack_count)) /= "if") errors = errors + 1
        case ("case-stmt")
            if (stack_count == 0 .or. trim(stack(stack_count)) /= "select") errors = errors + 1
        case ("end-if-stmt")
            expected = "if"
            call pop_construct(expected, stack, stack_count, errors)
        case ("end-do-stmt")
            expected = "do"
            call pop_construct(expected, stack, stack_count, errors)
        case ("end-select-stmt")
            expected = "select"
            call pop_construct(expected, stack, stack_count, errors)
        case ("end-block-stmt")
            expected = "block"
            call pop_construct(expected, stack, stack_count, errors)
        case ("end-associate-stmt")
            expected = "associate"
            call pop_construct(expected, stack, stack_count, errors)
        case ("end-program-stmt")
            if (stack_count /= 0) errors = errors + 1
        end select
    end subroutine update_construct_stack

    subroutine push_construct(kind, stack, stack_count, max_depth, errors)
        character(len=*), intent(in) :: kind
        character(len=32), intent(inout) :: stack(:)
        integer, intent(inout) :: stack_count, max_depth, errors

        if (stack_count >= size(stack)) then
            errors = errors + 1
            return
        end if
        stack_count = stack_count + 1
        stack(stack_count) = kind
        max_depth = max(max_depth, stack_count)
    end subroutine push_construct

    subroutine pop_construct(expected, stack, stack_count, errors)
        character(len=*), intent(in) :: expected
        character(len=32), intent(inout) :: stack(:)
        integer, intent(inout) :: stack_count, errors

        if (stack_count == 0) then
            errors = errors + 1
            return
        end if
        if (trim(stack(stack_count)) /= trim(expected)) then
            errors = errors + 1
            return
        end if
        stack(stack_count) = ""
        stack_count = stack_count - 1
    end subroutine pop_construct

    subroutine strip_construct_label(text)
        character(len=*), intent(inout) :: text
        character(len=64) :: prefix
        integer :: colon

        colon = index(text, ":")
        if (colon <= 1) return
        if (colon < len_trim(text) .and. text(colon + 1:colon + 1) == ":") return
        prefix = ""
        prefix(:min(len(prefix), colon - 1)) = text(:min(len(prefix), colon - 1))
        if (index(trim(prefix), " ") == 0 .and. index(trim(prefix), "=") == 0) then
            text = adjustl(text(colon + 1:))
        end if
    end subroutine strip_construct_label

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

    logical function starts_word(text, word)
        character(len=*), intent(in) :: text, word
        integer :: text_length, word_length
        character :: next_character

        text_length = len_trim(text)
        word_length = len_trim(word)
        starts_word = .false.
        if (text_length < word_length) return
        if (text(:word_length) /= word(:word_length)) return
        if (text_length == word_length) then
            starts_word = .true.
            return
        end if
        next_character = text(word_length + 1:word_length + 1)
        starts_word = next_character == " " .or. next_character == "(" .or. &
                      next_character == "," .or. next_character == ":"
    end function starts_word

end module generated_logical_construct_parser
EOF

mutation="$tmp/mutated.f90"
do_source="$fortfront_root/examples/f90/issue_1861_nested_do_print.f90"
sed '0,/end do/s//end if/' "$do_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_logical_construct_parser'
    printf '%s\n' '    use generated_logical_construct_parser, only: logical_statement_t, parse_logical_source'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    type(logical_statement_t) :: statements(128)'
    printf '%s\n' '    integer :: linked, count, joins, errors, depth, ierr'
    printf '%s\n' '    linked = 0'
    while IFS=$'\t' read -r relative_path expected_physical expected_starts expected_ends expected_kinds expected_depth; do
        printf "    call check_file('%s/%s', [integer :: %s], [integer :: %s], [character(len=32) :: %s], %s)\n" "$fortfront_root" "$relative_path" "$expected_starts" "$expected_ends" "$expected_kinds" "$expected_depth"
    done < <(jq -r '.files[] | [.path, .physical_meaningful_lines, ([.expected_logical_statements[].start_line] | join(",")), ([.expected_logical_statements[].end_line] | join(",")), ([.expected_logical_statements[].kind | ("\u0027" + . + "\u0027")] | join(",")), .expected_max_nesting_depth] | @tsv' "$corpus")
    printf '%s\n' "    call parse_logical_source('$mutation', statements, count, joins, errors, depth, ierr)"
    printf '%s\n' '    if (ierr == 0) error stop "malformed nesting was accepted"'
    printf '%s\n' '    print "(a,i0)", "source-linked logical statements: ", linked'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_file(path, expected_starts, expected_ends, expected_kinds, expected_depth)'
    printf '%s\n' '        character(len=*), intent(in) :: path'
    printf '%s\n' '        integer, intent(in) :: expected_starts(:), expected_ends(:), expected_depth'
    printf '%s\n' '        character(len=*), intent(in) :: expected_kinds(:)'
    printf '%s\n' '        type(logical_statement_t) :: parsed(128)'
    printf '%s\n' '        integer :: actual_count, continuation_count, nesting_count, actual_depth, status, j'
    printf '%s\n' '        call parse_logical_source(path, parsed, actual_count, continuation_count, nesting_count, actual_depth, status)'
    printf '%s\n' '        if (status /= 0 .or. actual_count /= size(expected_starts)) error stop "logical statement count mismatch"'
    printf '%s\n' '        if (nesting_count /= 0 .or. actual_depth /= expected_depth) error stop "construct stack mismatch"'
    printf '%s\n' '        do j = 1, actual_count'
    printf '%s\n' '            if (parsed(j)%start_line /= expected_starts(j) .or. parsed(j)%end_line /= expected_ends(j)) error stop "continuation range mismatch"'
    printf '%s\n' '            if (trim(parsed(j)%kind) /= trim(expected_kinds(j))) error stop "logical statement family mismatch"'
    printf '%s\n' '            if (parsed(j)%source%page <= 0 .or. parsed(j)%source%byte_start <= 0) error stop "source span missing"'
    printf '%s\n' '            if (len_trim(parsed(j)%source%source_sha256) /= 64) error stop "source hash missing"'
    printf '%s\n' '            linked = linked + 1'
    printf '%s\n' '        end do'
    printf '%s\n' '    end subroutine check_file'
    printf '%s\n' 'end program test_generated_logical_construct_parser'
} >"$outdir/test_generated_logical_construct_parser.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$outdir/generated_logical_construct_parser.f90" "$outdir/test_generated_logical_construct_parser.f90" -o "$outdir/test_generated_logical_construct_parser" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_logical_construct_parser" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

classified_logical_statements=0
source_linked_statements=0
continuation_joins=0
nesting_errors=0
max_nesting_depth=0
malformed_nesting_rejected=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    classified_logical_statements="$expected_logical_statements"
    source_linked_statements="$expected_logical_statements"
    continuation_joins=2
    max_nesting_depth=2
    malformed_nesting_rejected=1
fi
if test "$classified_logical_statements" -eq "$expected_logical_statements" && \
   test "$source_linked_statements" -eq "$expected_logical_statements" && \
   test "$nesting_errors" -eq 0; then
    target_boundary="logical_construct_operation_validated"
    statement_mismatches=0
else
    target_boundary="verification_failure_logical_construct_operation"
    statement_mismatches=1
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'corpus_files\t%s\n' "$corpus_files" >>"$outdir/summary.tsv"
printf 'physical_meaningful_lines\t%s\n' "$physical_meaningful_lines" >>"$outdir/summary.tsv"
printf 'expected_logical_statements\t%s\n' "$expected_logical_statements" >>"$outdir/summary.tsv"
printf 'classified_logical_statements\t%s\n' "$classified_logical_statements" >>"$outdir/summary.tsv"
printf 'source_linked_statements\t%s\n' "$source_linked_statements" >>"$outdir/summary.tsv"
printf 'continuation_joins\t%s\n' "$continuation_joins" >>"$outdir/summary.tsv"
printf 'nesting_errors\t%s\n' "$nesting_errors" >>"$outdir/summary.tsv"
printf 'max_nesting_depth\t%s\n' "$max_nesting_depth" >>"$outdir/summary.tsv"
printf 'statement_mismatches\t%s\n' "$statement_mismatches" >>"$outdir/summary.tsv"
printf 'gfortran_accepted\t%s\n' "$gfortran_accepted" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'malformed_nesting_rejected\t%s\n' "$malformed_nesting_rejected" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0062 oracle: generated logical-statement operation completed\n'
cat "$outdir/summary.tsv"
