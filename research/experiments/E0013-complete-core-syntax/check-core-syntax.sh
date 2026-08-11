#!/usr/bin/env bash
# Check the complete core PDF-to-production-to-StandardIR pipeline.
# The full-document audit is the scope oracle; fixed PDF witnesses are the
# independent behavioral oracle for the three machine-readable projections.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
canonical="${1:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
index="${2:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
scope_audit="${3:-$root/.cache/runs/E0013/R000000/j3-24-007.all-productions.jsonl}"
productions="${4:-$root/.cache/runs/E0013/R000001/j3-24-007.productions.jsonl}"
standardir="${5:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
roundtrip="${6:-$root/.cache/runs/E0013/R000003/j3-24-007.standardir.roundtrip.sx}"
normalized="${7:-$root/.cache/runs/E0013/R000004/j3-24-007.normalized.jsonl}"
source_hash="${8:-7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2}"

mkdir -p "$(dirname "$scope_audit")" "$(dirname "$productions")" \
    "$(dirname "$standardir")" "$(dirname "$roundtrip")" \
    "$(dirname "$normalized")"

(cd "$standard" && fo exec pdfproductions "$canonical" "$index" \
    "$scope_audit" 1 688)
jq -c . "$scope_audit" >/dev/null
test "$(wc -l < "$scope_audit")" = 1185
test "$(jq -r -s '[.[] | select(.kind == "production-start")] | length' "$scope_audit")" = 522
test "$(jq -r -s '[.[] | select(.kind == "production-continuation")] | length' "$scope_audit")" = 662

(cd "$standard" && fo exec pdfproductions "$canonical" "$index" \
    "$productions" 45 580)
jq -c . "$productions" >/dev/null
test "$(wc -l < "$productions")" = 1185
test "$(jq -r -s '[.[] | select(.kind == "production-start")] | length' "$productions")" = 522
test "$(jq -r -s '[.[] | select(.kind == "production-continuation")] | length' "$productions")" = 662

for witness in R401 R402 R403 R501 R516 R601 R603 R1547; do
    jq -e -s --arg rule "$witness" \
        'any(.[]; .rule == $rule and .kind == "production-start")' \
        "$productions" >/dev/null
done
jq -e -s 'any(.[]; .rule == "R401" and .lhs == "xyz-list")' "$productions" >/dev/null
jq -e -s 'any(.[]; .rule == "R402" and .lhs == "xyz-name")' "$productions" >/dev/null
jq -e -s 'any(.[]; .rule == "R403" and .lhs == "scalar-xyz")' "$productions" >/dev/null

core_rules=$(mktemp)
all_rules=$(mktemp)
trap 'rm -f "$core_rules" "$all_rules"' EXIT
jq -r -s '.[] | select(.kind == "production-start") | .rule' "$productions" \
    | LC_ALL=C sort > "$core_rules"
jq -r -s '.[] | select(.kind == "production-start") | .rule' "$scope_audit" \
    | LC_ALL=C sort > "$all_rules"
test "$(comm -23 "$all_rules" "$core_rules")" = $'R401\nR402\nR403'
test -z "$(comm -13 "$all_rules" "$core_rules")"

(cd "$standard" && fo exec pdfstandardir "$productions" "$standardir" \
    "$source_hash" 5-15)
test "$(wc -l < "$standardir")" = 523
test "$(rg -c '^\(syntax ' "$standardir")" = 522
grep -Fqx \
    "(standardir (format 1) (origin MECHANICAL) (source (document J3-24-007) (clause 5-15) (source-sha256 $source_hash)))" \
    "$standardir"
test "$(rg -c 'source-sha256 ' "$standardir")" = 523
rg -Fq '(syntax R401 (lhs xyz-list)' "$standardir"
rg -Fq '(syntax R516 (lhs keyword) (rhs (seq (ref name)))' "$standardir"
rg -Fq '(syntax R1547 (lhs stmt-function-stmt)' "$standardir"

(cd "$standard" && fo exec sxroundtrip "$standardir" "$roundtrip")
cmp -s "$standardir" "$roundtrip"

(cd "$standard" && fo exec sxnormalize "$standardir" "$normalized")
test "$(wc -l < "$normalized")" = 523
test "$(jq -r -s '[.[] | select(.kind == "normalized-production")] | length' "$normalized")" = 522
jq -e -s 'any(.[]; .rule == "R401" and .notation == "xyz [ , xyz ] ...")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R402" and .notation == "name")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R403" and .notation == "xyz")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R501" and .notation == "program-unit [ program-unit ] ...")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R516" and .notation == "name")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R601" and .notation == "letter or digit or underscore")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R603" and .notation == "letter [ alphanumeric-character ] ...")' "$normalized" >/dev/null
jq -e -s 'any(.[]; .rule == "R1547" and (.notation | test("function-name")))' "$normalized" >/dev/null

printf '%s\n' 'E0013 oracle: 522 productions, exact full-document scope, and all three machine-readable projections agree'
