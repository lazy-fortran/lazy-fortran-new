#!/usr/bin/env bash
# Generate and execute source-linked diagnostic lookup from composite SX.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e55="$root/research/experiments/E0055-can-accepted-projection-decisions-produc/analyse.sh"
e57="$root/research/experiments/E0057-can-accepted-composite-standardir-emit-a/analyse.sh"
composite="$root/.cache/runs/E0055/R000001/composite-input.sx"
outdir="${1:-$root/.cache/runs/E0058/R000001}"
expected_composite_sha256="3458da1debda9aff98974b720891af4426c0506905f58317e018854f8cd9b3eb"
expected_dispatch_sha256="c5a1aa1d2bcf0aa6e475b5f61ca11d80fa6ccc0138e144de2db7eb400993c2a0"

die() { printf 'E0058: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e55" >"$outdir/e0055.log" || die 'E0055 predecessor failed'
"$e57" >"$outdir/e0057.log" || die 'E0057 predecessor failed'
test "$(sha256sum "$composite" | cut -d' ' -f1)" = "$expected_composite_sha256" || \
    die 'composite input hash mismatch'
test "$(sha256sum "$root/.cache/runs/E0057/R000001/direct-parser-dispatch.tsv" | cut -d' ' -f1)" = "$expected_dispatch_sha256" || \
    die 'dispatch input hash mismatch'

extract_sources() {
    local input=$1 output=$2
    {
        printf 'lhs\trule\tpage\tbyte_start\tbyte_length\tsource_sha256\n'
        awk '
            function value(pattern, offset, drop) {
                if (!match($0, pattern)) return ""
                return substr($0, RSTART + offset, RLENGTH - drop)
            }
            /^\(syntax / {
                lhs=value("\\(lhs [^ )]+", 5, 5)
                page=value("\\(page [0-9]+\\)", 6, 7)
                byte_start=value("\\(byte-start [0-9]+\\)", 12, 13)
                byte_length=value("\\(byte-length [0-9]+\\)", 13, 14)
                source_sha=value("\\(source-sha256 [^)]+\\)", 15, 16)
                print lhs, $2, page, byte_start, byte_length, source_sha
            }
        ' OFS='\t' "$input"
    } >"$output"
}

extract_sources "$composite" "$outdir/diagnostic-source.tsv"
diagnostic_rows="$(awk 'NR > 1 {n++} END {print n + 0}' "$outdir/diagnostic-source.tsv")"
source_span_rows="$(awk -F '\t' 'NR > 1 && $3 != "" && $4 != "" && $5 != "" && $6 != "" {n++} END {print n + 0}' \
    "$outdir/diagnostic-source.tsv")"
test "$diagnostic_rows" -eq 519 || die 'diagnostic row count differs'
test "$source_span_rows" -eq 519 || die 'source span coverage differs'

{
    printf 'module generated_parser_diagnostics\n'
    printf '    use, intrinsic :: iso_fortran_env, only: int64\n'
    printf '    implicit none\n'
    printf '    private\n'
    printf '    public :: parser_source_ref_t, lookup_source\n\n'
    printf '    type :: parser_source_ref_t\n'
    printf '        character(len=63) :: lhs = ""\n'
    printf '        character(len=16) :: rule = ""\n'
    printf '        integer :: page = 0\n'
    printf '        integer(int64) :: byte_start = 0_int64\n'
    printf '        integer(int64) :: byte_length = 0_int64\n'
    printf '        character(len=64) :: source_sha256 = ""\n'
    printf '    end type parser_source_ref_t\n\n'
    printf '    integer, parameter :: source_count = %s\n' "$diagnostic_rows"
    printf '    type(parser_source_ref_t), parameter :: source_refs(source_count) = [ &\n'
    awk -F '\t' 'NR > 1 {
        suffix = (NR < 520) ? ", &" : " &"
        printf "        parser_source_ref_t( &\n            \x27%s\x27, \x27%s\x27, %s, %s_int64, %s_int64, &\n            \x27%s\x27)%s\n", $1, $2, $3, $4, $5, $6, suffix
    }' "$outdir/diagnostic-source.tsv"
    printf '    ]\n\n'
    printf 'contains\n\n'
    printf '    subroutine lookup_source(lhs, rule, reference, found)\n'
    printf '        character(len=*), intent(in) :: lhs, rule\n'
    printf '        type(parser_source_ref_t), intent(out) :: reference\n'
    printf '        logical, intent(out) :: found\n'
    printf '        integer :: i\n'
    printf '        reference = parser_source_ref_t()\n'
    printf '        found = .false.\n'
    printf '        do i = 1, source_count\n'
    printf '            if (trim(source_refs(i)%%lhs) == trim(lhs) .and. &\n'
    printf '                trim(source_refs(i)%%rule) == trim(rule)) then\n'
    printf '                reference = source_refs(i)\n'
    printf '                found = .true.\n'
    printf '                return\n'
    printf '            end if\n'
    printf '        end do\n'
    printf '    end subroutine lookup_source\n\n'
    printf 'end module generated_parser_diagnostics\n'
} >"$outdir/generated_parser_diagnostics.f90"

cat >"$outdir/test_generated_parser_diagnostics.f90" <<'EOF'
program test_generated_parser_diagnostics
    use, intrinsic :: iso_fortran_env, only: int64
    use generated_parser_diagnostics, only: parser_source_ref_t, lookup_source
    implicit none

    type(parser_source_ref_t) :: reference
    logical :: found

    call lookup_source('program', 'R501', reference, found)
    if (.not. found) error stop 'known source lookup failed'
    if (reference%page /= 53) error stop 'known page differs'
    if (reference%byte_start /= 138571_int64) error stop 'known byte start differs'
    if (reference%byte_length /= 53_int64) error stop 'known byte length differs'
    if (trim(reference%source_sha256) /= &
            '7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2') &
        error stop 'known source hash differs'

    call lookup_source('unknown', 'R999', reference, found)
    if (found) error stop 'unknown source lookup was accepted'
    print '(a)', 'source-linked diagnostic lookup passed'
end program test_generated_parser_diagnostics
EOF

set +e
gfortran -ffree-line-length-none -Wall -Wextra -Werror \
    "$outdir/generated_parser_diagnostics.f90" \
    "$outdir/test_generated_parser_diagnostics.f90" \
    -o "$outdir/test_generated_parser_diagnostics" \
    >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
if test "$fortran_compile_status" -eq 0; then
    "$outdir/test_generated_parser_diagnostics" >"$outdir/runtime.log" 2>&1
    runtime_test_status=$?
else
    runtime_test_status=1
fi
set -e

sed '1s/byte-start 138571/byte-start 138572/' "$composite" >"$tmp/mutated-composite.sx"
extract_sources "$tmp/mutated-composite.sx" "$tmp/mutated-diagnostic-source.tsv"
if cmp -s "$outdir/diagnostic-source.tsv" "$tmp/mutated-diagnostic-source.tsv"; then
    die 'negative control did not change diagnostic witness'
else
    negative_control="observed_failure"
fi

known_lookup=0
unknown_lookup_rejected=0
if test "$fortran_compile_status" -eq 0 && test "$runtime_test_status" -eq 0; then
    known_lookup=1
    unknown_lookup_rejected=1
fi
if test "$known_lookup" -eq 1 && test "$unknown_lookup_rejected" -eq 1; then
    target_boundary="source_linked_lookup_compiled_and_tested"
else
    target_boundary="verification_failure_diagnostic_lookup"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'composite_syntax_records\t%s\n' "$diagnostic_rows" >>"$outdir/summary.tsv"
printf 'diagnostic_rows\t%s\n' "$diagnostic_rows" >>"$outdir/summary.tsv"
printf 'source_span_rows\t%s\n' "$source_span_rows" >>"$outdir/summary.tsv"
printf 'known_lookup\t%s\n' "$known_lookup" >>"$outdir/summary.tsv"
printf 'unknown_lookup_rejected\t%s\n' "$unknown_lookup_rejected" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'runtime_test_status\t%s\n' "$runtime_test_status" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'source_composite_sha256\t%s\n' "$expected_composite_sha256" >>"$outdir/summary.tsv"
printf 'diagnostic_sha256\t%s\n' "$(sha256sum "$outdir/diagnostic-source.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'generated_module_sha256\t%s\n' "$(sha256sum "$outdir/generated_parser_diagnostics.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0058 oracle: source-linked diagnostic lookup completed\n'
cat "$outdir/summary.tsv"
