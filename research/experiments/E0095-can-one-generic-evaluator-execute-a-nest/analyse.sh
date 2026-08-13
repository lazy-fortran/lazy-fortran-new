#!/usr/bin/env bash
# Execute one nested implication predicate through a generic fact interpreter.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0090="$root/research/experiments/E0090-can-accepted-predicates-generate-a-seman/analyse.sh"
target_oracle="$root/research/experiments/E0095-can-one-generic-evaluator-execute-a-nest/target-oracle.tsv"
witness_oracle="$root/research/experiments/E0095-can-one-generic-evaluator-execute-a-nest/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0095/R000001}"
e0090_summary_hash="6eac160c592660bdeffc6460ccb6efc33b0c00e945a31e05029b7b23fdebf622"

die() {
    printf 'E0095: %s\n' "$1" >&2
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

printf 'constraint_id\tpredicate\trequired_facts\tprovided_facts\tline\tpage\tsource_hash\tsource_evidence\torigin\n' \
    >"$outdir/selected-rules.tsv"
awk -F '\t' -v OFS='\t' '
    $1 == "C721" {
        print $1, $11, $9, $10, $3, $4, $5, $12, $13
        selected++
    }
    END {if (selected != 1) exit 1}
' "$tmp/e0090/semantic-rule-table.tsv" >>"$outdir/selected-rules.tsv" ||
    die 'C721 selection differs'

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$outdir/selected-rules.tsv" | sort >"$tmp/actual-target.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$target_oracle" | sort >"$tmp/expected-target.tsv"
if cmp -s "$tmp/actual-target.tsv" "$tmp/expected-target.tsv"; then
    target_oracle_difference=0
else
    target_oracle_difference=1
    die 'independent C721 target oracle differs'
fi

provenance_matches="$(awk -F '\t' 'NR > 1 && $7 != "" && $9 == "MECHANICAL" {n++} END {print n + 0}' "$outdir/selected-rules.tsv")"
fact_matches="$(awk -F '\t' 'NR > 1 && $3 == "parsed-kind-param parsed-exponent-letter" && $4 == "checked-exponent-letter" {n++} END {print n + 0}' "$outdir/selected-rules.tsv")"
test "$provenance_matches" -eq 1 || die 'C721 provenance differs'
test "$fact_matches" -eq 1 || die 'C721 fact fields differ'

cat >"$outdir/generated-nested-evaluator.sh" <<'EOF'
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
literal="$(awk -F '=' '/^[[:space:]]*x[[:space:]]*=/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$source_file")"
[ -n "$predicate" ] && [ -n "$literal" ] || {
    printf 'missing-input\t%s\n' "$constraint_id" >&2
    exit 2
}

kind_param_present=0
if printf '%s\n' "$literal" | grep -Eq '_[0-9]+$'; then
    kind_param_present=1
fi
exponent_letter="$(printf '%s\n' "$literal" | sed -n 's/.*\([EDQ]\).*/\1/p')"
exponent_present=0
[ -n "$exponent_letter" ] && exponent_present=1

set +e
awk -v expr="$predicate" \
    -v kind_param="$kind_param_present" \
    -v exponent_present="$exponent_present" \
    -v exponent_letter="$exponent_letter" '
BEGIN {
    gsub(/[()]/, " & ", expr)
    gsub(/[[:space:]]+/, " ", expr)
    sub(/^ /, "", expr)
    sub(/ $/, "", expr)
    n = split(expr, token, " ")
    pos = 0
    value = evaluate()
    if (pos != n) exit 2
    exit(value ? 0 : 1)
}
function next_token(    value) {
    pos++
    if (pos > n) exit 2
    return token[pos]
}
function close_expr(    value) {
    value = next_token()
    if (value != ")") exit 2
}
function fact_present(name) {
    if (name == "kind-param") return kind_param
    if (name == "exponent-letter") return exponent_present
    exit 2
}
function fact_value(name) {
    if (name == "exponent-letter") return exponent_letter
    exit 2
}
function evaluate(    opener, operator, name, expected, left, right) {
    opener = next_token()
    if (opener != "(") exit 2
    operator = next_token()
    if (operator == "present") {
        name = next_token()
        close_expr()
        return fact_present(name)
    }
    if (operator == "eq") {
        name = next_token()
        expected = next_token()
        close_expr()
        return fact_value(name) == expected
    }
    if (operator == "and") {
        left = evaluate()
        right = evaluate()
        close_expr()
        return left && right
    }
    if (operator == "implies") {
        left = evaluate()
        right = evaluate()
        close_expr()
        return (!left) || right
    }
    exit 2
}
' </dev/null
predicate_status=$?
set -e

