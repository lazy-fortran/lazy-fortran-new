#!/usr/bin/env bash
# Check the first StandardIR SX projection against fixed structural witnesses.
# The expected nodes and provenance fields are the independent oracle; a
# parseable output file alone is not sufficient.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
productions="${1:-$root/.cache/runs/E0001/R000005/j3-24-007.productions.jsonl}"
output="${2:-$root/.cache/runs/E0001/R000006/j3-24-007.standardir.sx}"
source_hash="${3:-7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2}"

mkdir -p "$(dirname "$output")"
(cd "$standard" && fo exec pdfstandardir "$productions" "$output" "$source_hash" 5)

test "$(wc -l < "$output")" = 25
test "$(rg -c '^\(syntax ' "$output")" = 24
grep -Fqx \
    "(standardir (format 1) (origin MECHANICAL) (source (document J3-24-007) (clause 5) (source-sha256 $source_hash)))" \
    "$output"
rg -q '\(syntax R501 .*\(repeat \(ref program-unit\) 0 unbounded\).*\(byte-length 53\)' \
    "$output"
rg -q '\(syntax R1401 .*\(optional \(ref program-stmt\)\).*\(optional \(ref internal-subprogram-part\)\)' \
    "$output"
rg -q '\(syntax R515 .*\(ref forall-stmt\).*\(end-page 56\).*\(byte-length 804\)' \
    "$output"
test "$(rg -c 'source-sha256 ' "$output")" = 25

printf '%s\n' 'StandardIR oracle: 24 syntax objects, optional/repeat/alt nodes, provenance agree'
