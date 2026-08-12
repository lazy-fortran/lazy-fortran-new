#!/usr/bin/env bash
# Generate and execute the lossless complete-source acceptance operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-complete-v0.json"
e61="$root/research/experiments/E0061-can-generated-parser-accept-complete-/analyse.sh"
predecessor_summary="$root/.cache/runs/E0061/R000001/summary.tsv"
complete_module="$root/.cache/runs/E0061/R000001/generated_complete_source_parser.f90"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0068/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
expected_e61_summary_sha256="d5faae0444d7c328b232d5952dc4d089f851455339a271606ecf34501983ef2f"
expected_complete_module_sha256="4c1b90e83af789fbf4bee59b5906b9153daa4ce434290cfad901bcefa4d6b1bb"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0068: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-complete-v0" and (.files | length) == 5 and ([.files[].expected_statements[]] | length) == 72' "$corpus" >/dev/null || die 'complete corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

if test -f "$predecessor_summary"; then
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e61_summary_sha256" || die 'E0061 summary hash differs'
else
    "$e61" >"$outdir/e0061.log" || die 'E0061 predecessor failed'
    test "$(sha256sum "$predecessor_summary" | cut -d' ' -f1)" = "$expected_e61_summary_sha256" || die 'E0061 summary hash differs'
fi
test -f "$complete_module" || die 'complete-source predecessor module is missing'
test "$(sha256sum "$complete_module" | cut -d' ' -f1)" = "$expected_complete_module_sha256" || die 'complete-source predecessor module hash differs'
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

cat >"$outdir/generated_lossless_complete_source_acceptance.f90" <<'EOF'
! origin: MECHANICAL
module generated_lossless_complete_source_acceptance
    use generated_complete_source_parser, only: parsed_statement_t, parse_complete_source
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    implicit none
    private
    public :: acceptance_record_t, parse_source_acceptance

    type :: acceptance_record_t
        character(len=16) :: status = ""
        character(len=32) :: kind = ""
        character(len=16) :: rule = ""
        integer :: line_number = 0
        type(parser_source_ref_t) :: source
        character(len=64) :: message = ""
    end type acceptance_record_t

contains

    ! Recognized records are copied from the generated predecessor. A local
    ! residue becomes a typed record and source-linked diagnostic, not a skip.
    subroutine parse_source_acceptance(path, records, count, accepted_count, &
                                       unsupported_count, diagnostic_count, ierr)
        character(len=*), intent(in) :: path
        type(acceptance_record_t), intent(out) :: records(:)
        integer, intent(out) :: count, accepted_count, unsupported_count, diagnostic_count, ierr
        type(parsed_statement_t) :: parsed(256)
        integer :: parsed_count, parser_ierr, i, failure_line

        records = acceptance_record_t()
        count = 0
        accepted_count = 0
        unsupported_count = 0
        diagnostic_count = 0
        ierr = 0
        call parse_complete_source(path, parsed, parsed_count, parser_ierr)
        if (parser_ierr /= 0 .and. parser_ierr /= 3) then
            ierr = parser_ierr
            return
        end if
        if (parsed_count > size(records)) then
            ierr = 4
            return
        end if
        do i = 1, parsed_count
            records(i)%status = "accepted"
            records(i)%kind = parsed(i)%kind
            records(i)%rule = parsed(i)%rule
            records(i)%line_number = parsed(i)%line_number
            records(i)%source = parsed(i)%source
        end do
        count = parsed_count
        accepted_count = parsed_count
        if (parser_ierr == 3) then
            call first_unparsed_line(path, parsed_count, failure_line, ierr)
            if (ierr /= 0) return
            if (count >= size(records)) then
                ierr = 4
                return
            end if
            call append_unsupported(records(count + 1), failure_line, ierr)
            if (ierr /= 0) return
            count = count + 1
            unsupported_count = 1
            diagnostic_count = 1
        end if
    end subroutine parse_source_acceptance

    subroutine append_unsupported(record, line_number, ierr)
        type(acceptance_record_t), intent(out) :: record
        integer, intent(in) :: line_number
        integer, intent(out) :: ierr
        logical :: found

        record = acceptance_record_t()
        ierr = 0
        call lookup_source("program-unit", "R502", record%source, found)
        if (.not. found) then
            ierr = 5
            return
        end if
        record%status = "unsupported"
        record%kind = "unsupported"
        record%rule = "R502"
        record%line_number = line_number
        record%message = "unsupported local construct"
    end subroutine append_unsupported

    subroutine first_unparsed_line(path, parsed_count, line_number, ierr)
        character(len=*), intent(in) :: path
        integer, intent(in) :: parsed_count
        integer, intent(out) :: line_number, ierr
        character(len=512) :: line, text
        integer :: file_unit, io_status, physical_line, meaningful_count

        line_number = 0
        ierr = 0
        physical_line = 0
        meaningful_count = 0
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
            physical_line = physical_line + 1
            call normalize_line(line, text)
            if (len_trim(text) == 0) cycle
            meaningful_count = meaningful_count + 1
            if (meaningful_count == parsed_count + 1) then
                line_number = physical_line
                close(file_unit)
                return
            end if
        end do
        close(file_unit)
        ierr = 3
    end subroutine first_unparsed_line

    subroutine normalize_line(line, text)
        character(len=*), intent(in) :: line
        character(len=*), intent(out) :: text
        integer :: bang

        text = adjustl(line)
        bang = index(text, "!")
        if (bang == 1) then
            text = ""
        else if (bang > 1) then
            text = text(:bang - 1)
        end if
        text = adjustl(text)
    end subroutine normalize_line

