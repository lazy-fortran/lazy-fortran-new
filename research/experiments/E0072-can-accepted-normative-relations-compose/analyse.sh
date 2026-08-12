#!/usr/bin/env bash
# Compose adjudicated source facts with the existing D0019 resolution table.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${STANDARDIR_INPUT:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
e0043="$root/research/experiments/E0043-can-a-source-controlled-d0019-resolution/analyse.sh"
e0070="$root/research/experiments/E0070-can-bounded-sentence-and-table-structure/analyse.sh"
e0071="$root/research/experiments/E0071-can-source-controlled-adjudication-separ/analyse.sh"
outdir="${1:-$root/.cache/runs/E0072/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"

die() {
    printf 'E0072: %s\n' "$1" >&2
    exit 1
}

test -f "$input" || die "StandardIR input is missing: $input"
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || \
    die 'StandardIR input hash mismatch'
for script in "$e0043" "$e0070" "$e0071"; do
    test -x "$script" || die "predecessor analyzer is missing: $script"
done

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0043" "$input" "$tmp/e0043" >"$tmp/e0043.log"
"$e0070" "$tmp/e0070" >"$tmp/e0070.log"
"$e0071" "$tmp/e0071" >"$tmp/e0071.log"

base="$tmp/e0043/resolution-records.tsv"
relations="$tmp/e0071/adjudicated-records.tsv"
retained="$outdir/retained-candidates.tsv"
test "$(awk 'END {print NR - 1}' "$base")" -eq 182 || die 'D0019 record count changed'
test "$(awk 'END {print NR - 1}' "$relations")" -eq 42 || die 'adjudicated denominator changed'
test "$(awk -F '\t' 'NR > 1 && $6 == "accepted" {n++} END {print n + 0}' "$relations")" -eq 37 || \
    die 'accepted relation count changed'
test "$(awk -F '\t' 'NR > 1 && $6 == "retained" {n++} END {print n + 0}' "$relations")" -eq 5 || \
    die 'retained relation count changed'
cp "$relations" "$retained"

printf 'record_kind\tsource_term\tclass\tparser_target\tsemantic_role\tdocument\tsource_clause\tsource_rule\tsource_page\tsource_sha256\torigin\tevidence\n' \
    >"$outdir/composite-resolution-facts.tsv"
awk -F '\t' -v OFS='\t' -v h="$source_hash" '
    FILENAME == ARGV[1] {
        if (FNR == 1) next
        if (NF != 11 || $9 != h) bad=1
        print "d0019", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
        base++
        next
    }
    FILENAME == ARGV[2] {
        if (FNR == 1 || $6 != "accepted") next
        if (NF != 15 || $6 != "accepted" || $11 != h) bad=1
        class=$7
        target=(class == "lexical-class" ? $8 : "-")
        role=(class == "semantic-role" ? $8 : "-")
        print "adjudicated", $2, class, target, role, "J3-24-007", "-", $9, $12, $11, $10, $14
        relations++
        next
    }
    END {
        if (base != 182 || relations != 37) bad=1
        exit bad
    }
' "$base" "$relations" >>"$outdir/composite-resolution-facts.tsv" || \
    die 'composite fact merge failed'

awk -F '\t' -v h="$source_hash" '
    NR == 1 {next}
    {
        if (NF != 12 || $10 != h || $2 == "") bad=1
        key=$1 SUBSEP $2 SUBSEP $3 SUBSEP $4 SUBSEP $5 SUBSEP $8
        if (seen[key]++) bad=1
        count++
        if ($1 == "d0019") base++
        if ($1 == "adjudicated") relation++
    }
    END {
        if (base != 182 || relation != 37 || count != 219) bad=1
        exit bad
    }
' "$outdir/composite-resolution-facts.tsv" || die 'composite fact validation failed'

printf 'source_term\tclass\tparser_target\tsource_rule\tsource_page\torigin\n' \
    >"$outdir/parser-projection.tsv"
