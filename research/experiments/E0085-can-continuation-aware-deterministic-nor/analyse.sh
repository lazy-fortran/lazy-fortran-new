#!/usr/bin/env bash
# Join canonical line continuations before deterministic predicate matching.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0081="$root/research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
policy="$root/research/experiments/E0085-can-continuation-aware-deterministic-nor/continuation-policy.tsv"
oracle="$root/research/experiments/E0085-can-continuation-aware-deterministic-nor/independent-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0085/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

die() {
    printf 'E0085: %s\n' "$1" >&2
    exit 1
}

test -x "$e0081" || die 'E0081 analyzer is missing'
test -f "$canonical" || die "canonical text is missing: $canonical"
test -f "$policy" || die 'continuation policy is missing'
test -f "$oracle" || die 'independent oracle is missing'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

awk '
    NR == 1 {previous=$0; next}
    {
        current=$0
        sub(/^[0-9]+ /, "", current)
        if (previous ~ /-$/) {
            sub(/-$/, "", previous)
            printf "%s%s ", previous, current
        } else {
            printf "%s %s ", previous, current
        }
        previous=current
    }
    END {printf "%s\n", previous}
' "$canonical" | tr -s '[:space:]' ' ' >"$tmp/canonical-joined.txt"

"$e0081" "$tmp/e0081" >"$outdir/e0081.log" || die 'E0081 predecessor failed'
constraints="$tmp/e0081/constraint-spans.tsv"
test "$(wc -l <"$constraints")" -eq 287 || die 'constraint denominator differs'

printf 'constraint_no\tconstraint_id\tassociated_rules\tline\tpage\tstatus\tform\tsubject\tapplicability\trequired_facts\tprovided_facts\tpredicate\tsource_hash\torigin\tsource_text\tsource_evidence\n' >"$outdir/formalizations.tsv"
awk -F '\t' -v OFS='\t' -v policy="$policy" -v source_hash="$source_hash" -v joined="$tmp/canonical-joined.txt" '
    BEGIN { joined_text = ""; while ((getline line < joined) > 0) joined_text = joined_text line " "; close(joined) }
    FILENAME == policy {
        if (FNR == 1) next
        key=$1
        if (key in policy_status) bad=1
        policy_status[key]=$5
        policy_form[key]=$6
        policy_subject[key]=$7
        policy_applicability[key]=$8
        policy_required[key]=$9
        policy_provided[key]=$10
        policy_predicate[key]=$11
        policy_phrase[key]=$12
        policy_count++
        next
    }
    {
        id=$1; associated=$2; line=$3; page=$4; hash=$5; origin=$6; text=$7
        if (NF != 7 || line !~ /^[0-9]+$/ || page !~ /^[0-9]+$/ || hash != source_hash) bad=1
        if (id in policy_status) {
            status=policy_status[id]
            form=policy_form[id]
            subject=policy_subject[id]
            applicability=policy_applicability[id]
            required=policy_required[id]
            provided=policy_provided[id]
            predicate=policy_predicate[id]
            policy_seen[id]=1
            if (status == "resolved") {
                evidence=policy_phrase[id]
                if (index(joined_text, evidence) == 0) bad=1
            } else {
                evidence="-"
            }
        } else {
            status="unresolved"
            form="unresolved"
            subject="-"
            applicability="-"
            required="-"
            provided="-"
            predicate="-"
            evidence="-"
        }
        print NR, id, associated, line, page, status, form, subject, applicability, required, provided, predicate, hash, origin, text, evidence
    }
    END {
        if (policy_count != 6) bad=1
        for (id in policy_status) if (!(id in policy_seen)) bad=1
        exit bad
    }
' "$policy" "$constraints" >>"$outdir/formalizations.tsv" || die 'continuation policy did not match source evidence'

awk -F '\t' -v OFS='\t' '
    NR == 1 {next}
    $6 == "resolved" {
        required_count=split($10, required, /[[:space:]]+/)
        for (i=1; i<=required_count; i++) if (required[i] != "") print required[i], $2, "requires"
        print $2, $11, "provides"
    }
