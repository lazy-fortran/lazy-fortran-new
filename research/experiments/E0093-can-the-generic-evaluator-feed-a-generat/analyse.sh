#!/usr/bin/env bash
# Feed the generic evaluator into one generated structured diagnostic operation.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0092="$root/research/experiments/E0092-can-one-generic-evaluator-execute-three-/analyse.sh"
diagnostic_oracle="$root/research/experiments/E0093-can-the-generic-evaluator-feed-a-generat/diagnostic-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0093/R000001}"

e0092_summary_hash="e74608df7bffa6614ef8349dadd886633e2e525d412d9f28ed34fb683f012d03"

die() {
    printf 'E0093: %s\n' "$1" >&2
    exit 1
}

test -x "$e0092" || die 'E0092 analyzer is missing'
test -f "$diagnostic_oracle" || die 'diagnostic oracle is missing'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0092" "$tmp/e0092" >"$outdir/e0092.log" || die 'E0092 predecessor failed'
test "$(sha256sum "$tmp/e0092/summary.tsv" | cut -d' ' -f1)" = "$e0092_summary_hash" ||
    die 'E0092 predecessor summary changed'

cat >"$outdir/generated-diagnostic-operation.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

evaluator="__EVALUATOR__"
rule_table="__RULE_TABLE__"
case_id="${1:?case ID required}"
constraint_id="${2:?constraint ID required}"
source_file="${3:?source file required}"

field() {
    awk -F '\t' -v id="$constraint_id" -v column="$1" \
        '$1 == id {print $column; exit}' "$rule_table"
}

predicate="$(field 2)"
line="$(field 5)"
page="$(field 6)"
standard_hash="$(field 7)"
source_sha256="$(sha256sum "$source_file" | cut -d' ' -f1)"

if [ -z "$predicate" ] || [ -z "$line" ] || [ -z "$page" ] || [ -z "$standard_hash" ]; then
    printf 'unknown-rule\t%s\n' "$constraint_id" >&2
    exit 2
fi

evaluator_out="$(mktemp)"
evaluator_err="$(mktemp)"
trap 'rm -f "$evaluator_out" "$evaluator_err"' EXIT
set +e
"$evaluator" "$constraint_id" "$source_file" >"$evaluator_out" 2>"$evaluator_err"
evaluator_status=$?
set -e

case "$evaluator_status" in
    0)
        status=accepted
        severity=none
        message=accepted
        ;;
    1)
        status=error
        severity=error
        message="violates $constraint_id"
        ;;
    *)
        cat "$evaluator_err" >&2
        exit "$evaluator_status"
        ;;
esac

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$case_id" "$constraint_id" "$status" "$severity" "$line" "$page" \
    "$message" "$standard_hash" "$source_sha256" "$predicate"
exit "$evaluator_status"
EOF
sed -i "s|__EVALUATOR__|$tmp/e0092/generic-evaluator.sh|; s|__RULE_TABLE__|$tmp/e0092/selected-rules.tsv|" \
    "$outdir/generated-diagnostic-operation.sh"
if grep -Eq 'C601|C603|C719' "$outdir/generated-diagnostic-operation.sh"; then
    die 'generated diagnostic operation contains selected constraint IDs'
fi
chmod +x "$outdir/generated-diagnostic-operation.sh"

printf 'case_id\tconstraint_id\tstatus\tseverity\tstandard_line\tstandard_page\tmessage\tstandard_hash\tsource_sha256\tpredicate\n' \
    >"$outdir/diagnostic-records.tsv"

printf 'program c601_positive\ninteger :: a\nend program c601_positive\n' >"$tmp/c601-positive.f90"
printf 'program c601_negative\ninteger :: %s\nend program c601_negative\n' \
    "$(printf '%064d' 0 | tr '0' b)" >"$tmp/c601-negative.f90"
printf 'program c603_positive\n00001 continue\nend program c603_positive\n' >"$tmp/c603-positive.f90"
printf 'program c603_negative\n00000 continue\nend program c603_negative\n' >"$tmp/c603-negative.f90"
printf 'program c719_positive\ninteger(kind=1) :: x\nend program c719_positive\n' >"$tmp/c719-positive.f90"
printf 'program c719_negative\ninteger(kind=-1) :: x\nend program c719-negative\n' >"$tmp/c719-negative.f90"

predecessor_evaluator_cases=0
diagnostic_records=0
accepted_records=0
error_records=0
standard_source_links=0
source_file_hashes=0
predicate_records=0