case "$predicate_status" in
    0)
        printf 'accepted\t%s\tJ3-24-007 line=%s page=%s source_hash=%s\tpredicate=%s\n' \
            "$constraint_id" "$line" "$page" "$source_hash" "$predicate"
        exit 0
        ;;
    1)
        printf 'diagnostic\t%s\tJ3-24-007 line=%s page=%s source_hash=%s\tpredicate=%s\n' \
            "$constraint_id" "$line" "$page" "$source_hash" "$predicate" >&2
        exit 1
        ;;
    *)
        printf 'evaluator-error\t%s\tpredicate=%s\n' "$constraint_id" "$predicate" >&2
        exit 2
        ;;
esac
EOF
sed -i "s|__RULE_TABLE__|$outdir/selected-rules.tsv|" \
    "$outdir/generated-nested-evaluator.sh"
if grep -Eq 'C721' "$outdir/generated-nested-evaluator.sh"; then
    die 'generated evaluator contains the selected constraint ID'
fi
chmod +x "$outdir/generated-nested-evaluator.sh"

printf 'program c721_positive\nreal :: x\nx = 1.0E0_8\nend program c721_positive\n' \
    >"$tmp/c721-positive.f90"
printf 'program c721_negative\nreal :: x\nx = 1.0D0_8\nend program c721_negative\n' \
    >"$tmp/c721-negative.f90"
printf 'program c721_vacuous\nreal :: x\nx = 1.0D0\nend program c721_vacuous\n' \
    >"$tmp/c721-vacuous.f90"

printf 'case_id\tchecker_status\tgfortran_status\tconstraint_id\tshape\tantecedent\tconsequent\texpectation\tsource_sha256\n' \
    >"$outdir/witness-results.tsv"
evaluator_cases=0
implication_accepts=0
implication_rejects=0
gfortran_agreement=0
diagnostic_rows=0
source_linked_results=0

