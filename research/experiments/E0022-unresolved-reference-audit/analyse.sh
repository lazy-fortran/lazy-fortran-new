#!/usr/bin/env bash
# Inventory unresolved StandardIR references without inventing productions.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
outdir="${2:-$root/.cache/runs/E0022/R000001}"
standard="${STANDARD_ORACLE:-$root/../lazy-fortran/standard}"
kaby="${KABY76_ORACLE:-$root/../kaby76-fortran}"

input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash"
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash"

verify_blob() {
    local repo="$1" commit="$2" path="$3" expected="$4"
    git -C "$repo" cat-file -e "$commit:$path"
    test "$(git -C "$repo" cat-file blob "$commit:$path" | sha256sum | cut -d' ' -f1)" = "$expected"
}

verify_blob "$standard" 160032ae38d8bd239fbb943142fdee95bda49ae2 \
    grammars/src/Fortran2023Parser.g4 \
    d8bb1b600e30be245a2d8c87e32660a3b4ad83aa94728cf50cebf37c1e8b67ce
verify_blob "$kaby" ba846bbdea9df98428d094137d2adbe156f86207 \
    comp/Fortran2023Parser.g4 \
    8f1f55ee4f61f82d732d41bd9452917bc1ce293f64e19615649a5170fb2705a8

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

awk '
    function add(name, rule) {
        occurrences[name]++
        if (!seen[name SUBSEP rule]++) {
            referring[name] = referring[name] (referring[name] ? "," : "") rule
            referring_count[name]++
        }
    }
    /^\(syntax / {
        rule=$2
        gsub(/[()]/, "", rule)
        rest=$0
        while (match(rest, /\(ref [^)]*\)/)) {
            ref=substr(rest, RSTART, RLENGTH)
            sub(/^\(ref /, "", ref)
            sub(/\)$/, "", ref)
            add(ref, rule)
            rest=substr(rest, RSTART + RLENGTH)
        }
    }
    END {
        for (name in occurrences)
            print name "\t" occurrences[name] "\t" referring_count[name] "\t" referring[name]
    }
' "$input" | sort -t $'\t' -k1,1 >"$tmp/references.tsv"

awk '/^\(syntax / {x=$4; gsub(/[()]/,"",x); print x}' "$input" | sort -u >"$tmp/definitions"
awk -F '\t' '{print $1}' "$tmp/references.tsv" | sort -u >"$tmp/references"
comm -23 "$tmp/references" "$tmp/definitions" >"$tmp/unresolved"

grep -oE '\(ref [^)]*\)' "$input" | sed -E 's/^\(ref (.*)\)$/\1/' | sort -u >"$tmp/independent-references"
comm -23 "$tmp/independent-references" "$tmp/definitions" >"$tmp/independent-unresolved"
cmp -s "$tmp/references" "$tmp/independent-references"
cmp -s "$tmp/unresolved" "$tmp/independent-unresolved"

awk '
    /^[a-z][A-Za-z0-9_]*[[:space:]]*$/ {
        x=$1; sub(/_f2023$/, "", x); gsub(/_/, "-", x); print x
    }
' "$standard/grammars/src/Fortran2023Parser.g4" | sort -u >"$tmp/standard"
awk '
    /^[a-z][A-Za-z0-9_]*[[:space:]]*$/ {
        x=$1; sub(/_f2023$/, "", x); gsub(/_/, "-", x); print x
    }
' "$kaby/comp/Fortran2023Parser.g4" | sort -u >"$tmp/kaby76"

printf 'name\tref_occurrences\treferring_rules\tcanonical_lines\tstandard_present\tkaby76_present\n' \
    >"$outdir/reference-audit.tsv"
while IFS=$'\t' read -r name occurrences referring_count referring_rules; do
    canonical_lines="$(grep -F -c -- "$name" "$canonical" || true)"
    if grep -Fqx "$name" "$tmp/standard"; then standard_present=true; else standard_present=false; fi
    if grep -Fqx "$name" "$tmp/kaby76"; then kaby76_present=true; else kaby76_present=false; fi
    if grep -Fqx "$name" "$tmp/unresolved"; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$occurrences" "$referring_count" \
            "$canonical_lines" "$standard_present" "$kaby76_present" >>"$outdir/reference-audit.tsv"
    fi
done <"$tmp/references.tsv"

unresolved_unique="$(wc -l < "$tmp/unresolved")"
unresolved_reference_occurrences="$(awk -F '\t' 'NR > 1 {sum += $2} END {print sum + 0}' \
    "$outdir/reference-audit.tsv")"
unresolved_referring_rules="$(awk -F '\t' 'NR > 1 {sum += $3} END {print sum + 0}' \
    "$outdir/reference-audit.tsv")"
with_canonical="$(awk -F '\t' 'NR > 1 && $4 > 0 {count++} END {print count + 0}' \
    "$outdir/reference-audit.tsv")"
in_standard="$(awk -F '\t' 'NR > 1 && $5 == "true" {count++} END {print count + 0}' \
    "$outdir/reference-audit.tsv")"
in_kaby76="$(awk -F '\t' 'NR > 1 && $6 == "true" {count++} END {print count + 0}' \
    "$outdir/reference-audit.tsv")"

test "$unresolved_unique" -eq 181
grep -Fq $'xyz\t' "$outdir/reference-audit.tsv"
grep -Fq $'letter\t' "$outdir/reference-audit.tsv"
grep -Fq $'digit\t' "$outdir/reference-audit.tsv"
grep -Fq $'program-name\t' "$outdir/reference-audit.tsv"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'unresolved_unique_names\t%s\n' "$unresolved_unique" >>"$outdir/summary.tsv"
printf 'unresolved_reference_occurrences\t%s\n' "$unresolved_reference_occurrences" >>"$outdir/summary.tsv"
printf 'unresolved_referring_rules\t%s\n' "$unresolved_referring_rules" >>"$outdir/summary.tsv"
printf 'unresolved_with_canonical_evidence\t%s\n' "$with_canonical" >>"$outdir/summary.tsv"
printf 'unresolved_in_standard_grammar\t%s\n' "$in_standard" >>"$outdir/summary.tsv"
printf 'unresolved_in_kaby76_grammar\t%s\n' "$in_kaby76" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"

printf 'E0022 oracle: unresolved reference inventory agrees across independent traversals\n'
cat "$outdir/summary.tsv"
