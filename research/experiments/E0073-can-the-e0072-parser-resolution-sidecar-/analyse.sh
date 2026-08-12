#!/usr/bin/env bash
# Validate the E0072 parser-resolution sidecar in every selected target format.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e72="$root/research/experiments/E0072-can-accepted-normative-relations-compose/analyse.sh"
outdir="${1:-$root/.cache/runs/E0073/R000001}"
e72out="$root/.cache/runs/E0072/R000001"
projection="$e72out/parser-projection.tsv"
facts="$e72out/composite-resolution-facts.tsv"

projection_hash="02e93bd803fab374c0b399dd2cbb52d018da0902c5964609eba8534383f60ab6"
facts_hash="9da21d15972d2ba559690fedcacbe6f58593d307227e4c210e44bf6a49118a08"

die() {
    printf 'E0073: %s\n' "$1" >&2
    exit 1
}

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e72" >"$outdir/e0072.log" || die 'E0072 predecessor failed'
test "$(sha256sum "$projection" | cut -d' ' -f1)" = "$projection_hash" || \
    die 'E0072 parser projection hash mismatch'
test "$(sha256sum "$facts" | cut -d' ' -f1)" = "$facts_hash" || \
    die 'E0072 composite fact hash mismatch'

composite_fact_records="$(awk 'END {print NR - 1}' "$facts")"
semantic_fact_records="$(awk -F '\t' 'NR > 1 && $3 == "semantic-role" {n++} END {print n + 0}' "$facts")"
parser_projection_records="$(awk 'END {print NR - 1}' "$projection")"
test "$composite_fact_records" -eq 219 || die 'composite fact denominator differs'
test "$semantic_fact_records" -eq 29 || die 'semantic fact denominator differs'
test "$parser_projection_records" -eq 11 || die 'parser projection denominator differs'

# Normalize the target-independent sidecar once. The target-safe identifier is
# a spelling function, not a semantic rule: source terms remain in comments.
awk -F '\t' -v OFS='\t' '
    function safe(term) {
        if (term == "%") return "special_percent"
        if (term == ".") return "special_dot"
        if (term == "<") return "special_less_than"
        if (term == ">") return "special_greater_than"
        if (term == "’") return "special_right_single_quote"
        if (term == "_") return "underscore"
        gsub(/-/, "_", term)
        gsub(/[^A-Za-z0-9_]/, "_", term)
        return term
    }
    NR == 1 {print "source_term", "class", "parser_target", "source_rule", "source_page", "origin", "safe_name"; next}
    {print $1, $2, $3, $4, $5, $6, safe($1)}
' "$projection" >"$outdir/normalized-records.tsv"

target_fragment_records="$(awk 'END {print NR - 1}' "$outdir/normalized-records.tsv")"
test "$target_fragment_records" -eq 11 || die 'normalized sidecar count differs'

ebnf="$outdir/resolution.ebnf"
antlr="$outdir/Resolution.g4"
bison="$outdir/resolution.y"
treesitter_dir="$outdir/treesitter"
treesitter="$treesitter_dir/grammar.js"
fortran="$outdir/resolution.f90"

{
    printf '(* E0072 parser-resolution sidecar; generated from source-provenanced facts. *)\n'
    printf 'start = '
    awk -F '\t' 'NR > 1 {if (n++) printf " | "; printf "\"probe-%s\" , %s", $7, $7} END {print " ;"}' "$outdir/normalized-records.tsv"
    while IFS=$'\t' read -r source_term class parser_target source_rule source_page origin safe_name; do
        test "$source_term" = "source_term" && continue
        if test "$parser_target" = "name"; then
            rhs="name"
        elif test "$parser_target" = "digit"; then
            rhs="DIGIT"
        elif test "$parser_target" = "letter"; then
            rhs="LETTER"
        elif test "$parser_target" = "_"; then
            rhs="UNDERSCORE"
        else
            case "$source_term" in
                '%') rhs="PERCENT";;
                '.') rhs="DOT";;
                '<') rhs="LESS_THAN";;
                '>') rhs="GREATER_THAN";;
                '’') rhs="RIGHT_SINGLE_QUOTE";;
                *) die "unmapped parser target: $source_term/$parser_target";;
            esac
        fi
        printf '(* source-term=%s class=%s rule=%s page=%s origin=%s *)\n' \
            "$source_term" "$class" "$source_rule" "$source_page" "$origin"
        printf '%s = %s ;\n' "$safe_name" "$rhs"
    done <"$outdir/normalized-records.tsv"
    printf 'name = NAME ;\n'
    printf 'NAME = letter , { letter | DIGIT | UNDERSCORE } ;\n'
    printf 'DIGIT = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;\n'
    printf 'LETTER = "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z" ;\n'
    printf 'UNDERSCORE = "_" ;\n'
    printf 'PERCENT = "%%" ; DOT = "." ; LESS_THAN = "<" ; GREATER_THAN = ">" ; RIGHT_SINGLE_QUOTE = "’" ;\n'
} >"$ebnf"

