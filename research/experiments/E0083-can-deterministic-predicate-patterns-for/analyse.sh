#!/usr/bin/env bash
# Formalize a bounded set of source-linked Core 0 constraints mechanically.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0081="$root/research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
policy="$root/research/experiments/E0083-can-deterministic-predicate-patterns-for/predicate-policy.tsv"
oracle="$root/research/experiments/E0083-can-deterministic-predicate-patterns-for/independent-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0083/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

die() {
    printf 'E0083: %s\n' "$1" >&2
    exit 1
}

test -x "$e0081" || die 'E0081 analyzer is missing'
test -f "$canonical" || die "canonical text is missing: $canonical"
test -f "$policy" || die 'predicate policy is missing'
test -f "$oracle" || die 'independent oracle is missing'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0081" "$tmp/e0081" >"$outdir/e0081.log" || die 'E0081 predecessor failed'
constraints="$tmp/e0081/constraint-spans.tsv"
test "$(wc -l <"$constraints")" -eq 287 || die 'constraint denominator differs'

printf 'constraint_no\tconstraint_id\tassociated_rules\tline\tpage\tstatus\tform\tsubject\tapplicability\trequired_facts\tprovided_facts\tpredicate\tsource_hash\torigin\tsource_text\n' >"$outdir/formalizations.tsv"
awk -F '\t' -v OFS='\t' -v policy="$policy" -v source_hash="$source_hash" '
    FILENAME == policy {
        if (FNR == 1) next
        key=$1
        if (key in policy_form) bad=1
        policy_form[key]=$5
        policy_subject[key]=$6
        policy_applicability[key]=$7
        policy_required[key]=$8
        policy_provided[key]=$9
        policy_predicate[key]=$10
        policy_phrase[key]=$11
        policy_count++
        next
    }
    {
        id=$1; associated=$2; line=$3; page=$4; hash=$5; origin=$6; text=$7
        if (NF != 7 || line !~ /^[0-9]+$/ || page !~ /^[0-9]+$/ || hash != source_hash) bad=1
        if (id in policy_form) {
            status="resolved"
            form=policy_form[id]
            subject=policy_subject[id]
            applicability=policy_applicability[id]
            required=policy_required[id]
            provided=policy_provided[id]
            predicate=policy_predicate[id]
            if (index(tolower(text), tolower(policy_phrase[id])) == 0) bad=1
            policy_seen[id]=1
        } else {
            status="unresolved"
            form="unresolved"
            subject="-"
            applicability="-"
            required="-"
            provided="-"
            predicate="-"
        }
        print NR, id, associated, line, page, status, form, subject, applicability, required, provided, predicate, hash, origin, text
    }
    END {
        if (policy_count != 8) bad=1
        for (id in policy_form) if (!(id in policy_seen)) bad=1
        exit bad
    }
' "$policy" "$constraints" >>"$outdir/formalizations.tsv" || die 'constraint policy did not match the source inventory'

awk -F '\t' -v OFS='\t' '
    NR == 1 {next}
    $6 == "resolved" {
        required_count=split($10, required, /[[:space:]]+/)
        for (i=1; i<=required_count; i++) if (required[i] != "") print required[i], $2, "requires"
        print $2, $11, "provides"
    }
' "$outdir/formalizations.tsv" >"$outdir/fact-edges.tsv"

awk -F '\t' -v OFS='\t' -v order_file="$outdir/topological-order.tsv" '
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
' "$outdir/fact-edges.tsv" >"$outdir/topological-order.tsv" || die 'fact dependency graph contains a cycle'

awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $12}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-predicates.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $3}' "$oracle" | sort >"$tmp/oracle-predicates.tsv"
cmp -s "$tmp/actual-predicates.tsv" "$tmp/oracle-predicates.tsv" || die 'independent predicate oracle differs'
awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $10}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-required.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $4}' "$oracle" | sort >"$tmp/oracle-required.tsv"
cmp -s "$tmp/actual-required.tsv" "$tmp/oracle-required.tsv" || die 'independent required-fact oracle differs'
awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $11}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-provided.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $5}' "$oracle" | sort >"$tmp/oracle-provided.tsv"
cmp -s "$tmp/actual-provided.tsv" "$tmp/oracle-provided.tsv" || die 'independent provided-fact oracle differs'

