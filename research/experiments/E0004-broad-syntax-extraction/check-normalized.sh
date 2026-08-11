#!/usr/bin/env bash
# Check the independent StandardIR-to-production normalization projection.
# Fixed notation witnesses are the behavioral oracle; counts and uniqueness
# only establish that the whole selected SX corpus was consumed.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
input="${1:-$root/.cache/runs/E0004/R000003/j3-24-007.standardir.sx}"
output="${2:-$root/.cache/runs/E0004/R000005/j3-24-007.normalized.jsonl}"

mkdir -p "$(dirname "$output")"
(cd "$standard" && fo exec sxnormalize "$input" "$output")

test "$(wc -l < "$output")" = 495
jq -e -s '.[0] == {kind:"normalized-production-header",format:1,origin:"MECHANICAL"}' \
    "$output" >/dev/null
test "$(jq -r -s '[.[] | select(.kind == "normalized-production")] | length' "$output")" = 494
test "$(jq -r -s '[.[] | select(.kind == "normalized-production" and (.notation | length == 0))] | length' "$output")" = 0
test "$(jq -r -s '[.[] | select(.kind == "normalized-production" and (.rule | type == "string") and (.rule | length > 0))] | length' "$output")" = 494

jq -e -s 'any(.[]; .rule == "R603" and .lhs == "name" and .notation == "letter [ alphanumeric-character ] ...")' \
    "$output" >/dev/null
jq -e -s 'any(.[]; .rule == "R705" and .notation == "INTEGER [ kind-selector ]")' \
    "$output" >/dev/null
jq -e -s 'any(.[]; .rule == "R706" and .notation == "( [ KIND = ] scalar-int-constant-expr )")' \
    "$output" >/dev/null
jq -e -s 'any(.[]; .rule == "R871" and .notation == "NAMELIST / namelist-group-name / namelist-group-object-list [ [ , ] / namelist-group-name / namelist-group-object-list ] ...")' \
    "$output" >/dev/null
jq -e -s 'any(.[]; .rule == "R1043" and .notation == "where-construct-stmt [ where-body-construct ] ... [ masked-elsewhere-stmt [ where-body-construct ] ... ] ... [ elsewhere-stmt [ where-body-construct ] ... ] end-where-stmt")' \
    "$output" >/dev/null
jq -e -s 'any(.[]; .rule == "R1136" and .notation == "if-then-stmt block [ else-if-stmt block ] ... [ else-stmt block ] end-if-stmt")' \
    "$output" >/dev/null

printf '%s\n' 'normalization oracle: 494 productions consumed and fixed notation witnesses agree'
