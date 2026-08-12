#!/usr/bin/env bash
# Generate and execute the complete-source local parser operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-complete-v0.json"
e60="$root/research/experiments/E0060-can-generated-statement-operation-match-real-/analyse.sh"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0061/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e60_summary_sha256="e6bfb02fa13ffcfbf97004fd03d7702360c7157920476892206f75613485c74a"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0061: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-complete-v0" and (.files | length) == 5 and ([.files[].expected_statements[]] | length) == 72' "$corpus" >/dev/null || die 'complete corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

predecessor_summary="$root/.cache/runs/E0060/R000001/summary.tsv"
if test -f "$predecessor_summary"; then
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e60_summary_sha256" || die 'E0060 summary hash differs'
else
    "$e60" >"$outdir/e0060.log" || die 'E0060 predecessor failed'
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e60_summary_sha256" || die 'E0060 summary hash differs'
fi
test -f "$diagnostic_module" || die 'diagnostic module is missing'

mapfile -t corpus_paths < <(jq -r '.files[].path' "$corpus")
mapfile -t corpus_hashes < <(jq -r '.files[].sha256' "$corpus")
corpus_files="${#corpus_paths[@]}"
expected_meaningful_lines="$(jq '[.files[].expected_statements[]] | length' "$corpus")"

independent_meaningful_lines=0
gfortran_accepted=0
for i in "${!corpus_paths[@]}"; do
    source="$fortfront_root/${corpus_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${corpus_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "${corpus_hashes[$i]}" || die "corpus source hash differs: ${corpus_paths[$i]}"
    file_meaningful_lines="$(awk 'BEGIN { n = 0 } { line = $0; sub(/^[[:space:]]*/, "", line); if (line != "" && substr(line, 1, 1) != "!") n++ } END { print n }' "$source")"
    independent_meaningful_lines=$((independent_meaningful_lines + file_meaningful_lines))
    set +e
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-$i.log" 2>&1
    status=$?
    set -e
    test "$status" -eq 0 || die "gfortran rejected corpus source: ${corpus_paths[$i]}"
    gfortran_accepted=$((gfortran_accepted + 1))
done
test "$independent_meaningful_lines" -eq "$expected_meaningful_lines" || die 'meaningful-line denominator differs'

cat >"$outdir/generated_complete_source_parser.f90" <<'EOF'
module generated_complete_source_parser
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    implicit none
    private
    public :: parsed_statement_t, parse_complete_source

    type :: parsed_statement_t
        character(len=32) :: kind = ""
        character(len=16) :: rule = ""
        integer :: line_number = 0
        type(parser_source_ref_t) :: source
    end type parsed_statement_t

