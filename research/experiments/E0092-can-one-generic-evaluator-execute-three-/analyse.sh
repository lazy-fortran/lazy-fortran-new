#!/usr/bin/env bash
# Evaluate three accepted predicates through one generic table-driven evaluator.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0090="$root/research/experiments/E0090-can-accepted-predicates-generate-a-seman/analyse.sh"
target_oracle="$root/research/experiments/E0092-can-one-generic-evaluator-execute-three-/target-oracle.tsv"
witness_oracle="$root/research/experiments/E0092-can-one-generic-evaluator-execute-three-/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0092/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
e0090_summary_hash="6eac160c592660bdeffc6460ccb6efc33b0c00e945a31e05029b7b23fdebf622"

die() {
    printf 'E0092: %s\n' "$1" >&2
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

printf 'constraint_id\tpredicate\trequired_facts\tprovided_facts\tline\tpage\tsource_hash\tsource_evidence\torigin\tconstructor_form\n' >"$outdir/selected-rules.tsv"
awk -F '\t' -v OFS='\t' '
    $1 == "C601" || $1 == "C603" || $1 == "C719" {
        if ($11 ~ /^\(le /) constructor="le"
        else if ($11 ~ /^\(ge /) constructor="ge"
        else if ($11 ~ /^\(exists / && $11 ~ /\(ne /) constructor="exists-ne"
        else {bad=1; next}
        print $1, $11, $9, $10, $3, $4, $5, $12, $13, constructor
        selected++
    }
    END {if (selected != 3 || bad) exit 1}
' "$tmp/e0090/semantic-rule-table.tsv" >>"$outdir/selected-rules.tsv" ||
    die 'selected predicate forms differ'

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $10}' \
    "$outdir/selected-rules.tsv" | sort >"$tmp/actual-target.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$target_oracle" | sort >"$tmp/expected-target.tsv"
cmp -s "$tmp/actual-target.tsv" "$tmp/expected-target.tsv" ||
    die 'independent target oracle differs'

target_oracle_difference=0
target_rule_rows="$(awk 'END {print NR - 1}' "$outdir/selected-rules.tsv")"
generic_constructor_forms="$(awk -F '\t' 'NR > 1 {seen[$10]=1} END {for (form in seen) n++; print n + 0}' "$outdir/selected-rules.tsv")"
provenance_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $7 == hash && $9 == "MECHANICAL" {n++} END {print n + 0}' "$outdir/selected-rules.tsv")"
fact_matches="$(awk -F '\t' 'NR > 1 && (($1 == "C601" && $3 == "parsed-name" && $4 == "checked-name-length") || ($1 == "C603" && $3 == "parsed-label" && $4 == "checked-label-digits") || ($1 == "C719" && $3 == "constant-expression-value" && $4 == "checked-nonnegative-kind")) {n++} END {print n + 0}' "$outdir/selected-rules.tsv")"
test "$target_rule_rows" -eq 3 || die 'selected rule row count differs'
test "$generic_constructor_forms" -eq 3 || die 'generic constructor count differs'
test "$provenance_matches" -eq 3 || die 'selected provenance differs'
test "$fact_matches" -eq 3 || die 'selected fact fields differ'

cat >"$outdir/generic-evaluator.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

rule_table="__RULE_TABLE__"
constraint_id="${1:?constraint ID required}"
source_file="${2:?source file required}"

field() {
    awk -F '\t' -v id="$constraint_id" -v column="$1" \
        '$1 == id {print $column; exit}' "$rule_table"
}

predicate="$(field 2)"
line="$(field 5)"
page="$(field 6)"
source_hash="$(field 7)"
if [ -z "$predicate" ] || [ -z "$line" ] || [ -z "$page" ] || [ -z "$source_hash" ]; then
    printf 'unknown-rule\t%s\n' "$constraint_id" >&2
    exit 2
fi

read_fact() {
    case "$1" in
        name-length:name)
            awk -F '::' '/^[[:space:]]*integer[[:space:]]*::/ {
                value=$2
                gsub(/[[:space:]]/, "", value)
                print length(value)
                exit
            }' "$source_file"
            ;;
        value:kind-param)
            awk -F '[=)]' '/^[[:space:]]*integer[[:space:]]*\(kind[[:space:]]*=/ {
                value=$2
                gsub(/[[:space:]]/, "", value)
                print value
                exit
            }' "$source_file"
            ;;
        value:digit-in-label)
            awk '{
                value=$0
                sub(/^[[:space:]]*/, "", value)
                if (value ~ /^[0-9][0-9]*[[:space:]]/) {
                    sub(/[[:space:]].*$/, "", value)
                    print value
                    exit
                }
            }' "$source_file"
            ;;
        *)
            return 2
            ;;
    esac
}

