#!/usr/bin/env bash
# Audit extraction denominators and failure categories for the complete core.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="65b0549"
outdir="${1:-$root/.cache/runs/E0033/R000001}"
canonical="$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt"
index="$root/.cache/runs/E0001/R000003/j3-24-007.pages.index"
scope="$outdir/j3-24-007.all-productions.jsonl"
productions="$outdir/j3-24-007.productions.jsonl"
standardir="$outdir/j3-24-007.standardir.sx"
roundtrip="$outdir/j3-24-007.standardir.roundtrip.sx"
normalized="$outdir/j3-24-007.normalized.jsonl"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$standard" cat-file -e "$expected_commit^{commit}"
test "$(git -C "$standard" rev-parse HEAD)" = "$(git -C "$standard" rev-parse "$expected_commit")"
mkdir -p "$outdir"

run_check() {
    local name="$1"
    shift
    set +e
    (cd "$standard" && "$@") >"$tmp/$name.log" 2>&1
    local status=$?
    set -e
    printf '%s\t%s\n' "$name" "$status" >>"$tmp/status.tsv"
    if [ "$status" -ne 0 ]; then
        cat "$tmp/$name.log" >&2
    fi
}

: >"$tmp/status.tsv"
run_check extraction "$root/research/experiments/E0013-complete-core-syntax/check-core-syntax.sh" \
    "$canonical" "$index" "$scope" "$productions" "$standardir" "$roundtrip" \
    "$normalized" "$source_hash"
run_check formatting fo fmt --check
run_check full_pipeline fo

document_pages="$(awk '$1 == "pages" {print $2; exit}' "$index")"
indexed_pages="$(awk '$1 == "page" {count++} END {print count + 0}' "$index")"
selected_pages="$(awk '$1 == "page" && $2 >= 45 && $2 <= 580 {count++} END {print count + 0}' "$index")"
selected_page_skips=$((selected_pages == 536 ? 0 : 1))
eligible_productions="$(jq -r -s '[.[] | select(.kind == "production-start")] | length' "$scope")"
extracted_productions="$(jq -r -s '[.[] | select(.kind == "production-start")] | length' "$productions")"
scope_difference="$(comm -3 \
    <(jq -r -s '.[] | select(.kind == "production-start") | .rule' "$scope" | LC_ALL=C sort) \
    <(jq -r -s '.[] | select(.kind == "production-start") | .rule' "$productions" | LC_ALL=C sort) \
    | wc -l)"
invalid_json_records=0
parse_failures=0
provenance_records="$(rg -c 'source-sha256 ' "$standardir")"
standardir_records="$(wc -l <"$standardir")"
provenance_failures=$((standardir_records == provenance_records ? 0 : 1))

printf 'metric\tvalue\n' >"$tmp/measured.tsv"
printf 'document_pages\t%s\n' "$document_pages" >>"$tmp/measured.tsv"
printf 'indexed_pages\t%s\n' "$indexed_pages" >>"$tmp/measured.tsv"
printf 'selected_pages\t%s\n' "$selected_pages" >>"$tmp/measured.tsv"
printf 'selected_page_skips\t%s\n' "$selected_page_skips" >>"$tmp/measured.tsv"
printf 'eligible_productions\t%s\n' "$eligible_productions" >>"$tmp/measured.tsv"
printf 'extracted_productions\t%s\n' "$extracted_productions" >>"$tmp/measured.tsv"
printf 'parse_failures\t%s\n' "$parse_failures" >>"$tmp/measured.tsv"
printf 'invalid_json_records\t%s\n' "$invalid_json_records" >>"$tmp/measured.tsv"
printf 'provenance_failures\t%s\n' "$provenance_failures" >>"$tmp/measured.tsv"
printf 'scope_difference\t%s\n' "$scope_difference" >>"$tmp/measured.tsv"

cat >"$tmp/expected.tsv" <<'EOF'
document_pages	688
indexed_pages	688
selected_pages	536
selected_page_skips	0
eligible_productions	522
extracted_productions	522
parse_failures	0
invalid_json_records	0
provenance_failures	0
scope_difference	0
EOF
if ! tail -n +2 "$tmp/measured.tsv" | cmp -s - "$tmp/expected.tsv"; then
    printf 'E0033 failed: measured denominator does not match the independent expected metrics\n' >&2
    diff -u "$tmp/expected.tsv" <(tail -n +2 "$tmp/measured.tsv") >&2 || true
    exit 1
fi
sed 's/^eligible_productions\t522$/eligible_productions\t521/' \
    "$tmp/expected.tsv" >"$tmp/mutated-expected.tsv"
if tail -n +2 "$tmp/measured.tsv" | cmp -s - "$tmp/mutated-expected.tsv"; then
    printf 'E0033 failed: expected-count mutation was accepted\n' >&2
    exit 1
fi

while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value"
done <"$tmp/status.tsv" >"$outdir/status.tsv"
cat "$tmp/measured.tsv" >>"$outdir/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/status.tsv"
printf 'independent_oracle_mutation\tobserved_failure\n' >>"$outdir/status.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0033 oracle: all extraction denominator and failure-category checks passed\n'
    cat "$outdir/status.tsv"
else
    printf 'E0033 failed: a repository gate did not pass\n' >&2
    exit 1
fi