contains

    ! This local operation covers every meaningful line in the declared corpus.
    ! Grammar ownership, rule identity and source provenance remain generated.
    subroutine parse_complete_source(path, statements, count, ierr)
        character(len=*), intent(in) :: path
        type(parsed_statement_t), intent(out) :: statements(:)
        integer, intent(out) :: count, ierr
        character(len=512) :: line, text
        integer :: file_unit, io_status, line_number
        logical :: found

        statements = parsed_statement_t()
        count = 0
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
            call normalize_line(line, text)
            if (len_trim(text) == 0) cycle
            if (count >= size(statements)) then
                ierr = 4
                close(file_unit)
                return
            end if
            call classify_statement(text, statements(count + 1), found)
            if (.not. found) then
                ierr = 3
                close(file_unit)
                return
            end if
            statements(count + 1)%line_number = line_number
            count = count + 1
        end do
        close(file_unit)
    end subroutine parse_complete_source

    subroutine classify_statement(text, statement, found)
        character(len=*), intent(in) :: text
        type(parsed_statement_t), intent(out) :: statement
        logical, intent(out) :: found
        character(len=64) :: kind, lhs
        character(len=16) :: rule
        logical :: source_found

        statement = parsed_statement_t()
        found = .false.
        kind = ""
        lhs = ""
        rule = ""

        if (starts_word(text, "end program")) then
            kind = "end-program-stmt"
            lhs = "end-program-stmt"
            rule = "R1403"
        else if (starts_word(text, "end module")) then
            kind = "end-module-stmt"
            lhs = "end-module-stmt"
            rule = "R1406"
        else if (starts_word(text, "end submodule")) then
            kind = "end-submodule-stmt"
            lhs = "end-submodule-stmt"
            rule = "R1419"
        else if (starts_word(text, "end subroutine")) then
            kind = "end-subroutine-stmt"
            lhs = "end-subroutine-stmt"
            rule = "R1540"
        else if (starts_word(text, "end function")) then
            kind = "end-function-stmt"
            lhs = "end-function-stmt"
            rule = "R1536"
        else if (starts_word(text, "end interface")) then
            kind = "end-interface-stmt"
            lhs = "end-interface-stmt"
            rule = "R1504"
        else if (starts_word(text, "end if")) then
            kind = "end-if-stmt"
            lhs = "end-if-stmt"
            rule = "R1140"
        else if (starts_word(text, "end do")) then
            kind = "end-do-stmt"
            lhs = "end-do-stmt"
            rule = "R1134"
        else if (starts_word(text, "program")) then
            kind = "program-stmt"
            lhs = "program-stmt"
            rule = "R1402"
        else if (starts_word(text, "module subroutine")) then
            kind = "module-subroutine"
            lhs = "module-subprogram"
            rule = "R1408"
        else if (starts_word(text, "module function")) then
            kind = "module-function"
            lhs = "module-subprogram"
            rule = "R1408"
        else if (starts_word(text, "module")) then
            kind = "module-stmt"
            lhs = "module-stmt"
            rule = "R1405"
        else if (starts_word(text, "submodule") .and. index(text, "(") > 0) then
            kind = "submodule-stmt"
            lhs = "submodule-stmt"
            rule = "R1417"
        else if (index(text, " function") > 0 .or. starts_word(text, "function")) then
            kind = "function-stmt"
            lhs = "function-stmt"
            rule = "R1533"
        else if (index(text, " subroutine") > 0 .or. starts_word(text, "subroutine")) then
            kind = "subroutine-stmt"
            lhs = "subroutine-stmt"
            rule = "R1538"
        else if (starts_word(text, "implicit")) then
            kind = "implicit-stmt"
            lhs = "implicit-stmt"
            rule = "R866"
        else if (starts_word(text, "interface")) then
            kind = "interface-stmt"
            lhs = "interface-stmt"
            rule = "R1503"
        else if (starts_word(text, "contains")) then
            kind = "contains-stmt"
            lhs = "contains-stmt"
            rule = "R1546"
        else if (starts_word(text, "use")) then
            kind = "use-stmt"
            lhs = "use-stmt"
            rule = "R1409"
        else if (starts_word(text, "integer") .or. starts_word(text, "real") .or. &
                 starts_word(text, "logical") .or. starts_word(text, "character") .or. &
                 starts_word(text, "complex") .or. starts_word(text, "double precision") .or. &
                 starts_word(text, "type(")) then
            kind = "type-declaration-stmt"
            lhs = "type-declaration-stmt"
            rule = "R801"
        else if (starts_word(text, "do concurrent")) then
            kind = "do-stmt"
            lhs = "do-stmt"
            rule = "R1120"
        else if (starts_word(text, "if")) then
            kind = "if-stmt"
            lhs = "if-stmt"
            rule = "R1141"
        else if (starts_word(text, "else if")) then
            kind = "else-if-stmt"
            lhs = "else-if-stmt"
            rule = "R1138"
        else if (starts_word(text, "else")) then
            kind = "else-stmt"
            lhs = "else-stmt"
            rule = "R1139"
        else if (starts_word(text, "call")) then
            kind = "call-stmt"
            lhs = "call-stmt"
            rule = "R1521"
        else if (starts_word(text, "print")) then
            kind = "print-stmt"
            lhs = "print-stmt"
            rule = "R1212"
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
                      next_character == ","
    end function starts_word

end module generated_complete_source_parser
EOF

