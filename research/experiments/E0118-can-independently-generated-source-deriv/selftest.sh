#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
experiment="$root/research/experiments/E0118-can-independently-generated-source-deriv"
outdir="$(mktemp -d)"
trap 'rm -rf "$outdir"' EXIT

python3 "$experiment/analyze.py" "$experiment/fixtures/ledger.jsonl" \
    --canonical "$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" \
    --oracle "$experiment/fixtures/oracle.tsv" \
    --outdir "$outdir" --expected-rows 5 >/dev/null

test "$(jq -r '.eligible_constraint_rows' "$outdir/summary.json")" = 5
test "$(jq -r '.source_case_oracle_mismatches' "$outdir/summary.json")" -gt 0
test "$(jq -r '.independent_oracle_sha256' "$outdir/summary.json")" = "$(sha256sum "$experiment/fixtures/oracle.tsv" | cut -d' ' -f1)"
test "$(jq -r '.source_case_oracle_unavailable' "$outdir/summary.json")" = 1
test "$(jq -r '.compiler_unavailable_cells' "$outdir/summary.json")" -gt 0
test "$(jq -r '.mutation_control_failures' "$outdir/summary.json")" = 0
test "$(jq -s -r '[.[] | select(.row_key == "F001@1" and .source_expected == true and .facts.x == 1 and .candidate_result == false and .case_status == "mismatch")] | length' "$outdir/cases.jsonl")" = 1
test "$(jq -s -r '[.[] | select(.row_key == "F002@1" and .source_expected == false and .facts.x == 1 and .facts.y == null)] | length' "$outdir/cases.jsonl")" = 1
test "$(jq -s -r '[.[] | select(.row_key == "F003@1" and .source_expected == false and .facts.x == 0 and .facts.y == 1)] | length' "$outdir/cases.jsonl")" = 1
test "$(jq -s -r '[.[] | select(.row_key == "F004@1" and .source_expected == true and .facts.flag == null)] | length' "$outdir/cases.jsonl")" = 1
test "$(jq -s -r '[.[] | select(.row_key == "F005@1" and .source_case_status == "oracle_unavailable")] | length' "$outdir/rows.jsonl")" = 1
test "$(jq -s -r '[.[] | select(.mutation == "source-hash/provenance-substitution" and .status == "rejected")] | length' "$outdir/mutations.jsonl")" = 5
printf '%s\n' 'E0118 selftest: PASS'
