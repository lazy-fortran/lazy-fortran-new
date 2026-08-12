#!/usr/bin/env bash
# Verify the approved schema-value contract over the deterministic reference slice.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="bb8756a"
outdir="${1:-$root/.cache/runs/E0038/R000001}"
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
run_check schema_value fo test test_schema_value
run_check runtime_checked_schema_value fo test test_schema_value \
    --flag '-fcheck=all -fbacktrace'
run_check driver fo exec sxschema specs/schema-v0.sxs \
    build/E0038-regenerated.f90 schema_v0_generated
run_check generated_byte_identity cmp generated/schema_v0_generated.f90 \
    build/E0038-regenerated.f90
run_check generated_formatting fo fmt --check generated/schema_v0_generated.f90
run_check full_pipeline fo

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value" >>"$outdir/summary.tsv"
done <"$tmp/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/summary.tsv"
printf 'declaration_forms_checked\t6\n' >>"$outdir/summary.tsv"
printf 'canonical_value_cases_checked\t9\n' >>"$outdir/summary.tsv"
printf 'negative_value_cases_checked\t3\n' >>"$outdir/summary.tsv"
printf 'generated_source_bytes\t%s\n' "$(wc -c <"$standard/generated/schema_v0_generated.f90")" >>"$outdir/summary.tsv"
printf 'generated_source_sha256\t%s\n' "$(sha256sum "$standard/generated/schema_v0_generated.f90" | awk '{print $1}')" >>"$outdir/summary.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0038 oracle: approved schema-value contract passed all checks\n'
    cat "$outdir/summary.tsv"
else
    printf 'E0038 failed: one or more checks did not pass\n' >&2
    exit 1
fi