awk -F '\t' -v OFS='\t' '
    NR == 1 {next}
    ($3 == "alias" && $4 != "-") || ($3 == "lexical-class" && $4 != "-") {
        key=$2 SUBSEP $3 SUBSEP $4
        if (!seen[key]++) print $2, $3, $4, $8, $9, $11
    }
' "$outdir/composite-resolution-facts.tsv" | sort -t $'\t' -k1,1 >>"$outdir/parser-projection.tsv"

awk -F '\t' 'NR > 1 && $3 == "semantic-role" {bad=1} END {exit bad}' \
    "$outdir/parser-projection.tsv" || die 'semantic relation entered parser projection'

# Independently rebuild the projection from the two predecessor tables.
awk -F '\t' -v OFS='\t' '
    FILENAME == ARGV[1] {
        if (FNR == 1) next
        if (($2 == "alias" || $2 == "lexical-class") && $3 != "-") {
            key=$1 SUBSEP $2 SUBSEP $3
            if (!seen[key]++) print $1, $2, $3, $7, $8, $10
        }
        next
    }
    FILENAME == ARGV[2] {
        if (FNR == 1 || $6 != "accepted" || $7 != "lexical-class" || $8 == "-") next
        key=$2 SUBSEP $7 SUBSEP $8
        if (!seen[key]++) print $2, $7, $8, $9, $12, $10
    }
' "$base" "$relations" | sort -t $'\t' -k1,1 >"$tmp/independent-projection.tsv"
tail -n +2 "$outdir/parser-projection.tsv" | sort -t $'\t' -k1,1 >"$tmp/primary-projection.tsv"
cmp -s "$tmp/primary-projection.tsv" "$tmp/independent-projection.tsv" || \
    die 'parser projection differs from independent rebuild'

awk -F '\t' 'NR > 1 && $1 == "adjudicated" && $3 == "semantic-role" {n++} END {if (n != 29) exit 1}' \
    "$outdir/composite-resolution-facts.tsv" || die 'semantic relation count changed'

mutated="$tmp/mutated-facts.tsv"
awk -F '\t' -v OFS='\t' 'NR == 1 {print; next} $1 == "adjudicated" && $2 == "parent-type-name" && $8 == "C737" {$3="unresolved"} {print}' \
    "$outdir/composite-resolution-facts.tsv" >"$mutated"
if awk -F '\t' 'NR > 1 && $1 == "adjudicated" && $3 == "semantic-role" {n++} END {exit (n == 29 ? 0 : 1)}' "$mutated"; then
    die 'negative relation mutation did not fail'
else
    negative_control='observed_failure'
fi

d0019_records=182
adjudicated_records=37
merged_records=219
retained_records=5
unresolved_records=151
semantic_not_aliases=29
parser_projection_records="$(awk 'END {print NR - 1}' "$outdir/parser-projection.tsv")"
source_hash_matches="$(awk -F '\t' -v h="$source_hash" 'NR > 1 && $10 == h {n++} END {print n + 0}' "$outdir/composite-resolution-facts.tsv")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'd0019_records\t%s\n' "$d0019_records" >>"$outdir/summary.tsv"
printf 'adjudicated_relation_records\t%s\n' "$adjudicated_records" >>"$outdir/summary.tsv"
printf 'merged_fact_records\t%s\n' "$merged_records" >>"$outdir/summary.tsv"
printf 'retained_relations\t%s\n' "$retained_records" >>"$outdir/summary.tsv"
printf 'unresolved_records\t%s\n' "$unresolved_records" >>"$outdir/summary.tsv"
printf 'semantic_facts_not_parser_aliases\t%s\n' "$semantic_not_aliases" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'projection_difference\t0\n' >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"

printf 'E0072 oracle: D0019 and adjudicated relation composition passed\n'
cat "$outdir/summary.tsv"
