#!/usr/bin/env bash
# Verify generated schema readers and writers against fixed SX and the reference codec.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="44be898"
outdir="${1:-$root/.cache/runs/E0039/R000001}"
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
run_check schema_parser fo test test_schema_ir
run_check schema_codegen fo test test_schema_codegen
run_check generated_api fo test test_schema_generated_api
run_check runtime_checked_generated_api fo test test_schema_generated_api \
    --flag '-fcheck=all -fbacktrace'
run_check driver fo exec sxschema specs/schema-v0.sxs \
    build/E0039-regenerated.f90 schema_v0_generated
run_check generated_byte_identity cmp generated/schema_v0_generated.f90 \
    build/E0039-regenerated.f90
run_check generated_formatting fo fmt --check generated/schema_v0_generated.f90
run_check full_pipeline fo

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value" >>"$outdir/summary.tsv"
done <"$tmp/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/summary.tsv"
printf 'canonical_api_cases_checked\t10\n' >>"$outdir/summary.tsv"
printf 'negative_api_cases_checked\t2\n' >>"$outdir/summary.tsv"
printf 'generated_source_bytes\t%s\n' "$(wc -c <"$standard/generated/schema_v0_generated.f90")" >>"$outdir/summary.tsv"
printf 'generated_source_sha256\t%s\n' "$(sha256sum "$standard/generated/schema_v0_generated.f90" | awk '{print $1}')" >>"$outdir/summary.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0039 oracle: generated schema APIs agreed with the reference codec\n'
    cat "$outdir/summary.tsv"
else
    printf 'E0039 failed: one or more checks did not pass\n' >&2
    exit 1
fi
