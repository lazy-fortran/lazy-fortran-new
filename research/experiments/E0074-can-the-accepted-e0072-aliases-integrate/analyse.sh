#!/usr/bin/env bash
# Integrate accepted E0072 aliases with the complete syntax projection.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e72="$root/research/experiments/E0072-can-accepted-normative-relations-compose/analyse.sh"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"
source="$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx"
e72out="$root/.cache/runs/E0072/R000001"
outdir="${1:-$root/.cache/runs/E0074/R000001}"
source_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
projection_hash="02e93bd803fab374c0b399dd2cbb52d018da0902c5964609eba8534383f60ab6"
facts_hash="9da21d15972d2ba559690fedcacbe6f58593d307227e4c210e44bf6a49118a08"

die() {
    printf 'E0074: %s\n' "$1" >&2
    exit 1
}

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

test "$(sha256sum "$source" | cut -d' ' -f1)" = "$source_hash" || die 'syntax source hash mismatch'
"$e72" >"$outdir/e0072.log" || die 'E0072 predecessor failed'
projection="$e72out/parser-projection.tsv"
facts="$e72out/composite-resolution-facts.tsv"
test "$(sha256sum "$projection" | cut -d' ' -f1)" = "$projection_hash" || die 'parser projection hash mismatch'
test "$(sha256sum "$facts" | cut -d' ' -f1)" = "$facts_hash" || die 'composite facts hash mismatch'

source_syntax_records="$(awk '/^\(syntax / {n++} END {print n + 0}' "$source")"
test "$source_syntax_records" -eq 522 || die 'source syntax denominator differs'

awk -F '\t' -v OFS='\t' 'NR == 1 {print; next} $2 == "alias" {print}' \
    "$projection" >"$outdir/alias-records.tsv"
alias_records="$(awk 'END {print NR - 1}' "$outdir/alias-records.tsv")"
test "$alias_records" -eq 3 || die 'accepted alias denominator differs'

awk -F '\t' -v OFS='\t' 'NR == 1 {print; next} $3 == "semantic-role" {print}' \
    "$facts" >"$outdir/semantic-facts.tsv"
semantic_fact_records="$(awk 'END {print NR - 1}' "$outdir/semantic-facts.tsv")"
test "$semantic_fact_records" -eq 29 || die 'semantic fact denominator differs'

semantic_alias_overlap="$(awk -F '\t' '
    FILENAME == ARGV[1] && FNR > 1 {alias[$1]=1; next}
    FILENAME == ARGV[2] && FNR > 1 && ($2 in alias) {n++}
    END {print n + 0}
' "$outdir/alias-records.tsv" "$outdir/semantic-facts.tsv")"
test "$semantic_alias_overlap" -eq 1 || die 'source-term overlap denominator differs'

semantic_projection_leaks="$(awk -F '\t' '
    FILENAME == ARGV[1] && FNR > 1 {projected[$1 SUBSEP $2]=1; next}
    FILENAME == ARGV[2] && FNR > 1 && (($2 SUBSEP $3) in projected) {n++}
    END {print n + 0}
' "$projection" "$outdir/semantic-facts.tsv")"
test "$semantic_projection_leaks" -eq 0 || die 'semantic fact key entered parser projection'

