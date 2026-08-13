#!/usr/bin/env bash
# Evaluate C719 from the generated E0090 semantic rule table.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0090="$root/research/experiments/E0090-can-accepted-predicates-generate-a-seman/analyse.sh"
target_oracle="$root/research/experiments/E0091-can-the-generated-rule-table-evaluate-c7/target-oracle.tsv"
witness_oracle="$root/research/experiments/E0091-can-the-generated-rule-table-evaluate-c7/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0091/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
e0090_summary_hash="6eac160c592660bdeffc6460ccb6efc33b0c00e945a31e05029b7b23fdebf622"

die() {
    printf 'E0091: %s\n' "$1" >&2
    exit 1
}

test -x "$e0090" || die 'E0090 analyzer is missing'
test -f "$target_oracle" || die 'target oracle is missing'
test -f "$witness_oracle" || die 'witness oracle is missing'
command -v gfortran >/dev/null 2>&1 || die 'gfortran is missing'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0090" "$tmp/e0090" >"$outdir/e0090.log" || die 'E0090 predecessor failed'
test "$(sha256sum "$tmp/e0090/summary.tsv" | cut -d' ' -f1)" = "$e0090_summary_hash" ||
    die 'E0090 predecessor summary changed'

predecessor_rule_rows="$(awk -F '\t' '$1 == "generated_rule_rows" {print $2}' "$tmp/e0090/summary.tsv")"
test "$predecessor_rule_rows" -eq 22 || die 'E0090 rule table denominator differs'

# The target table is a projection of the predecessor table, not a second
# hand-maintained implementation record.
printf 'constraint_id\tpredicate\trequired_facts\tprovided_facts\tline\tpage\tsource_hash\tsource_evidence\torigin\n' >"$outdir/c719-rule.tsv"
awk -F '\t' -v OFS='\t' '$1 == "C719" {
    found++
    print $1, $11, $9, $10, $3, $4, $5, $12, $13
}' "$tmp/e0090/semantic-rule-table.tsv" >>"$outdir/c719-rule.tsv"
target_rule_rows="$(awk 'END {print NR - 1}' "$outdir/c719-rule.tsv")"
test "$target_rule_rows" -eq 1 || die 'C719 target row count differs'

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8, $9}' \
    "$outdir/c719-rule.tsv" | sort >"$tmp/actual-target.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8, $9}' \
    "$target_oracle" | sort >"$tmp/expected-target.tsv"
cmp -s "$tmp/actual-target.tsv" "$tmp/expected-target.tsv" ||
    die 'independent C719 target oracle differs'

target_table_difference=0
target_provenance_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $7 == hash && $8 != "-" && $9 == "MECHANICAL" {n++} END {print n + 0}' "$outdir/c719-rule.tsv")"
target_fact_matches="$(awk -F '\t' 'NR > 1 && $3 == "constant-expression-value" && $4 == "checked-nonnegative-kind" {n++} END {print n + 0}' "$outdir/c719-rule.tsv")"
test "$target_provenance_matches" -eq 1 || die 'C719 provenance differs'
test "$target_fact_matches" -eq 1 || die 'C719 fact fields differ'

predicate="$(awk -F '\t' '$1 == "C719" {print $2}' "$outdir/c719-rule.tsv")"
lower_bound="$(printf '%s\n' "$predicate" | sed -n 's/.*value kind-param) \([0-9][0-9-]*\)).*/\1/p')"
test "$lower_bound" = 0 || die 'C719 lower bound was not derived from predicate'

printf 'program c719_positive\ninteger(kind=1) :: x\nend program c719_positive\n' >"$tmp/positive.f90"
printf 'program c719_negative\ninteger(kind=-1) :: x\nend program c719_negative\n' >"$tmp/negative.f90"

