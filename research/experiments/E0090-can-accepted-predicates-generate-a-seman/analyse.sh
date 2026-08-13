#!/usr/bin/env bash
# Generate a semantic rule table from E0089 and exercise its C601 rule.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0089="$root/research/experiments/E0089-can-the-e0088-adjudication-compose-into-/analyse.sh"
table_oracle="$root/research/experiments/E0090-can-accepted-predicates-generate-a-seman/table-oracle.tsv"
witness_oracle="$root/research/experiments/E0090-can-accepted-predicates-generate-a-seman/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0090/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
e0089_summary_hash="38328fef8473ff35c2708c7b8a41b07b8fda7ee978102829fd1c521a3900c0ea"

die() {
    printf 'E0090: %s\n' "$1" >&2
    exit 1
}

test -x "$e0089" || die 'E0089 analyzer is missing'
test -f "$table_oracle" || die 'table oracle is missing'
test -f "$witness_oracle" || die 'witness oracle is missing'
command -v gfortran >/dev/null 2>&1 || die 'gfortran is missing'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0089" "$tmp/e0089" >"$outdir/e0089.log" || die 'E0089 predecessor failed'
test "$(sha256sum "$tmp/e0089/summary.tsv" | cut -d' ' -f1)" = "$e0089_summary_hash" ||
    die 'E0089 predecessor summary changed'

accepted_predecessor_rows="$(awk -F '\t' '$1 == "resolved_constraints" {print $2}' "$tmp/e0089/summary.tsv")"
test "$accepted_predecessor_rows" -eq 22 || die 'E0089 accepted denominator differs'

# This is the generated table. Its structure is fixed by the formalization
# record schema; no rule-specific wiring is hand-maintained here.
printf 'constraint_id\tassociated_rules\tline\tpage\tsource_hash\tform\tsubject\tapplicability\trequired_facts\tprovided_facts\tpredicate\tsource_evidence\torigin\n' >"$outdir/semantic-rule-table.tsv"
awk -F '\t' -v OFS='\t' '
    NR > 1 && $6 == "resolved" {
        print $2, $3, $4, $5, $14, $7, $8, $9, $10, $11, $12, $17, $15
    }
' "$tmp/e0089/formalizations.tsv" >>"$outdir/semantic-rule-table.tsv"

table_rows="$(awk 'END {print NR - 1}' "$outdir/semantic-rule-table.tsv")"
test "$table_rows" -eq 22 || die 'generated rule table row count differs'

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $11, $9, $10}' \
    "$outdir/semantic-rule-table.tsv" | sort >"$tmp/actual-table-oracle.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4}' \
    "$table_oracle" | sort >"$tmp/expected-table-oracle.tsv"
cmp -s "$tmp/actual-table-oracle.tsv" "$tmp/expected-table-oracle.tsv" ||
    die 'independent semantic table oracle differs'

table_oracle_difference=0
unique_rule_ids="$(awk -F '\t' 'NR > 1 {seen[$1]++} END {for (id in seen) if (seen[id] != 1) bad=1; for (id in seen) n++; if (bad) exit 1; print n + 0}' "$outdir/semantic-rule-table.tsv")" ||
    die 'generated rule table has duplicate IDs'
provenance_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $5 == hash && $13 == "MECHANICAL" {n++} END {print n + 0}' "$outdir/semantic-rule-table.tsv")"
source_evidence_matches="$(awk -F '\t' 'NR > 1 && $12 != "-" && $12 != "" {n++} END {print n + 0}' "$outdir/semantic-rule-table.tsv")"
unresolved_rows_emitted="$(awk -F '\t' 'NR > 1 && ($1 == "C1588" || $13 == "UNRESOLVED") {n++} END {print n + 0}' "$outdir/semantic-rule-table.tsv")"
c1588_rows_emitted="$(awk -F '\t' 'NR > 1 && $1 == "C1588" {n++} END {print n + 0}' "$outdir/semantic-rule-table.tsv")"
test "$unique_rule_ids" -eq 22 || die 'generated rule table IDs are not unique'
test "$provenance_matches" -eq 22 || die 'generated rule table provenance differs'
test "$source_evidence_matches" -eq 22 || die 'generated rule table evidence differs'
test "$unresolved_rows_emitted" -eq 0 || die 'unresolved rule was emitted'
test "$c1588_rows_emitted" -eq 0 || die 'C1588 was emitted'

# Structural dispatch is also generated from the table. It contains no
# manually maintained list of callers.
printf 'constraint_id\tprocedure\trequired_facts\tprovided_facts\tpredicate\tline\tpage\n' >"$outdir/semantic-dispatch.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {
    print $1, "check_" $1, $9, $10, $11, $3, $4
}' "$outdir/semantic-rule-table.tsv" >>"$outdir/semantic-dispatch.tsv"
generated_dispatch_rows="$(awk 'END {print NR - 1}' "$outdir/semantic-dispatch.tsv")"
test "$generated_dispatch_rows" -eq 22 || die 'generated dispatch row count differs'

