#!/usr/bin/env bash
# Compose the accepted R402 and lexical D0019 resolution witnesses.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
outdir="${2:-$root/.cache/runs/E0046/R000001}"
e0044="$root/research/experiments/E0044-can-the-source-controlled-r402-closure-r/analyse.sh"
e0045="$root/research/experiments/E0045-can-source-controlled-lexical-witnesses-/analyse.sh"
r44="$root/.cache/runs/E0044/R000001/resolution-records.tsv"
r45="$root/.cache/runs/E0045/R000001/resolution-records.tsv"
input="$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
r44_hash="7408d0d9e6efa62b185fad282d5d8e2aac7f2f28e3b62f0944ed4f054d8d65dc"
r45_hash="ae9508105d81252b2d2badb3b75631792e4c983df6ce9dc9ec57f6897b97dc13"

die() { printf 'E0046: %s\n' "$1" >&2; exit 1; }
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
mkdir -p "$outdir"
"$e0044" >"$outdir/e0044.log"
"$e0045" >"$outdir/e0045.log"
test "$(sha256sum "$r44" | cut -d' ' -f1)" = "$r44_hash" || die 'E0044 record hash mismatch'
test "$(sha256sum "$r45" | cut -d' ' -f1)" = "$r45_hash" || die 'E0045 record hash mismatch'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# E0044 is the base table. E0045 replaces only rows that it resolves beyond
# the base table. Any overlapping resolved fields must agree.
awk -F '\t' '
    FILENAME == ARGV[1] { if (FNR == 1) h=$0; else a[$1]=$0; next }
    FILENAME == ARGV[2] { if (FNR > 1) b[$1]=$0; next }
    END {
        print h
        for (n in a) {
            split(a[n], x, FS)
            if (!(n in b)) bad=1
            else {
                split(b[n], y, FS)
                if (x[2] != "unresolved" && y[2] != "unresolved")
                    for (i = 2; i <= 10; i++) if (x[i] != y[i]) bad=1
                if (x[2] == "unresolved" && y[2] != "unresolved") print b[n]
                else print a[n]
            }
        }
        if (bad) exit 1
    }
' "$r44" "$r45" >"$tmp/combined.tsv" || die 'resolution slices disagree'
{
    head -n 1 "$tmp/combined.tsv"
    tail -n +2 "$tmp/combined.tsv" | sort -t $'\t' -k1,1
} >"$outdir/resolution-records.tsv"

awk -F '\t' -v hash="$source_hash" '
    NR == 1 { next }
    {
        if (NF != 11 || $5 != "J3-24-007" || $9 != hash || $10 != "MECHANICAL") bad=1
        seen[$1]++; count++
        if ($2 == "alias") aliases++
        if ($2 == "lexical-class") lexical++
        if ($2 == "metavariable") metavariable++
        if ($2 == "semantic-role") semantic++
        if ($2 == "unresolved") unresolved++
        if ($2 == "disputed") disputed++
    }
    END {
        for (n in seen) if (seen[n] != 1) bad=1
        if (count != 182 || aliases != 49 || lexical != 25 || metavariable != 1 || semantic != 0 || unresolved != 107 || disputed != 0) bad=1
        exit bad
    }
' "$outdir/resolution-records.tsv" || die 'combined resolution validation failed'

awk -F '\t' 'NR > 1 && $2 == "alias" {print $1 "\t" $3}' "$outdir/resolution-records.tsv" | sort >"$tmp/aliases"
awk -F '\t' 'NR > 1 && $2 == "alias" {print $1 "\t" $3}' "$r44" | sort >"$tmp/expected-aliases"
diff -u "$tmp/expected-aliases" "$tmp/aliases" >/dev/null || die 'alias closure differs'
awk -F '\t' 'NR > 1 && $2 == "lexical-class" {print $1 "\t" $3}' "$outdir/resolution-records.tsv" | sort >"$tmp/lexical"
awk -F '\t' 'NR > 1 && $2 == "lexical-class" {print $1 "\t" $3}' "$r45" | sort >"$tmp/expected-lexical"
diff -u "$tmp/expected-lexical" "$tmp/lexical" >/dev/null || die 'lexical closure differs'