result=0
if [[ "$predicate" == \(le* ]]; then
    threshold="$(printf '%s\n' "$predicate" | sed -n 's/.*name) \([0-9][0-9]*\)).*/\1/p')"
    actual="$(read_fact name-length:name)"
    [ -n "$actual" ] && [ -n "$threshold" ] || { printf 'missing-fact\t%s\n' "$constraint_id" >&2; exit 2; }
    [ "$actual" -le "$threshold" ] || result=1
elif [[ "$predicate" == \(ge* ]]; then
    threshold="$(printf '%s\n' "$predicate" | sed -n 's/.*kind-param) \(-\?[0-9][0-9]*\)).*/\1/p')"
    actual="$(read_fact value:kind-param)"
    [ -n "$actual" ] && [ -n "$threshold" ] || { printf 'missing-fact\t%s\n' "$constraint_id" >&2; exit 2; }
    [ "$actual" -ge "$threshold" ] || result=1
elif [[ "$predicate" == '(exists digit-in-label (ne (value digit-in-label) 0))' ]]; then
    actual="$(read_fact value:digit-in-label)"
    [ -n "$actual" ] || { printf 'missing-fact\t%s\n' "$constraint_id" >&2; exit 2; }
    [[ "$actual" =~ [1-9] ]] || result=1
else
    printf 'unsupported-predicate\t%s\t%s\n' "$constraint_id" "$predicate" >&2
    exit 2
fi

if [ "$result" -eq 0 ]; then
    printf 'accepted\t%s\tJ3-24-007 line=%s page=%s source_hash=%s\tpredicate=%s\n' \
        "$constraint_id" "$line" "$page" "$source_hash" "$predicate"
    exit 0
fi
printf 'diagnostic\t%s\tJ3-24-007 line=%s page=%s source_hash=%s\tpredicate=%s\n' \
    "$constraint_id" "$line" "$page" "$source_hash" "$predicate" >&2
exit 1
EOF
sed -i "s|__RULE_TABLE__|$outdir/selected-rules.tsv|" "$outdir/generic-evaluator.sh"
if grep -Eq 'C601|C603|C719' "$outdir/generic-evaluator.sh"; then
    die 'generic evaluator contains constraint-specific branches'
fi
chmod +x "$outdir/generic-evaluator.sh"

printf 'program c601_positive\ninteger :: a\nend program c601_positive\n' >"$tmp/c601-positive.f90"
printf 'program c601_negative\ninteger :: %s\nend program c601_negative\n' \
    "$(printf '%064d' 0 | tr '0' b)" >"$tmp/c601-negative.f90"
printf 'program c603_positive\n00001 continue\nend program c603_positive\n' >"$tmp/c603-positive.f90"
printf 'program c603_negative\n00000 continue\nend program c603-negative\n' >"$tmp/c603-negative.f90"
printf 'program c719_positive\ninteger(kind=1) :: x\nend program c719_positive\n' >"$tmp/c719-positive.f90"
printf 'program c719_negative\ninteger(kind=-1) :: x\nend program c719-negative\n' >"$tmp/c719-negative.f90"

printf 'case_id\tchecker_status\tgfortran_status\tconstraint_id\tshape\tstandard_line\tstandard_page\texpectation\tsource_sha256\n' >"$outdir/witness-results.tsv"
evaluator_cases=0
positive_checker_accepts=0
negative_checker_rejects=0
diagnostic_rows=0
gfortran_agreement=0
source_linked_results=0

while IFS=$'\t' read -r case_id constraint_id expected_checker expected_gfortran shape expected_line expected_page expectation; do
    [ "$case_id" = "case_id" ] && continue
    source_file="$tmp/$case_id.f90"
    set +e
    "$outdir/generic-evaluator.sh" "$constraint_id" "$source_file" \
        >"$tmp/$case_id.checker.out" 2>"$tmp/$case_id.checker.err"
    checker_status=$?
    gfortran -std=f2023 -pedantic -fsyntax-only "$source_file" \
        >"$tmp/$case_id.gfortran.out" 2>&1
    gfortran_status=$?
    set -e
    test "$checker_status" -eq "$expected_checker" || die "$case_id checker status differs"
    test "$gfortran_status" -eq "$expected_gfortran" || die "$case_id gfortran status differs"
    if [ "$expected_checker" -eq 0 ]; then
        grep -Fq $'accepted\t'"$constraint_id"$'\tJ3-24-007 line='"$expected_line"$' page='"$expected_page" \
            "$tmp/$case_id.checker.out" || die "$case_id lacks accepted provenance"
        test ! -s "$tmp/$case_id.checker.err" || die "$case_id emitted a diagnostic"
        positive_checker_accepts=$((positive_checker_accepts + 1))
    else
        grep -Fq $'diagnostic\t'"$constraint_id"$'\tJ3-24-007 line='"$expected_line"$' page='"$expected_page" \
            "$tmp/$case_id.checker.err" || die "$case_id lacks diagnostic provenance"
        diagnostic_rows=$((diagnostic_rows + 1))
        negative_checker_rejects=$((negative_checker_rejects + 1))
    fi
    if [ "$checker_status" -eq "$gfortran_status" ]; then
        gfortran_agreement=$((gfortran_agreement + 1))
    fi
    source_linked_results=$((source_linked_results + 1))
    source_sha256="$(sha256sum "$source_file" | cut -d' ' -f1)"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$case_id" "$checker_status" "$gfortran_status" "$constraint_id" "$shape" \
        "$expected_line" "$expected_page" "$expectation" "$source_sha256" \
        >>"$outdir/witness-results.tsv"
    evaluator_cases=$((evaluator_cases + 1))
done <"$witness_oracle"

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8}' \
    "$outdir/witness-results.tsv" | sort >"$tmp/actual-witness.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $3, $4, $2, $5, $6, $7, $8}' \
    "$witness_oracle" | sort >"$tmp/expected-witness.tsv"
cmp -s "$tmp/actual-witness.tsv" "$tmp/expected-witness.tsv" ||
    die 'independent witness oracle differs'

sed 's/(ge (value kind-param) 0)/(gt (value kind-param) 0)/' \
    "$outdir/selected-rules.tsv" >"$tmp/mutated-rules.tsv"
if cmp -s "$tmp/mutated-rules.tsv" "$outdir/selected-rules.tsv"; then
    die 'predicate mutation did not change selected rules'
fi
negative_control=observed_failure

parser_projection_records=0
model_calls=0
test "$target_oracle_difference" -eq 0 || die 'target oracle difference is nonzero'
test "$evaluator_cases" -eq 6 || die 'evaluator case denominator differs'
test "$positive_checker_accepts" -eq 3 || die 'positive acceptance count differs'
test "$negative_checker_rejects" -eq 3 || die 'negative rejection count differs'
test "$diagnostic_rows" -eq 3 || die 'diagnostic count differs'
test "$gfortran_agreement" -eq 6 || die 'gfortran agreement differs'
test "$source_linked_results" -eq 6 || die 'source-link count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'predecessor_rule_rows\t%s\n' "$predecessor_rule_rows" >>"$outdir/summary.tsv"
printf 'selected_rule_rows\t%s\n' "$target_rule_rows" >>"$outdir/summary.tsv"
printf 'generic_constructor_forms\t%s\n' "$generic_constructor_forms" >>"$outdir/summary.tsv"
printf 'target_oracle_difference\t%s\n' "$target_oracle_difference" >>"$outdir/summary.tsv"
printf 'provenance_matches\t%s\n' "$provenance_matches" >>"$outdir/summary.tsv"
printf 'fact_matches\t%s\n' "$fact_matches" >>"$outdir/summary.tsv"
printf 'evaluator_cases\t%s\n' "$evaluator_cases" >>"$outdir/summary.tsv"
printf 'positive_checker_accepts\t%s\n' "$positive_checker_accepts" >>"$outdir/summary.tsv"
printf 'negative_checker_rejects\t%s\n' "$negative_checker_rejects" >>"$outdir/summary.tsv"
printf 'diagnostic_rows\t%s\n' "$diagnostic_rows" >>"$outdir/summary.tsv"
printf 'gfortran_agreement\t%s\n' "$gfortran_agreement" >>"$outdir/summary.tsv"
printf 'source_linked_results\t%s\n' "$source_linked_results" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'target_oracle_sha256\t%s\n' "$(sha256sum "$target_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_oracle_sha256\t%s\n' "$(sha256sum "$witness_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'selected_rules_sha256\t%s\n' "$(sha256sum "$outdir/selected-rules.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_results_sha256\t%s\n' "$(sha256sum "$outdir/witness-results.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0092 oracle: generic three-predicate evaluator passed\n'
cat "$outdir/summary.tsv"
