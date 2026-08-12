#!/usr/bin/env bash
# Compose retained E0077 candidates with the unresolved residue.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e74="$root/research/experiments/E0074-can-the-accepted-e0072-aliases-integrate/analyse.sh"
e75="$root/research/experiments/E0075-can-the-178-name-post-alias-residue-be-c/analyse.sh"
e77="$root/research/experiments/E0077-can-source-controlled-adjudication-separ/analyse.sh"
facts="$root/.cache/runs/E0075/R000001/residue-classification.tsv"
adjudicated="$root/.cache/runs/E0077/R000001/adjudicated.tsv"
outdir="${1:-$root/.cache/runs/E0078/R000001}"
e74_integrated_hash="3c62ea0c5816348c7dbff2b8d9895725ba61c02507949ea978d62be21a52a8c5"
e74_dispatch_hash="953311db9e6c1cb5143613933156276e4ef9d399b6570948d12aa800bd987c2f"

die() { printf 'E0078: %s\n' "$1" >&2; exit 1; }
mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e74" >"$outdir/e0074.log" || die 'E0074 predecessor failed'
"$e75" >"$outdir/e0075.log" || die 'E0075 predecessor failed'
"$e77" >"$outdir/e0077.log" || die 'E0077 predecessor failed'
integrated="$root/.cache/runs/E0074/R000001/integrated-syntax.sx"
dispatch="$root/.cache/runs/E0074/R000001/direct-dispatch.tsv"
projection="$root/.cache/runs/E0072/R000001/parser-projection.tsv"
test "$(sha256sum "$integrated" | cut -d' ' -f1)" = "$e74_integrated_hash" || die 'E0074 integrated hash changed'
test "$(sha256sum "$dispatch" | cut -d' ' -f1)" = "$e74_dispatch_hash" || die 'E0074 dispatch hash changed'

composition="$outdir/residue-composition.tsv"
awk -F '\t' -v OFS='\t' '
    BEGIN {print "source_term", "disposition", "class", "parser_target", "source_sha256", "origin", "evidence"}
    FILENAME == ARGV[1] {
        if (FNR == 1) next
        if ($2 == "retained") retained[$1]=1
        next
    }
    FILENAME == ARGV[2] {
        if (FNR == 1) next
        if ($2 != "unresolved") next
        disposition=(($1 in retained) ? "retained-contextual" : "unresolved-no-evidence")
        evidence=(($1 in retained) ? "E0077 retained contextual candidate" : "E0075 unresolved after deterministic evidence")
        print $1, disposition, $3, "-", $9, "MECHANICAL", evidence
    }
' "$adjudicated" "$facts" >"$composition" || die 'residue composition failed'

residue_records="$(awk 'END {print NR - 1}' "$composition")"
retained_candidate_records="$(awk -F '\t' 'NR > 1 && $2 == "retained-contextual" {n++} END {print n + 0}' "$composition")"
unresolved_no_evidence_records="$(awk -F '\t' 'NR > 1 && $2 == "unresolved-no-evidence" {n++} END {print n + 0}' "$composition")"
source_hash_matches="$(awk -F '\t' 'NR > 1 && $5 == "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2" {n++} END {print n + 0}' "$composition")"
parser_target_records="$(awk -F '\t' 'NR > 1 && $4 != "-" {n++} END {print n + 0}' "$composition")"
test "$residue_records" -eq 151 || die 'residue denominator differs'
test "$retained_candidate_records" -eq 3 || die 'retained candidate count differs'
test "$unresolved_no_evidence_records" -eq 148 || die 'unresolved-no-evidence count differs'
test "$source_hash_matches" -eq 151 || die 'residue source hashes differ'
test "$parser_target_records" -eq 0 || die 'residue parser target introduced'

parser_leaks=0
while IFS=$'\t' read -r source_term disposition class target hash origin evidence; do
    test "$source_term" = "source_term" && continue
    if rg -F -q "$source_term" "$projection"; then
        parser_leaks=$((parser_leaks + 1))
    fi
done <"$composition"
test "$parser_leaks" -eq 0 || die 'residue term leaked into parser projection'

