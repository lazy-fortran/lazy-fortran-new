#!/usr/bin/env bash
# Parse and rewrite the StandardIR artifact, then require byte identity.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
input="${1:-$root/.cache/runs/E0001/R000006/j3-24-007.standardir.sx}"
output="${2:-$root/.cache/runs/E0001/R000007/j3-24-007.standardir.sx}"

mkdir -p "$(dirname "$output")"
(cd "$standard" && fo exec sxroundtrip "$input" "$output")
cmp -s "$input" "$output"
test "$(wc -l < "$output")" = 25
test "$(rg -c '^\(syntax ' "$output")" = 24

printf '%s\n' 'SX round-trip oracle: canonical StandardIR bytes are identical'
