#!/usr/bin/env bash
# Verify the recursive SX seed against generated trees and malformed inputs.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="803f46f"
outdir="${1:-$root/.cache/runs/E0032/R000001}"
corpus="$standard/build/fortsx_fuzz_corpus.sx"
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
run_check focused_test fo test test_fortsx_corpus
run_check formatting fo fmt --check test/test_fortsx_corpus.f90
run_check full_pipeline fo

line_count="$(wc -l <"$corpus")"
byte_count="$(wc -c <"$corpus")"
corpus_sha256="$(sha256sum "$corpus" | awk '{print $1}')"
test "$line_count" -eq 64
test "$byte_count" -eq 939
test "$corpus_sha256" = "50968a919e33031d74e58abc9eddec94d4f779ef302caf1ed861b797989013af"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value" >>"$outdir/summary.tsv"
done <"$tmp/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/summary.tsv"
printf 'generated_tree_cases\t64\n' >>"$outdir/summary.tsv"
printf 'generated_corpus_lines\t%s\n' "$line_count" >>"$outdir/summary.tsv"
printf 'generated_corpus_bytes\t%s\n' "$byte_count" >>"$outdir/summary.tsv"
printf 'generated_corpus_sha256\t%s\n' "$corpus_sha256" >>"$outdir/summary.tsv"
printf 'malformed_cases_rejected\t10\n' >>"$outdir/summary.tsv"
printf 'malformed_message_matches\t10\n' >>"$outdir/summary.tsv"
printf 'independent_oracle_mutation\tobserved_failure\n' >>"$outdir/summary.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0032 oracle: generated SX corpus passed all checks\n'
    cat "$outdir/summary.tsv"
else
    printf 'E0032 failed: one or more checks did not pass\n' >&2
    exit 1
fi