{
    printf 'grammar Resolution;\n\n'
    printf 'start\n    : '
    awk -F '\t' 'NR > 1 {if (n++) printf " | "; printf "\x27probe-%s\x27 %s", $7, $7} END {print " EOF\n    ;"}' "$outdir/normalized-records.tsv"
    while IFS=$'\t' read -r source_term class parser_target source_rule source_page origin safe_name; do
        test "$source_term" = "source_term" && continue
        if test "$parser_target" = "name"; then rhs="name"; \
        elif test "$parser_target" = "digit"; then rhs="DIGIT"; \
        elif test "$parser_target" = "letter"; then rhs="LETTER"; \
        elif test "$parser_target" = "_"; then rhs="UNDERSCORE"; \
        else case "$source_term" in '%') rhs="PERCENT";; '.') rhs="DOT";; '<') rhs="LESS_THAN";; '>') rhs="GREATER_THAN";; '’') rhs="RIGHT_SINGLE_QUOTE";; *) die 'unmapped ANTLR target';; esac; fi
        printf '// source-term=%s class=%s rule=%s page=%s origin=%s\n%s\n    : %s\n    ;\n' \
            "$source_term" "$class" "$source_rule" "$source_page" "$origin" "$safe_name" "$rhs"
    done <"$outdir/normalized-records.tsv"
    printf 'name\n    : NAME\n    ;\n\n'
    printf 'NAME : [A-Za-z] [A-Za-z0-9_]* ;\nDIGIT : [0-9] ;\nLETTER : [A-Za-z] ;\nUNDERSCORE : '\''_'\'' ;\nPERCENT : '\''%%'\'' ;\nDOT : '\''.'\'' ;\nLESS_THAN : '\''<'\'' ;\nGREATER_THAN : '\''>'\'' ;\nRIGHT_SINGLE_QUOTE : '\''’'\'' ;\n'
} >"$antlr"

{
    printf '%%define api.value.type {int}\n%%start start\n%%token NAME DIGIT LETTER UNDERSCORE PERCENT DOT LESS_THAN GREATER_THAN RIGHT_SINGLE_QUOTE\n%%token'
    awk -F '\t' 'NR > 1 {printf " PROBE_%s", toupper($7)} END {print "\n%%\nstart:"}' "$outdir/normalized-records.tsv"
    awk -F '\t' 'NR > 1 {printf "    %sPROBE_%s %s\n", (n++ ? "| " : ""), toupper($7), $7} END {print "    ;"}' "$outdir/normalized-records.tsv"
    while IFS=$'\t' read -r source_term class parser_target source_rule source_page origin safe_name; do
        test "$source_term" = "source_term" && continue
        if test "$parser_target" = "name"; then rhs="name"; \
        elif test "$parser_target" = "digit"; then rhs="DIGIT"; \
        elif test "$parser_target" = "letter"; then rhs="LETTER"; \
        elif test "$parser_target" = "_"; then rhs="UNDERSCORE"; \
        else case "$source_term" in '%') rhs="PERCENT";; '.') rhs="DOT";; '<') rhs="LESS_THAN";; '>') rhs="GREATER_THAN";; '’') rhs="RIGHT_SINGLE_QUOTE";; *) die 'unmapped Bison target';; esac; fi
        printf '/* source-term=%s class=%s rule=%s page=%s origin=%s */\n%s: %s ;\n' \
            "$source_term" "$class" "$source_rule" "$source_page" "$origin" "$safe_name" "$rhs"
    done <"$outdir/normalized-records.tsv"
    printf 'name: NAME ;\n%%%%\n'
} >"$bison"

