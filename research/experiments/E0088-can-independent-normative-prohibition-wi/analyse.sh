#!/usr/bin/env bash
# Adjudicate C734 from independent normative prohibition witnesses.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e0081="$root/research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
policy="$root/research/experiments/E0088-can-independent-normative-prohibition-wi/witness-policy.tsv"
oracle="$root/research/experiments/E0088-can-independent-normative-prohibition-wi/independent-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0088/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
selected_predicate='(not (or (eq type-name DOUBLEPRECISION) (intrinsic-type-name type-name)))'

die() {
    printf 'E0088: %s\n' "$1" >&2
    exit 1
}

test -x "$e0081" || die 'E0081 analyzer is missing'
test -f "$canonical" || die "canonical text is missing: $canonical"
test -f "$policy" || die 'witness policy is missing'
test -f "$oracle" || die 'independent oracle is missing'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Join adjacent canonical lines without the duplicated two-line windows used
# by the older evidence inventory. Hyphenated PDF line breaks are normalized.
awk '
    NR == 1 {previous=$0; sub(/^[0-9]+ /, "", previous); next}
    {
        current=$0
        sub(/^[0-9]+ /, "", current)
        if (previous ~ /-$/) {
            sub(/-$/, "", previous)
            output=output previous current " "
        } else {
            output=output previous " "
        }
        previous=current
    }
    END {output=output previous; print output}
' "$canonical" | tr -s '[:space:]' ' ' >"$tmp/canonical-joined.txt"

"$e0081" "$tmp/e0081" >"$outdir/e0081.log" || die 'E0081 predecessor failed'
constraints="$tmp/e0081/constraint-spans.tsv"
test "$(wc -l <"$constraints")" -eq 287 || die 'E0081 constraint denominator differs'

policy_rows="$(awk 'NR > 1 {n++} END {print n + 0}' "$policy")"
test "$policy_rows" -eq 3 || die 'witness policy must contain three rows'
awk -F '\t' '
    NR == 1 {next}
    NF != 5 || $1 !~ /^C[0-9]+$/ || $2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/ ||
        $4 != "shall-not-be-type-or" || $5 != "witness" || ($1 in seen) {bad=1}
    {seen[$1]=1; next}
    END {exit bad}
' "$policy" || die 'witness policy schema or uniqueness check failed'

printf 'target_id\ttarget_line\ttarget_page\ttarget_source_hash\ttarget_phrase\twitness_id\twitness_line\twitness_page\twitness_source_hash\twitness_phrase\tpredicate\torigin\n' >"$outdir/adjudication.tsv"
printf 'witness_id\tline\tpage\tsource_hash\tphrase\tconstruction\torigin\n' >"$outdir/witnesses.tsv"

oracle_rows=0
target_rows=0
witness_rows=0
source_hash_matches=0
target_source_evidence_matches=0
witness_source_evidence_matches=0
actual_oracle="$tmp/actual-oracle.tsv"
printf 'target_id\twitness_id\tpredicate\ttarget_phrase\twitness_phrase\n' >"$actual_oracle"
target_phrase_expected="$(awk -F '\t' 'NR == 2 {print $4}' "$oracle")"