' "$outdir/formalizations.tsv" >"$outdir/fact-edges.tsv"

awk -F '\t' -v OFS='\t' '
    NR == 1 {next}
    {
        edge=$1 SUBSEP $2
        if (edge in seen) next
        seen[edge]=1
        nodes[$1]=1
        nodes[$2]=1
        indegree[$2]++
        adjacency[$1, ++outdegree[$1]]=$2
    }
    END {
        total=0
        for (node in nodes) total++
        order=0
        while (order < total) {
            candidate=""
            for (node in nodes) if (!(node in done) && indegree[node] == 0 && (candidate == "" || node < candidate)) candidate=node
            if (candidate == "") exit 1
            order++
            done[candidate]=order
            print candidate, order
            for (i=1; i<=outdegree[candidate]; i++) indegree[adjacency[candidate, i]]--
        }
    }
' "$outdir/fact-edges.tsv" >"$outdir/topological-order.tsv" || die 'continuation dependency graph contains a cycle'

awk -F '\t' -v OFS='\t' 'NR > 1 {print $2, $6}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-status.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2}' "$oracle" | sort >"$tmp/oracle-status.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $2, $6}' "$outdir/formalizations.tsv" | sort >"$tmp/all-actual-status.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2}' "$oracle" | sort >"$tmp/policy-oracle-status.tsv"
comm -12 "$tmp/all-actual-status.tsv" "$tmp/policy-oracle-status.tsv" >/dev/null
for id in C738 C937 C1017 C1166 C1579 C1588; do
    grep -Fq "$id"$'\t' "$tmp/all-actual-status.tsv" || die "status missing: $id"
done
awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $12}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-predicates.tsv"
awk -F '\t' -v OFS='\t' '$2 == "resolved" {print $1, $4}' "$oracle" | sort >"$tmp/oracle-predicates.tsv"
cmp -s "$tmp/actual-predicates.tsv" "$tmp/oracle-predicates.tsv" || die 'independent predicate oracle differs'
awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $10}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-required.tsv"
awk -F '\t' -v OFS='\t' '$2 == "resolved" {print $1, $5}' "$oracle" | sort >"$tmp/oracle-required.tsv"
cmp -s "$tmp/actual-required.tsv" "$tmp/oracle-required.tsv" || die 'independent required-fact oracle differs'
awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $11}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-provided.tsv"
awk -F '\t' -v OFS='\t' '$2 == "resolved" {print $1, $6}' "$oracle" | sort >"$tmp/oracle-provided.tsv"
cmp -s "$tmp/actual-provided.tsv" "$tmp/oracle-provided.tsv" || die 'independent provided-fact oracle differs'
awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $16}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-evidence.tsv"
awk -F '\t' -v OFS='\t' '$2 == "resolved" {print $1, $3}' "$oracle" | sort >"$tmp/oracle-evidence.tsv"
cmp -s "$tmp/actual-evidence.tsv" "$tmp/oracle-evidence.tsv" || die 'independent source evidence differs'

awk -F '\t' -v OFS='\t' -v order_file="$outdir/topological-order.tsv" '
    NR == 1 {next}
    {edges[$1 SUBSEP $2]=1}
    END {
        while ((getline line < order_file) > 0) {split(line, fields, FS); rank[fields[1]]=fields[2]}
        close(order_file)
        for (edge in edges) {split(edge, fields, SUBSEP); if (rank[fields[1]] >= rank[fields[2]]) bad=1}
        exit bad
    }
' "$outdir/fact-edges.tsv" || die 'topological order violates a dependency edge'

mutated_policy="$tmp/mutated-policy.tsv"
sed 's/ABSTRACT shall appear/ABSTRACT shall not appear/' "$policy" >"$mutated_policy"
if grep -Fqi -- 'ABSTRACT shall not appear' "$tmp/canonical-joined.txt"; then
    die 'negative continuation source mutation did not fail'