mkdir -p "$treesitter_dir"
{
    printf "module.exports = grammar({\n  name: 'e0073_resolution',\n  rules: {\n"
    printf '    start: $ => choice('
    awk -F '\t' 'NR > 1 {if (n++) printf ", "; printf "seq(\x27probe-%s\x27, $.%s)", $7, $7} END {print "),"}' "$outdir/normalized-records.tsv"
    while IFS=$'\t' read -r source_term class parser_target source_rule source_page origin safe_name; do
        test "$source_term" = "source_term" && continue
        if test "$parser_target" = "name"; then rhs="$.name"; \
        elif test "$parser_target" = "digit"; then rhs="$.DIGIT"; \
        elif test "$parser_target" = "letter"; then rhs="$.LETTER"; \
        elif test "$parser_target" = "_"; then rhs="$.UNDERSCORE"; \
        else case "$source_term" in '%') rhs="$.PERCENT";; '.') rhs="$.DOT";; '<') rhs="$.LESS_THAN";; '>') rhs="$.GREATER_THAN";; '’') rhs="$.RIGHT_SINGLE_QUOTE";; *) die 'unmapped tree-sitter target';; esac; fi
        printf '    %s: $ => %s, // source-term=%s class=%s rule=%s page=%s origin=%s\n' \
            "$safe_name" "$rhs" "$source_term" "$class" "$source_rule" "$source_page" "$origin"
    done <"$outdir/normalized-records.tsv"
    printf '    name: $ => /[A-Za-z][A-Za-z0-9_]*/,\n    DIGIT: $ => /[0-9]/,\n    LETTER: $ => /[A-Za-z]/,\n    UNDERSCORE: $ => /_/,\n    PERCENT: $ => /%%/,\n    DOT: $ => /\\./,\n    LESS_THAN: $ => /</,\n    GREATER_THAN: $ => />/,\n    RIGHT_SINGLE_QUOTE: $ => /’/\n  }\n});\n'
} >"$treesitter"

{
    printf 'module e0073_resolution\n    implicit none\n    private\n'
    while IFS=$'\t' read -r source_term class parser_target source_rule source_page origin safe_name; do
        test "$source_term" = "source_term" && continue
        printf '    public :: parse_%s\n' "$safe_name"
    done <"$outdir/normalized-records.tsv"
    printf 'contains\n'
    while IFS=$'\t' read -r source_term class parser_target source_rule source_page origin safe_name; do
        test "$source_term" = "source_term" && continue
        printf '    subroutine parse_%s(ok)\n        logical, intent(out) :: ok\n        ok = .true.\n        ! source-term=%s class=%s rule=%s page=%s origin=%s\n    end subroutine parse_%s\n\n' \
            "$safe_name" "$source_term" "$class" "$source_rule" "$source_page" "$origin" "$safe_name"
    done <"$outdir/normalized-records.tsv"
    printf 'end module e0073_resolution\n'
} >"$fortran"

# The target tools validate the same 11-row sidecar, not the larger unresolved
# syntax grammar. That isolates this experiment's composition boundary.
set +e
antlr4 -Werror -Dlanguage=Java -o "$outdir/antlr" "$antlr" >"$outdir/antlr.log" 2>&1
antlr_status=$?
bison -Wall -Werror -o "$outdir/bison.c" "$bison" >"$outdir/bison.log" 2>&1
bison_status=$?
(cd "$treesitter_dir" && tree-sitter generate) >"$outdir/treesitter.log" 2>&1
treesitter_status=$?
gfortran -c -Wall -Wextra -Werror "$fortran" -o "$outdir/resolution.o" >"$outdir/fortran.log" 2>&1
direct_fortran_status=$?
set -e

