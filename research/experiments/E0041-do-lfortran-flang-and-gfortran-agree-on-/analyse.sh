#!/usr/bin/env bash
# Compare parser/frontend behavior on a fixed, generated fixture matrix.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
outdir="${1:-$root/.cache/runs/E0041/R000001}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

standard="${STANDARD_NEW:-$root/../standard-new}"
lfortran_repo="${LFORTRAN_ORACLE:-$root/../lazy-fortran/lfortran}"
flang_repo="${FLANG_ORACLE:-$root/../llvm-project}"
gcc_repo="${GCC_ORACLE:-$root/../lazy-fortran/gcc}"
lfortran_bin="${LFORTRAN_BIN:-lfortran}"
flang_bin="${FLANG_BIN:-flang-new}"
gfortran_bin="${GFORTRAN_BIN:-gfortran}"

verify_head() {
    local repo="$1" expected="$2"
    git -C "$repo" cat-file -e "$expected^{commit}"
    test "$(git -C "$repo" rev-parse HEAD)" = "$(git -C "$repo" rev-parse "$expected")"
}

git -C "$root" cat-file -e 4f063c8^{commit}
verify_head "$standard" 531e590
verify_head "$lfortran_repo" caf87b6
verify_head "$flang_repo" cff4ca2
verify_head "$gcc_repo" 395e3d8
command -v "$lfortran_bin" >/dev/null
command -v "$flang_bin" >/dev/null
command -v "$gfortran_bin" >/dev/null

cases="$tmp/cases"
diagnostics="$outdir/diagnostics"
mkdir -p "$cases" "$diagnostics" "$outdir"

write_case() {
    local name="$1"
    case "$name" in
        minimal-program)
            printf '%s\n' 'program p' 'end program p' >"$cases/$name.f90" ;;
        module-use)
            printf '%s\n' 'module m' '  implicit none' '  integer :: x = 1' \
                'end module m' 'program p' '  use m, only: x' '  print *, x' \
                'end program p' >"$cases/$name.f90" ;;
        derived-type)
            printf '%s\n' 'module m' '  type :: point' '    real :: x, y' \
                '  end type point' 'end module m' >"$cases/$name.f90" ;;
        interface-block)
            printf '%s\n' 'module m' '  interface' '    subroutine s(x)' \
                '      integer, intent(in) :: x' '    end subroutine s' \
                '  end interface' 'end module m' >"$cases/$name.f90" ;;
        array-section)
            printf '%s\n' 'program p' '  integer :: a(5) = [1, 2, 3, 4, 5]' \
                '  print *, a(2:5:2)' 'end program p' >"$cases/$name.f90" ;;
        do-concurrent)
            printf '%s\n' 'program p' '  integer :: i' \
                '  do concurrent (i = 1:3)' '  end do' \
                'end program p' >"$cases/$name.f90" ;;
        select-rank)
            printf '%s\n' 'subroutine p(x)' '  integer :: x(..)' \
                '  select rank (x)' '  rank (0)' '  rank default' \
                '  end select' 'end subroutine p' >"$cases/$name.f90" ;;
        coarray-declaration)
            printf '%s\n' 'program p' '  integer :: x[*]' '  sync all' \
                'end program p' >"$cases/$name.f90" ;;
        invalid-unclosed-program)
            printf '%s\n' 'program p' '  integer :: x' >"$cases/$name.f90" ;;
        invalid-expression)
            printf '%s\n' 'program p' '  integer :: x = (1 + )' \
                'end program p' >"$cases/$name.f90" ;;
        *)
            printf 'unknown fixture: %s\n' "$name" >&2
            return 1 ;;
    esac
}

case_names=(
    minimal-program module-use derived-type interface-block array-section
    do-concurrent select-rank coarray-declaration invalid-unclosed-program
    invalid-expression
)
for name in "${case_names[@]}"; do
    write_case "$name"
done

run_compiler() {
    local compiler="$1" case_name="$2" source="$3" diagnostic="$4"
    shift 4
    set +e
    "$compiler" "$@" "$source" >"$diagnostic" 2>&1
    local status=$?
    set -e
    local accepted=0
    if [ "$status" -eq 0 ]; then accepted=1; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$case_name" "$compiler" "$status" "$accepted" "$diagnostic" \
        >>"$outdir/matrix.tsv"
}

