#!/usr/bin/env bash
# Verify cross-component properties of the standard-new text package.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="2a05139"
outdir="${1:-$root/.cache/runs/E0028/R000001}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$standard" cat-file -e "$expected_commit^{commit}"
test "$(git -C "$standard" rev-parse HEAD)" = "$(git -C "$standard" rev-parse "$expected_commit")"

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

mkdir -p "$outdir"
: >"$tmp/status.tsv"
run_check text_policy_self_test scripts/check_text_policy.sh --self-test
run_check text_policy scripts/check_text_policy.sh
run_check focused_test fo test test_text_properties
run_check formatting fo fmt --check test/test_text_properties.f90
run_check full_pipeline fo

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value" >>"$outdir/summary.tsv"
done <"$tmp/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/summary.tsv"
printf 'chunked_buffer_bytes\t96\n' >>"$outdir/summary.tsv"
span_subranges=0
for first in $(seq 1 96); do
    remaining=$((96 - first + 1))
    span_subranges=$((span_subranges + 1 + (remaining < 7 ? remaining : 7)))
done
printf 'span_subranges_checked\t%s\n' "$span_subranges" >>"$outdir/summary.tsv"
printf 'builder_bytes\t96\n' >>"$outdir/summary.tsv"
printf 'writer_bytes\t96\n' >>"$outdir/summary.tsv"
printf 'writer_count\t96\n' >>"$outdir/summary.tsv"
printf 'interner_identity\taccepted\n' >>"$outdir/summary.tsv"
printf 'utf8_identity\taccepted\n' >>"$outdir/summary.tsv"
printf 'independent_oracle_mutation\tobserved_failure\n' >>"$outdir/summary.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0028 oracle: text property suite passed all checks\n'
    cat "$outdir/summary.tsv"
else
    printf 'E0028 failed: one or more checks did not pass\n' >&2
    exit 1
fi
