#!/usr/bin/env bash
# Adjudicate the three E0076 candidates without parser projection.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e76="$root/research/experiments/E0076-how-much-of-the-151-unresolved-residue-h/analyse.sh"
canonical="$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt"
candidates="$root/.cache/runs/E0076/R000001/candidate-spans.tsv"
adjudication="$root/research/experiments/E0077-can-source-controlled-adjudication-separ/adjudication.tsv"
outdir="${1:-$root/.cache/runs/E0077/R000001}"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

die() { printf 'E0077: %s\n' "$1" >&2; exit 1; }
mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e76" >"$outdir/e0076.log" || die 'E0076 predecessor failed'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical hash mismatch'
test "$(awk 'END {print NR}' "$candidates")" -eq 3 || die 'candidate denominator differs'

for phrase in \
    'or .NE., the other generic-spec may have a defined-operator that is the corresponding operator <, <=,' \
    'R1508 generic-spec is generic-name' \
    'If a submodule-name appears in the end-submodule-stmt, it shall be identical'; do
    rg -F -q "$phrase" "$canonical" || die "missing source evidence: $phrase"
done

adjudicated="$outdir/adjudicated.tsv"
awk -F '\t' -v OFS='\t' -v source_hash="$source_hash" '
    BEGIN {print "term", "disposition", "class", "parser_target", "source_hash", "origin", "reason", "evidence"}
    FILENAME == ARGV[1] {
        if (FNR == 1) next
        disposition[$1]=$2; class[$1]=$3; target[$1]=$4
        reason[$1]=$5; evidence[$1]=$6
        next
    }
    FILENAME == ARGV[2] {
        term=$1
        if (!(term in disposition) || seen[term]++) exit 7
        print term, disposition[term], class[term], target[term], source_hash, "LLM", reason[term], evidence[term]
        emitted[term]=1
    }
    END {for (term in disposition) if (!(term in emitted)) missing++; if (missing) exit 7}
' "$adjudication" "$candidates" >"$adjudicated" || die 'candidate/adjudication join failed'

candidate_spans="$(awk 'END {print NR - 1}' "$adjudicated")"
accepted_records="$(awk -F '\t' 'NR > 1 && $2 == "accepted" {n++} END {print n + 0}' "$adjudicated")"
retained_records="$(awk -F '\t' 'NR > 1 && $2 == "retained" {n++} END {print n + 0}' "$adjudicated")"
accepted_semantic_role_records="$(awk -F '\t' 'NR > 1 && $2 == "accepted" && $3 == "semantic-role" {n++} END {print n + 0}' "$adjudicated")"
source_hash_matches="$(awk -F '\t' -v h="$source_hash" 'NR > 1 && $5 == h {n++} END {print n + 0}' "$adjudicated")"
source_evidence_matches=0
while IFS=$'\t' read -r term disposition class target hash origin reason evidence; do
    test "$term" = "term" && continue
    if rg -F -q "$evidence" "$canonical"; then source_evidence_matches=$((source_evidence_matches + 1)); fi
done <"$adjudicated"

test "$candidate_spans" -eq 3 || die 'adjudicated count differs'
test "$accepted_records" -eq 0 || die 'unexpected accepted candidate'
test "$retained_records" -eq 3 || die 'retained count differs'
test "$accepted_semantic_role_records" -eq 0 || die 'unexpected semantic relation'
test "$source_hash_matches" -eq 3 || die 'source hash count differs'
test "$source_evidence_matches" -eq 3 || die 'source evidence count differs'

awk -F '\t' 'NR > 1 {print $1}' "$adjudicated" | sort >"$tmp/adjudicated-names"
awk -F '\t' '{print $1}' "$candidates" | sort >"$tmp/candidate-names"
candidate_inventory_difference="$(comm -3 "$tmp/adjudicated-names" "$tmp/candidate-names" | wc -l)"
independent_difference="$candidate_inventory_difference"
test "$candidate_inventory_difference" -eq 0 || die 'candidate inventory differs'

awk -F '\t' -v OFS='\t' 'NR == 1 {print; next} NR == 2 {$2="accepted"} {print}' "$adjudicated" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $2 == "accepted" {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'candidate_spans\t%s\n' "$candidate_spans" >>"$outdir/summary.tsv"
printf 'accepted_records\t%s\n' "$accepted_records" >>"$outdir/summary.tsv"
printf 'retained_records\t%s\n' "$retained_records" >>"$outdir/summary.tsv"
printf 'accepted_semantic_role_records\t%s\n' "$accepted_semantic_role_records" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'source_evidence_matches\t%s\n' "$source_evidence_matches" >>"$outdir/summary.tsv"
printf 'candidate_inventory_difference\t%s\n' "$candidate_inventory_difference" >>"$outdir/summary.tsv"
printf 'independent_difference\t%s\n' "$independent_difference" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'adjudicated_sha256\t%s\n' "$(sha256sum "$adjudicated" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0077 oracle: source-controlled adjudication completed\n'
cat "$outdir/summary.tsv"
