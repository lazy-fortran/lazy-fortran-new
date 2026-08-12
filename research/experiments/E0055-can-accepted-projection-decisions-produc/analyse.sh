#!/usr/bin/env bash
# Apply accepted D0024, D0026 and D0027 projections to one composite input.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e49="$root/research/experiments/E0049-can-accepted-resolutions-and-fixed-errat/analyse.sh"
e53="$root/research/experiments/E0053-can-the-remaining-target-failures-be-par/analyse.sh"
input="$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx"
canonical="$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"
outdir="${1:-$root/.cache/runs/E0055/R000001}"

input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

die() { printf 'E0055: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'

"$e49" >"$outdir/e0049.log" || die 'E0049 predecessor failed'
"$e53" >"$outdir/e0053.log" || die 'E0053 predecessor failed'
normalized="$root/.cache/runs/E0049/R000001/normalized-resolution-records.tsv"
inventory="$root/.cache/runs/E0048/R000001/expansion-inventory.tsv"
residue="$root/.cache/runs/E0053/R000001/residual-buckets.tsv"
test "$(awk 'END {print NR - 1}' "$normalized")" -eq 182 || die 'resolution record count differs'
test "$(awk 'END {print NR - 1}' "$inventory")" -eq 100 || die 'expansion inventory count differs'
test "$(awk 'END {print NR - 1}' "$residue")" -eq 103 || die 'residue count differs'

base_errata="$root/research/errata/j3-24-007.json"
extension_errata="$root/research/errata/j3-24-007-r1123.json"
map="$tmp/errata-map.tsv"
{
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation] | @tsv' "$base_errata"
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation] | @tsv' "$extension_errata"
} | sort -t $'\t' -k1,1 >"$map"
test "$(wc -l <"$map")" -eq 8 || die 'errata denominator differs'

overlap_a="scalar-int-constant-name"
overlap_b="scalar-int-variable-name"
overlap_c="scalar-variable-name"

# R402 and lexical projections. D0026 overlap terms are composed below.
projection="$tmp/projection.tsv"
awk -F '\t' -v OFS='\t' \
    -v a="$overlap_a" -v b="$overlap_b" -v c="$overlap_c" '
    NR > 1 && $3 == "alias" && $1 != a && $1 != b && $1 != c {
        print $1, "(ref " $4 ")", "alias", $4
        n++
    }
    NR > 1 && $3 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/ {
        print $1, "(token " $4 ")", "lexical-class", $4
        n++
    }
    END {if (n != 67) exit 1}
' "$normalized" >"$projection" || die 'accepted projection denominator differs'

# R401 and R403 are typed expansions, not parser aliases. R403 bases are
# reduced by an R402 alias when the source provides that fact.
expansions="$tmp/expansions.tsv"
awk -F '\t' -v OFS='\t' \
    -v a="$overlap_a" -v b="$overlap_b" -v c="$overlap_c" '
    FILENAME == ARGV[1] && FNR > 1 && $3 == "alias" {alias[$1]=$4; next}
    FILENAME == ARGV[2] && FNR > 1 {
        source=$1; family=$2; base=$3
        if (base in alias) target=alias[base]
        else if (base ~ /-name$/) target="name"
        else target=base
        if (family == "R401") {
            expression="(seq (ref " target ") (repeat (seq (token ,) (ref " target ")) 0 unbounded))"
        } else if (family == "R403") {
            expression="(ref " target ")"
        } else {exit 1}
        overlap=(source == a || source == b || source == c) ? "overlap" : "single"
        print source, family, base, target, expression, overlap
        records++
    }
    END {if (records != 100) exit 1}
' "$normalized" "$inventory" >"$expansions" || die 'typed expansion construction failed'
awk -F '\t' '$2 == "R401" && $6 == "overlap" {a++} $2 == "R403" && $6 == "overlap" {b++} END {if (a != 0 || b != 3) exit 1}' "$expansions" || die 'overlap denominator differs'

schema="$outdir/lexical-schema.tsv"
{
    awk -F '\t' '$1 == "letter" || $1 == "digit" || $1 == "rep-char" {print $1 "\tlexical-class\t" $7 "\t" $8 "\t" $9 "\tgenerated-lexer-terminal\taccepted"}' "$root/.cache/runs/E0046/R000001/resolution-records.tsv"
    awk -F '\t' 'NR > 1 && ($4 == "–" || $4 == "’") {print $4 "\tunicode-ambiguous\t" $5 "\t" $6 "\t7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2\texternal-unresolved-terminal\tunresolved"}' "$residue"
} | sort -t $'\t' -k1,1 >"$tmp/schema-body.tsv"
{ printf 'source_term\tclass\tsource_rule\tsource_page\tsource_sha256\tprojection\tstate\n'; cat "$tmp/schema-body.tsv"; } >"$schema"
test "$(awk 'END {print NR - 1}' "$schema")" -eq 5 || die 'lexical schema denominator differs'
test "$(awk -F '\t' 'NR > 1 && $6 == "generated-lexer-terminal" {n++} END {print n + 0}' "$schema")" -eq 3 || die 'lexical projection count differs'
test "$(awk -F '\t' 'NR > 1 && $7 == "unresolved" {n++} END {print n + 0}' "$schema")" -eq 2 || die 'unresolved lexical count differs'

