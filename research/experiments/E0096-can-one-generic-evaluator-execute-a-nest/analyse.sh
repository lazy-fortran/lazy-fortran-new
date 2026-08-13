#!/usr/bin/env bash
# Execute one nested not-or predicate over intrinsic-type facts.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0090="$root/research/experiments/E0090-can-accepted-predicates-generate-a-seman/analyse.sh"
target_oracle="$root/research/experiments/E0096-can-one-generic-evaluator-execute-a-nest/target-oracle.tsv"
witness_oracle="$root/research/experiments/E0096-can-one-generic-evaluator-execute-a-nest/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0096/R000001}"
e0090_summary_hash="6eac160c592660bdeffc6460ccb6efc33b0c00e945a31e05029b7b23fdebf622"

die() {
    printf 'E0096: %s\n' "$1" >&2
    exit 1
}

test -x "$e0090" || die 'E0090 analyzer is missing'
test -f "$target_oracle" || die 'target oracle is missing'
test -f "$witness_oracle" || die 'witness oracle is missing'
command -v gfortran >/dev/null 2>&1 || die 'gfortran is missing'
command -v flang-new >/dev/null 2>&1 || die 'flang-new is missing'
mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0090" "$tmp/e0090" >"$outdir/e0090.log" || die 'E0090 predecessor failed'
test "$(sha256sum "$tmp/e0090/summary.tsv" | cut -d' ' -f1)" = "$e0090_summary_hash" ||
    die 'E0090 predecessor summary changed'

printf 'constraint_id\tpredicate\trequired_facts\tprovided_facts\tline\tpage\tsource_hash\tsource_evidence\torigin\n' \
    >"$outdir/selected-rules.tsv"
awk -F '\t' -v OFS='\t' '
    $1 == "C734" {
        print $1, $11, $9, $10, $3, $4, $5, $12, $13
        selected++
    }
    END {if (selected != 1) exit 1}
' "$tmp/e0090/semantic-rule-table.tsv" >>"$outdir/selected-rules.tsv" ||
    die 'C734 selection differs'

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$outdir/selected-rules.tsv" | sort >"$tmp/actual-target.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$target_oracle" | sort >"$tmp/expected-target.tsv"
if cmp -s "$tmp/actual-target.tsv" "$tmp/expected-target.tsv"; then
    target_oracle_difference=0
else
    target_oracle_difference=1
    die 'independent C734 target oracle differs'
fi

provenance_matches="$(awk -F '\t' 'NR > 1 && $7 != "" && $9 == "MECHANICAL" {n++} END {print n + 0}' "$outdir/selected-rules.tsv")"
fact_matches="$(awk -F '\t' 'NR > 1 && $3 == "resolved-type type-name-fact intrinsic-type-fact" && $4 == "checked-type-name" {n++} END {print n + 0}' "$outdir/selected-rules.tsv")"
test "$provenance_matches" -eq 1 || die 'C734 provenance differs'
test "$fact_matches" -eq 1 || die 'C734 fact fields differ'

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
type_name="$(awk '/^[[:space:]]*type[[:space:]]*::/ {value=$0; sub(/^[[:space:]]*type[[:space:]]*::[[:space:]]*/, "", value); gsub(/[[:space:]]/, "", value); print toupper(value); exit}' "$source_file")"
[ -n "$predicate" ] && [ -n "$type_name" ] || {
    printf 'missing-input\t%s\n' "$constraint_id" >&2
    exit 2
}

set +e
awk -v expr="$predicate" -v type_name="$type_name" '
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
function next_token() {
    pos++
    if (pos > n) exit 2
    return token[pos]
}
function close_expr(    value) {
    value = next_token()
    if (value != ")") exit 2
}
function intrinsic_name(name) {
    return name == "INTEGER" || name == "REAL" || name == "DOUBLEPRECISION" ||
           name == "COMPLEX" || name == "LOGICAL" || name == "CHARACTER"
}
function evaluate(    opener, operator, name, expected, left, right) {
    opener = next_token()
    if (opener != "(") exit 2
    operator = next_token()
    if (operator == "eq") {
        name = next_token()
        expected = toupper(next_token())
        close_expr()
        if (name != "type-name") exit 2
        return type_name == expected
    }
    if (operator == "intrinsic-type-name") {
        name = next_token()
        close_expr()
        if (name != "type-name") exit 2
        return intrinsic_name(type_name)
    }
    if (operator == "or") {
        left = evaluate()
        right = evaluate()
        close_expr()
        return left || right
    }
    if (operator == "not") {
        value = evaluate()
        close_expr()
        return !value
    }
    exit 2
}
' </dev/null
predicate_status=$?
set -e