c601_line="$(awk -F '\t' '$1 == "C601" {print $3}' "$outdir/semantic-rule-table.tsv")"
c601_page="$(awk -F '\t' '$1 == "C601" {print $4}' "$outdir/semantic-rule-table.tsv")"
c601_hash="$(awk -F '\t' '$1 == "C601" {print $5}' "$outdir/semantic-rule-table.tsv")"
c601_predicate="$(awk -F '\t' '$1 == "C601" {print $11}' "$outdir/semantic-rule-table.tsv")"
c601_limit="$(printf '%s\n' "$c601_predicate" | sed -n 's/.*name) \([0-9][0-9]*\)).*/\1/p')"
test "$c601_line" = 2809 || die 'C601 source line differs'
test "$c601_page" = 67 || die 'C601 source page differs'
test "$c601_hash" = "$source_hash" || die 'C601 source hash differs'
test "$c601_limit" = 63 || die 'C601 bound was not generated from its predicate'

positive_name=a
negative_name="$(printf '%064d' 0 | tr '0' b)"
printf 'program c601_positive\ninteger :: %s\nend program c601_positive\n' "$positive_name" >"$tmp/positive.f90"
printf 'program c601_negative\ninteger :: %s\nend program c601_negative\n' "$negative_name" >"$tmp/negative.f90"

# This checker is a generated local implementation for the one witness rule.
# The bound and provenance are substituted from the generated table above.
cat >"$tmp/generated-c601-checker.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source_file="\${1:?source file required}"
name="\$(awk -F '::' '/^[[:space:]]*integer[[:space:]]*::/ {value=\$2; gsub(/[[:space:]]/, "", value); print value; exit}' "\$source_file")"
length="\${#name}"
if [ "\$length" -le "$c601_limit" ]; then
    printf 'accepted\\tC601\\tJ3-24-007 line=$c601_line page=$c601_page source_hash=$c601_hash\\tname_length=%s\\n' "\$length"
    exit 0
fi
printf 'diagnostic\\tC601\\tJ3-24-007 line=$c601_line page=$c601_page source_hash=$c601_hash\\tname_length=%s maximum=$c601_limit\\n' "\$length" >&2
exit 1
EOF
chmod +x "$tmp/generated-c601-checker.sh"
cp "$tmp/generated-c601-checker.sh" "$outdir/generated-c601-checker.sh"

set +e
"$tmp/generated-c601-checker.sh" "$tmp/positive.f90" >"$tmp/positive-checker.out" 2>"$tmp/positive-checker.err"
positive_checker_status=$?
"$tmp/generated-c601-checker.sh" "$tmp/negative.f90" >"$tmp/negative-checker.out" 2>"$tmp/negative-checker.err"
negative_checker_status=$?
gfortran -std=f2023 -pedantic -fsyntax-only "$tmp/positive.f90" >"$tmp/positive-gfortran.out" 2>&1
positive_gfortran_status=$?
gfortran -std=f2023 -pedantic -fsyntax-only "$tmp/negative.f90" >"$tmp/negative-gfortran.out" 2>&1
negative_gfortran_status=$?
set -e

grep -Fq $'accepted\tC601\tJ3-24-007 line=2809 page=67' "$tmp/positive-checker.out" ||
    die 'positive checker lacks source-linked acceptance'
test ! -s "$tmp/positive-checker.err" || die 'positive checker emitted a diagnostic'
grep -Fq $'diagnostic\tC601\tJ3-24-007 line=2809 page=67' "$tmp/negative-checker.err" ||
    die 'negative checker lacks source-linked diagnostic'
grep -Fq 'maximum=63' "$tmp/negative-checker.err" || die 'negative checker lacks generated bound'
grep -Fq 'too long' "$tmp/negative-gfortran.out" || die 'gfortran negative witness changed'
test "$positive_checker_status" -eq 0 || die 'positive generated checker rejected witness'
test "$negative_checker_status" -eq 1 || die 'negative generated checker accepted witness'
test "$positive_gfortran_status" -eq 0 || die 'gfortran rejected positive witness'
test "$negative_gfortran_status" -eq 1 || die 'gfortran accepted negative witness'

positive_name_length="${#positive_name}"
negative_name_length="${#negative_name}"
positive_expectation="$(awk -F '\t' '$1 == "positive" {print $8}' "$witness_oracle")"
negative_expectation="$(awk -F '\t' '$1 == "negative" {print $8}' "$witness_oracle")"
test "$positive_name_length" -eq "$(awk -F '\t' '$1 == "positive" {print $4}' "$witness_oracle")" || die 'positive witness length differs'
test "$negative_name_length" -eq "$(awk -F '\t' '$1 == "negative" {print $4}' "$witness_oracle")" || die 'negative witness length differs'

printf 'case_id\tchecker_status\tgfortran_status\tname_length\tconstraint_id\tstandard_line\tstandard_page\tchecker_expectation\tsource_sha256\n' >"$outdir/witness-results.tsv"
printf 'positive\t%s\t%s\t%s\tC601\t%s\t%s\t%s\t%s\n' \
    "$positive_checker_status" "$positive_gfortran_status" "$positive_name_length" \
    "$c601_line" "$c601_page" "$positive_expectation" \
    "$(sha256sum "$tmp/positive.f90" | cut -d' ' -f1)" >>"$outdir/witness-results.tsv"
