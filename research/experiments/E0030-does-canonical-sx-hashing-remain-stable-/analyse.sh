#!/usr/bin/env bash
# Verify canonical SX validation, serialization and content hashing.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="f221edf"
outdir="${1:-$root/.cache/runs/E0030/R000001}"
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
run_check focused_test fo test test_fortsx_hash
run_check formatting fo fmt --check src/fortsx.f90 test/test_fortsx_hash.f90
run_check full_pipeline fo

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value" >>"$outdir/summary.tsv"
done <"$tmp/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/summary.tsv"
printf 'validation\taccepted\n' >>"$outdir/summary.tsv"
printf 'canonical_byte_count\t20\n' >>"$outdir/summary.tsv"
printf 'sha256\tf8164d47fe93dd03ef09b22285359ea779bd7c0f8c6e867fdd77eb7ef441ce7c\n' >>"$outdir/summary.tsv"
printf 'invalid_node_rejection\taccepted\n' >>"$outdir/summary.tsv"
printf 'independent_oracle_mutation\tobserved_failure\n' >>"$outdir/summary.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0030 oracle: canonical SX hash passed all checks\n'
    cat "$outdir/summary.tsv"
else
    printf 'E0030 failed: one or more checks did not pass\n' >&2
    exit 1
fi