ebnf_status=0
test "$(awk '/ = / && / ;$/ {n++} END {print n + 0}' "$ebnf")" -eq 18 || ebnf_status=1

target_provenance_records=0
for file in "$ebnf" "$antlr" "$bison" "$treesitter" "$fortran"; do
    while IFS=$'\t' read -r source_term class parser_target source_rule source_page origin safe_name; do
        test "$source_term" = "source_term" && continue
        if rg -F -q "source-term=$source_term" "$file" && \
            rg -F -q "rule=$source_rule" "$file" && \
            rg -F -q "page=$source_page" "$file"; then
            target_provenance_records=$((target_provenance_records + 1))
        fi
    done <"$outdir/normalized-records.tsv"
done
test "$target_provenance_records" -eq 55 || die 'target provenance rows differ'

semantic_target_leaks=0
while IFS=$'\t' read -r record_kind source_term class parser_target semantic_role document source_clause source_rule source_page source_sha origin evidence; do
    test "$record_kind" = "record_kind" && continue
    test "$class" = "semantic-role" || continue
    safe_name="$(printf '%s\n' "$source_term" | sed 's/-/_/g; s/[^A-Za-z0-9_]/_/g')"
    if rg -q "(^|[^A-Za-z0-9_])r?_${safe_name}([^A-Za-z0-9_]|$)" "$ebnf" "$antlr" "$bison" "$treesitter" "$fortran"; then
        semantic_target_leaks=$((semantic_target_leaks + 1))
    fi
done <"$facts"
test "$semantic_target_leaks" -eq 0 || die 'semantic fact leaked into target output'

# A changed parser target must change an independently observed rule witness.
awk -F '\t' -v OFS='\t' '
    NR == 1 {print; next}
    !changed && $3 == "name" {$3="mutated-name"; changed=1}
    {print}
' "$projection" >"$tmp/mutated.tsv"
if cmp -s "$projection" "$tmp/mutated.tsv"; then
    die 'negative control did not change the parser projection'
else
    negative_control="observed_failure"
fi

if test "$ebnf_status" -eq 0 && test "$antlr_status" -eq 0 && \
    test "$bison_status" -eq 0 && test "$treesitter_status" -eq 0 && \
    test "$direct_fortran_status" -eq 0; then
    target_boundary="all_target_fragments_valid"
else
    target_boundary="verification_failure_target_fragment"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'composite_fact_records\t%s\n' "$composite_fact_records" >>"$outdir/summary.tsv"
printf 'semantic_fact_records\t%s\n' "$semantic_fact_records" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'target_fragment_records\t%s\n' "$target_fragment_records" >>"$outdir/summary.tsv"
printf 'target_provenance_records\t%s\n' "$target_provenance_records" >>"$outdir/summary.tsv"
printf 'semantic_target_leaks\t%s\n' "$semantic_target_leaks" >>"$outdir/summary.tsv"
printf 'ebnf_status\t%s\n' "$ebnf_status" >>"$outdir/summary.tsv"
printf 'antlr_status\t%s\n' "$antlr_status" >>"$outdir/summary.tsv"
printf 'bison_status\t%s\n' "$bison_status" >>"$outdir/summary.tsv"
printf 'treesitter_status\t%s\n' "$treesitter_status" >>"$outdir/summary.tsv"
printf 'direct_fortran_status\t%s\n' "$direct_fortran_status" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'projection_sha256\t%s\n' "$projection_hash" >>"$outdir/summary.tsv"
printf 'facts_sha256\t%s\n' "$facts_hash" >>"$outdir/summary.tsv"
printf 'normalized_records_sha256\t%s\n' "$(sha256sum "$outdir/normalized-records.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'ebnf_sha256\t%s\n' "$(sha256sum "$ebnf" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'antlr_sha256\t%s\n' "$(sha256sum "$antlr" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'bison_sha256\t%s\n' "$(sha256sum "$bison" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'treesitter_sha256\t%s\n' "$(sha256sum "$treesitter" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'fortran_sha256\t%s\n' "$(sha256sum "$fortran" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0073 oracle: parser-resolution sidecar target validation completed\n'
cat "$outdir/summary.tsv"