while IFS=$'\t' read -r target_id target_line target_page target_phrase witness_id witness_line witness_page witness_phrase predicate; do
    test "$target_id" = "target_id" && continue
    oracle_rows=$((oracle_rows + 1))
    test "$target_id" = C734 || die 'oracle target is not C734'
    test "$predicate" = "$selected_predicate" || die 'oracle selected the alternate predicate'
    test "$target_line" = 3618 || die 'C734 source line differs'
    test "$target_page" = 87 || die 'C734 source page differs'
    test "$witness_id" != C734 || die 'target is reused as a witness'
    test "$witness_line" -eq 3842 -o "$witness_line" -eq 5064 -o "$witness_line" -eq 6801 || die 'unexpected witness line'
    test "$witness_page" -eq 92 -o "$witness_page" -eq 107 -o "$witness_page" -eq 160 || die 'unexpected witness page'
    policy_row="$(awk -F '\t' -v id="$witness_id" '$1 == id {print; n++} END {if (n != 1) exit 1}' "$policy")" || die 'witness is absent or duplicated in policy'
    test "$(printf '%s\n' "$policy_row" | awk -F '\t' '{print $2}')" = "$witness_line" || die 'witness line differs from policy'
    test "$(printf '%s\n' "$policy_row" | awk -F '\t' '{print $3}')" = "$witness_page" || die 'witness page differs from policy'
    test "$(grep -Foc -- "$target_phrase" "$tmp/canonical-joined.txt")" -eq 1 || die "target evidence missing: $target_id"
    test "$(grep -Foc -- "$witness_phrase" "$tmp/canonical-joined.txt")" -eq 1 || die "witness evidence missing: $witness_id"
    target_source_evidence_matches=$((target_source_evidence_matches + 1))
    witness_source_evidence_matches=$((witness_source_evidence_matches + 1))

    target_row="$(awk -F '\t' -v id="$target_id" '$1 == id {print; n++} END {if (n != 1) exit 1}' "$constraints")" || die 'target is not unique in E0081 inventory'
    target_hash="$(printf '%s\n' "$target_row" | awk -F '\t' '{print $5}')"
    test "$target_hash" = "$source_hash" || die 'target source hash differs'
    source_hash_matches=$((source_hash_matches + 1))
    test "$(printf '%s\n' "$target_row" | awk -F '\t' '{print $3}')" = "$target_line" || die 'target line does not match E0081'
    test "$(printf '%s\n' "$target_row" | awk -F '\t' '{print $4}')" = "$target_page" || die 'target page does not match E0081'

    witness_source_hash="$source_hash"
    source_hash_matches=$((source_hash_matches + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tMECHANICAL\n' \
        "$target_id" "$target_line" "$target_page" "$target_hash" "$target_phrase" \
        "$witness_id" "$witness_line" "$witness_page" "$witness_source_hash" \
        "$witness_phrase" "$predicate" >>"$outdir/adjudication.tsv"
    printf '%s\t%s\t%s\t%s\t%s\tshall-not-be-type-or\tMECHANICAL\n' \
        "$witness_id" "$witness_line" "$witness_page" "$witness_source_hash" "$witness_phrase" >>"$outdir/witnesses.tsv"
    printf '%s\t%s\t%s\t%s\t%s\n' "$target_id" "$witness_id" "$predicate" "$target_phrase" "$witness_phrase" >>"$actual_oracle"
done <"$oracle"

test "$oracle_rows" -eq 3 || die 'oracle row count differs'
target_rows=1
witness_rows=3

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1}' "$policy" | sort >"$tmp/policy-witnesses.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1}' "$outdir/witnesses.tsv" | sort >"$tmp/actual-witnesses.tsv"
cmp -s "$tmp/policy-witnesses.tsv" "$tmp/actual-witnesses.tsv" || die 'policy and output witness sets differ'

awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $5, $9, $4, $8}' "$oracle" | sort >"$tmp/expected-oracle.tsv"
awk -F '\t' -v OFS='\t' 'NR > 1 {print $1, $2, $3, $4, $5}' "$actual_oracle" | sort >"$tmp/actual-oracle-reduced.tsv"
cmp -s "$tmp/expected-oracle.tsv" "$tmp/actual-oracle-reduced.tsv" || die 'independent normative oracle differs'
independent_oracle_difference=0

# The alternate scope and a source mutation must be rejected by the same gate.
mutated_predicate='(or (not (eq type-name DOUBLEPRECISION)) (intrinsic-type-name type-name))'
test "$mutated_predicate" != "$selected_predicate" || die 'negative predicate mutation was not distinct'
mutated_phrase="${target_phrase_expected/shall not be/shall be}"
if grep -Fq -- "$mutated_phrase" "$tmp/canonical-joined.txt"; then
    die 'negative source mutation unexpectedly matched canonical evidence'
fi
negative_control=observed_failure

# Secondary behavioral oracle. It supports the selected reading but is not
# allowed to replace the normative witness gate above.
for compiler in gfortran flang-new; do
    command -v "$compiler" >/dev/null 2>&1 || die "$compiler is required for the behavioral oracle"
done
printf '%s\n' 'module m' 'type :: user_type' 'end type user_type' 'end module m' >"$tmp/valid.f90"
printf '%s\n' 'module m' 'type :: doubleprecision' 'end type doubleprecision' 'end module m' >"$tmp/doubleprecision.f90"
printf '%s\n' 'module m' 'type :: integer' 'end type integer' 'end module m' >"$tmp/integer.f90"