end module generated_lossless_complete_source_acceptance
EOF

mutation="$tmp/mutated.f90"
mutation_source="$fortfront_root/examples/f90/module_parsing_basic.f90"
sed 's/c = a + b/event post/' "$mutation_source" >"$mutation"
set +e
gfortran -std=f2018 -fsyntax-only "$mutation" >"$outdir/gfortran-mutation.log" 2>&1
gfortran_mutation_status=$?
set -e
test "$gfortran_mutation_status" -ne 0 || die 'gfortran accepted the unsupported mutation'

{
    printf '%s\n' 'program test_generated_lossless_complete_source_acceptance'
    printf '%s\n' '    use generated_lossless_complete_source_acceptance, only: acceptance_record_t, parse_source_acceptance'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    integer :: accepted_total, source_linked_total, unsupported_total, diagnostic_total'
    printf '%s\n' '    accepted_total = 0; source_linked_total = 0; unsupported_total = 0; diagnostic_total = 0'
    while IFS=$'\t' read -r relative_path expected_starts expected_kinds; do
        printf "    call check_file('%s/%s', [integer :: %s], [character(len=32) :: %s])\n" "$fortfront_root" "$relative_path" "$expected_starts" "$expected_kinds"
    done < <(jq -r '.files[] | [.path, ([.expected_statements[].line] | join(",")), ([.expected_statements[].kind | ("\u0027" + . + "\u0027")] | join(","))] | @tsv' "$corpus")
    printf '%s\n' '    call check_mutation()'
    printf '%s\n' '    if (accepted_total /= 72 .or. source_linked_total /= 72) error stop "complete acceptance total mismatch"'
    printf '%s\n' '    if (unsupported_total /= 1 .or. diagnostic_total /= 1) error stop "diagnostic total mismatch"'
    printf '%s\n' '    print "(a,i0,1x,a,i0)", "accepted records: ", accepted_total, "unsupported diagnostics: ", diagnostic_total'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_file(path, expected_lines, expected_kinds)'
    printf '%s\n' '        character(len=*), intent(in) :: path'
    printf '%s\n' '        integer, intent(in) :: expected_lines(:)'
    printf '%s\n' '        character(len=*), intent(in) :: expected_kinds(:)'
    printf '%s\n' '        type(acceptance_record_t), allocatable :: records(:)'
    printf '%s\n' '        integer :: count, accepted, unsupported, diagnostics, status, i'
    printf '%s\n' '        allocate(records(256))'
    printf '%s\n' '        call parse_source_acceptance(path, records, count, accepted, unsupported, diagnostics, status)'
    printf '%s\n' '        if (status /= 0 .or. count /= size(expected_lines) .or. accepted /= count .or. unsupported /= 0 .or. diagnostics /= 0) error stop "complete acceptance mismatch"'
    printf '%s\n' '        do i = 1, count'
    printf '%s\n' '            if (trim(records(i)%status) /= "accepted" .or. records(i)%line_number /= expected_lines(i) .or. trim(records(i)%kind) /= trim(expected_kinds(i))) error stop "accepted record mismatch"'
    printf '%s\n' '            if (records(i)%source%page <= 0 .or. records(i)%source%byte_start <= 0) error stop "accepted source span missing"'
    printf '%s\n' '            if (trim(records(i)%source%source_sha256) /= "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2") error stop "accepted source hash mismatch"'
    printf '%s\n' '        end do'
    printf '%s\n' '        accepted_total = accepted_total + accepted'
    printf '%s\n' '        source_linked_total = source_linked_total + count'
    printf '%s\n' '        deallocate(records)'
    printf '%s\n' '    end subroutine check_file'
    printf '%s\n' '    subroutine check_mutation()'
    printf '%s\n' '        type(acceptance_record_t), allocatable :: records(:)'
    printf '%s\n' '        character(len=1024) :: mutation_path'
    printf '%s\n' '        integer :: count, accepted, unsupported, diagnostics, status'
    printf '%s\n' '        call get_environment_variable("E0068_MUTATION", mutation_path)'
    printf '%s\n' '        allocate(records(256))'
    printf '%s\n' '        call parse_source_acceptance(trim(mutation_path), records, count, accepted, unsupported, diagnostics, status)'
    printf '%s\n' '        if (status /= 0 .or. count /= 6 .or. accepted /= 5 .or. unsupported /= 1 .or. diagnostics /= 1) error stop "unsupported residue was not retained"'
    printf '%s\n' '        if (trim(records(6)%status) /= "unsupported" .or. records(6)%line_number /= 6) error stop "unsupported diagnostic location mismatch"'
    printf '%s\n' '        if (records(6)%source%page <= 0 .or. records(6)%source%byte_start <= 0) error stop "diagnostic source context missing"'
    printf '%s\n' '        if (trim(records(6)%source%lhs) /= "program-unit" .or. trim(records(6)%source%rule) /= "R502") error stop "diagnostic source context mismatch"'
    printf '%s\n' '        unsupported_total = unsupported_total + unsupported'
    printf '%s\n' '        diagnostic_total = diagnostic_total + diagnostics'
    printf '%s\n' '        deallocate(records)'
    printf '%s\n' '    end subroutine check_mutation'
    printf '%s\n' 'end program test_generated_lossless_complete_source_acceptance'
} >"$outdir/test_generated_lossless_complete_source_acceptance.f90"
sed -i '1i! origin: MECHANICAL' "$outdir/test_generated_lossless_complete_source_acceptance.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$complete_module" "$outdir/generated_lossless_complete_source_acceptance.f90" "$outdir/test_generated_lossless_complete_source_acceptance.f90" -o "$outdir/test_generated_lossless_complete_source_acceptance" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    E0068_MUTATION="$mutation" "$outdir/test_generated_lossless_complete_source_acceptance" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

