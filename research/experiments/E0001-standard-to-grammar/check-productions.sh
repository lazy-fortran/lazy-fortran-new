#!/usr/bin/env bash
# Check the clause-5 production extraction against expected records from the
# pinned J3 document. The expected rule sequence is the independent oracle;
# jq validity and record counts alone are insufficient.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
canonical="${1:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
index="${2:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
output="${3:-$root/.cache/runs/E0001/R000005/j3-24-007.productions.jsonl}"

mkdir -p "$(dirname "$output")"
(cd "$standard" && fo exec pdfproductions "$canonical" "$index" "$output" 53 56)

jq -e -s '.[0].format == 1 and .[0].origin == "MECHANICAL" and .[0].source == "canonical-text"' \
    "$output" >/dev/null

actual_rules="$(jq -r -s '[.[] | select(.kind == "production-start") | .rule] | join(" ")' "$output")"
expected_rules='R501 R502 R1401 R503 R1532 R1537 R1404 R1416 R1420 R504 R505 R506 R507 R508 R509 R510 R511 R512 R1407 R1408 R1541 R513 R514 R515'
test "$actual_rules" = "$expected_rules"
test "$(jq -r -s '[.[] | select(.kind == "production-start")] | length' "$output")" = 24
test "$(jq -r -s 'length' "$output")" = 133

jq -e -s '
    any(.[]; .rule == "R501" and .kind == "production-start" and
        .lhs == "program" and .operator == "is" and
        .text == "program-unit") and
    any(.[]; .rule == "R515" and .kind == "production-continuation" and
        .page == 56 and .operator == "or" and .text == "forall-stmt")
' "$output" >/dev/null

printf '%s\n' 'production oracle: 24 starts, 133 records, R501/R515 boundaries agree'