integrated_syntax_records="$(awk '/^\(syntax / {n++} END {print n + 0}' "$integrated")"
dispatch_rows="$(awk 'END {print NR - 1}' "$dispatch")"
dispatch_provenance_rows="$(awk -F '\t' 'NR > 1 && $3 != "" && $4 != "" && $5 != "" {n++} END {print n + 0}' "$dispatch")"
test "$integrated_syntax_records" -eq 522 || die 'integrated syntax records differ'
test "$dispatch_rows" -eq 522 || die 'dispatch rows differ'
test "$dispatch_provenance_rows" -eq 522 || die 'dispatch provenance differs'

integrated_hash_difference=0
dispatch_hash_difference=0
test "$(sha256sum "$integrated" | cut -d' ' -f1)" = "$e74_integrated_hash" || integrated_hash_difference=1
test "$(sha256sum "$dispatch" | cut -d' ' -f1)" = "$e74_dispatch_hash" || dispatch_hash_difference=1
test "$integrated_hash_difference" -eq 0 || die 'integration changed after retained composition'
test "$dispatch_hash_difference" -eq 0 || die 'dispatch changed after retained composition'

summary_e74="$root/.cache/runs/E0074/R000001/summary.tsv"
export_antlr_validator_status="$(awk -F '\t' '$1 == "antlr_validate_status" {print $2}' "$summary_e74")"
export_bison_validator_status="$(awk -F '\t' '$1 == "bison_validate_status" {print $2}' "$summary_e74")"
export_treesitter_validator_status="$(awk -F '\t' '$1 == "treesitter_validate_status" {print $2}' "$summary_e74")"
direct_fortran_status="$(awk -F '\t' '$1 == "direct_fortran_status" {print $2}' "$summary_e74")"

awk -F '\t' 'NR > 1 {print $1}' "$composition" | sort >"$tmp/composed-names"
awk -F '\t' 'NR > 1 && $2 == "unresolved" {print $1}' "$facts" | sort >"$tmp/expected-names"
independent_difference="$(comm -3 "$tmp/composed-names" "$tmp/expected-names" | wc -l)"
test "$independent_difference" -eq 0 || die 'independent residue set differs'

awk -F '\t' -v OFS='\t' 'NR == 1 {print; next} NR == 2 {$2="parser-alias"} {print}' "$composition" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $2 == "parser-alias" {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'residue_records\t%s\n' "$residue_records" >>"$outdir/summary.tsv"
printf 'retained_candidate_records\t%s\n' "$retained_candidate_records" >>"$outdir/summary.tsv"
printf 'unresolved_no_evidence_records\t%s\n' "$unresolved_no_evidence_records" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'parser_target_records\t%s\n' "$parser_target_records" >>"$outdir/summary.tsv"
printf 'parser_leaks\t%s\n' "$parser_leaks" >>"$outdir/summary.tsv"
printf 'integrated_syntax_records\t%s\n' "$integrated_syntax_records" >>"$outdir/summary.tsv"
printf 'dispatch_rows\t%s\n' "$dispatch_rows" >>"$outdir/summary.tsv"
printf 'dispatch_provenance_rows\t%s\n' "$dispatch_provenance_rows" >>"$outdir/summary.tsv"
printf 'integrated_hash_difference\t%s\n' "$integrated_hash_difference" >>"$outdir/summary.tsv"
printf 'dispatch_hash_difference\t%s\n' "$dispatch_hash_difference" >>"$outdir/summary.tsv"
printf 'export_antlr_validator_status\t%s\n' "$export_antlr_validator_status" >>"$outdir/summary.tsv"
printf 'export_bison_validator_status\t%s\n' "$export_bison_validator_status" >>"$outdir/summary.tsv"
printf 'export_treesitter_validator_status\t%s\n' "$export_treesitter_validator_status" >>"$outdir/summary.tsv"
printf 'direct_fortran_status\t%s\n' "$direct_fortran_status" >>"$outdir/summary.tsv"
printf 'independent_difference\t%s\n' "$independent_difference" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'composition_sha256\t%s\n' "$(sha256sum "$composition" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'integrated_sha256\t%s\n' "$e74_integrated_hash" >>"$outdir/summary.tsv"
printf 'dispatch_sha256\t%s\n' "$e74_dispatch_hash" >>"$outdir/summary.tsv"

printf 'E0078 oracle: retained residue composition and full integration completed\n'
cat "$outdir/summary.tsv"
