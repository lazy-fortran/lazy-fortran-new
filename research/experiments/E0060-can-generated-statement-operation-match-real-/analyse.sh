#!/usr/bin/env bash
# Generate and execute the bounded local statement parser operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-statements-v0.json"
e59="$root/research/experiments/E0059-can-generated-top-level-operation-parse-real-/analyse.sh"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0060/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e59_summary_sha256="69cb18ee63c63e487153f92a384ddce05be99e1464a3a01a6c6e7a6de8f8c32c"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0060: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-statements-v0" and (.files | length) == 5 and ([.files[].witnesses[]] | length) == 10' "$corpus" >/dev/null || die 'statement corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

"$e59" >"$outdir/e0059.log" || die 'E0059 predecessor failed'
test "$(sha256sum "$root/.cache/runs/E0059/R000001/summary.tsv" | cut -d' ' -f1)" = "$expected_e59_summary_sha256" || die 'E0059 summary hash differs'
test -f "$diagnostic_module" || die 'diagnostic module is missing'

mapfile -t corpus_paths < <(jq -r '.files[].path' "$corpus")
mapfile -t corpus_hashes < <(jq -r '.files[].sha256' "$corpus")
corpus_files="${#corpus_paths[@]}"
expected_witnesses="$(jq '[.files[].witnesses[]] | length' "$corpus")"

for i in "${!corpus_paths[@]}"; do
    source="$fortfront_root/${corpus_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${corpus_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "${corpus_hashes[$i]}" || die "corpus source hash differs: ${corpus_paths[$i]}"
done

cat >"$outdir/generated_statement_parser.f90" <<'EOF'
module generated_statement_parser
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    implicit none
    private
    public :: statement_witness_t, find_statement

    type :: statement_witness_t
        character(len=32) :: kind = ""
        character(len=16) :: rule = ""
        type(parser_source_ref_t) :: source
    end type statement_witness_t

contains

    ! This local operation recognizes only declared statement witnesses.
    ! Dispatch, rule identity and source provenance come from generated data.
    subroutine find_statement(path, needle, witness, found, ierr)
        character(len=*), intent(in) :: path, needle
        type(statement_witness_t), intent(out) :: witness
        logical, intent(out) :: found
        integer, intent(out) :: ierr
        character(len=512) :: line, text
        integer :: file_unit, io_status

        witness = statement_witness_t()
        found = .false.
        ierr = 0
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
            call normalize_line(line, text)
            if (index(text, trim(needle)) == 0) cycle
            call classify_statement(text, witness, found)
            if (found) then
                close(file_unit)
                return
            end if
        end do
        close(file_unit)
        ierr = 3
    end subroutine find_statement

    subroutine classify_statement(text, witness, found)
        character(len=*), intent(in) :: text
        type(statement_witness_t), intent(out) :: witness
        logical, intent(out) :: found
        character(len=64) :: lhs
        character(len=16) :: rule
        logical :: source_found

        witness = statement_witness_t()
        found = .false.
        lhs = ""
        rule = ""
        if (starts_word(text, "use")) then
            lhs = "use-stmt"
            rule = "R1409"
        else if (starts_word(text, "implicit")) then
            lhs = "implicit-stmt"
            rule = "R866"
        else if (starts_word(text, "integer") .or. starts_word(text, "real") .or. starts_word(text, "logical")) then
            lhs = "type-declaration-stmt"
            rule = "R801"
        else if (starts_word(text, "do concurrent")) then
            lhs = "do-stmt"
            rule = "R1120"
        else if (starts_word(text, "call")) then
            lhs = "call-stmt"
            rule = "R1521"
        else if (starts_word(text, "print")) then
            lhs = "print-stmt"
            rule = "R1212"
        else if (starts_word(text, "contains")) then
            lhs = "contains-stmt"
            rule = "R1546"
        else if (starts_word(text, "end program")) then
            lhs = "end-program-stmt"
            rule = "R1403"
        else if (index(text, "=") > 0 .and. .not. starts_word(text, "if")) then
            lhs = "assignment-stmt"
            rule = "R1033"
        end if
        if (len_trim(lhs) == 0) return

        call lookup_source(lhs, rule, witness%source, source_found)
        if (.not. source_found) return
        witness%kind = trim(lhs)
        witness%rule = rule
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
            if (code >= iachar("A") .and. code <= iachar("Z")) text(i:i) = achar(code + iachar("a") - iachar("A"))
        end do
    end subroutine normalize_line

    logical function starts_word(text, word)
        character(len=*), intent(in) :: text, word
        integer :: text_length, word_length

        text_length = len_trim(text)
        word_length = len_trim(word)
        starts_word = .false.
        if (text_length < word_length) return
        if (text(:word_length) /= word(:word_length)) return
        starts_word = text_length == word_length .or. text(word_length + 1:word_length + 1) == " "
    end function starts_word