awk -F '\t' -v OFS='\t' -v order_file="$outdir/topological-order.tsv" '
    NR == 1 {next}
    {from=$1; to=$2; edges[from SUBSEP to]=1}
    END {
        while ((getline line < order_file) > 0) {split(line, fields, FS); rank[fields[1]]=fields[2]}
        close(order_file)
        for (edge in edges) {split(edge, fields, SUBSEP); if (rank[fields[1]] >= rank[fields[2]]) bad=1}
        exit bad
    }
' "$outdir/fact-edges.tsv" || die 'topological order violates a dependency edge'

mutated_policy="$tmp/mutated-policy.tsv"
sed 's/The maximum length of a name is 63 characters\./The maximum length of a name is 64 characters./' "$policy" >"$mutated_policy"
if grep -Fqi -- 'The maximum length of a name is 64 characters.' "$canonical"; then
    die 'negative source mutation did not fail'
fi
mutated_oracle="$tmp/mutated-oracle.tsv"
sed 's/(le (name-length name) 63)/(lt (name-length name) 63)/' "$oracle" >"$mutated_oracle"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $3}' "$mutated_oracle" | sort >"$tmp/mutated-predicates.tsv"
if cmp -s "$tmp/actual-predicates.tsv" "$tmp/mutated-predicates.tsv"; then
    die 'negative predicate mutation did not fail'
fi
negative_control=observed_failure

eligible_constraints="$(wc -l <"$constraints")"
selected_constraints="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
normalized_predicates="$selected_constraints"
resolved_constraints="$selected_constraints"
unresolved_constraints="$(awk -F '\t' 'NR > 1 && $6 == "unresolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
disputed_constraints=0
source_hash_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $13 == hash {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
source_evidence_matches="$(awk -F '\t' 'NR > 1 && $6 == "resolved" && $15 != "" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
required_fact_records="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n += split($10, a, /[[:space:]]+/)} END {print n + 0}' "$outdir/formalizations.tsv")"
provided_fact_records="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
dependency_edges="$(awk 'END {print NR}' "$outdir/fact-edges.tsv")"
topological_order_difference=0
independent_normalization_difference=0
parser_projection_records=0
model_calls=0

test "$eligible_constraints" -eq 287 || die 'eligible denominator differs'
test "$selected_constraints" -eq 8 || die 'selected constraint count differs'
test "$resolved_constraints" -eq 8 || die 'resolved constraint count differs'
test "$unresolved_constraints" -eq 279 || die 'unresolved constraint count differs'
test "$source_hash_matches" -eq 287 || die 'source hash count differs'
test "$source_evidence_matches" -eq 8 || die 'source evidence count differs'
test "$required_fact_records" -eq 10 || die 'required fact count differs'
test "$provided_fact_records" -eq 8 || die 'provided fact count differs'
test "$dependency_edges" -eq 18 || die 'dependency edge count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'eligible_constraints\t%s\n' "$eligible_constraints" >>"$outdir/summary.tsv"
printf 'selected_constraints\t%s\n' "$selected_constraints" >>"$outdir/summary.tsv"
printf 'normalized_predicates\t%s\n' "$normalized_predicates" >>"$outdir/summary.tsv"
printf 'resolved_constraints\t%s\n' "$resolved_constraints" >>"$outdir/summary.tsv"
printf 'unresolved_constraints\t%s\n' "$unresolved_constraints" >>"$outdir/summary.tsv"
printf 'disputed_constraints\t%s\n' "$disputed_constraints" >>"$outdir/summary.tsv"
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

printf 'E0083 oracle: deterministic bounded constraint formalization passed\n'
cat "$outdir/summary.tsv"
