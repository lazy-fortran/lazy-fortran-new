#!/usr/bin/env bash
# Classify every accepted predicate row with one generic top-level dispatcher.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0090="$root/research/experiments/E0090-can-accepted-predicates-generate-a-seman/analyse.sh"
form_oracle="$root/research/experiments/E0094-can-one-generic-predicate-dispatcher-cla/predicate-form-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0094/R000001}"
e0090_summary_hash="6eac160c592660bdeffc6460ccb6efc33b0c00e945a31e05029b7b23fdebf622"

die() {
    printf 'E0094: %s\n' "$1" >&2
    exit 1
}

test -x "$e0090" || die 'E0090 analyzer is missing'
test -f "$form_oracle" || die 'predicate form oracle is missing'
mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0090" "$tmp/e0090" >"$outdir/e0090.log" || die 'E0090 predecessor failed'
test "$(sha256sum "$tmp/e0090/summary.tsv" | cut -d' ' -f1)" = "$e0090_summary_hash" ||
    die 'E0090 predecessor summary changed'

cat >"$outdir/generated-predicate-dispatcher.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

rule_table="__RULE_TABLE__"
constraint_id="${1:?constraint ID required}"

field() {
    awk -F '\t' -v id="$constraint_id" -v column="$1" \
        '$1 == id {print $column; exit}' "$rule_table"
}

predicate="$(field 2)"
line="$(field 3)"
page="$(field 4)"
source_hash="$(field 5)"
constructor="$(printf '%s\n' "$predicate" | sed -n 's/^(\([^ ]*\).*/\1/p')"

if [ -z "$predicate" ] || [ -z "$constructor" ] || [ -z "$line" ] ||
   [ -z "$page" ] || [ -z "$source_hash" ]; then
    printf 'incomplete-rule\t%s\n' "$constraint_id" >&2
    exit 2
fi

case "$constructor" in
    and|exists|ge|implies|in|le|not|or|unique)
        ;;
    *)
        printf 'unsupported-constructor\t%s\n' "$constructor" >&2
        exit 1
        ;;
esac

printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$constraint_id" "$constructor" "$line" \
    "$page" "$source_hash" "$predicate"
EOF
printf '%s\n' "$tmp/e0090/semantic-rule-table.tsv" >"$tmp/rule-table-path"
sed -i "s|__RULE_TABLE__|$tmp/dispatch-table.tsv|" \
    "$outdir/generated-predicate-dispatcher.sh"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $11, $3, $4, $5}' \
    "$tmp/e0090/semantic-rule-table.tsv" >"$tmp/dispatch-table.tsv"
if grep -Eq 'C601|C603|C718|C719|C721|C725|C734|C738|C795|C7117|C7118|C937|C1017|C1166|C1306|C1404|C1405|C1515|C1526|C1579|C1587|C1590' \
    "$outdir/generated-predicate-dispatcher.sh"; then
    die 'generated dispatcher contains selected constraint IDs'
fi
chmod +x "$outdir/generated-predicate-dispatcher.sh"

printf 'constraint_id\tconstructor\tline\tpage\tsource_hash\tpredicate\n' \
    >"$outdir/dispatch-results.tsv"
dispatcher_rows=0
provenance_matches=0
unsupported_constructor_rows=0

while IFS=$'\t' read -r constraint_id expected_constructor; do
    [ "$constraint_id" = constraint_id ] && continue
    set +e
    "$outdir/generated-predicate-dispatcher.sh" "$constraint_id" \
        >"$tmp/$constraint_id.out" 2>"$tmp/$constraint_id.err"
    status=$?
    set -e
    test "$status" -eq 0 || die "$constraint_id dispatcher rejected accepted form"
    cat "$tmp/$constraint_id.out" >>"$outdir/dispatch-results.tsv"
    actual_constructor=$(awk -F '\t' '{print $2}' "$tmp/$constraint_id.out")
    test "$actual_constructor" = "$expected_constructor" ||
        die "$constraint_id constructor differs"
    [ -n "$(awk -F '\t' '{print $5}' "$tmp/$constraint_id.out")" ] ||
        die "$constraint_id source hash missing"
    provenance_matches=$((provenance_matches + 1))
    dispatcher_rows=$((dispatcher_rows + 1))