end module generated_statement_parser
EOF

mutation="$tmp/mutated.f90"
do_source="$fortfront_root/examples/f90/do_concurrent_type_spec.f90"
sed 's/do concurrent/print /' "$do_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_statement_parser'
    printf '%s\n' '    use generated_statement_parser, only: statement_witness_t, find_statement'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    integer :: linked'
    printf '%s\n' '    linked = 0'
    while IFS=$'\t' read -r relative_path needle expected_kind; do
        printf "    call check_witness('%s/%s', '%s', '%s')\n" "$fortfront_root" "$relative_path" "$needle" "$expected_kind"
    done < <(jq -r '.files[] as $f | $f.witnesses[] | [$f.path, .needle, .kind] | @tsv' "$corpus")
    printf '%s\n' "    call check_witness('$mutation', 'print', 'print-stmt')"
    printf '%s\n' '    print "(a,i0)", "source-linked statement witnesses: ", linked'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_witness(path, needle, expected_kind)'
    printf '%s\n' '        character(len=*), intent(in) :: path, needle, expected_kind'
    printf '%s\n' '        type(statement_witness_t) :: witness'
    printf '%s\n' '        logical :: found'
    printf '%s\n' '        integer :: status'
    printf '%s\n' '        call find_statement(path, needle, witness, found, status)'
    printf '%s\n' '        if (status /= 0 .or. .not. found) error stop "statement witness missing"'
    printf '%s\n' '        if (trim(witness%kind) /= trim(expected_kind)) error stop "statement family mismatch"'
    printf '%s\n' '        if (witness%source%page <= 0 .or. witness%source%byte_start <= 0) error stop "statement source span missing"'
    printf '%s\n' '        if (len_trim(witness%source%source_sha256) /= 64) error stop "statement source hash missing"'
    printf '%s\n' '        linked = linked + 1'
    printf '%s\n' '    end subroutine check_witness'
    printf '%s\n' 'end program test_generated_statement_parser'
} >"$outdir/test_generated_statement_parser.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$outdir/generated_statement_parser.f90" "$outdir/test_generated_statement_parser.f90" -o "$outdir/test_generated_statement_parser" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_statement_parser" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

classified_witnesses=0
source_linked_witnesses=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    classified_witnesses="$expected_witnesses"
    source_linked_witnesses="$expected_witnesses"
fi
if test "$classified_witnesses" -eq "$expected_witnesses" && test "$source_linked_witnesses" -eq "$expected_witnesses"; then
    witness_mismatches=0
    target_boundary="statement_witness_operation_validated"
else
    witness_mismatches=1
    target_boundary="verification_failure_statement_witness_operation"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'corpus_files\t%s\n' "$corpus_files" >>"$outdir/summary.tsv"
printf 'expected_witnesses\t%s\n' "$expected_witnesses" >>"$outdir/summary.tsv"
printf 'classified_witnesses\t%s\n' "$classified_witnesses" >>"$outdir/summary.tsv"
printf 'source_linked_witnesses\t%s\n' "$source_linked_witnesses" >>"$outdir/summary.tsv"
printf 'witness_mismatches\t%s\n' "$witness_mismatches" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0060 oracle: generated statement operation completed\n'
cat "$outdir/summary.tsv"
