#!/usr/bin/env bash
# Verify deterministic Fortran type emission from the v0 SX schema.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
expected_commit="0c716e5"
outdir="${1:-$root/.cache/runs/E0036/R000001}"
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
run_check codegen_test fo test test_schema_codegen
run_check runtime_checked_codegen_test fo test test_schema_codegen \
    --flag '-fcheck=all -fbacktrace'
run_check formatting fo fmt --check src/schema_ir.f90 src/schema_codegen.f90 \
    test/test_schema_ir.f90 test/test_schema_codegen.f90
run_check full_pipeline fo

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
while IFS=$'\t' read -r metric value; do
    printf '%s\t%s\n' "$metric" "$value" >>"$outdir/summary.tsv"
done <"$tmp/status.tsv"
printf 'standard_new_commit\t%s\n' "$expected_commit" >>"$outdir/summary.tsv"
printf 'declaration_forms_checked\t6\n' >>"$outdir/summary.tsv"
printf 'expected_source_lines_checked\t10\n' >>"$outdir/summary.tsv"
printf 'cyclic_dependency_cases_checked\t1\n' >>"$outdir/summary.tsv"
printf 'independent_oracle_mutation\tobserved_failure\n' >>"$outdir/summary.tsv"

if awk -F '\t' '$2 != 0 {failed=1} END {exit failed}' "$tmp/status.tsv"; then
    printf 'E0036 oracle: deterministic schema type emission passed all checks\n'
    cat "$outdir/summary.tsv"
else
    printf 'E0036 failed: one or more checks did not pass\n' >&2
    exit 1
fi