done <"$form_oracle"

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2}' \
    "$outdir/dispatch-results.tsv" | sort >"$tmp/actual-forms.tsv"
awk -F '\t' 'NR > 1 {print $1, $2}' OFS='\t' "$form_oracle" | sort >"$tmp/expected-forms.tsv"
if cmp -s "$tmp/actual-forms.tsv" "$tmp/expected-forms.tsv"; then
    dispatch_oracle_difference=0
else
    dispatch_oracle_difference=1
    die 'independent predicate-form oracle differs'
fi

sed 's/(le /(mystery /' "$tmp/dispatch-table.tsv" >"$tmp/mutated-table.tsv"
sed -i "s|$tmp/dispatch-table.tsv|$tmp/mutated-table.tsv|" \
    "$outdir/generated-predicate-dispatcher.sh"
set +e
"$outdir/generated-predicate-dispatcher.sh" C601 >"$tmp/mutated.out" 2>"$tmp/mutated.err"
mutated_status=$?
set -e
if [ "$mutated_status" -ne 1 ]; then
    die 'unknown-constructor mutation was accepted'
fi
negative_control=observed_failure

predecessor_rule_rows=$(awk -F '\t' '$1 == "generated_rule_rows" {print $2}' "$tmp/e0090/summary.tsv")
accepted_predicate_rows=$(awk 'END {print NR - 1}' "$form_oracle")
unique_top_level_constructors=$(awk -F '\t' 'NR > 1 {seen[$2]=1} END {for (x in seen) n++; print n + 0}' "$outdir/dispatch-results.tsv")
parser_projection_records=0
model_calls=0
generated_dispatcher_without_rule_ids=1
test "$predecessor_rule_rows" -eq 22 || die 'predecessor row count differs'
test "$accepted_predicate_rows" -eq 22 || die 'accepted predicate denominator differs'
test "$dispatcher_rows" -eq 22 || die 'dispatcher row count differs'
test "$unique_top_level_constructors" -eq 9 || die 'constructor count differs'
test "$dispatch_oracle_difference" -eq 0 || die 'dispatch oracle differs'
test "$provenance_matches" -eq 22 || die 'provenance count differs'
test "$unsupported_constructor_rows" -eq 0 || die 'unsupported constructor count differs'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'predecessor_rule_rows\t%s\n' "$predecessor_rule_rows" >>"$outdir/summary.tsv"
printf 'accepted_predicate_rows\t%s\n' "$accepted_predicate_rows" >>"$outdir/summary.tsv"
printf 'dispatcher_rows\t%s\n' "$dispatcher_rows" >>"$outdir/summary.tsv"
printf 'unique_top_level_constructors\t%s\n' "$unique_top_level_constructors" >>"$outdir/summary.tsv"
printf 'dispatch_oracle_difference\t%s\n' "$dispatch_oracle_difference" >>"$outdir/summary.tsv"
printf 'provenance_matches\t%s\n' "$provenance_matches" >>"$outdir/summary.tsv"
printf 'unsupported_constructor_rows\t%s\n' "$unsupported_constructor_rows" >>"$outdir/summary.tsv"
printf 'generated_dispatcher_without_rule_ids\t%s\n' "$generated_dispatcher_without_rule_ids" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'predicate_form_oracle_sha256\t%s\n' "$(sha256sum "$form_oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'dispatch_results_sha256\t%s\n' "$(sha256sum "$outdir/dispatch-results.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0094 oracle: generic predicate dispatcher classified all accepted forms\n'
cat "$outdir/summary.tsv"
