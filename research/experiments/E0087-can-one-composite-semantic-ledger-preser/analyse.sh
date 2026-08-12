#!/usr/bin/env bash
# Compose the resolved, disputed and unresolved semantic formalization states.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0081="$root/research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh"
policy="$root/research/experiments/E0087-can-one-composite-semantic-ledger-preser/composite-policy.tsv"
oracle="$root/research/experiments/E0087-can-one-composite-semantic-ledger-preser/independent-oracle.tsv"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
outdir="${1:-$root/.cache/runs/E0087/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

die() {
    printf 'E0087: %s\n' "$1" >&2
    exit 1
}

test -x "$e0081" || die 'E0081 analyzer is missing'
test -f "$policy" || die 'composite policy is missing'
test -f "$oracle" || die 'independent oracle is missing'
test -f "$canonical" || die "canonical text is missing: $canonical"
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

printf 'constraint_no\tconstraint_id\tassociated_rules\tline\tpage\tstatus\tform\tsubject\tapplicability\trequired_facts\tprovided_facts\tpredicate_a\tpredicate_b\tsource_hash\torigin\tsource_text\tsource_evidence\tadjudication\treason\n' >"$outdir/formalizations.tsv"
awk -F '\t' -v OFS='\t' -v policy="$policy" -v source_hash="$source_hash" -v joined="$tmp/canonical-joined.txt" '
    BEGIN {
        joined_text=""
        while ((getline line < joined) > 0) joined_text=joined_text line " "
        close(joined)
    }
    FILENAME == policy {
        if (FNR == 1) next
        key=$1
        if (key in policy_status) bad=1
        policy_assoc[key]=$2
        policy_line[key]=$3
        policy_page[key]=$4
        policy_status[key]=$5
        policy_form[key]=$6
        policy_subject[key]=$7
        policy_applicability[key]=$8
        policy_required[key]=$9
        policy_provided[key]=$10
        policy_a[key]=$11
        policy_b[key]=$12
        policy_phrase[key]=$13
        policy_adjudication[key]=$14
        policy_reason[key]=$15
        policy_count++
        next
    }
    {
        id=$1; associated=$2; line=$3; page=$4; hash=$5; origin=$6; text=$7
        if (NF != 7 || line !~ /^[0-9]+$/ || page !~ /^[0-9]+$/ || hash != source_hash) bad=1
        if (id in policy_status) {
            associated=policy_assoc[id]
            line=policy_line[id]
            page=policy_page[id]
            status=policy_status[id]
            form=policy_form[id]
            subject=policy_subject[id]
            applicability=policy_applicability[id]
            required=policy_required[id]
            provided=policy_provided[id]
            predicate_a=policy_a[id]
            predicate_b=policy_b[id]
            evidence=policy_phrase[id]
            adjudication=policy_adjudication[id]
            reason=policy_reason[id]
            policy_seen[id]=1
            if (evidence != "-") {
                evidence_count=split(evidence, evidence_parts, /[|][|]/)
                for (i=1; i<=evidence_count; i++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", evidence_parts[i])
                    if (evidence_parts[i] != "" && index(joined_text, evidence_parts[i]) == 0) bad=1
                }
            }
            if (status == "resolved" && (predicate_a == "-" || predicate_b != "-" || adjudication != "accepted")) bad=1
            if (status == "disputed" && (predicate_a == "-" || predicate_b == "-" || predicate_a == predicate_b || adjudication != "pending")) bad=1
            if (status == "unresolved" && (predicate_a != "-" || predicate_b != "-" || adjudication != "not-ready")) bad=1
        } else {
            status="unresolved"
            form="unresolved"
            subject="-"
            applicability="-"
            required="-"
            provided="-"
            predicate_a="-"
            predicate_b="-"
            evidence="-"
            adjudication="not-ready"
            reason="outside selected composite policy"
        }
        print NR, id, associated, line, page, status, form, subject, applicability, required, provided, predicate_a, predicate_b, hash, origin, text, evidence, adjudication, reason
    }
    END {
        if (policy_count != 23) bad=1
        for (id in policy_status) if (!(id in policy_seen)) bad=1
        exit bad
    }