printf 'negative\t%s\t%s\t%s\tC601\t%s\t%s\t%s\t%s\n' \
    "$negative_checker_status" "$negative_gfortran_status" "$negative_name_length" \
    "$c601_line" "$c601_page" "$negative_expectation" \
    "$(sha256sum "$tmp/negative.f90" | cut -d' ' -f1)" >>"$outdir/witness-results.tsv"

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8}' \
    "$outdir/witness-results.tsv" | sort >"$tmp/actual-witness-oracle.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8}' \
    "$witness_oracle" | sort >"$tmp/expected-witness-oracle.tsv"
cmp -s "$tmp/actual-witness-oracle.tsv" "$tmp/expected-witness-oracle.tsv" ||
    die 'independent witness oracle differs'

positive_diagnostic_rows="$(grep -F -c $'diagnostic\tC601' "$tmp/positive-checker.err" || true)"
negative_diagnostic_rows="$(grep -F -c $'diagnostic\tC601' "$tmp/negative-checker.err" || true)"
positive_source_linked=1
negative_source_linked=1

# A predicate mutation must change the generated-table oracle.
sed 's/(le (name-length name) 63)/(lt (name-length name) 63)/' \
    "$outdir/semantic-rule-table.tsv" >"$tmp/mutated-table.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $11, $9, $10}' \
    "$tmp/mutated-table.tsv" | sort >"$tmp/mutated-table-oracle.tsv"
if cmp -s "$tmp/mutated-table-oracle.tsv" "$tmp/expected-table-oracle.tsv"; then
    die 'negative predicate mutation did not fail'
fi
negative_control=observed_failure

parser_projection_records=0
model_calls=0
test "$table_oracle_difference" -eq 0 || die 'table oracle difference is nonzero'
test "$generated_dispatch_rows" -eq 22 || die 'dispatch denominator differs'
test "$provenance_matches" -eq 22 || die 'provenance denominator differs'
test "$source_evidence_matches" -eq 22 || die 'source evidence denominator differs'
test "$positive_diagnostic_rows" -eq 0 || die 'positive witness has a diagnostic'
test "$negative_diagnostic_rows" -eq 1 || die 'negative witness lacks a diagnostic'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'accepted_predecessor_rows\t%s\n' "$accepted_predecessor_rows" >>"$outdir/summary.tsv"
printf 'generated_rule_rows\t%s\n' "$table_rows" >>"$outdir/summary.tsv"
printf 'generated_dispatch_rows\t%s\n' "$generated_dispatch_rows" >>"$outdir/summary.tsv"
printf 'table_oracle_difference\t%s\n' "$table_oracle_difference" >>"$outdir/summary.tsv"
printf 'unique_rule_ids\t%s\n' "$unique_rule_ids" >>"$outdir/summary.tsv"
printf 'provenance_matches\t%s\n' "$provenance_matches" >>"$outdir/summary.tsv"
printf 'source_evidence_matches\t%s\n' "$source_evidence_matches" >>"$outdir/summary.tsv"
printf 'unresolved_rows_emitted\t%s\n' "$unresolved_rows_emitted" >>"$outdir/summary.tsv"
printf 'c1588_rows_emitted\t%s\n' "$c1588_rows_emitted" >>"$outdir/summary.tsv"
printf 'c601_checker_positive_status\t%s\n' "$positive_checker_status" >>"$outdir/summary.tsv"
printf 'c601_checker_negative_status\t%s\n' "$negative_checker_status" >>"$outdir/summary.tsv"
printf 'c601_positive_diagnostic_rows\t%s\n' "$positive_diagnostic_rows" >>"$outdir/summary.tsv"
printf 'c601_negative_diagnostic_rows\t%s\n' "$negative_diagnostic_rows" >>"$outdir/summary.tsv"
printf 'c601_positive_gfortran_status\t%s\n' "$positive_gfortran_status" >>"$outdir/summary.tsv"
printf 'c601_negative_gfortran_status\t%s\n' "$negative_gfortran_status" >>"$outdir/summary.tsv"
printf 'c601_positive_source_linked\t%s\n' "$positive_source_linked" >>"$outdir/summary.tsv"
printf 'c601_negative_source_linked\t%s\n' "$negative_source_linked" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'table_oracle_sha256\t%s\n' "$(sha256sum "$table_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_oracle_sha256\t%s\n' "$(sha256sum "$witness_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'rule_table_sha256\t%s\n' "$(sha256sum "$outdir/semantic-rule-table.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'dispatch_sha256\t%s\n' "$(sha256sum "$outdir/semantic-dispatch.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_results_sha256\t%s\n' "$(sha256sum "$outdir/witness-results.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0090 oracle: generated semantic rule table and C601 witness passed\n'
cat "$outdir/summary.tsv"
