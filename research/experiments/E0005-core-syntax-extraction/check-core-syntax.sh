#!/usr/bin/env bash
# Check the contiguous PDF-to-production-to-StandardIR pipeline.
# Fixed PDF witnesses are the independent behavioral oracle; corpus-wide
# counts and round-trips establish that the complete selected span was used.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
canonical="${1:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
index="${2:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
productions="${3:-$root/.cache/runs/E0005/R000001/j3-24-007.productions.jsonl}"
standardir="${4:-$root/.cache/runs/E0005/R000002/j3-24-007.standardir.sx}"
roundtrip="${5:-$root/.cache/runs/E0005/R000003/j3-24-007.standardir.roundtrip.sx}"
normalized="${6:-$root/.cache/runs/E0005/R000004/j3-24-007.normalized.jsonl}"
source_hash="${7:-7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2}"

mkdir -p "$(dirname "$productions")" "$(dirname "$standardir")" \
    "$(dirname "$roundtrip")" "$(dirname "$normalized")"

(cd "$standard" && fo exec pdfproductions "$canonical" "$index" \
    "$productions" 53 580)
jq -c . "$productions" >/dev/null
test "$(wc -l < "$productions")" = 1182
test "$(jq -r -s '[.[] | select(.kind == "production-start")] | length' "$productions")" = 519
test "$(jq -r -s '[.[] | select(.kind == "production-continuation")] | length' "$productions")" = 662
jq -e -s 'any(.[]; .rule == "R501" and .kind == "production-start")' "$productions" >/dev/null
jq -e -s 'any(.[]; .rule == "R516" and .text == "name")' "$productions" >/dev/null
jq -e -s 'any(.[]; .rule == "R601" and .lhs == "alphanumeric-character")' "$productions" >/dev/null
jq -e -s 'any(.[]; .rule == "R603" and .lhs == "name")' "$productions" >/dev/null
jq -e -s 'any(.[]; .rule == "R1547" and .kind == "production-start")' "$productions" >/dev/null

(cd "$standard" && fo exec pdfstandardir "$productions" "$standardir" \
    "$source_hash" 5-15)
test "$(wc -l < "$standardir")" = 520
test "$(rg -c '^\(syntax ' "$standardir")" = 519
grep -Fqx \
    "(standardir (format 1) (origin MECHANICAL) (source (document J3-24-007) (clause 5-15) (source-sha256 $source_hash)))" \
    "$standardir"
test "$(rg -c 'source-sha256 ' "$standardir")" = 520
rg -Fq '(syntax R516 (lhs keyword) (rhs (seq (ref name)))' "$standardir"
rg -Fq '(syntax R1547 (lhs stmt-function-stmt)' "$standardir"

(cd "$standard" && fo exec sxroundtrip "$standardir" "$roundtrip")
cmp -s "$standardir" "$roundtrip"

(cd "$standard" && fo exec sxnormalize "$standardir" "$normalized")
test "$(wc -l < "$normalized")" = 520
test "$(jq -r -s '[.[] | select(.kind == "normalized-production")] | length' "$normalized")" = 519
jq -e -s 'any(.[]; .rule == "R501" and .notation == "program-unit [ program-unit ] ...")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R516" and .notation == "name")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R601" and .notation == "letter or digit or underscore")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R603" and .notation == "letter [ alphanumeric-character ] ...")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R1547" and (.notation | test("function-name")))' "$normalized" >/dev/null

printf '%s\n' 'E0005 oracle: 519 productions and all three machine-readable projections agree'