while IFS=$'\t' read -r case_id constraint_id expected_checker expected_gfortran shape antecedent consequent expectation; do
    [ "$case_id" = case_id ] && continue
    source_file="$tmp/$case_id.f90"
    set +e
    "$outdir/generated-nested-evaluator.sh" "$constraint_id" "$source_file" \
        >"$tmp/$case_id.checker.out" 2>"$tmp/$case_id.checker.err"
    checker_status=$?
    gfortran -std=f2023 -pedantic -fsyntax-only "$source_file" \
        >"$tmp/$case_id.gfortran.out" 2>&1
    gfortran_status=$?
    set -e
    test "$checker_status" -eq "$expected_checker" || die "$case_id checker status differs"
    test "$gfortran_status" -eq "$expected_gfortran" || die "$case_id gfortran status differs"
    if [ "$expected_checker" -eq 0 ]; then
        grep -Fq $'accepted\t'"$constraint_id"$'\tJ3-24-007 line=3355 page=81' \
            "$tmp/$case_id.checker.out" || die "$case_id lacks acceptance provenance"
        test ! -s "$tmp/$case_id.checker.err" || die "$case_id emitted a diagnostic"
        implication_accepts=$((implication_accepts + 1))
    else
        grep -Fq $'diagnostic\t'"$constraint_id"$'\tJ3-24-007 line=3355 page=81' \
            "$tmp/$case_id.checker.err" || die "$case_id lacks diagnostic provenance"
        diagnostic_rows=$((diagnostic_rows + 1))
        implication_rejects=$((implication_rejects + 1))
    fi
    if [ "$checker_status" -eq "$gfortran_status" ]; then
        gfortran_agreement=$((gfortran_agreement + 1))
    fi
    source_linked_results=$((source_linked_results + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$case_id" "$checker_status" "$gfortran_status" \
        "$constraint_id" "$shape" "$antecedent" \
        "$consequent" "$expectation" \
        "$(sha256sum "$source_file" | cut -d' ' -f1)" \
        >>"$outdir/witness-results.tsv"
    evaluator_cases=$((evaluator_cases + 1))
done <"$witness_oracle"

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $4, $2, $3, $5, $6, $7, $8}' \
    "$outdir/witness-results.tsv" | sort >"$tmp/actual-witness.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8}' \
    "$witness_oracle" | sort >"$tmp/expected-witness.tsv"
cmp -s "$tmp/actual-witness.tsv" "$tmp/expected-witness.tsv" ||
    die 'independent witness oracle differs'

sed 's/(eq exponent-letter E)/(eq exponent-letter D)/' \
    "$outdir/selected-rules.tsv" >"$tmp/mutated-rules.tsv"
sed "s|$outdir/selected-rules.tsv|$tmp/mutated-rules.tsv|" \
    "$outdir/generated-nested-evaluator.sh" >"$tmp/mutated-evaluator.sh"
chmod +x "$tmp/mutated-evaluator.sh"
set +e
"$tmp/mutated-evaluator.sh" C721 "$tmp/c721-positive.f90" \
    >"$tmp/mutated.out" 2>"$tmp/mutated.err"
mutated_status=$?
set -e
if [ "$mutated_status" -ne 1 ]; then
    die 'predicate mutation did not change the positive result'
fi
negative_control=observed_failure

predecessor_rule_rows=$(awk -F '\t' '$1 == "generated_rule_rows" {print $2}' "$tmp/e0090/summary.tsv")
selected_rule_rows=1
generic_constructor_forms=4
parser_projection_records=0
model_calls=0
test "$predecessor_rule_rows" -eq 22 || die 'predecessor denominator differs'
test "$evaluator_cases" -eq 3 || die 'evaluator denominator differs'
test "$implication_accepts" -eq 2 || die 'implication acceptance count differs'
test "$implication_rejects" -eq 1 || die 'implication rejection count differs'
test "$gfortran_agreement" -eq 3 || die 'gfortran agreement differs'
test "$diagnostic_rows" -eq 1 || die 'diagnostic count differs'
test "$source_linked_results" -eq 3 || die 'source-link count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'predecessor_rule_rows\t%s\n' "$predecessor_rule_rows" >>"$outdir/summary.tsv"
printf 'selected_rule_rows\t%s\n' "$selected_rule_rows" >>"$outdir/summary.tsv"
printf 'generic_constructor_forms\t%s\n' "$generic_constructor_forms" >>"$outdir/summary.tsv"
printf 'target_oracle_difference\t%s\n' "$target_oracle_difference" >>"$outdir/summary.tsv"
printf 'provenance_matches\t%s\n' "$provenance_matches" >>"$outdir/summary.tsv"
printf 'fact_matches\t%s\n' "$fact_matches" >>"$outdir/summary.tsv"
printf 'evaluator_cases\t%s\n' "$evaluator_cases" >>"$outdir/summary.tsv"
printf 'implication_accepts\t%s\n' "$implication_accepts" >>"$outdir/summary.tsv"
printf 'implication_rejects\t%s\n' "$implication_rejects" >>"$outdir/summary.tsv"
printf 'gfortran_agreement\t%s\n' "$gfortran_agreement" >>"$outdir/summary.tsv"
printf 'diagnostic_rows\t%s\n' "$diagnostic_rows" >>"$outdir/summary.tsv"
printf 'source_linked_results\t%s\n' "$source_linked_results" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'target_oracle_sha256\t%s\n' "$(sha256sum "$target_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_oracle_sha256\t%s\n' "$(sha256sum "$witness_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'selected_rules_sha256\t%s\n' "$(sha256sum "$outdir/selected-rules.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_results_sha256\t%s\n' "$(sha256sum "$outdir/witness-results.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0095 oracle: generic nested implication evaluator passed\n'
cat "$outdir/summary.tsv"