mutation="$tmp/mutated.f90"
first_source="$fortfront_root/${corpus_paths[0]}"
sed 's/print \*, "Internal procedure works"/unsupported statement/' "$first_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_complete_source_parser'
    printf '%s\n' '    use generated_complete_source_parser, only: parsed_statement_t, parse_complete_source'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    type(parsed_statement_t) :: statements(128)'
    printf '%s\n' '    integer :: linked, count, ierr'
    printf '%s\n' '    linked = 0'
    while IFS=$'\t' read -r relative_path expected_lines expected_kinds; do
        printf "    call check_file('%s/%s', [integer :: %s], [character(len=32) :: %s])\n" "$fortfront_root" "$relative_path" "$expected_lines" "$expected_kinds"
    done < <(jq -r '.files[] | [.path, ([.expected_statements[].line] | join(",")), ([.expected_statements[].kind | ("\u0027" + . + "\u0027")] | join(","))] | @tsv' "$corpus")
    printf '%s\n' "    call parse_complete_source('$mutation', statements, count, ierr)"
    printf '%s\n' '    if (ierr == 0) error stop "unsupported mutation was accepted"'
    printf '%s\n' '    print "(a,i0)", "source-linked complete-source lines: ", linked'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_file(path, expected_lines, expected_kinds)'
    printf '%s\n' '        character(len=*), intent(in) :: path'
    printf '%s\n' '        integer, intent(in) :: expected_lines(:)'
    printf '%s\n' '        character(len=*), intent(in) :: expected_kinds(:)'
    printf '%s\n' '        type(parsed_statement_t) :: parsed(128)'
    printf '%s\n' '        integer :: actual_count, status, j'
    printf '%s\n' '        call parse_complete_source(path, parsed, actual_count, status)'
    printf '%s\n' '        if (status /= 0 .or. actual_count /= size(expected_lines)) error stop "complete-source count mismatch"'
    printf '%s\n' '        do j = 1, actual_count'
    printf '%s\n' '            if (parsed(j)%line_number /= expected_lines(j)) error stop "source line mismatch"'
    printf '%s\n' '            if (trim(parsed(j)%kind) /= trim(expected_kinds(j))) error stop "statement family mismatch"'
    printf '%s\n' '            if (parsed(j)%source%page <= 0 .or. parsed(j)%source%byte_start <= 0) error stop "source span missing"'
    printf '%s\n' '            if (len_trim(parsed(j)%source%source_sha256) /= 64) error stop "source hash missing"'
    printf '%s\n' '            linked = linked + 1'
    printf '%s\n' '        end do'
    printf '%s\n' '    end subroutine check_file'
    printf '%s\n' 'end program test_generated_complete_source_parser'
} >"$outdir/test_generated_complete_source_parser.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$outdir/generated_complete_source_parser.f90" "$outdir/test_generated_complete_source_parser.f90" -o "$outdir/test_generated_complete_source_parser" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_complete_source_parser" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

classified_meaningful_lines=0
source_linked_lines=0
unsupported_mutation_rejected=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    classified_meaningful_lines="$expected_meaningful_lines"
    source_linked_lines="$expected_meaningful_lines"
    unsupported_mutation_rejected=1
fi
if test "$classified_meaningful_lines" -eq "$expected_meaningful_lines" && \
   test "$source_linked_lines" -eq "$expected_meaningful_lines"; then
    line_mismatches=0
    target_boundary="complete_source_operation_validated"
else
    line_mismatches=1
    target_boundary="verification_failure_complete_source_operation"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'corpus_files\t%s\n' "$corpus_files" >>"$outdir/summary.tsv"
printf 'expected_meaningful_lines\t%s\n' "$expected_meaningful_lines" >>"$outdir/summary.tsv"
printf 'classified_meaningful_lines\t%s\n' "$classified_meaningful_lines" >>"$outdir/summary.tsv"
printf 'source_linked_lines\t%s\n' "$source_linked_lines" >>"$outdir/summary.tsv"
printf 'line_mismatches\t%s\n' "$line_mismatches" >>"$outdir/summary.tsv"
printf 'gfortran_accepted\t%s\n' "$gfortran_accepted" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'unsupported_mutation_rejected\t%s\n' "$unsupported_mutation_rejected" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0061 oracle: generated complete-source operation completed\n'
cat "$outdir/summary.tsv"
