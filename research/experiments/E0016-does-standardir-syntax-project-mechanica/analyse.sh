#!/usr/bin/env bash
# Generate and independently check the canonical EBNF projection.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
output="${2:-$root/.cache/runs/E0016/R000001/j3-24-007.ebnf}"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

test -x "$standard/fo" || test -f "$standard/fpm.toml"
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash"
mkdir -p "$(dirname "$output")"

(cd "$standard" && fo exec sxebnf "$input" "$output")

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Independent metadata projection from the StandardIR input.
awk '
    /^\(syntax / {
        rule = $2
        lhs = $4
        gsub(/[()]/, "", rule)
        gsub(/[()]/, "", lhs)
        document = ""
        clause = ""
        page = ""
        source_sha256 = ""
        for (i = 1; i <= NF; i++) {
            if ($i == "(document") { document = $(i + 1); gsub(/[()]/, "", document) }
            if ($i == "(clause") { clause = $(i + 1); gsub(/[()]/, "", clause) }
            if ($i == "(page") { page = $(i + 1); gsub(/[()]/, "", page) }
            if ($i == "(source-sha256") {
                source_sha256 = $(i + 1)
                gsub(/[()]/, "", source_sha256)
            }
        }
        print rule "\t" lhs "\t" document "\t" clause "\t" page "\t" source_sha256
    }
' "$input" > "$tmp/expected.tsv"

awk '
    /^\(\* rule=/ {
        rule = $2
        document = $3
        clause = $4
        page = $5
        source_sha256 = $6
        sub(/^rule=/, "", rule)
        sub(/^document=/, "", document)
        sub(/^clause=/, "", clause)
        sub(/^page=/, "", page)
        sub(/^source-sha256=/, "", source_sha256)
        getline production
        lhs = production
        sub(/ ::= .*/, "", lhs)
        print rule "\t" lhs "\t" document "\t" clause "\t" page "\t" source_sha256
    }
' "$output" > "$tmp/actual.tsv"

cmp -s "$tmp/expected.tsv" "$tmp/actual.tsv"
records="$(wc -l < "$tmp/expected.tsv")"
productions="$(rg -c '^\(\* rule=' "$output")"
test "$records" -eq 522
test "$productions" -eq "$records"
test "$(rg -c '^\(\* rule=.*source-sha256=' "$output")" -eq "$records"
test "$(grep -o "$source_hash" "$output" | wc -l)" -eq "$records"

grep -Fqx 'xyz-list ::= xyz { "," xyz } ;' "$output"
grep -Fqx 'program ::= program-unit { program-unit } ;' "$output"
grep -Fqx 'program-unit ::= ( main-program | external-subprogram | module | submodule | block-data ) ;' "$output"

bytes="$(stat -c '%s' "$output")"
sha256="$(sha256sum "$output" | cut -d' ' -f1)"
printf 'E0016 oracle: %s records, %s productions, ordered provenance agrees\n' \
    "$records" "$productions"
printf 'output_bytes\t%s\noutput_sha256\t%s\n' "$bytes" "$sha256"