composite="$outdir/composite-input.sx"
awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0)
            text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    FILENAME == ARGV[1] {
        optional_old["(optional (ref " $1 "))"]="(optional (seq (ref " $2 ") (token " $3 ")))"
        errata_old["(ref " $1 ")"]="(ref " $2 ") (token " $3 ")"
        next
    }
    FILENAME == ARGV[2] {replacement[$1]=$2; next}
    FILENAME == ARGV[3] {expansion[$1]=$5; next}
    FILENAME == ARGV[4] && /^\(syntax / {
        rule=$0
        sub(/^\(syntax /, "", rule)
        sub(/ .*/, "", rule)
        if (rule == "R401" || rule == "R402" || rule == "R403") {templates++; next}
        for (old in optional_old) $0=replace_all($0, old, optional_old[old])
        for (old in errata_old) $0=replace_all($0, old, errata_old[old])
        for (old in replacement) $0=replace_all($0, "(ref " old ")", replacement[old])
        for (old in expansion) {
            marker="__E0055_EXPANSION_" (++markers) "__"
            before=$0
            $0=replace_all($0, "(ref " old ")", marker)
            if ($0 != before) used[old]++
            marker_value[marker]=expansion[old]
        }
        for (marker in marker_value) $0=replace_all($0, marker, marker_value[marker])
        print
        records++
    }
    END {
        if (templates != 3 || records != 519) exit 1
        for (old in expansion) if (!(old in used)) missing++
        if (missing) exit 1
    }
' "$map" "$projection" "$expansions" "$input" >"$composite" || die 'composite projection failed'

test "$(rg -c '^\(syntax ' "$composite")" -eq 519 || die 'composite syntax record count differs'
if rg -F -q '(ref xyz)' "$composite"; then die 'metavariable escaped its typed expansion boundary'; fi
while IFS=$'\t' read -r source _; do
    if rg -F -q "(ref $source)" "$composite"; then die "projected reference remains: $source"; fi
done < <(tail -n +2 "$projection")
while IFS=$'\t' read -r source _; do
    if rg -F -q "(ref $source)" "$composite"; then die "expansion reference remains: $source"; fi
done <"$expansions"

awk -F '\t' -v OFS='\t' '$6 == "overlap" {print $1, $2, $3, $4, "R402-alias+R403-scalar", "C401", "D0025-before-D0024-D0026"}' \
    "$expansions" >"$outdir/compositional-overlaps.tsv"
test "$(wc -l <"$outdir/compositional-overlaps.tsv")" -eq 3 || die 'overlap payload count differs'

printf 'E0055 projection phase passed\n'

# Generate all target formats from the same SX input.
(cd "$standard_new" && fo exec sxantlr "$composite" "$outdir/base-Fortran2023.g4") >"$outdir/sxantlr.log" 2>&1
(cd "$standard_new" && fo exec sxbison "$composite" "$outdir/base-Fortran2023.y") >"$outdir/sxbison.log" 2>&1
(cd "$standard_new" && fo exec sxtreesitter "$composite" "$outdir/base-grammar.js") >"$outdir/sxtreesitter.log" 2>&1

# Target adapters are generated from the same lexical schema. REP_CHAR is
# intentionally symbolic because the source makes its character set
# processor-dependent. The two Unicode forms are named unresolved terminals,
# not assigned a normative interpretation.
{
    cat "$outdir/base-Fortran2023.g4"
    cat <<'EOF'
// D0027 generated lexical-fact schema. Source citations are in lexical-schema.tsv.
r_letter : LETTER ;
r_digit : DIGIT ;
r_rep_x2D_char : REP_CHAR ;
r__xE2__x80__x93_ : UNRESOLVED_U2013 ;
r__xE2__x80__x99_ : UNRESOLVED_U2019 ;
LETTER : [A-Za-z] ;
DIGIT : [0-9] ;
REP_CHAR : . ;
UNRESOLVED_U2013 : '\u2013' ;
UNRESOLVED_U2019 : '\u2019' ;
EOF
} >"$outdir/Fortran2023.g4"

awk '
    BEGIN {section=0}
    /^%%$/ {
        section++
        if (section == 1) print "%token LETTER DIGIT REP_CHAR UNRESOLVED_U2013 UNRESOLVED_U2019"
        if (section == 2) {
            print "r_letter: LETTER ;"
            print "r_digit: DIGIT ;"
            print "r_rep_x2D_char: REP_CHAR ;"
            print "r__xE2__x80__x93_: UNRESOLVED_U2013 ;"
            print "r__xE2__x80__x99_: UNRESOLVED_U2019 ;"
        }
        print
        next
    }
    {print}
' "$outdir/base-Fortran2023.y" >"$outdir/Fortran2023.y"

awk '
    /^  }$/ {
        print "r_letter: $ => $._e0055_letter,"
        print "r_digit: $ => $._e0055_digit,"
        print "r_rep_x2D_char: $ => $._e0055_rep_char,"
        print "r__xE2__x80__x93_: $ => $._e0055_u2013,"
        print "r__xE2__x80__x99_: $ => $._e0055_u2019,"
        print "_e0055_letter: $ => /[A-Za-z]/,"
        print "_e0055_digit: $ => /[0-9]/,"
        print "_e0055_rep_char: $ => /[\\s\\S]/,"
        print "_e0055_u2013: $ => /\\u2013/,"
        print "_e0055_u2019: $ => /\\u2019/,"
    }
    {print}
' "$outdir/base-grammar.js" >"$outdir/grammar.js"

set +e
antlr4 -Werror -Dlanguage=Java -o "$outdir/antlr" "$outdir/Fortran2023.g4" >"$outdir/antlr.log" 2>&1
antlr_status=$?
bison -Wall -Werror -o "$outdir/bison.c" "$outdir/Fortran2023.y" >"$outdir/bison.log" 2>&1
bison_status=$?
mkdir -p "$outdir/treesitter"
cp "$outdir/grammar.js" "$outdir/treesitter/grammar.js"
(cd "$outdir/treesitter" && tree-sitter generate) >"$outdir/treesitter.log" 2>&1
treesitter_status=$?
set -e

sed -n 's/.*reference to undefined rule: \([^[:space:]]*\).*/\1/p' "$outdir/antlr.log" | sort -u >"$outdir/antlr-unresolved.txt"
sed -n "s/.*symbol '\([^']*\)' is used.*/\1/p" "$outdir/bison.log" | sort -u >"$outdir/bison-unresolved.txt"
antlr_unresolved="$(wc -l <"$outdir/antlr-unresolved.txt")"
bison_unresolved="$(wc -l <"$outdir/bison-unresolved.txt")"
treesitter_structural_error=0
if rg -q 'Error when generating parser|SyntaxError: Unexpected token' "$outdir/treesitter.log"; then treesitter_structural_error=1; fi
antlr_warnings="$(rg -c '^warning\(' "$outdir/antlr.log" || true)"
bison_warnings="$(rg -c 'warning:' "$outdir/bison.log" || true)"
antlr_warnings="${antlr_warnings:-0}"
bison_warnings="${bison_warnings:-0}"

# Controlled mutation: an R401 row cannot be relabeled R403 without failing
# the family invariant used by the accepted typed expansion contract.
awk -F '\t' 'BEGIN {OFS="\t"} NR == 1 {print; next} NR == 2 {$2="R403"} {print}' \
    "$expansions" >"$tmp/mutated-expansions.tsv"
if awk -F '\t' '$1 ~ /-list$/ && $2 != "R401" {bad=1} $1 ~ /^scalar-/ && $2 != "R403" {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated-expansions.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

if test "$antlr_status" -eq 0 && test "$bison_status" -eq 0 && \
    test "$treesitter_status" -eq 0 && test "$treesitter_structural_error" -eq 0; then
    target_boundary="accepted"
else
    target_boundary="verification_failure_structural_target"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'source_syntax_records\t522\n' >>"$outdir/summary.tsv"
printf 'generated_syntax_records\t519\n' >>"$outdir/summary.tsv"
printf 'r401_expansions\t80\n' >>"$outdir/summary.tsv"
printf 'r403_expansions\t20\n' >>"$outdir/summary.tsv"
printf 'compositional_overlaps\t3\n' >>"$outdir/summary.tsv"
printf 'lexical_schema_records\t5\n' >>"$outdir/summary.tsv"
printf 'lexical_schema_projected\t3\n' >>"$outdir/summary.tsv"
printf 'unresolved_schema_records\t2\n' >>"$outdir/summary.tsv"
printf 'antlr_status\t%s\n' "$antlr_status" >>"$outdir/summary.tsv"
printf 'bison_status\t%s\n' "$bison_status" >>"$outdir/summary.tsv"
printf 'treesitter_status\t%s\n' "$treesitter_status" >>"$outdir/summary.tsv"
printf 'antlr_unresolved\t%s\n' "$antlr_unresolved" >>"$outdir/summary.tsv"
printf 'bison_unresolved\t%s\n' "$bison_unresolved" >>"$outdir/summary.tsv"
printf 'treesitter_structural_error\t%s\n' "$treesitter_structural_error" >>"$outdir/summary.tsv"
printf 'antlr_warnings\t%s\n' "$antlr_warnings" >>"$outdir/summary.tsv"
printf 'bison_warnings\t%s\n' "$bison_warnings" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'source_input_sha256\t%s\n' "$input_hash" >>"$outdir/summary.tsv"
printf 'composite_input_sha256\t%s\n' "$(sha256sum "$composite" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'lexical_schema_sha256\t%s\n' "$(sha256sum "$schema" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'overlap_sha256\t%s\n' "$(sha256sum "$outdir/compositional-overlaps.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0055 oracle: accepted deterministic projections validated\n'
cat "$outdir/summary.tsv"