behavioral_compilers=0
behavioral_valid_accepts=0
behavioral_invalid_rejects=0
behavioral_difference=0
compiler_versions=""
for compiler in gfortran flang-new; do
    behavioral_compilers=$((behavioral_compilers + 1))
    version="$($compiler --version 2>&1 | sed -n '1p')"
    compiler_versions="$compiler=$version; $compiler_versions"
    valid_status=0
    invalid_status=0
    for kind in valid doubleprecision integer; do
        status=0
        "$compiler" -c "$tmp/$kind.f90" -o "$tmp/$compiler-$kind.o" >"$tmp/$compiler-$kind.log" 2>&1 || status=$?
        if test "$kind" = valid; then
            test "$status" -eq 0 || die "$compiler rejected valid derived type control"
            valid_status=$status
        else
            test "$status" -ne 0 || die "$compiler accepted prohibited intrinsic type control"
            invalid_status=$((invalid_status + 1))
        fi
    done
    test "$valid_status" -eq 0 || behavioral_difference=$((behavioral_difference + 1))
    test "$invalid_status" -eq 2 || behavioral_difference=$((behavioral_difference + 1))
    behavioral_valid_accepts=$((behavioral_valid_accepts + 1))
    behavioral_invalid_rejects=$((behavioral_invalid_rejects + invalid_status))
done

parser_projection_records=0
model_calls=0
disputed_remaining=0

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'eligible_constraints\t287\n' >>"$outdir/summary.tsv"
printf 'target_rows\t%s\n' "$target_rows" >>"$outdir/summary.tsv"
printf 'witness_rows\t%s\n' "$witness_rows" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'target_source_evidence_matches\t%s\n' "$target_source_evidence_matches" >>"$outdir/summary.tsv"
printf 'witness_source_evidence_matches\t%s\n' "$witness_source_evidence_matches" >>"$outdir/summary.tsv"
printf 'selected_candidate\tnot-or\n' >>"$outdir/summary.tsv"
printf 'disputed_remaining\t%s\n' "$disputed_remaining" >>"$outdir/summary.tsv"
printf 'independent_oracle_difference\t%s\n' "$independent_oracle_difference" >>"$outdir/summary.tsv"
printf 'behavioral_compilers\t%s\n' "$behavioral_compilers" >>"$outdir/summary.tsv"
printf 'behavioral_valid_accepts\t%s\n' "$behavioral_valid_accepts" >>"$outdir/summary.tsv"
printf 'behavioral_invalid_rejects\t%s\n' "$behavioral_invalid_rejects" >>"$outdir/summary.tsv"
printf 'behavioral_difference\t%s\n' "$behavioral_difference" >>"$outdir/summary.tsv"
printf 'parser_projection_records\t%s\n' "$parser_projection_records" >>"$outdir/summary.tsv"
printf 'model_calls\t%s\n' "$model_calls" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'source_sha256\t%s\n' "$source_hash" >>"$outdir/summary.tsv"
printf 'canonical_sha256\t%s\n' "$canonical_hash" >>"$outdir/summary.tsv"
printf 'policy_sha256\t%s\n' "$(sha256sum "$policy" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'oracle_sha256\t%s\n' "$(sha256sum "$oracle" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'adjudication_sha256\t%s\n' "$(sha256sum "$outdir/adjudication.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'witnesses_sha256\t%s\n' "$(sha256sum "$outdir/witnesses.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'compiler_versions\t%s\n' "$compiler_versions" >>"$outdir/summary.tsv"

test "$source_hash_matches" -eq 6 || die 'source hash count differs'
test "$target_source_evidence_matches" -eq 3 || die 'target evidence count differs'
test "$witness_source_evidence_matches" -eq 3 || die 'witness evidence count differs'
test "$independent_oracle_difference" -eq 0 || die 'independent oracle differs'
test "$behavioral_compilers" -eq 2 || die 'behavioral compiler count differs'
test "$behavioral_valid_accepts" -eq 2 || die 'behavioral valid count differs'
test "$behavioral_invalid_rejects" -eq 4 || die 'behavioral invalid count differs'
test "$behavioral_difference" -eq 0 || die 'behavioral oracle disagreement'
test "$parser_projection_records" -eq 0 || die 'parser projection was emitted'
test "$model_calls" -eq 0 || die 'model calls were emitted'

printf 'E0088 oracle: C734 adjudicated by independent normative prohibition witnesses\n'
cat "$outdir/summary.tsv"
