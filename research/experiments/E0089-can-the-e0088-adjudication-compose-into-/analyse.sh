#!/usr/bin/env bash
# Compose the E0088 C734 successor into a new semantic ledger.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0087="$root/research/experiments/E0087-can-one-composite-semantic-ledger-preser/analyse.sh"
e0088="$root/research/experiments/E0088-can-independent-normative-prohibition-wi/analyse.sh"
policy="$root/research/experiments/E0089-can-the-e0088-adjudication-compose-into-/successor-policy.tsv"
oracle="$root/research/experiments/E0089-can-the-e0088-adjudication-compose-into-/independent-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0089/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
e0087_summary_hash="56f9a1c9d05ca6ceb26d75b1e9d557d0880c72ebbcf61b69df35481168073a30"
e0088_predicate='(not (or (eq type-name DOUBLEPRECISION) (intrinsic-type-name type-name)))'

die() {
    printf 'E0089: %s\n' "$1" >&2
    exit 1
}

test -x "$e0087" || die 'E0087 analyzer is missing'
test -x "$e0088" || die 'E0088 analyzer is missing'
test -f "$policy" || die 'successor policy is missing'
test -f "$oracle" || die 'independent oracle is missing'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0087" "$tmp/e0087" >"$outdir/e0087.log" || die 'E0087 predecessor failed'
"$e0088" "$tmp/e0088" >"$outdir/e0088.log" || die 'E0088 adjudication failed'

e0087_summary_sha256="$(sha256sum "$tmp/e0087/summary.tsv" | cut -d' ' -f1)"
test "$e0087_summary_sha256" = "$e0087_summary_hash" || die 'E0087 predecessor summary changed'
e0087_resolved="$(awk -F '\t' '$1 == "resolved_constraints" {print $2}' "$tmp/e0087/summary.tsv")"
e0087_disputed="$(awk -F '\t' '$1 == "disputed_constraints" {print $2}' "$tmp/e0087/summary.tsv")"
test "$e0087_resolved" -eq 21 || die 'E0087 resolved denominator differs'
test "$e0087_disputed" -eq 1 || die 'E0087 disputed denominator differs'

e0088_candidate="$(awk -F '\t' 'NR > 1 && $1 == "C734" {if (n == 0) first=$11; if ($11 != first) bad=1; n++} END {if (n != 3 || bad) exit 1; print first}' "$tmp/e0088/adjudication.tsv")" || die 'E0088 C734 witness rows disagree'
test "$e0088_candidate" = "$e0088_predicate" || die 'E0088 predicate differs'

policy_rows="$(awk 'END {print NR - 1}' "$policy")"
test "$policy_rows" -eq 1 || die 'successor policy must contain one row'
awk -F '\t' '
    NR == 1 {next}
    NF != 6 || $1 != "C734" || $2 != "resolved" || $3 == "-" || $4 != "-" ||
        $5 != "accepted" || $6 != "E0088 cross-clause normative prohibition adjudication" {bad=1}
    END {exit bad}
' "$policy" || die 'successor policy schema differs'

awk -F '\t' -v OFS='\t' -v predicate="$e0088_candidate" '
    NR == 1 {print; next}
    $2 == "C734" {
        c734++
        $6="resolved"
        $12=predicate
        $13="-"
        $18="accepted"
        $19="E0088 cross-clause normative prohibition adjudication"
    }
    {print}
    END {if (c734 != 1) exit 1}
' "$tmp/e0087/formalizations.tsv" >"$outdir/formalizations.tsv" || die 'successor transformation did not find exactly one C734 row'

# Every non-C734 formalization field must remain byte-stable relative to E0087.
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "C734" {print}' "$tmp/e0087/formalizations.tsv" >"$tmp/e0087-non-c734.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "C734" {print}' "$outdir/formalizations.tsv" >"$tmp/e0089-non-c734.tsv"
cmp -s "$tmp/e0087-non-c734.tsv" "$tmp/e0089-non-c734.tsv" || die 'non-C734 predecessor rows changed'

# C734 retains its source identity, facts and evidence while changing only its
# adjudication state and predicate-b candidate.
awk -F '\t' -v OFS='\t' '$2 == "C734" {print $3, $4, $5, $7, $8, $9, $10, $11, $14, $15, $16, $17}' "$tmp/e0087/formalizations.tsv" | sort >"$tmp/old-c734-stable.tsv"
awk -F '\t' -v OFS='\t' '$2 == "C734" {print $3, $4, $5, $7, $8, $9, $10, $11, $14, $15, $16, $17}' "$outdir/formalizations.tsv" | sort >"$tmp/new-c734-stable.tsv"
cmp -s "$tmp/old-c734-stable.tsv" "$tmp/new-c734-stable.tsv" || die 'C734 source or fact fields changed'

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
' "$outdir/fact-edges.tsv" >"$outdir/topological-order.tsv" || die 'successor dependency graph contains a cycle'

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
' "$outdir/fact-edges.tsv" || die 'successor topological order violates an edge'

mutated_oracle="$tmp/mutated-oracle.tsv"
sed 's/^C734\tresolved/C734\tdisputed/' "$oracle" >"$mutated_oracle"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3}' "$mutated_oracle" | sort >"$tmp/mutated-status.tsv"
if cmp -s "$tmp/actual-status.tsv" "$tmp/mutated-status.tsv"; then
    die 'negative status mutation did not fail'
fi
sed 's/(not (or (eq type-name DOUBLEPRECISION) (intrinsic-type-name type-name)))/(or (not (eq type-name DOUBLEPRECISION)) (intrinsic-type-name type-name))/' "$oracle" >"$mutated_oracle"
awk -F '\t' -v OFS='\t' 'NR > 1 && $2 != "unresolved" {print $1, $5, $6}' "$mutated_oracle" | sort >"$tmp/mutated-predicates.tsv"
if cmp -s "$tmp/actual-predicates.tsv" "$tmp/mutated-predicates.tsv"; then
    die 'negative predicate mutation did not fail'
fi
negative_control=observed_failure

eligible_constraints="$(awk 'END {print NR - 1}' "$outdir/formalizations.tsv")"
selected_rows="$(awk -F '\t' 'NR > 1 && ($6 != "unresolved" || $2 == "C1588") {n++} END {print n + 0}' "$outdir/formalizations.tsv")"
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
test "$resolved_constraints" -eq 22 || die 'resolved count differs'
test "$disputed_constraints" -eq 0 || die 'disputed count differs'
test "$unresolved_constraints" -eq 265 || die 'unresolved count differs'
test "$accepted_predicates" -eq 22 || die 'accepted predicate count differs'
test "$competing_candidate_records" -eq 0 || die 'competing candidate count differs'
test "$source_hash_matches" -eq 287 || die 'source hash count differs'
test "$source_evidence_matches" -eq 22 || die 'source evidence count differs'
test "$independent_oracle_agreement" -eq 0 || die 'independent oracle agreement differs'
test "$adjudication_gate_violations" -eq 0 || die 'adjudication gate has violations'
test "$required_fact_records" -eq 49 || die 'required fact count differs'
test "$provided_fact_records" -eq 22 || die 'provided fact count differs'
test "$dependency_edges" -eq 71 || die 'dependency edge count differs'

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

printf 'E0089 oracle: E0088 adjudication composed into successor ledger\n'
cat "$outdir/summary.tsv"