case "$predicate_status" in
    0)
        printf 'accepted\t%s\tJ3-24-007 line=%s page=%s source_hash=%s\tpredicate=%s\n' \
            "$constraint_id" "$line" "$page" \
            "$source_hash" "$predicate"
        exit 0
        ;;
    1)
        printf 'diagnostic\t%s\tJ3-24-007 line=%s page=%s source_hash=%s\tpredicate=%s\n' \
            "$constraint_id" "$line" "$page" \
            "$source_hash" "$predicate" >&2
        exit 1
        ;;
    *)
        printf 'evaluator-error\t%s\tpredicate=%s\n' "$constraint_id" \
            "$predicate" >&2
        exit 2
        ;;
esac
EOF
sed -i "s|__RULE_TABLE__|$outdir/selected-rules.tsv|" \
    "$outdir/generated-nested-evaluator.sh"
if grep -Eq 'C734' "$outdir/generated-nested-evaluator.sh"; then
    die 'generated evaluator contains the selected constraint ID'
fi
chmod +x "$outdir/generated-nested-evaluator.sh"

printf 'module c734_positive\ntype :: mytype\nend type\nend module c734_positive\n' \
    >"$tmp/c734-positive.f90"
printf 'module c734_doubleprecision\ntype :: doubleprecision\nend type\nend module c734_doubleprecision\n' \
    >"$tmp/c734-doubleprecision.f90"
printf 'module c734_integer\ntype :: integer\nend type\nend module c734_integer\n' \
    >"$tmp/c734-integer.f90"

printf 'case_id\tchecker_status\tgfortran_status\tflang_status\tconstraint_id\tshape\tintrinsic_name\texpectation\tsource_sha256\n' \
    >"$outdir/witness-results.tsv"
evaluator_cases=0
evaluator_accepts=0
evaluator_rejects=0
behavioral_compilers=0
behavioral_agreements=0
diagnostic_rows=0
source_linked_results=0

