#!/usr/bin/env bash
# Compare StandardIR rule/lhs inventories with permitted external sources.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
outdir="${2:-$root/.cache/runs/E0020/R000001}"
standard="${STANDARD_ORACLE:-$root/../lazy-fortran/standard}"
kaby="${KABY76_ORACLE:-$root/../kaby76-fortran}"
lfortran="${LFORTRAN_ORACLE:-$root/../lazy-fortran/lfortran}"
flang="${FLANG_ORACLE:-$root/../llvm-project}"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash"
mkdir -p "$outdir"

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
verify_blob "$lfortran" caf87b660f803148f000046392a5da803f9fc630 \
    src/lfortran/parser/parser.yy \
    112ef0ce5078ccec630a893bc51b92232348c37742b1451c833928a422907936
verify_blob "$flang" cff4ca2e51f89c992d8a1b6ce1067846ba680e2e \
    flang/lib/Parser/Fortran-parsers.cpp \
    abb4126d6c0c4e516628ba9836c428f83f0ccf883439e67cbfdd061aa42d83b9

tmp="$(mktemp -d)"
generated="$tmp/generated"
standard_rules="$tmp/standard"
kaby_rules="$tmp/kaby"
lfortran_rules="$tmp/lfortran"
flang_ids="$tmp/flang"

# Primary extraction. Names are normalized only for comparison: hyphens and
# underscores are the surface spelling difference, and version suffixes are
# removed from the house grammar's comparison source.
awk '/^\(syntax / {x=$4; gsub(/[()]/,"",x); print x}' "$input" | sort -u > "$generated"
awk '
    /^[a-z][A-Za-z0-9_]*[[:space:]]*$/ {
        x=$1; sub(/_f2023$/, "", x); gsub(/_/, "-", x); print x
    }
' "$standard/grammars/src/Fortran2023Parser.g4" | sort -u > "$standard_rules"
awk '
    /^[a-z][A-Za-z0-9_]*[[:space:]]*$/ {
        x=$1; sub(/_f2023$/, "", x); gsub(/_/, "-", x); print x
    }
' "$kaby/comp/Fortran2023Parser.g4" | sort -u > "$kaby_rules"
awk '
    /^[a-z][A-Za-z0-9_]*[[:space:]]*$/ {
        x=$1; gsub(/_/, "-", x); print x
    }
' "$lfortran/src/lfortran/parser/parser.yy" | sort -u > "$lfortran_rules"
rg --no-heading '^// R[0-9]+' "$flang/flang/lib/Parser" \
    --glob '*.cpp' --glob '*.h' |
    sed -E 's#.*// (R[0-9]+).*#\1#' | sort -u > "$flang_ids"

compare_names() {
    local name="$1" source="$2" generated="$3" metrics="$4"
    local overlap only_generated only_source
    overlap="$(comm -12 "$generated" "$source" | wc -l)"
    only_generated="$(comm -23 "$generated" "$source" | wc -l)"
    only_source="$(comm -13 "$generated" "$source" | wc -l)"
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" \
        "$(wc -l < "$source")" "$overlap" "$only_generated" "$only_source" >> "$metrics"
    comm -23 "$generated" "$source" > "$outdir/$name.only-generated"
    comm -13 "$generated" "$source" > "$outdir/$name.only-source"
}

printf 'source\tsource_rules\toverlap\tstandardir_only\tsource_only\n' > "$outdir/comparison.tsv"
compare_names standard "$standard_rules" "$generated" "$outdir/comparison.tsv"
compare_names kaby76 "$kaby_rules" "$generated" "$outdir/comparison.tsv"
compare_names lfortran "$lfortran_rules" "$generated" "$outdir/comparison.tsv"

generated_ids="$tmp/generated-ids"
awk '/^\(syntax / {print $2}' "$input" | sort -u > "$generated_ids"
compare_names flang "$flang_ids" "$generated_ids" "$outdir/comparison.tsv"

# Independent traversal. It uses separate extraction expressions and checks
# the same totals plus witnesses, without reading the primary set files.
awk '
    function normalized(x) { sub(/_f2023$/, "", x); gsub(/_/, "-", x); return x }
    /^[a-z][A-Za-z0-9_]*[[:space:]]*$/ { x=$1; print normalized(x) }
' "$standard/grammars/src/Fortran2023Parser.g4" | sort -u > "$tmp/ind-standard"
awk '/^\(syntax / {x=$2; print x}' "$input" | sort -u > "$tmp/ind-ids"

test "$(wc -l < "$generated")" -eq 502
test "$(wc -l < "$generated_ids")" -eq 502
test "$(comm -12 "$generated" "$tmp/ind-standard" | wc -l)" -eq "$(awk '$1=="standard" {print $3}' "$outdir/comparison.tsv")"
test "$(comm -12 "$generated_ids" "$flang_ids" | wc -l)" -eq "$(awk '$1=="flang" {print $3}' "$outdir/comparison.tsv")"
grep -qx 'program-unit' "$kaby_rules"
grep -qx 'program-unit' "$standard_rules"
grep -qx 'R501' "$flang_ids"
grep -qx 'R501' "$generated_ids"

cp "$outdir/comparison.tsv" "$outdir/summary.tsv"
printf 'E0020 oracle: structural inventories and independent counts agree\n'
cat "$outdir/comparison.tsv"