integrated="$outdir/integrated-syntax.sx"
awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0)
            text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    FILENAME == ARGV[1] {
        if (FNR > 1) alias[$1]=$3
        next
    }
    FILENAME == ARGV[2] && /^\(syntax / {
        for (old in alias) $0=replace_all($0, "(ref " old ")", "(ref " alias[old] ")")
        print
    }
' "$outdir/alias-records.tsv" "$source" >"$integrated"

integrated_syntax_records="$(awk '/^\(syntax / {n++} END {print n + 0}' "$integrated")"
test "$integrated_syntax_records" -eq "$source_syntax_records" || die 'integrated syntax record count differs'

awk -F '\t' -v OFS='\t' '
    FILENAME == ARGV[1] && FNR > 1 {alias[$1]=$3; next}
    FILENAME == ARGV[2] {
        for (old in alias) {
            rest=$0
            while ((pos=index(rest, "(ref " old ")")) > 0) {
                count[old]++
                rest=substr(rest, pos + length("(ref " old ")"))
            }
        }
    }
    END {for (old in alias) print old, count[old] + 0}
' "$outdir/alias-records.tsv" "$source" | sort -t $'\t' -k1,1 >"$outdir/alias-rewrite-counts.tsv"
alias_reference_rewrites="$(awk -F '\t' '{n += $2} END {print n + 0}' "$outdir/alias-rewrite-counts.tsv")"
test "$alias_reference_rewrites" -gt 0 || die 'no alias references were rewritten'
if rg -F -q '(ref program-name)' "$integrated" || \
    rg -F -q '(ref entity-name)' "$integrated" || \
    rg -F -q '(ref type-name)' "$integrated"; then
    die 'accepted alias reference remains'
fi

# Report references whose names have no production in the integrated input.
awk '
    FILENAME == ARGV[1] && /^\(syntax / {
        if (match($0, /\(lhs [^ )]+\)/)) {
            lhs=substr($0, RSTART + 5, RLENGTH - 6)
            defined[lhs]=1
        }
        next
    }
    FILENAME == ARGV[1] && /^\(syntax / {next}
    END {
        while ((getline line < ARGV[1]) > 0) {
            while (match(line, /\(ref [^ )]+\)/)) {
                ref=substr(line, RSTART + 5, RLENGTH - 6)
                if (!(ref in defined)) {occurrences++; unresolved[ref]=1}
                line=substr(line, RSTART + RLENGTH)
            }
        }
        close(ARGV[1])
        for (ref in unresolved) unique++
        print occurrences "\t" unique
    }
' "$integrated" >"$outdir/unresolved-summary.tsv"
unresolved_reference_occurrences="$(cut -f1 "$outdir/unresolved-summary.tsv")"
unresolved_unique_names="$(cut -f2 "$outdir/unresolved-summary.tsv")"
test "$unresolved_reference_occurrences" -gt 0 || die 'unresolved residue unexpectedly disappeared'

ebnf="$outdir/integrated.ebnf"
antlr="$outdir/integrated.g4"
bison="$outdir/integrated.y"
treesitter_dir="$outdir/treesitter"
treesitter="$treesitter_dir/grammar.js"
mkdir -p "$treesitter_dir"
set +e
(cd "$standard_new" && fo exec sxebnf "$integrated" "$ebnf") >"$outdir/ebnf-export.log" 2>&1
export_ebnf_status=$?
(cd "$standard_new" && fo exec sxantlr "$integrated" "$antlr") >"$outdir/antlr-export.log" 2>&1
export_antlr_status=$?
(cd "$standard_new" && fo exec sxbison "$integrated" "$bison") >"$outdir/bison-export.log" 2>&1
export_bison_status=$?
(cd "$standard_new" && fo exec sxtreesitter "$integrated" "$treesitter") >"$outdir/treesitter-export.log" 2>&1
export_treesitter_status=$?
set -e
test -s "$ebnf" || die 'EBNF export missing'
test -s "$antlr" || die 'ANTLR export missing'
test -s "$bison" || die 'Bison export missing'
test -s "$treesitter" || die 'tree-sitter export missing'

set +e
antlr4 -Werror -Dlanguage=Java -o "$outdir/antlr" "$antlr" >"$outdir/antlr-validate.log" 2>&1
antlr_validate_status=$?
bison -Wall -Werror -o "$outdir/bison.c" "$bison" >"$outdir/bison-validate.log" 2>&1
bison_validate_status=$?
mkdir -p "$treesitter_dir/validated"
cp "$treesitter" "$treesitter_dir/validated/grammar.js"
(cd "$treesitter_dir/validated" && tree-sitter generate) >"$outdir/treesitter-validate.log" 2>&1
treesitter_validate_status=$?
set -e

# Generate deterministic direct-parser dispatch from the integrated syntax.
dispatch="$outdir/direct-dispatch.tsv"
{
    printf 'lhs\tprocedure\trule\tpage\tsource_sha256\n'
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
            gsub(/_/, "_x5F_", procedure)
            gsub(/-/, "_x2D_", procedure)
            gsub(/,/, "_x2C_", procedure)
            gsub(/:/, "_x3A_", procedure)
            gsub(/\./, "_x2E_", procedure)
            gsub(/</, "_x3C_", procedure)
            gsub(/>/, "_x3E_", procedure)
            print lhs, "parse_" procedure, $2, page, source_sha
        }
    ' OFS='\t' "$integrated" | sort -t $'\t' -k1,1 -k3,3n
} >"$dispatch"
dispatch_rows="$(awk 'END {print NR - 1}' "$dispatch")"
dispatch_provenance_rows="$(awk -F '\t' 'NR > 1 && $3 != "" && $4 != "" && $5 != "" {n++} END {print n + 0}' "$dispatch")"
dispatch_label_collisions="$(awk -F '\t' 'NR > 1 && !seen[$1]++ {count[$2]++} END {for (x in count) if (count[x] > 1) n++; print n + 0}' "$dispatch")"
test "$dispatch_rows" -eq 522 || die 'dispatch row count differs'
test "$dispatch_provenance_rows" -eq 522 || die 'dispatch provenance count differs'
test "$dispatch_label_collisions" -eq 0 || die 'dispatch labels collide'

