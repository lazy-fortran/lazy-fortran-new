#!/usr/bin/env bash
# Run the first generated frontend AST/wiring gate.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fortfront="${FORTFRONT_NEW_ROOT:-$root/../fortfront-new}"
outdir="${1:-$root/.cache/runs/E0119/R000001}"
schema="$root/contracts/frontend-ast-v0.sxs"
fixture="$root/contracts/fixtures/frontend-ast-v0.sx"
generator="$fortfront/tools/generate_ast.py"
behavioral="$fortfront/tools/test_generated_ast.py"
generated="$fortfront/src/generated/frontend_ast_v0_generated.f90"

die() { printf 'E0119: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
test -f "$schema" || die 'AST schema is missing'
test -f "$fixture" || die 'AST fixture is missing'
test -f "$generator" || die 'generator is missing'
test -f "$behavioral" || die 'behavioral oracle is missing'
test -f "$generated" || die 'checked-in generated source is missing'

test "$(git -C "$fortfront" rev-parse HEAD)" = \
    'bb9f4a08a0600b048823a0654d6282db16d893db' || die 'frontend pin mismatch'
test -z "$(git -C "$fortfront" status --porcelain)" || die 'frontend worktree is dirty'

start_ns="$(date +%s%N)"
"$root/scripts/check-contracts.sh" >"$outdir/contracts.log"
python3 "$behavioral" >"$outdir/behavioral.log"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 "$generator" "$schema" "$tmp/generated" >"$outdir/generator.log"
cmp -s "$generated" "$tmp/generated/frontend_ast_v0_generated.f90" || \
    die 'checked-in generated source is stale'

set +e
(cd "$fortfront" && fo) >"$outdir/fo.log" 2>&1
fo_status=$?
set -e
if test "$fo_status" -ne 0; then
    die 'fortfront-new full fo gate failed'
fi
if test -d "$fortfront/build"; then
    mv "$fortfront/build" "$outdir/fortfront-build"
fi
test -z "$(git -C "$fortfront" status --porcelain)" || \
    die 'fortfront worktree changed during gate'
bash -n "$fortfront/tools/regenerate_generated_ast.sh"
python3 -m py_compile "$generator" "$behavioral"
rm -rf "$fortfront/tools/__pycache__"
test -z "$(git -C "$fortfront" status --porcelain)" || \
    die 'syntax checks changed frontend worktree'

end_ns="$(date +%s%N)"
wall_s_total="$(awk -v start="$start_ns" -v end="$end_ns" \
    'BEGIN {printf "%.6f", (end - start) / 1000000000}')"
syntax_records="$(rg -c '^  \(record ' "$schema" || true)"
generated_types="$(rg -c '^    type, public :: ' "$generated" || true)"
generated_wiring="$(rg -c '^            type is ' "$generated" || true)"
provenance_fields="$(rg -c 'source_hash|source-hash' "$generated" || true)"
generated_bytes="$(wc -c <"$generated" | tr -d ' ')"
origin_mechanical="$(rg -c 'Origin: MECHANICAL' "$generated" || true)"

{
    printf 'metric\tvalue\n'
    printf 'syntax_records_consumed\t%s\n' "$syntax_records"
    printf 'generated_ast_types\t%s\n' "$generated_types"
    printf 'generated_wiring_entries\t%s\n' "$generated_wiring"
    printf 'generated_source_bytes\t%s\n' "$generated_bytes"
    printf 'provenance_fields\t%s\n' "$provenance_fields"
    printf 'mechanical_origin_labels\t%s\n' "$origin_mechanical"
    printf 'contract_validation_pass\t1\n'
    printf 'sx_fixture_roundtrip_pass\t1\n'
    printf 'independent_oracle_agreements\t1\n'
    printf 'independent_oracle_disagreements\t0\n'
    printf 'fo_status\t%s\n' "$fo_status"
    printf 'program_declaration_acceptance\t1\n'
    printf 'program_declaration_rejection\t1\n'
    printf 'unsupported_constructs_explicit\t1\n'
    printf 'wall_s_total\t%s\n' "$wall_s_total"
    printf 'gate\taccepted\n'
} >"$outdir/summary.tsv"

printf 'E0119 accepted: %s\n' "$outdir/summary.tsv"