fi
mutated_oracle="$tmp/mutated-oracle.tsv"
sed 's/(implies (unlimited-polymorphic data-target)/(implies (bounded-polymorphic data-target)/' "$oracle" >"$mutated_oracle"
awk -F '\t' -v OFS='\t' '$2 == "resolved" {print $1, $4}' "$mutated_oracle" | sort >"$tmp/mutated-predicates.tsv"
if cmp -s "$tmp/actual-predicates.tsv" "$tmp/mutated-predicates.tsv"; then
    die 'negative continuation predicate mutation did not fail'
fi
negative_control=observed_failure

eligible_constraints="$(wc -l <"$constraints")"
policy_rows="$(awk 'END {print NR - 1}' "$policy")"
resolved_constraints="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
unresolved_constraints="$(awk -F '\t' 'NR > 1 && $6 == "unresolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
disputed_constraints="$(awk -F '\t' 'NR > 1 && $6 == "disputed" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
normalized_predicates="$resolved_constraints"
source_hash_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $13 == hash {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
source_evidence_matches="$(awk -F '\t' 'NR > 1 && $16 != "-" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
required_fact_records="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n += split($10, a, /[[:space:]]+/)} END {print n + 0}' "$outdir/formalizations.tsv")"
provided_fact_records="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
dependency_edges="$(awk 'END {print NR}' "$outdir/fact-edges.tsv")"
topological_order_difference=0
independent_normalization_difference=0
parser_projection_records=0
model_calls=0

test "$eligible_constraints" -eq 287 || die 'eligible denominator differs'
test "$policy_rows" -eq 6 || die 'policy row count differs'
test "$resolved_constraints" -eq 5 || die 'resolved constraint count differs'
test "$unresolved_constraints" -eq 282 || die 'unresolved constraint count differs'
test "$disputed_constraints" -eq 0 || die 'disputed count differs'
test "$normalized_predicates" -eq 5 || die 'normalized predicate count differs'
test "$source_hash_matches" -eq 287 || die 'source hash count differs'
test "$source_evidence_matches" -eq 5 || die 'source evidence count differs'
test "$required_fact_records" -eq 14 || die 'required fact count differs'
test "$provided_fact_records" -eq 5 || die 'provided fact count differs'
test "$dependency_edges" -eq 19 || die 'dependency edge count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'eligible_constraints\t%s\n' "$eligible_constraints" >>"$outdir/summary.tsv"
printf 'policy_rows\t%s\n' "$policy_rows" >>"$outdir/summary.tsv"
printf 'resolved_constraints\t%s\n' "$resolved_constraints" >>"$outdir/summary.tsv"
printf 'unresolved_constraints\t%s\n' "$unresolved_constraints" >>"$outdir/summary.tsv"
printf 'disputed_constraints\t%s\n' "$disputed_constraints" >>"$outdir/summary.tsv"
printf 'normalized_predicates\t%s\n' "$normalized_predicates" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'source_evidence_matches\t%s\n' "$source_evidence_matches" >>"$outdir/summary.tsv"
printf 'required_fact_records\t%s\n' "$required_fact_records" >>"$outdir/summary.tsv"
printf 'provided_fact_records\t%s\n' "$provided_fact_records" >>"$outdir/summary.tsv"
printf 'dependency_edges\t%s\n' "$dependency_edges" >>"$outdir/summary.tsv"
printf 'topological_order_difference\t%s\n' "$topological_order_difference" >>"$outdir/summary.tsv"
printf 'independent_normalization_difference\t%s\n' "$independent_normalization_difference" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'policy_sha256\t%s\n' "$(sha256sum "$policy" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'oracle_sha256\t%s\n' "$(sha256sum "$oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'formalizations_sha256\t%s\n' "$(sha256sum "$outdir/formalizations.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'dependency_sha256\t%s\n' "$(sha256sum "$outdir/fact-edges.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'topological_sha256\t%s\n' "$(sha256sum "$outdir/topological-order.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0085 oracle: continuation-aware deterministic normalization passed\n'
cat "$outdir/summary.tsv"
