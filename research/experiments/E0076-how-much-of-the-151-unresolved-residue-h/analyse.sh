#!/usr/bin/env bash
# Measure deterministic normative-prose evidence for the 151-name residue.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e70="$root/research/experiments/E0070-can-bounded-sentence-and-table-structure/analyse.sh"
e75="$root/research/experiments/E0075-can-the-178-name-post-alias-residue-be-c/analyse.sh"
units="$root/.cache/runs/E0070/R000001/logical-units.tsv"
all_candidates="$root/.cache/runs/E0070/R000001/candidate-spans.tsv"
classification="$root/.cache/runs/E0075/R000001/residue-classification.tsv"
outdir="${1:-$root/.cache/runs/E0076/R000001}"

die() { printf 'E0076: %s\n' "$1" >&2; exit 1; }
mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e70" >"$outdir/e0070.log" || die 'E0070 predecessor failed'
"$e75" >"$outdir/e0075.log" || die 'E0075 predecessor failed'
test -s "$units" || die 'logical-unit output missing'
test -s "$all_candidates" || die 'candidate output missing'

awk -F '\t' 'NR > 1 && $2 == "unresolved" {print $1}' "$classification" | sort >"$tmp/unresolved-names.txt"
unresolved_denominator="$(wc -l <"$tmp/unresolved-names.txt")"
test "$unresolved_denominator" -eq 151 || die 'unresolved denominator differs'
logical_units="$(wc -l <"$units")"

# E0070's bounded candidate inventory is the primary pass; filter it to the
# current residue denominator without adjudicating any candidate.
awk -F '\t' 'FILENAME == ARGV[1] {selected[$1]=1; next} ($1 in selected) {print}' \
    "$tmp/unresolved-names.txt" "$all_candidates" >"$outdir/candidate-spans.tsv"

candidate_spans="$(wc -l <"$outdir/candidate-spans.tsv")"
candidate_names="$(cut -f1 "$outdir/candidate-spans.tsv" | sort -u | wc -l)"
alias_candidates="$(awk -F '\t' '$3 == "alias" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
lexical_candidates="$(awk -F '\t' '$3 == "lexical-class" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
metavariable_candidates="$(awk -F '\t' '$3 == "metavariable" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
semantic_role_candidates="$(awk -F '\t' '$3 == "semantic-role" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
source_linked_candidates="$(awk -F '\t' '$10 != "" && $6 != "" && $8 != "" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
unresolved_after_patterns=$((unresolved_denominator - candidate_names))

awk -F '\t' 'FILENAME == ARGV[1] {selected[$1]=1; next} ($1 in selected) {print}' \
    "$tmp/unresolved-names.txt" "$root/.cache/runs/E0070/R000001/independent-candidates.tsv" | sort -u >"$tmp/independent.tsv"
cut -f1,3 "$outdir/candidate-spans.tsv" | sort -u >"$tmp/primary.tsv"
independent_difference="$(comm -3 "$tmp/primary.tsv" "$tmp/independent.tsv" | wc -l)"
test "$independent_difference" -eq 0 || die 'independent candidate set differs'
negative_control="$(awk -F '\t' '$1 == "negative_control" {print $2}' "$root/.cache/runs/E0070/R000001/summary.tsv")"
test "$negative_control" = "observed_failure" || die 'predecessor negative control failed'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'unresolved_denominator\t%s\n' "$unresolved_denominator" >>"$outdir/summary.tsv"
printf 'logical_units\t%s\n' "$logical_units" >>"$outdir/summary.tsv"
printf 'candidate_spans\t%s\n' "$candidate_spans" >>"$outdir/summary.tsv"
printf 'candidate_names\t%s\n' "$candidate_names" >>"$outdir/summary.tsv"
printf 'alias_candidates\t%s\n' "$alias_candidates" >>"$outdir/summary.tsv"
printf 'lexical_candidates\t%s\n' "$lexical_candidates" >>"$outdir/summary.tsv"
printf 'metavariable_candidates\t%s\n' "$metavariable_candidates" >>"$outdir/summary.tsv"
printf 'semantic_role_candidates\t%s\n' "$semantic_role_candidates" >>"$outdir/summary.tsv"
printf 'unresolved_after_patterns\t%s\n' "$unresolved_after_patterns" >>"$outdir/summary.tsv"
printf 'source_linked_candidates\t%s\n' "$source_linked_candidates" >>"$outdir/summary.tsv"
printf 'independent_difference\t%s\n' "$independent_difference" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'logical_units_sha256\t%s\n' "$(sha256sum "$units" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'candidate_spans_sha256\t%s\n' "$(sha256sum "$outdir/candidate-spans.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0076 oracle: deterministic unresolved-residue prose evidence completed\n'
cat "$outdir/summary.tsv"
