#!/usr/bin/env bash
# Extract the lexical-to-program-unit syntax span and check fixed boundary
# witnesses. This catches prose being attached to a preceding production and
# checks JSON escaping on a synthetic lexical token.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
canonical="${1:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
index="${2:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
output="${3:-$root/.cache/runs/E0004/R000002/j3-24-007.productions.jsonl}"

mkdir -p "$(dirname "$output")"
(cd "$standard" && fo exec pdfproductions "$canonical" "$index" "$output" 67 580)
jq -c . "$output" >/dev/null

test "$(wc -l < "$output")" = 1049
test "$(rg -c '"kind":"production-start"' "$output")" = 494
test "$(jq -r -s '[.[] | select(.rule == "R601")] | length' "$output")" = 3
test "$(jq -r -s '[.[] | select(.rule == "R602")] | length' "$output")" = 1
test "$(jq -r -s '[.[] | select(.rule == "R603")] | length' "$output")" = 1

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf '%s\n%s\n' 'R601 lexical is letter' 'or \' >"$tmp/input.text"
bytes="$(wc -c < "$tmp/input.text")"
printf 'canonical-format 1\npage 1 start 0 length %s\n' "$bytes" >"$tmp/input.index"
(cd "$standard" && fo exec pdfproductions "$tmp/input.text" "$tmp/input.index" \
    "$tmp/output.jsonl" 1 1)
jq -e -s 'any(.[]; .text == "\\")' "$tmp/output.jsonl" >/dev/null

printf '%s\n' 'E0004 oracle: 494 starts, prose boundaries and JSON escapes agree'