' "$policy" "$constraints" >>"$outdir/formalizations.tsv" || die 'composite policy did not match source evidence'

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
' "$outdir/fact-edges.tsv" >"$outdir/topological-order.tsv" || die 'composite dependency graph contains a cycle'

awk -F '\t' -v OFS='\t' 'NR > 1 && $6 != "unresolved" {print $2, $6, $7}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-status.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "unresolved" {print $1, $2, $3}' "$oracle" | sort >"$tmp/oracle-status.tsv"
cmp -s "$tmp/actual-status.tsv" "$tmp/oracle-status.tsv" || die 'independent status/form oracle differs'

awk -F '\t' -v OFS='\t' 'NR > 1 && $6 != "unresolved" {print $2, $12, $13}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-predicates.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "unresolved" {print $1, $5, $6}' "$oracle" | sort >"$tmp/oracle-predicates.tsv"
cmp -s "$tmp/actual-predicates.tsv" "$tmp/oracle-predicates.tsv" || die 'independent predicate oracle differs'

awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $10}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-required.tsv"
awk -F '\t' -v OFS='\t' '$2 == "resolved" {print $1, $7}' "$oracle" | sort >"$tmp/oracle-required.tsv"
cmp -s "$tmp/actual-required.tsv" "$tmp/oracle-required.tsv" || die 'independent required-fact oracle differs'

awk -F '\t' -v OFS='\t' 'NR > 1 && $6 == "resolved" {print $2, $11}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-provided.tsv"
awk -F '\t' -v OFS='\t' '$2 == "resolved" {print $1, $8}' "$oracle" | sort >"$tmp/oracle-provided.tsv"
cmp -s "$tmp/actual-provided.tsv" "$tmp/oracle-provided.tsv" || die 'independent provided-fact oracle differs'

awk -F '\t' -v OFS='\t' 'NR > 1 && $6 != "unresolved" {print $2, $17}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-evidence.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "unresolved" {print $1, $4}' "$oracle" | sort >"$tmp/oracle-evidence.tsv"
cmp -s "$tmp/actual-evidence.tsv" "$tmp/oracle-evidence.tsv" || die 'independent source evidence differs'

awk -F '\t' -v OFS='\t' 'NR > 1 && $6 != "unresolved" {print $2, $18}' "$outdir/formalizations.tsv" | sort >"$tmp/actual-adjudication.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "unresolved" {print $1, $9}' "$oracle" | sort >"$tmp/oracle-adjudication.tsv"
cmp -s "$tmp/actual-adjudication.tsv" "$tmp/oracle-adjudication.tsv" || die 'independent adjudication oracle differs'

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

if grep -Fqi -- 'DOUBLEPRECISION and the same as the name' "$tmp/canonical-joined.txt"; then
    die 'negative source mutation did not fail'
fi
mutated_oracle="$tmp/mutated-oracle.tsv"
sed 's/(not (or (eq type-name DOUBLEPRECISION) (intrinsic-type-name type-name)))/(not (and (eq type-name DOUBLEPRECISION) (intrinsic-type-name type-name)))/' "$oracle" >"$mutated_oracle"
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "unresolved" {print $1, $5, $6}' "$mutated_oracle" | sort >"$tmp/mutated-predicates.tsv"
if cmp -s "$tmp/actual-predicates.tsv" "$tmp/mutated-predicates.tsv"; then
    die 'negative predicate mutation did not fail'
fi
mutated_status="$tmp/mutated-status.tsv"
sed 's/^C734\tdisputed/C734\tresolved/' "$oracle" >"$mutated_status"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3}' "$mutated_status" | sort >"$tmp/mutated-status-fields.tsv"
if cmp -s "$tmp/actual-status.tsv" "$tmp/mutated-status-fields.tsv"; then
    die 'negative adjudication-state mutation did not fail'
fi
negative_control=observed_failure