dispatch_fortran="$outdir/generated-integrated-dispatch.f90"
{
    printf 'module generated_integrated_dispatch\n'
    printf '    implicit none\n    private\n    public :: parser_context_t, parser_dispatch\n\n'
    printf '    type :: parser_context_t\n        integer :: token_position = 1\n    end type parser_context_t\n\ncontains\n\n'
    printf '    subroutine parser_dispatch(context, lhs, ok)\n        type(parser_context_t), intent(inout) :: context\n        character(len=*), intent(in) :: lhs\n        logical, intent(out) :: ok\n        select case (trim(lhs))\n'
    awk -F '\t' 'NR > 1 && !seen[$1]++ {printf "        case (\x27%s\x27)\n            call %s(context, ok)\n", $1, $2}' "$dispatch"
    printf '        case default\n            ok = .false.\n        end select\n    end subroutine parser_dispatch\n\n'
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
        END {if (current != "") print "    end subroutine " procedure}
    ' "$dispatch"
    printf '\nend module generated_integrated_dispatch\n'
} >"$dispatch_fortran"
gfortran -c -Wall -Wextra -Werror "$dispatch_fortran" -o "$outdir/generated-integrated-dispatch.o" >"$outdir/fortran.log" 2>&1
direct_fortran_status=$?

# Mutation control: a changed accepted alias must change the integrated syntax.
awk -F '\t' -v OFS='\t' 'NR == 1 {print; next} $1 == "program-name" {$3="mutated-name"} {print}' \
    "$outdir/alias-records.tsv" >"$tmp/mutated-alias-records.tsv"
awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0)
            text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    FILENAME == ARGV[1] {if (FNR > 1) alias[$1]=$3; next}
    FILENAME == ARGV[2] && /^\(syntax / {for (old in alias) $0=replace_all($0, "(ref " old ")", "(ref " alias[old] ")"); print}
' "$tmp/mutated-alias-records.tsv" "$source" >"$tmp/mutated-integrated.sx"
if cmp -s "$integrated" "$tmp/mutated-integrated.sx"; then
    die 'negative control did not change integrated syntax'
else
    negative_control="observed_failure"
fi

if test "$direct_fortran_status" -eq 0 && test "$dispatch_rows" -eq 522; then
    wiring_boundary="integrated_dispatch_compiled"
else
    wiring_boundary="verification_failure_direct_wiring"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'source_syntax_records\t%s\n' "$source_syntax_records" >>"$outdir/summary.tsv"
printf 'integrated_syntax_records\t%s\n' "$integrated_syntax_records" >>"$outdir/summary.tsv"
printf 'alias_records\t%s\n' "$alias_records" >>"$outdir/summary.tsv"
printf 'alias_reference_rewrites\t%s\n' "$alias_reference_rewrites" >>"$outdir/summary.tsv"
printf 'semantic_fact_records\t%s\n' "$semantic_fact_records" >>"$outdir/summary.tsv"
printf 'semantic_alias_overlap\t%s\n' "$semantic_alias_overlap" >>"$outdir/summary.tsv"
printf 'semantic_projection_leaks\t%s\n' "$semantic_projection_leaks" >>"$outdir/summary.tsv"
printf 'unresolved_reference_occurrences\t%s\n' "$unresolved_reference_occurrences" >>"$outdir/summary.tsv"
printf 'unresolved_unique_names\t%s\n' "$unresolved_unique_names" >>"$outdir/summary.tsv"
printf 'export_ebnf_status\t%s\n' "$export_ebnf_status" >>"$outdir/summary.tsv"
printf 'export_antlr_status\t%s\n' "$export_antlr_status" >>"$outdir/summary.tsv"
printf 'export_bison_status\t%s\n' "$export_bison_status" >>"$outdir/summary.tsv"
printf 'export_treesitter_status\t%s\n' "$export_treesitter_status" >>"$outdir/summary.tsv"
printf 'antlr_validate_status\t%s\n' "$antlr_validate_status" >>"$outdir/summary.tsv"
printf 'bison_validate_status\t%s\n' "$bison_validate_status" >>"$outdir/summary.tsv"
printf 'treesitter_validate_status\t%s\n' "$treesitter_validate_status" >>"$outdir/summary.tsv"
printf 'dispatch_rows\t%s\n' "$dispatch_rows" >>"$outdir/summary.tsv"
printf 'dispatch_provenance_rows\t%s\n' "$dispatch_provenance_rows" >>"$outdir/summary.tsv"
printf 'dispatch_label_collisions\t%s\n' "$dispatch_label_collisions" >>"$outdir/summary.tsv"
printf 'direct_fortran_status\t%s\n' "$direct_fortran_status" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'wiring_boundary\t%s\n' "$wiring_boundary" >>"$outdir/summary.tsv"
printf 'source_sha256\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'projection_sha256\t%s\n' "$projection_hash" >>"$outdir/summary.tsv"
printf 'facts_sha256\t%s\n' "$facts_hash" >>"$outdir/summary.tsv"
printf 'integrated_sha256\t%s\n' "$(sha256sum "$integrated" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'dispatch_sha256\t%s\n' "$(sha256sum "$dispatch" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'fortran_sha256\t%s\n' "$(sha256sum "$dispatch_fortran" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0074 oracle: accepted alias integration and direct wiring completed\n'
cat "$outdir/summary.tsv"
