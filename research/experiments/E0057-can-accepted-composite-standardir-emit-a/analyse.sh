#!/usr/bin/env bash
# Emit deterministic direct-parser dispatch wiring from accepted composite SX.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e55="$root/research/experiments/E0055-can-accepted-projection-decisions-produc/analyse.sh"
composite="$root/.cache/runs/E0055/R000001/composite-input.sx"
outdir="${1:-$root/.cache/runs/E0057/R000001}"
expected_composite_sha256="3458da1debda9aff98974b720891af4426c0506905f58317e018854f8cd9b3eb"

die() { printf 'E0057: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e55" >"$outdir/e0055.log" || die 'E0055 predecessor failed'
test "$(sha256sum "$composite" | cut -d' ' -f1)" = "$expected_composite_sha256" || \
    die 'E0055 composite hash mismatch'

source_records="$(awk '/^\(syntax / {n++} END {print n + 0}' \
    "$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx")"
composite_records="$(awk '/^\(syntax / {n++} END {print n + 0}' "$composite")"
test "$source_records" -eq 522 || die 'source syntax denominator differs'
test "$composite_records" -eq 519 || die 'composite syntax denominator differs'

extract_dispatch() {
    local input=$1 output=$2
    {
        printf 'lhs\tprocedure\trule\tpage\tsource_sha256\tsource_line\n'
        awk '
            function value(pattern, offset, drop) {
                if (!match($0, pattern)) return ""
                return substr($0, RSTART + offset, RLENGTH - drop)
            }
            /^\(syntax / {
                lhs=value("\\(lhs [^ )]+", 5, 5)
                page=value("\\(page [0-9]+\\)", 6, 7)
                source_sha=value("\\(source-sha256 [^)]+\\)", 15, 16)
                procedure=lhs
                gsub(/[^A-Za-z0-9_]/, "_", procedure)
                print lhs, "parse_" procedure, $2, page, source_sha, NR
            }
        ' OFS='\t' "$input" | sort -t $'\t' -k1,1 -k6,6n
    } >"$output"
}

extract_dispatch "$composite" "$outdir/direct-parser-dispatch.tsv"

dispatch_rows="$(awk 'NR > 1 {n++} END {print n + 0}' "$outdir/direct-parser-dispatch.tsv")"
unique_lhs="$(awk -F '\t' 'NR > 1 {seen[$1]=1} END {for (x in seen) n++; print n + 0}' \
    "$outdir/direct-parser-dispatch.tsv")"
duplicate_dispatch_labels="$(awk -F '\t' 'NR > 1 && !seen[$1]++ {procedures[$2]++} END {for (x in procedures) if (procedures[x] > 1) n++; print n + 0}' \
    "$outdir/direct-parser-dispatch.tsv")"
provenance_rows="$(awk -F '\t' 'NR > 1 && $3 != "" && $4 != "" && $5 != "" {n++} END {print n + 0}' \
    "$outdir/direct-parser-dispatch.tsv")"
unresolved_references="$(rg -c '\(ref xyz\)' "$composite" || true)"
unresolved_references="${unresolved_references:-0}"
test "$dispatch_rows" -eq "$composite_records" || die 'dispatch row count differs'
test "$unique_lhs" -eq 499 || die 'unique lhs count differs'
test "$duplicate_dispatch_labels" -eq 0 || die 'dispatch labels collide'
test "$provenance_rows" -eq "$dispatch_rows" || die 'provenance row count differs'
test "$unresolved_references" -eq 0 || die 'typed unresolved reference remains'

{
    printf 'module generated_direct_parser_dispatch\n'
    printf '    implicit none\n'
    printf '    private\n'
    printf '    public :: parser_context_t, parser_dispatch\n\n'
    printf '    type :: parser_context_t\n'
    printf '        integer :: token_position = 1\n'
    printf '    end type parser_context_t\n\n'
    printf 'contains\n\n'
    printf '    subroutine parser_dispatch(context, lhs, ok)\n'
    printf '        type(parser_context_t), intent(inout) :: context\n'
    printf '        character(len=*), intent(in) :: lhs\n'
    printf '        logical, intent(out) :: ok\n'
    printf '        select case (trim(lhs))\n'
    awk -F '\t' 'NR > 1 && !seen[$1]++ {printf "        case (\x27%s\x27)\n            call %s(context, ok)\n", $1, $2}' \
        "$outdir/direct-parser-dispatch.tsv"
    printf '        case default\n'
    printf '            ok = .false.\n'
    printf '        end select\n'
    printf '    end subroutine parser_dispatch\n\n'
    awk -F '\t' '
        NR == 1 {next}
        $1 != current {
            if (current != "") print "    end subroutine " procedure
            current=$1
            procedure=$2
            printf "    ! StandardIR lhs %s\n    subroutine %s(context, ok)\n", current, procedure
            print "        type(parser_context_t), intent(inout) :: context"
            print "        logical, intent(out) :: ok"
            print "        if (context%token_position < 1) context%token_position = 1"
            print "        ok = .false."
            print "        ! Local implementation hole. Wiring is generated here."
        }
        {printf "        ! source rule %s, page %s, source-sha256 %s\n", $3, $4, $5}
        END {
            if (current != "") print "    end subroutine " procedure
        }
    ' "$outdir/direct-parser-dispatch.tsv"
    printf '\nend module generated_direct_parser_dispatch\n'
} >"$outdir/generated_direct_parser_dispatch.f90"

set +e
gfortran -c -Wall -Wextra -Werror \
    "$outdir/generated_direct_parser_dispatch.f90" \
    -o "$outdir/generated_direct_parser_dispatch.o" \
    >"$outdir/fortran.log" 2>&1
fortran_compile_status=$?
set -e

extract_dispatch "$composite" "$tmp/original-dispatch.tsv"
sed '1s/(lhs program)/(lhs program_mutated)/' "$composite" >"$tmp/mutated-composite.sx"
extract_dispatch "$tmp/mutated-composite.sx" "$tmp/mutated-dispatch.tsv"
if cmp -s "$tmp/original-dispatch.tsv" "$tmp/mutated-dispatch.tsv"; then
    die 'negative control did not change the dispatch witness'
else
    negative_control="observed_failure"
fi

if test "$fortran_compile_status" -eq 0; then
    target_boundary="wiring_skeleton_compiled"
else
    target_boundary="verification_failure_generated_wiring"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'source_syntax_records\t%s\n' "$source_records" >>"$outdir/summary.tsv"
printf 'composite_syntax_records\t%s\n' "$composite_records" >>"$outdir/summary.tsv"
printf 'unique_lhs\t%s\n' "$unique_lhs" >>"$outdir/summary.tsv"
printf 'dispatch_rows\t%s\n' "$dispatch_rows" >>"$outdir/summary.tsv"
printf 'generated_procedures\t%s\n' "$unique_lhs" >>"$outdir/summary.tsv"
printf 'duplicate_dispatch_labels\t%s\n' "$duplicate_dispatch_labels" >>"$outdir/summary.tsv"
printf 'provenance_rows\t%s\n' "$provenance_rows" >>"$outdir/summary.tsv"
printf 'unresolved_references\t%s\n' "$unresolved_references" >>"$outdir/summary.tsv"
printf 'fortran_compile_status\t%s\n' "$fortran_compile_status" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'source_composite_sha256\t%s\n' "$expected_composite_sha256" >>"$outdir/summary.tsv"
printf 'dispatch_sha256\t%s\n' "$(sha256sum "$outdir/direct-parser-dispatch.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'skeleton_sha256\t%s\n' "$(sha256sum "$outdir/generated_direct_parser_dispatch.f90" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0057 oracle: direct-parser wiring skeleton completed\n'
cat "$outdir/summary.tsv"