awk -F '\t' 'NR == 1 {print "source_term\tclass\tparser_target\tsource_rule\tsource_page\torigin"; next} ($2 == "alias" || ($2 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/)) {print $1 "\t" $2 "\t" $3 "\t" $7 "\t" $8 "\t" $10}' "$outdir/resolution-records.tsv" >"$outdir/composite-input.tsv"
test "$(wc -l < "$outdir/composite-input.tsv")" -eq 71 || die 'combined projection row count differs'

awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0) text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    FILENAME == ARGV[1] {
        if (FNR > 1 && $2 == "alias") replacement[$1]="(ref " $3 ")"
        if (FNR > 1 && $2 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/) replacement[$1]="(token " $3 ")"
        next
    }
    FILENAME == ARGV[2] && /^\(syntax / {
        old=$0
        for (n in replacement) $0=replace_all($0, "(ref " n ")", replacement[n])
        if ($0 != old || /\(lhs name\)|\(lhs alphanumeric-character\)/) print
    }
' "$outdir/resolution-records.tsv" "$input" >"$outdir/composite-resolution-slice.sx"
test "$(wc -l < "$outdir/composite-resolution-slice.sx")" -gt 8 || die 'combined SX witness count did not grow'
(cd "$standard_new" && fo exec sxantlr "$outdir/composite-resolution-slice.sx" "$outdir/composite-resolution-slice.g4") >"$outdir/composite-resolution-slice.log"

for excluded in '–' '’'; do
    awk -F '\t' -v term="$excluded" 'NR > 1 && $1 == term && $2 == "unresolved" {found=1} END {exit (found ? 0 : 1)}' "$outdir/resolution-records.tsv" || die "excluded Unicode term was resolved: $excluded"
done
awk -F '\t' 'NR == 1 {print; next} $1 == "entity-name" {$2="unresolved"} {OFS="\t"; print}' "$outdir/resolution-records.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $1 == "entity-name" && !($2 == "alias" && $3 == "name") {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

records="$(awk 'END {print NR - 1}' "$outdir/resolution-records.tsv")"
aliases="$(awk -F '\t' 'NR > 1 && $2 == "alias" {n++} END {print n + 0}' "$outdir/resolution-records.tsv")"
lexical="$(awk -F '\t' 'NR > 1 && $2 == "lexical-class" {n++} END {print n + 0}' "$outdir/resolution-records.tsv")"
metavariable="$(awk -F '\t' 'NR > 1 && $2 == "metavariable" {n++} END {print n + 0}' "$outdir/resolution-records.tsv")"
unresolved="$(awk -F '\t' 'NR > 1 && $2 == "unresolved" {n++} END {print n + 0}' "$outdir/resolution-records.tsv")"
source_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $9 == hash {n++} END {print n + 0}' "$outdir/resolution-records.tsv")"
witnesses="$(wc -l < "$outdir/composite-resolution-slice.sx")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'resolution_records\t%s\n' "$records" >>"$outdir/summary.tsv"
printf 'alias_records\t%s\n' "$aliases" >>"$outdir/summary.tsv"
printf 'lexical_class_records\t%s\n' "$lexical" >>"$outdir/summary.tsv"
printf 'metavariable_records\t%s\n' "$metavariable" >>"$outdir/summary.tsv"
printf 'semantic_role_records\t0\n' >>"$outdir/summary.tsv"
printf 'unresolved_records\t%s\n' "$unresolved" >>"$outdir/summary.tsv"
printf 'disputed_records\t0\n' >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_matches" >>"$outdir/summary.tsv"
printf 'alias_projection_records\t49\n' >>"$outdir/summary.tsv"
printf 'lexical_projection_records\t21\n' >>"$outdir/summary.tsv"
printf 'unicode_exclusions_retained\t2\n' >>"$outdir/summary.tsv"
printf 'composite_syntax_witnesses\t%s\n' "$witnesses" >>"$outdir/summary.tsv"
printf 'composite_input_sha256\t%s\n' "$(sha256sum "$outdir/composite-resolution-slice.sx" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'composite_grammar_sha256\t%s\n' "$(sha256sum "$outdir/composite-resolution-slice.g4" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'E0046 oracle: combined R402 and lexical resolution projection passed\n'
cat "$outdir/summary.tsv"
