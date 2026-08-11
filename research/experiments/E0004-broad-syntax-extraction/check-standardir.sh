#!/usr/bin/env bash
# Check the broad StandardIR SX projection against fixed structural witnesses.
# The output must be parseable, byte-round-trippable and structurally faithful
# at the punctuation, optional-group and cross-line witnesses.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
productions="${1:-$root/.cache/runs/E0004/R000002/j3-24-007.productions.jsonl}"
output="${2:-$root/.cache/runs/E0004/R000003/j3-24-007.standardir.sx}"
roundtrip="${3:-$root/.cache/runs/E0004/R000004/j3-24-007.standardir.roundtrip.sx}"
source_hash="${4:-7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2}"
clause="${5:-6-15}"

mkdir -p "$(dirname "$output")" "$(dirname "$roundtrip")"
(cd "$standard" && fo exec pdfstandardir "$productions" "$output" "$source_hash" "$clause")

test "$(wc -l < "$output")" = 495
test "$(rg -c '^\(syntax ' "$output")" = 494
grep -Fqx \
    "(standardir (format 1) (origin MECHANICAL) (source (document J3-24-007) (clause $clause) (source-sha256 $source_hash)))" \
    "$output"
rg -Fq '(syntax R603 (lhs name) (rhs (seq (ref letter) (repeat (ref alphanumeric-character) 0 unbounded)))' "$output"
rg -Fq '(syntax R705 (lhs integer-type-spec) (rhs (seq (token INTEGER) (optional (ref kind-selector))))' "$output"
rg -Fq '(syntax R706 (lhs kind-selector) (rhs (seq (token "(") (optional (seq (token KIND) (token =)))' "$output"
rg -Fq '(syntax R779 (lhs lbracket) (rhs (seq (token [)))' "$output"
rg -Fq '(syntax R780 (lhs rbracket) (rhs (seq (token ])))' "$output"
rg -Fq '(syntax R871 (lhs namelist-stmt)' "$output"
rg -Fq '(repeat (seq (optional (token ,))' "$output"
rg -Fq '(syntax R1043 (lhs where-construct)' "$output"
rg -Fq '(repeat (seq (ref masked-elsewhere-stmt)' "$output"
rg -Fq '(syntax R1136 (lhs if-construct)' "$output"
rg -Fq '(repeat (seq (ref else-if-stmt)' "$output"
test "$(rg -c 'source-sha256 ' "$output")" = 495

(cd "$standard" && fo exec sxroundtrip "$output" "$roundtrip")
cmp -s "$output" "$roundtrip"

printf '%s\n' 'StandardIR oracle: 494 syntax objects, punctuation/groups/provenance and SX round-trip agree'