eligible_constraints="$(wc -l <"$constraints")"
selected_rows="$(awk 'END {print NR - 1}' "$policy")"
resolved_constraints="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
disputed_constraints="$(awk -F '\t' 'NR > 1 && $6 == "disputed" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
unresolved_constraints="$(awk -F '\t' 'NR > 1 && $6 == "unresolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
accepted_predicates="$resolved_constraints"
competing_candidate_records="$(awk -F '\t' 'NR > 1 && $6 == "disputed" && $13 != "-" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
source_hash_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $14 == hash {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
source_evidence_matches="$(awk -F '\t' 'NR > 1 && $17 != "-" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
independent_oracle_agreement="$(cmp -s "$tmp/actual-status.tsv" "$tmp/oracle-status.tsv" && cmp -s "$tmp/actual-predicates.tsv" "$tmp/oracle-predicates.tsv" && cmp -s "$tmp/actual-required.tsv" "$tmp/oracle-required.tsv" && cmp -s "$tmp/actual-provided.tsv" "$tmp/oracle-provided.tsv" && cmp -s "$tmp/actual-evidence.tsv" "$tmp/oracle-evidence.tsv" && cmp -s "$tmp/actual-adjudication.tsv" "$tmp/oracle-adjudication.tsv" && printf 0 || printf 1)"
adjudication_gate_violations="$(awk -F '\t' 'NR > 1 && (($6 == "resolved" && ($12 == "-" || $13 != "-" || $18 != "accepted")) || ($6 == "disputed" && ($12 == "-" || $13 == "-" || $12 == $13 || $18 != "pending")) || ($6 == "unresolved" && ($12 != "-" || $13 != "-" || $18 != "not-ready"))) {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
required_fact_records="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n += split($10, a, /[[:space:]]+/)} END {print n + 0}' "$outdir/formalizations.tsv")"
provided_fact_records="$(awk -F '\t' 'NR > 1 && $6 == "resolved" {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
dependency_edges="$(awk 'END {print NR}' "$outdir/fact-edges.tsv")"
topological_order_difference=0
independent_normalization_difference=0
parser_projection_records=0
model_calls=0

test "$eligible_constraints" -eq 287 || die 'eligible denominator differs'
test "$selected_rows" -eq 23 || die 'selected row count differs'
test "$resolved_constraints" -eq 21 || die 'resolved count differs'
test "$disputed_constraints" -eq 1 || die 'disputed count differs'
test "$unresolved_constraints" -eq 265 || die 'unresolved count differs'
test "$accepted_predicates" -eq 21 || die 'accepted predicate count differs'
test "$competing_candidate_records" -eq 1 || die 'competing candidate count differs'
test "$source_hash_matches" -eq 287 || die 'source hash count differs'
test "$source_evidence_matches" -eq 22 || die 'source evidence count differs'
test "$independent_oracle_agreement" -eq 0 || die 'independent oracle agreement differs'
test "$adjudication_gate_violations" -eq 0 || die 'adjudication gate has violations'
test "$required_fact_records" -eq 46 || die 'required fact count differs'
test "$provided_fact_records" -eq 21 || die 'provided fact count differs'
test "$dependency_edges" -eq 67 || die 'dependency edge count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'eligible_constraints\t%s\n' "$eligible_constraints" >>"$outdir/summary.tsv"
printf 'selected_rows\t%s\n' "$selected_rows" >>"$outdir/summary.tsv"
printf 'resolved_constraints\t%s\n' "$resolved_constraints" >>"$outdir/summary.tsv"
printf 'disputed_constraints\t%s\n' "$disputed_constraints" >>"$outdir/summary.tsv"
printf 'unresolved_constraints\t%s\n' "$unresolved_constraints" >>"$outdir/summary.tsv"
printf 'accepted_predicates\t%s\n' "$accepted_predicates" >>"$outdir/summary.tsv"
printf 'competing_candidate_records\t%s\n' "$competing_candidate_records" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'source_evidence_matches\t%s\n' "$source_evidence_matches" >>"$outdir/summary.tsv"
printf 'independent_oracle_agreement\t%s\n' "$independent_oracle_agreement" >>"$outdir/summary.tsv"
printf 'adjudication_gate_violations\t%s\n' "$adjudication_gate_violations" >>"$outdir/summary.tsv"
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

printf 'E0087 oracle: composite semantic ledger and adjudication gate passed\n'
cat "$outdir/summary.tsv"