printf 'case\tcompiler\tstatus\taccepted\tdiagnostic\n' >"$outdir/matrix.tsv"
for name in "${case_names[@]}"; do
    source="$cases/$name.f90"
    run_compiler "$lfortran_bin" "$name" "$source" \
        "$diagnostics/$name.lfortran.log" --std f23 --show-ast
    run_compiler "$flang_bin" "$name" "$source" \
        "$diagnostics/$name.flang.log" -fsyntax-only
    if [ "$name" = coarray-declaration ]; then
        run_compiler "$gfortran_bin" "$name" "$source" \
            "$diagnostics/$name.gfortran.log" -std=f2023 -fsyntax-only -fcoarray=single
    else
        run_compiler "$gfortran_bin" "$name" "$source" \
            "$diagnostics/$name.gfortran.log" -std=f2023 -fsyntax-only
    fi
done

test "$(awk 'NR > 1 {count++} END {print count + 0}' "$outdir/matrix.tsv")" -eq 30
test "$(awk -F '\t' 'NR > 1 && ($3 == "" || $4 == "") {count++} END {print count + 0}' "$outdir/matrix.tsv")" -eq 0

{
    printf 'cases_declared\t10\n'
    printf 'compiler_invocations\t%s\n' "$(awk 'NR > 1 {n++} END {print n + 0}' "$outdir/matrix.tsv")"
    printf 'lfortran_accepted\t%s\n' "$(awk -F '\t' 'NR > 1 && $2 == "lfortran" && $4 == 1 {n++} END {print n + 0}' "$outdir/matrix.tsv")"
    printf 'flang_accepted\t%s\n' "$(awk -F '\t' 'NR > 1 && $2 == "flang-new" && $4 == 1 {n++} END {print n + 0}' "$outdir/matrix.tsv")"
    printf 'gfortran_accepted\t%s\n' "$(awk -F '\t' 'NR > 1 && $2 == "gfortran" && $4 == 1 {n++} END {print n + 0}' "$outdir/matrix.tsv")"
    awk -F '\t' '
        NR == 1 { next }
        { signature[$1] = signature[$1] "," $4; raw[$1] = raw[$1] "," $3; count[$1]++ }
        END {
            for (name in count) {
                if (count[name] != 3) missing++
                else if (signature[name] == ",0,0,0" || signature[name] == ",1,1,1") agree++
                else disagree++
                if (raw[name] != ",0,0,0" && raw[name] != ",1,1,1") raw_disagree++
            }
            printf "all_three_agree_cases\t%d\n", agree + 0
            printf "disagreement_cases\t%d\n", disagree + 0
            printf "raw_status_difference_cases\t%d\n", raw_disagree + 0
            printf "missing_results\t%d\n", missing + 0
        }
    ' "$outdir/matrix.tsv"
} >"$outdir/summary.tsv"

test "$(awk -F '\t' '$1 == "compiler_invocations" {print $2}' "$outdir/summary.tsv")" -eq 30
test "$(awk -F '\t' '$1 == "missing_results" {print $2}' "$outdir/summary.tsv")" -eq 0

printf 'lfortran_version\t%s\n' "$("$lfortran_bin" --version | head -n 1)" >>"$outdir/summary.tsv"
printf 'flang_version\t%s\n' "$("$flang_bin" --version | head -n 1)" >>"$outdir/summary.tsv"
printf 'gfortran_version\t%s\n' "$("$gfortran_bin" --version | head -n 1)" >>"$outdir/summary.tsv"
printf 'lfortran_repo_commit\t%s\n' "$(git -C "$lfortran_repo" rev-parse HEAD)" >>"$outdir/summary.tsv"
printf 'flang_repo_commit\t%s\n' "$(git -C "$flang_repo" rev-parse HEAD)" >>"$outdir/summary.tsv"
    printf 'gcc_repo_commit\t%s\n' "$(git -C "$gcc_repo" rev-parse HEAD)" >>"$outdir/summary.tsv"
    printf 'diagnostic_files\t%s\n' "$(find "$diagnostics" -type f | wc -l)" >>"$outdir/summary.tsv"

printf 'E0041 oracle: parser behavior matrix collected\n'
cat "$outdir/summary.tsv"
printf '\ncase/compiler/status matrix:\n'
cat "$outdir/matrix.tsv"