while IFS=$'\t' read -r case_id constraint_id expected_status expected_severity expected_line expected_page expected_message; do
    [ "$case_id" = case_id ] && continue
    source_file="$tmp/$case_id.f90"
    set +e
    "$outdir/generated-diagnostic-operation.sh" "$case_id" "$constraint_id" "$source_file" \
        >"$tmp/$case_id.record" 2>"$tmp/$case_id.err"
    operation_status=$?
    set -e
    case "$expected_status" in
        accepted) expected_operation_status=0 ;;
        error) expected_operation_status=1 ;;
        *) die "$case_id has unsupported oracle status" ;;
    esac
    test "$operation_status" -eq "$expected_operation_status" || die "$case_id operation status differs"
    cat "$tmp/$case_id.record" >>"$outdir/diagnostic-records.tsv"
    fields=$(awk -F '\t' 'NF == 10 {print NF}' "$tmp/$case_id.record")
    test "$fields" = 10 || die "$case_id diagnostic record is not structured"
    standard_hash=$(awk -F '\t' '{print $8}' "$tmp/$case_id.record")
    source_sha256=$(awk -F '\t' '{print $9}' "$tmp/$case_id.record")
    predicate=$(awk -F '\t' '{print $10}' "$tmp/$case_id.record")
    [ -n "$standard_hash" ] && standard_source_links=$((standard_source_links + 1))
    [ -n "$source_sha256" ] && source_file_hashes=$((source_file_hashes + 1))
    [ -n "$predicate" ] && predicate_records=$((predicate_records + 1))
    case "$expected_status" in
        accepted) accepted_records=$((accepted_records + 1)) ;;
        error) error_records=$((error_records + 1)) ;;
    esac
    predecessor_evaluator_cases=$((predecessor_evaluator_cases + 1))
done <"$diagnostic_oracle"

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$outdir/diagnostic-records.tsv" | sort >"$tmp/actual-diagnostics.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5, $6, $7}' \
    "$diagnostic_oracle" | sort >"$tmp/expected-diagnostics.tsv"
if cmp -s "$tmp/actual-diagnostics.tsv" "$tmp/expected-diagnostics.tsv"; then
    diagnostic_oracle_difference=0
else
    diagnostic_oracle_difference=1
    die 'independent diagnostic oracle differs'
fi

sed 's/violates /broken /' "$outdir/generated-diagnostic-operation.sh" >"$tmp/mutated-operation.sh"
chmod +x "$tmp/mutated-operation.sh"
set +e
"$tmp/mutated-operation.sh" c601-negative C601 "$tmp/c601-negative.f90" >"$tmp/mutated-record" 2>"$tmp/mutated-error"
mutated_status=$?
set -e
if [ "$mutated_status" -ne 1 ] || grep -Fq $'\tviolates C601\t' "$tmp/mutated-record"; then
    die 'diagnostic message mutation was not observed'
fi
negative_control=observed_failure

generic_operation_without_rule_ids=1
parser_projection_records=0
model_calls=0
test "$predecessor_evaluator_cases" -eq 6 || die 'predecessor evaluator denominator differs'
diagnostic_records=$((accepted_records + error_records))
test "$diagnostic_records" -eq 6 || die 'diagnostic record denominator differs'
test "$accepted_records" -eq 3 || die 'accepted record count differs'
test "$error_records" -eq 3 || die 'error record count differs'
test "$standard_source_links" -eq 6 || die 'standard provenance link count differs'
test "$source_file_hashes" -eq 6 || die 'source hash count differs'
test "$predicate_records" -eq 6 || die 'predicate record count differs'
test "$generic_operation_without_rule_ids" -eq 1 || die 'generic operation ID scan differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'predecessor_evaluator_cases\t%s\n' "$predecessor_evaluator_cases" >>"$outdir/summary.tsv"
printf 'diagnostic_records\t%s\n' "$diagnostic_records" >>"$outdir/summary.tsv"
printf 'accepted_records\t%s\n' "$accepted_records" >>"$outdir/summary.tsv"
printf 'error_records\t%s\n' "$error_records" >>"$outdir/summary.tsv"
printf 'diagnostic_oracle_difference\t%s\n' "$diagnostic_oracle_difference" >>"$outdir/summary.tsv"
printf 'standard_source_links\t%s\n' "$standard_source_links" >>"$outdir/summary.tsv"
printf 'source_file_hashes\t%s\n' "$source_file_hashes" >>"$outdir/summary.tsv"
printf 'predicate_records\t%s\n' "$predicate_records" >>"$outdir/summary.tsv"
printf 'generic_operation_without_rule_ids\t%s\n' "$generic_operation_without_rule_ids" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'diagnostic_oracle_sha256\t%s\n' "$(sha256sum "$diagnostic_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'diagnostic_records_sha256\t%s\n' "$(sha256sum "$outdir/diagnostic-records.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0093 oracle: generated source-linked diagnostic operation passed\n'
cat "$outdir/summary.tsv"
