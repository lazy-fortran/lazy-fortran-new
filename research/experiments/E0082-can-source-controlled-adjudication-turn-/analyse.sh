#!/usr/bin/env bash
# Source-control E0081 candidates without promoting modal occurrences to aliases.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0081="$root/research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
policy="$root/research/experiments/E0082-can-source-controlled-adjudication-turn-/adjudication-policy.tsv"
outdir="${1:-$root/.cache/runs/E0082/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

die() {
    printf 'E0082: %s\n' "$1" >&2
    exit 1
}

test -x "$e0081" || die 'E0081 analyzer is missing'
test -f "$canonical" || die "canonical text is missing: $canonical"
test -f "$policy" || die "adjudication policy is missing: $policy"
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0081" "$tmp/e0081" >"$outdir/e0081.log" || die 'E0081 predecessor failed'
candidate="$tmp/e0081/candidate-spans.tsv"
constraints="$tmp/e0081/constraint-spans.tsv"
test "$(wc -l <"$candidate")" -eq 266 || die 'E0081 candidate denominator differs'
test "$(wc -l <"$constraints")" -eq 287 || die 'E0081 constraint denominator differs'

printf 'candidate_no\tterm\tkind\tline\tpage\tdisposition\taccepted_class\ttarget\tsource_ref\tsource_hash\torigin\tevidence\treason\tsource_text\n' \
    >"$outdir/adjudicated-records.tsv"
awk -F '\t' -v OFS='\t' -v policy="$policy" -v source_hash="$source_hash" '
    FILENAME == policy {
        if (FNR == 1) next
        key=$1 SUBSEP $2 SUBSEP $3
        if (key in policy_class) bad=1
        policy_class[key]=$4
        policy_target[key]=$5
        policy_ref[key]=$6
        policy_evidence[key]=$7
        policy_reason[key]=$8
        policy_count++
        next
    }
    {
        term=$1; kind=$3; line=$5; page=$6; text=$9
        key=term SUBSEP kind SUBSEP line
        if (seen[key]++) bad=1
        if (key in policy_class) {
            disposition="accepted"
            accepted_class=policy_class[key]
            target=policy_target[key]
            source_ref=policy_ref[key]
            evidence=policy_evidence[key]
            reason=policy_reason[key]
            policy_seen[key]=1
            if (index(tolower(text), tolower(evidence)) == 0) bad=1
        } else if (kind == "constraint") {
            disposition="retained"
            accepted_class="constraint-evidence"
            target="-"
            source_ref="J3-24-007:canonical-line-" line
            evidence=text
            reason="modal occurrence retained until predicate formalization"
        } else {
            bad=1
        }
        print NR - 1, term, kind, line, page, disposition, accepted_class, target, \
            source_ref, source_hash, "MECHANICAL", evidence, reason, text
    }
    END {
        if (policy_count != 10) bad=1
        for (key in policy_class) if (!(key in policy_seen)) bad=1
        exit bad
    }
' "$policy" "$candidate" >>"$outdir/adjudicated-records.tsv" || \
    die 'candidate inventory and adjudication policy differ'

printf 'constraint_no\tconstraint_id\tassociated_rules\tline\tpage\tsource_hash\torigin\tdisposition\tformalization_status\tsource_text\n' \
    >"$outdir/constraint-records.tsv"
awk -F '\t' -v OFS='\t' -v source_hash="$source_hash" '
    {
        if (NF != 7 || $3 !~ /^[0-9]+$/ || $3 == 0 || $4 !~ /^[0-9]+$/ || $4 == 0 || $5 != source_hash) bad=1
        print NR, $1, $2, $3, $4, $5, $6, "recorded", "unresolved-body", $7
    }
    END {exit bad}
' "$constraints" >>"$outdir/constraint-records.tsv" || die 'constraint provenance is incomplete'

# Independent inventory joins compare source keys with output keys.
awk -F '\t' 'BEGIN {OFS="\t"} {print $1, $3, $5}' "$candidate" | sort >"$tmp/source-candidates.tsv"
awk -F '\t' 'BEGIN {OFS="\t"} NR > 1 {print $2, $3, $4}' \
    "$outdir/adjudicated-records.tsv" | sort >"$tmp/adjudicated-candidates.tsv"
cmp -s "$tmp/source-candidates.tsv" "$tmp/adjudicated-candidates.tsv" || die 'candidate inventory differs'
awk -F '\t' 'BEGIN {OFS="\t"} {print $1, $2}' "$constraints" | sort >"$tmp/source-constraints.tsv"
awk -F '\t' 'BEGIN {OFS="\t"} NR > 1 {print $2, $3}' \
    "$outdir/constraint-records.tsv" | sort >"$tmp/recorded-constraints.tsv"
cmp -s "$tmp/source-constraints.tsv" "$tmp/recorded-constraints.tsv" || die 'constraint inventory differs'