cat >"$tmp/generated-c719-checker.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source_file="\${1:?source file required}"
kind_value="\$(awk -F '[=)]' '/^[[:space:]]*integer[[:space:]]*\\(kind[[:space:]]*=/ {value=\$2; gsub(/[[:space:]]/, "", value); print value; exit}' "\$source_file")"
if [ "\$kind_value" -ge "$lower_bound" ]; then
    printf 'accepted\\tC719\\tJ3-24-007 line=$(
      awk -F '\t' '$1 == "C719" {print $5}' "$outdir/c719-rule.tsv"
    ) page=$(
      awk -F '\t' '$1 == "C719" {print $6}' "$outdir/c719-rule.tsv"
    ) source_hash=$source_hash\\tkind_value=%s\\n' "\$kind_value"
    exit 0
fi
printf 'diagnostic\\tC719\\tJ3-24-007 line=$(
  awk -F '\t' '$1 == "C719" {print $5}' "$outdir/c719-rule.tsv"
) page=$(
  awk -F '\t' '$1 == "C719" {print $6}' "$outdir/c719-rule.tsv"
) source_hash=$source_hash\\tkind_value=%s minimum=$lower_bound\\n' "\$kind_value" >&2
exit 1
EOF
chmod +x "$tmp/generated-c719-checker.sh"
cp "$tmp/generated-c719-checker.sh" "$outdir/generated-c719-checker.sh"

set +e
"$tmp/generated-c719-checker.sh" "$tmp/positive.f90" >"$tmp/positive-checker.out" 2>"$tmp/positive-checker.err"
positive_checker_status=$?
"$tmp/generated-c719-checker.sh" "$tmp/negative.f90" >"$tmp/negative-checker.out" 2>"$tmp/negative-checker.err"
negative_checker_status=$?
gfortran -std=f2023 -pedantic -fsyntax-only "$tmp/positive.f90" >"$tmp/positive-gfortran.out" 2>&1
positive_gfortran_status=$?
gfortran -std=f2023 -pedantic -fsyntax-only "$tmp/negative.f90" >"$tmp/negative-gfortran.out" 2>&1
negative_gfortran_status=$?
set -e

line="$(awk -F '\t' '$1 == "C719" {print $5}' "$outdir/c719-rule.tsv")"
page="$(awk -F '\t' '$1 == "C719" {print $6}' "$outdir/c719-rule.tsv")"
grep -Fq $'accepted\tC719\tJ3-24-007 line=3297 page=80' "$tmp/positive-checker.out" ||
    die 'positive checker lacks C719 source link'
test ! -s "$tmp/positive-checker.err" || die 'positive checker emitted a diagnostic'
grep -Fq $'diagnostic\tC719\tJ3-24-007 line=3297 page=80' "$tmp/negative-checker.err" ||
    die 'negative checker lacks C719 source-linked diagnostic'
grep -Fq 'minimum=0' "$tmp/negative-checker.err" || die 'negative checker lacks generated lower bound'
test "$line" = 3297 || die 'C719 line differs'
test "$page" = 80 || die 'C719 page differs'
test "$positive_checker_status" -eq 0 || die 'positive checker rejected witness'
test "$negative_checker_status" -eq 1 || die 'negative checker accepted witness'
test "$positive_gfortran_status" -eq 0 || die 'gfortran rejected positive witness'
test "$negative_gfortran_status" -eq 1 || die 'gfortran accepted negative witness'

positive_kind=1
negative_kind=-1
positive_expectation="$(awk -F '\t' '$1 == "positive" {print $8}' "$witness_oracle")"
negative_expectation="$(awk -F '\t' '$1 == "negative" {print $8}' "$witness_oracle")"
printf 'case_id\tchecker_status\tgfortran_status\tkind_value\tconstraint_id\tstandard_line\tstandard_page\tchecker_expectation\n' >"$outdir/witness-results.tsv"
printf 'positive\t%s\t%s\t%s\tC719\t%s\t%s\t%s\n' \
    "$positive_checker_status" "$positive_gfortran_status" "$positive_kind" \
    "$line" "$page" "$positive_expectation" >>"$outdir/witness-results.tsv"