accepted_records=0
source_linked_records=0
unsupported_records=0
diagnostic_records=0
complete_file_mismatches=0
diagnostic_provenance=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    accepted_records="$expected_meaningful_lines"
    source_linked_records="$expected_meaningful_lines"
    unsupported_records=1
    diagnostic_records=1
    diagnostic_provenance=1
else
    complete_file_mismatches=1
fi

if test "$accepted_records" -eq "$expected_meaningful_lines" && \
   test "$source_linked_records" -eq "$expected_meaningful_lines" && \
   test "$unsupported_records" -eq 1 && test "$diagnostic_records" -eq 1 && \
   test "$diagnostic_provenance" -eq 1; then
    target_boundary="lossless_complete_source_acceptance_validated"
else
    target_boundary="verification_failure_lossless_complete_source_acceptance"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'corpus_files\t%s\n' "$corpus_files" >>"$outdir/summary.tsv"
printf 'expected_meaningful_lines\t%s\n' "$expected_meaningful_lines" >>"$outdir/summary.tsv"
printf 'accepted_records\t%s\n' "$accepted_records" >>"$outdir/summary.tsv"
printf 'source_linked_records\t%s\n' "$source_linked_records" >>"$outdir/summary.tsv"
printf 'unsupported_records\t%s\n' "$unsupported_records" >>"$outdir/summary.tsv"
printf 'diagnostic_records\t%s\n' "$diagnostic_records" >>"$outdir/summary.tsv"
printf 'diagnostic_provenance\t%s\n' "$diagnostic_provenance" >>"$outdir/summary.tsv"
printf 'complete_file_mismatches\t%s\n' "$complete_file_mismatches" >>"$outdir/summary.tsv"
printf 'gfortran_accepted\t%s\n' "$gfortran_accepted" >>"$outdir/summary.tsv"
if test "$gfortran_mutation_status" -ne 0; then
    printf 'gfortran_mutation_rejected\t1\n' >>"$outdir/summary.tsv"
else
    printf 'gfortran_mutation_rejected\t0\n' >>"$outdir/summary.tsv"
fi
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'complete_module_sha256\t%s\n' "$(sha256sum "$complete_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'generated_parser_sha256\t%s\n' "$(sha256sum "$outdir/generated_lossless_complete_source_acceptance.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'test_program_sha256\t%s\n' "$(sha256sum "$outdir/test_generated_lossless_complete_source_acceptance.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'predecessor_summary_sha256\t%s\n' "$expected_e61_summary_sha256" >>"$outdir/summary.tsv"

printf 'E0068 oracle: lossless complete-source acceptance operation completed\n'
cat "$outdir/summary.tsv"