while IFS=$'\t' read -r case_id constraint_id expected_checker expected_gfortran expected_flang shape intrinsic_name expectation; do
    [ "$case_id" = case_id ] && continue
    source_file="$tmp/$case_id.f90"
    set +e
    "$outdir/generated-nested-evaluator.sh" "$constraint_id" "$source_file" \
        >"$tmp/$case_id.checker.out" 2>"$tmp/$case_id.checker.err"
    checker_status=$?
    gfortran -std=f2023 -pedantic -fsyntax-only "$source_file" \
        >"$tmp/$case_id.gfortran.out" 2>&1
    gfortran_status=$?
    flang-new -pedantic -fsyntax-only "$source_file" \
        >"$tmp/$case_id.flang.out" 2>&1
    flang_status=$?
    set -e
    test "$checker_status" -eq "$expected_checker" || die "$case_id checker status differs"
    test "$gfortran_status" -eq "$expected_gfortran" || die "$case_id gfortran status differs"
    test "$flang_status" -eq "$expected_flang" || die "$case_id flang status differs"
    if [ "$expected_checker" -eq 0 ]; then
        grep -Fq $'accepted\tC734\tJ3-24-007 line=3618 page=87' \
            "$tmp/$case_id.checker.out" || die "$case_id lacks acceptance provenance"
        test ! -s "$tmp/$case_id.checker.err" || die "$case_id emitted a diagnostic"
        evaluator_accepts=$((evaluator_accepts + 1))
    else
        grep -Fq $'diagnostic\tC734\tJ3-24-007 line=3618 page=87' \
            "$tmp/$case_id.checker.err" || die "$case_id lacks diagnostic provenance"
        diagnostic_rows=$((diagnostic_rows + 1))
        evaluator_rejects=$((evaluator_rejects + 1))
    fi
    behavioral_compilers=$((behavioral_compilers + 2))
    if [ "$checker_status" -eq "$gfortran_status" ] &&
       [ "$checker_status" -eq "$flang_status" ]; then
        behavioral_agreements=$((behavioral_agreements + 1))
    fi
    source_linked_results=$((source_linked_results + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$case_id" "$checker_status" "$gfortran_status" \
        "$flang_status" "$constraint_id" "$shape" \
        "$intrinsic_name" "$expectation" \
        "$(sha256sum "$source_file" | cut -d' ' -f1)" \
        >>"$outdir/witness-results.tsv"
    evaluator_cases=$((evaluator_cases + 1))
done <"$witness_oracle"

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $5, $2, $3, $4, $6, $7, $8}' \
    "$outdir/witness-results.tsv" | sort >"$tmp/actual-witness.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7, $8}' \
    "$witness_oracle" | sort >"$tmp/expected-witness.tsv"
cmp -s "$tmp/actual-witness.tsv" "$tmp/expected-witness.tsv" ||
    die 'independent witness oracle differs'

sed 's/DOUBLEPRECISION/MYTYPE/' \
    "$outdir/selected-rules.tsv" >"$tmp/mutated-rules.tsv"
sed "s|$outdir/selected-rules.tsv|$tmp/mutated-rules.tsv|" \
    "$outdir/generated-nested-evaluator.sh" >"$tmp/mutated-evaluator.sh"
chmod +x "$tmp/mutated-evaluator.sh"
set +e
"$tmp/mutated-evaluator.sh" C734 "$tmp/c734-positive.f90" \
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
test "$evaluator_accepts" -eq 1 || die 'acceptance count differs'
test "$evaluator_rejects" -eq 2 || die 'rejection count differs'
test "$behavioral_compilers" -eq 6 || die 'behavioral compiler count differs'
test "$behavioral_agreements" -eq 3 || die 'behavioral agreement count differs'
test "$diagnostic_rows" -eq 2 || die 'diagnostic count differs'
test "$source_linked_results" -eq 3 || die 'source-link count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'predecessor_rule_rows\t%s\n' "$predecessor_rule_rows" >>"$outdir/summary.tsv"
printf 'selected_rule_rows\t%s\n' "$selected_rule_rows" >>"$outdir/summary.tsv"
printf 'generic_constructor_forms\t%s\n' "$generic_constructor_forms" >>"$outdir/summary.tsv"
printf 'target_oracle_difference\t%s\n' "$target_oracle_difference" >>"$outdir/summary.tsv"
printf 'provenance_matches\t%s\n' "$provenance_matches" >>"$outdir/summary.tsv"
printf 'fact_matches\t%s\n' "$fact_matches" >>"$outdir/summary.tsv"
printf 'evaluator_cases\t%s\n' "$evaluator_cases" >>"$outdir/summary.tsv"
printf 'evaluator_accepts\t%s\n' "$evaluator_accepts" >>"$outdir/summary.tsv"
printf 'evaluator_rejects\t%s\n' "$evaluator_rejects" >>"$outdir/summary.tsv"
printf 'behavioral_compilers\t%s\n' "$behavioral_compilers" >>"$outdir/summary.tsv"
printf 'behavioral_agreements\t%s\n' "$behavioral_agreements" >>"$outdir/summary.tsv"
printf 'diagnostic_rows\t%s\n' "$diagnostic_rows" >>"$outdir/summary.tsv"
printf 'source_linked_results\t%s\n' "$source_linked_results" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'target_oracle_sha256\t%s\n' "$(sha256sum "$target_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_oracle_sha256\t%s\n' "$(sha256sum "$witness_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'selected_rules_sha256\t%s\n' "$(sha256sum "$outdir/selected-rules.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witness_results_sha256\t%s\n' "$(sha256sum "$outdir/witness-results.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0096 oracle: generic nested not-or evaluator passed\n'
cat "$outdir/summary.tsv"
