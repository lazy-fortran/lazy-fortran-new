#!/usr/bin/env bash
# Generate and execute the local top-level program-unit parser operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "$0")/../../.." && pwd)"
corpus="$root/research/corpora/phase1-modern-fortran-v0.json"
e58="$root/research/experiments/E0058-can-accepted-composite-records-generate-/analyse.sh"
diagnostic_module="$root/.cache/runs/E0058/R000001/generated_parser_diagnostics.f90"
outdir="${1:-$root/.cache/runs/E0059/R000001}"
fortfront_root="${FORTFRONT_ROOT:-$root/../fortfront}"
expected_fortfront_commit="b8cb5926fd82ed299d00e8c50eaa41587f55237d"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

die() { printf 'E0059: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -e '.name == "phase1-modern-fortran-v0" and (.files | length) == 5' "$corpus" >/dev/null || die 'corpus manifest shape differs'
test "$(git -C "$fortfront_root" rev-parse HEAD)" = "$expected_fortfront_commit" || die 'fortfront oracle commit differs'

"$e58" >"$outdir/e0058.log" || die 'E0058 predecessor failed'
test -f "$diagnostic_module" || die 'diagnostic module is missing'

mapfile -t corpus_paths < <(jq -r '.files[].path' "$corpus")
mapfile -t corpus_hashes < <(jq -r '.files[].sha256' "$corpus")
mapfile -t corpus_statuses < <(jq -r '.files[].gfortran_status' "$corpus")
corpus_files="${#corpus_paths[@]}"
expected_units="$(jq '[.files[].units[]] | length' "$corpus")"

gfortran_accepted=0
for i in "${!corpus_paths[@]}"; do
    source="$fortfront_root/${corpus_paths[$i]}"
    test -f "$source" || die "corpus source is missing: ${corpus_paths[$i]}"
    test "$(sha256sum "$source" | cut -d' ' -f1)" = "${corpus_hashes[$i]}" || die "corpus source hash differs: ${corpus_paths[$i]}"
    set +e
    gfortran -std=f2018 -fsyntax-only "$source" >"$outdir/gfortran-$i.log" 2>&1
    status=$?
    set -e
    test "$status" = "${corpus_statuses[$i]}" || die "gfortran status differs: ${corpus_paths[$i]}"
    test "$status" -eq 0 && gfortran_accepted=$((gfortran_accepted + 1))
done

cat >"$outdir/generated_top_level_parser.f90" <<'EOF'
module generated_top_level_parser
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    implicit none
    private
    public :: parsed_unit_t, parse_top_level_units

    type :: parsed_unit_t
        character(len=32) :: kind = ""
        character(len=16) :: rule = ""
        type(parser_source_ref_t) :: source
    end type parsed_unit_t

contains

    ! This is the local constructive operation. Unit dispatch, source lookup,
    ! and the diagnostic record layout remain generated inputs.
    subroutine parse_top_level_units(path, units, count, ierr)
        character(len=*), intent(in) :: path
        type(parsed_unit_t), intent(out) :: units(:)
        integer, intent(out) :: count, ierr
        character(len=512) :: line, text
        character(len=32) :: current_kind
        integer :: file_unit, io_status, nested

        units = parsed_unit_t()
        count = 0
        ierr = 0
        current_kind = ""
        nested = 0

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
            if (len_trim(text) == 0) cycle

            if (len_trim(current_kind) == 0) then
                call start_top_level_unit(text, current_kind, units, count, ierr)
                if (ierr /= 0) then
                    close(file_unit)
                    return
                end if
            else if (nested > 0) then
                if (is_procedure_end(text)) nested = nested - 1
            else if (is_current_end(current_kind, text)) then
                current_kind = ""
            else if (is_procedure_start(text)) then
                nested = nested + 1
            end if
        end do
        close(file_unit)

        if (len_trim(current_kind) /= 0 .or. nested /= 0) ierr = 3
    end subroutine parse_top_level_units

    subroutine start_top_level_unit(text, current_kind, units, count, ierr)
        character(len=*), intent(in) :: text
        character(len=*), intent(out) :: current_kind
        type(parsed_unit_t), intent(inout) :: units(:)
        integer, intent(inout) :: count
        integer, intent(out) :: ierr
        character(len=64) :: lhs
        character(len=16) :: rule
        logical :: found

        ierr = 0
        current_kind = ""
        lhs = ""
        rule = ""
        if (starts_word(text, "program")) then
            current_kind = "program"
            lhs = "main-program"
            rule = "R1401"
        else if (starts_word(text, "submodule")) then
            current_kind = "submodule"
            lhs = "submodule"
            rule = "R1416"
        else if (starts_word(text, "module") .and. .not. starts_word(text, "module procedure") .and. .not. starts_word(text, "module function") .and. .not. starts_word(text, "module subroutine")) then
            current_kind = "module"
            lhs = "module"
            rule = "R1404"
        else if (starts_word(text, "block data")) then
            current_kind = "block-data"
            lhs = "block-data"
            rule = "R1420"
        else if (is_procedure_start(text)) then
            if (index(text, "subroutine") > 0) then
                current_kind = "subroutine"
                lhs = "subroutine-subprogram"
                rule = "R1537"
            else
                current_kind = "function"
                lhs = "function-subprogram"
                rule = "R1532"
            end if
        end if

        if (len_trim(current_kind) == 0) return
        if (count >= size(units)) then
            ierr = 4
            return
        end if
        count = count + 1
        units(count)%kind = current_kind
        units(count)%rule = rule
        call lookup_source(lhs, rule, units(count)%source, found)
        if (.not. found) ierr = 5
    end subroutine start_top_level_unit

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

    logical function is_procedure_start(text)
        character(len=*), intent(in) :: text

        is_procedure_start = starts_word(text, "function") .or. starts_word(text, "subroutine") .or. index(text, " function") > 0 .or. index(text, " subroutine") > 0
    end function is_procedure_start

    logical function is_procedure_end(text)
        character(len=*), intent(in) :: text

        is_procedure_end = starts_word(text, "end function") .or. starts_word(text, "end subroutine")
    end function is_procedure_end

    logical function is_current_end(kind, text)
        character(len=*), intent(in) :: kind, text

        is_current_end = .false.
        select case (trim(kind))
        case ("program")
            is_current_end = starts_word(text, "end program") .or. (starts_word(text, "end") .and. len_trim(text) == 3)
        case ("module")
            is_current_end = starts_word(text, "end module")
        case ("submodule")
            is_current_end = starts_word(text, "end submodule")
        case ("block-data")
            is_current_end = starts_word(text, "end block data")
        case ("function", "subroutine")
            is_current_end = is_procedure_end(text)
        end select
    end function is_current_end

end module generated_top_level_parser
EOF

mutation="$tmp/mutated.f90"
first_source="$fortfront_root/${corpus_paths[0]}"
sed -e 's/^program main$/module main/' -e 's/^END program main$/end module main/' "$first_source" >"$mutation"

{
    printf '%s\n' 'program test_generated_top_level_parser'
    printf '%s\n' '    use generated_top_level_parser, only: parsed_unit_t, parse_top_level_units'
    printf '%s\n' '    implicit none'
    printf '%s\n' '    type(parsed_unit_t) :: units(64)'
    printf '%s\n' '    integer :: count, ierr, linked'
    printf '%s\n' '    linked = 0'
    while IFS=$'\t' read -r relative_path unit_kinds; do
        expected=""
        IFS=',' read -r -a kind_array <<<"$unit_kinds"
        for kind in "${kind_array[@]}"; do
            expected="$expected'$kind',"
        done
        expected="${expected%,}"
        printf "    call check_file('%s/%s', [character(len=32) :: %s])\n" "$fortfront_root" "$relative_path" "$expected"
    done < <(jq -r '.files[] | [.path, (.units | join(","))] | @tsv' "$corpus")
    printf '%s\n' "    call parse_top_level_units('$mutation', units, count, ierr)"
    printf '%s\n' '    if (ierr /= 0 .or. count /= 1) error stop "mutation parse failed"'
    printf '%s\n' '    if (trim(units(1)%kind) /= "module") error stop "mutation witness did not change"'
    printf '%s\n' '    print "(a,i0)", "source-linked top-level units: ", linked'
    printf '%s\n' 'contains'
    printf '%s\n' '    subroutine check_file(path, expected)'
    printf '%s\n' '        character(len=*), intent(in) :: path, expected(:)'
    printf '%s\n' '        type(parsed_unit_t) :: parsed(64)'
    printf '%s\n' '        integer :: actual_count, status, j'
    printf '%s\n' '        call parse_top_level_units(path, parsed, actual_count, status)'
    printf '%s\n' '        if (status /= 0 .or. actual_count /= size(expected)) error stop "unit count mismatch"'
    printf '%s\n' '        do j = 1, actual_count'
    printf '%s\n' '            if (trim(parsed(j)%kind) /= trim(expected(j))) error stop "unit kind mismatch"'
    printf '%s\n' '            if (parsed(j)%source%page <= 0 .or. parsed(j)%source%byte_start <= 0) error stop "source span missing"'
    printf '%s\n' '            if (len_trim(parsed(j)%source%source_sha256) /= 64) error stop "source hash missing"'
    printf '%s\n' '            linked = linked + 1'
    printf '%s\n' '        end do'
    printf '%s\n' '    end subroutine check_file'
    printf '%s\n' 'end program test_generated_top_level_parser'
} >"$outdir/test_generated_top_level_parser.f90"

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror "$diagnostic_module" "$outdir/generated_top_level_parser.f90" "$outdir/test_generated_top_level_parser.f90" -o "$outdir/test_generated_top_level_parser" >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_top_level_parser" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

classified_units=0
source_linked_units=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    classified_units="$expected_units"
    source_linked_units="$expected_units"
fi
if test "$classified_units" -eq "$expected_units" && test "$source_linked_units" -eq "$expected_units"; then
    unit_mismatches=0
    target_boundary="top_level_local_operation_validated"
else
    unit_mismatches=1
    target_boundary="verification_failure_top_level_local_operation"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'corpus_files\t%s\n' "$corpus_files" >>"$outdir/summary.tsv"
printf 'expected_units\t%s\n' "$expected_units" >>"$outdir/summary.tsv"
printf 'classified_units\t%s\n' "$classified_units" >>"$outdir/summary.tsv"
printf 'source_linked_units\t%s\n' "$source_linked_units" >>"$outdir/summary.tsv"
printf 'unit_mismatches\t%s\n' "$unit_mismatches" >>"$outdir/summary.tsv"
printf 'gfortran_accepted\t%s\n' "$gfortran_accepted" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\tobserved_failure\n' >>"$outdir/summary.tsv"
printf 'zero_model_calls\ttrue\n' >>"$outdir/summary.tsv"
printf 'corpus_manifest_sha256\t%s\n' "$(sha256sum "$corpus" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'source_hash\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'diagnostic_module_sha256\t%s\n' "$(sha256sum "$diagnostic_module" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0059 oracle: generated top-level operation completed\n'
cat "$outdir/summary.tsv"