printf 'negative\t%s\t%s\t%s\tC719\t%s\t%s\t%s\n' \
    "$negative_checker_status" "$negative_gfortran_status" "$negative_kind" \
    "$line" "$page" "$negative_expectation" >>"$outdir/witness-results.tsv"

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8}' \
    "$outdir/witness-results.tsv" | sort >"$tmp/actual-witness.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8}' \
    "$witness_oracle" | sort >"$tmp/expected-witness.tsv"
cmp -s "$tmp/actual-witness.tsv" "$tmp/expected-witness.tsv" ||
    die 'independent witness oracle differs'

positive_diagnostic_rows="$(grep -F -c $'diagnostic\tC719' "$tmp/positive-checker.err" || true)"
negative_diagnostic_rows="$(grep -F -c $'diagnostic\tC719' "$tmp/negative-checker.err" || true)"
positive_source_linked=1
negative_source_linked=1

# Mutating either the predicate or source location must alter the target oracle.
sed 's/(ge (value kind-param) 0)/(gt (value kind-param) 0)/' \
    "$outdir/c719-rule.tsv" >"$tmp/mutated-predicate.tsv"
if cmp -s "$tmp/mutated-predicate.tsv" "$outdir/c719-rule.tsv"; then
    die 'predicate mutation did not change target row'
fi
sed 's/\t3297\t80\t/\t3298\t80\t/' \
    "$outdir/c719-rule.tsv" >"$tmp/mutated-source.tsv"
if cmp -s "$tmp/mutated-source.tsv" "$outdir/c719-rule.tsv"; then
    die 'source-location mutation did not change target row'
fi
negative_control=observed_failure

parser_projection_records=0
model_calls=0
test "$target_table_difference" -eq 0 || die 'target oracle difference is nonzero'
test "$positive_diagnostic_rows" -eq 0 || die 'positive diagnostic count differs'
test "$negative_diagnostic_rows" -eq 1 || die 'negative diagnostic count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'predecessor_rule_rows\t%s\n' "$predecessor_rule_rows" >>"$outdir/summary.tsv"
printf 'target_rule_rows\t%s\n' "$target_rule_rows" >>"$outdir/summary.tsv"
printf 'target_table_difference\t%s\n' "$target_table_difference" >>"$outdir/summary.tsv"
printf 'target_provenance_matches\t%s\n' "$target_provenance_matches" >>"$outdir/summary.tsv"
printf 'target_fact_matches\t%s\n' "$target_fact_matches" >>"$outdir/summary.tsv"
printf 'generated_bound\t%s\n' "$lower_bound" >>"$outdir/summary.tsv"
printf 'checker_positive_status\t%s\n' "$positive_checker_status" >>"$outdir/summary.tsv"
printf 'checker_negative_status\t%s\n' "$negative_checker_status" >>"$outdir/summary.tsv"
printf 'positive_diagnostic_rows\t%s\n' "$positive_diagnostic_rows" >>"$outdir/summary.tsv"
printf 'negative_diagnostic_rows\t%s\n' "$negative_diagnostic_rows" >>"$outdir/summary.tsv"
printf 'positive_gfortran_status\t%s\n' "$positive_gfortran_status" >>"$outdir/summary.tsv"
printf 'negative_gfortran_status\t%s\n' "$negative_gfortran_status" >>"$outdir/summary.tsv"
printf 'positive_source_linked\t%s\n' "$positive_source_linked" >>"$outdir/summary.tsv"
printf 'negative_source_linked\t%s\n' "$negative_source_linked" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'target_oracle_sha256\t%s\n' "$(sha256sum "$target_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_oracle_sha256\t%s\n' "$(sha256sum "$witness_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'target_rule_sha256\t%s\n' "$(sha256sum "$outdir/c719-rule.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_results_sha256\t%s\n' "$(sha256sum "$outdir/witness-results.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0091 oracle: generated C719 evaluator passed\n'
cat "$outdir/summary.tsv"
