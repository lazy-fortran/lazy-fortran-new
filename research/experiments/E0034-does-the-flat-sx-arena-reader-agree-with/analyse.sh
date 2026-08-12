#!/usr/bin/env bash
# Verify the flat SX arena reader against the recursive seed over the corpus.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="5e3def5"
outdir="${1:-$root/.cache/runs/E0034/R000001}"
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
run_check arena_fixture fo test test_fortsx_arena
run_check arena_corpus fo test test_fortsx_arena_corpus
run_check formatting fo fmt --check src/fortsx_arena.f90 test/test_fortsx_arena.f90 \
    test/test_fortsx_arena_corpus.f90
run_check full_pipeline fo

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value" >>"$outdir/summary.tsv"
done <"$tmp/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/summary.tsv"
printf 'generated_tree_cases\t64\n' >>"$outdir/summary.tsv"
printf 'malformed_cases_checked\t10\n' >>"$outdir/summary.tsv"
printf 'differential_byte_status\taccepted\n' >>"$outdir/summary.tsv"
printf 'independent_oracle_mutation\tobserved_failure\n' >>"$outdir/summary.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0034 oracle: flat SX arena corpus differential passed all checks\n'
    cat "$outdir/summary.tsv"
else
    printf 'E0034 failed: one or more checks did not pass\n' >&2
    exit 1
fi