source_evidence=0
while IFS=$'\t' read -r term kind line accepted_class target source_ref evidence reason; do
    [ "$term" = term ] && continue
    grep -Fqi -- "$evidence" "$canonical" || die "policy evidence missing: $term/$line"
    source_evidence=$((source_evidence + 1))
done <"$policy"
test "$source_evidence" -eq 10 || die 'source evidence witness count differs'

# A policy mutation must make the source-controlled witness check fail.
mutated_policy="$tmp/mutated-policy.tsv"
sed 's/The name of the subroutine is subroutine-name/The name of the subroutine is changed-name/' \
    "$policy" >"$mutated_policy"
if grep -Fqi -- 'The name of the subroutine is changed-name' "$canonical"; then
    die 'negative policy mutation did not fail'
else
    negative_control=observed_failure
fi

candidate_spans="$(awk 'END {print NR - 1}' "$outdir/adjudicated-records.tsv")"
accepted_records="$(awk -F '\t' 'NR > 1 && $6 == "accepted" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
accepted_lexical="$(awk -F '\t' 'NR > 1 && $6 == "accepted" && $7 == "lexical-class" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
accepted_metavariable="$(awk -F '\t' 'NR > 1 && $6 == "accepted" && $7 == "metavariable" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
accepted_semantic="$(awk -F '\t' 'NR > 1 && $6 == "accepted" && $7 == "semantic-role" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
retained_constraints="$(awk -F '\t' 'NR > 1 && $6 == "retained" && $3 == "constraint" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
constraint_records="$(awk 'END {print NR - 1}' "$outdir/constraint-records.tsv")"
source_linked_candidates="$(awk -F '\t' 'NR > 1 && $5 ~ /^[0-9]+$/ && $5 > 0 && $10 != "" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
source_linked_constraints="$(awk -F '\t' 'NR > 1 && $5 ~ /^[0-9]+$/ && $5 > 0 && $6 != "" {n++} END {print n + 0}' "$outdir/constraint-records.tsv")"
ambiguous_names="$(awk -F '\t' '$1 == "ambiguous_names" {print $2}' "$tmp/e0081/summary.tsv")"

test "$candidate_spans" -eq 266 || die 'adjudicated candidate count differs'
test "$accepted_records" -eq 10 || die 'accepted record count differs'
test "$accepted_lexical" -eq 2 || die 'lexical fact count differs'
test "$accepted_metavariable" -eq 1 || die 'metavariable fact count differs'
test "$accepted_semantic" -eq 7 || die 'semantic relation count differs'
test "$retained_constraints" -eq 256 || die 'retained constraint count differs'
test "$constraint_records" -eq 287 || die 'constraint record count differs'
test "$source_linked_candidates" -eq 266 || die 'candidate provenance count differs'
test "$source_linked_constraints" -eq 287 || die 'constraint provenance count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'candidate_spans\t%s\n' "$candidate_spans" >>"$outdir/summary.tsv"
printf 'accepted_records\t%s\n' "$accepted_records" >>"$outdir/summary.tsv"
printf 'accepted_lexical_class_records\t%s\n' "$accepted_lexical" >>"$outdir/summary.tsv"
printf 'accepted_metavariable_records\t%s\n' "$accepted_metavariable" >>"$outdir/summary.tsv"
printf 'accepted_semantic_role_records\t%s\n' "$accepted_semantic" >>"$outdir/summary.tsv"
printf 'retained_constraint_candidates\t%s\n' "$retained_constraints" >>"$outdir/summary.tsv"
printf 'ambiguous_candidate_names\t%s\n' "$ambiguous_names" >>"$outdir/summary.tsv"
printf 'unresolved_body_constraint_records\t%s\n' "$constraint_records" >>"$outdir/summary.tsv"
printf 'source_linked_candidates\t%s\n' "$source_linked_candidates" >>"$outdir/summary.tsv"
printf 'source_linked_constraints\t%s\n' "$source_linked_constraints" >>"$outdir/summary.tsv"
printf 'accepted_standardir_resolution_facts\t%s\n' "$accepted_records" >>"$outdir/summary.tsv"
printf 'formalized_constraint_bodies\t0\n' >>"$outdir/summary.tsv"
printf 'parser_projection_records\t0\n' >>"$outdir/summary.tsv"
printf 'model_calls\t0\n' >>"$outdir/summary.tsv"
printf 'independent_candidate_difference\t0\n' >>"$outdir/summary.tsv"
printf 'independent_constraint_difference\t0\n' >>"$outdir/summary.tsv"
printf 'source_evidence_matches\t%s\n' "$source_evidence" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'policy_sha256\t%s\n' "$(sha256sum "$policy" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'adjudicated_sha256\t%s\n' "$(sha256sum "$outdir/adjudicated-records.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'constraints_sha256\t%s\n' "$(sha256sum "$outdir/constraint-records.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0082 oracle: source-controlled semantic adjudication passed\n'
cat "$outdir/summary.tsv"
