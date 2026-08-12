#!/usr/bin/env bash
# Generate and independently check the tree-sitter grammar.js projection.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
output="${2:-$root/.cache/runs/E0019/R000001/fortran2023.js}"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

test -f "$standard/fpm.toml"
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash"
mkdir -p "$(dirname "$output")"

(cd "$standard" && fo exec sxtreesitter "$input" "$output")

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

awk '
    function safe_name(value) {
        gsub(/-/, "_x2D_", value)
        return "r_" value
    }
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
        print rule "\t" safe_name(lhs) "\t" document "\t" clause "\t" page "\t" source_sha256
    }
' "$input" > "$tmp/expected.tsv"

awk '
    /^\/\/ rule=/ {
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
        getline declaration
        lhs = declaration
        sub(/: \$ => .*/, "", lhs)
        print rule "\t" lhs "\t" document "\t" clause "\t" page "\t" source_sha256
    }
' "$output" > "$tmp/actual.tsv"

cmp -s "$tmp/expected.tsv" "$tmp/actual.tsv"
records="$(wc -l < "$tmp/expected.tsv")"
comments="$(rg -c '^// rule=' "$output")"
rules="$(rg -c '^r_.*: \$ => ' "$output")"
test "$records" -eq 522
test "$comments" -eq "$records"
test "$rules" -eq "$records"
test "$(rg -o "$source_hash" "$output" | wc -l)" -eq "$records"
head -n 1 "$output" | grep -Fqx '// Generated from StandardIR syntax'
rg -Fqx "module.exports = grammar({" "$output"
rg -Fqx "  name: 'fortran2023'," "$output"
tail -n 2 "$output" | head -n 1 | grep -Fqx '  }'
tail -n 1 "$output" | grep -Fqx '});'
grep -Fqx "r_xyz_x2D_list: \$ => seq($.r_xyz, repeat(seq(',', $.r_xyz)))," "$output"
grep -Fqx 'r_program: $ => seq($.r_program_x2D_unit, repeat($.r_program_x2D_unit)),' "$output"

bytes="$(stat -c '%s' "$output")"
sha256="$(sha256sum "$output" | cut -d' ' -f1)"
printf 'E0019 oracle: %s records, %s tree-sitter rules, ordered provenance agrees\n' \
    "$records" "$rules"
printf 'output_bytes\t%s\noutput_sha256\t%s\n' "$bytes" "$sha256"
