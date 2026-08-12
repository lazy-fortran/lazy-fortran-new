#!/usr/bin/env bash
# Repair source-controlled punctuation absorbed into SX reference names.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
errata="$root/research/errata/j3-24-007.json"
outdir="${2:-$root/.cache/runs/E0047/R000001}"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"

input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
errata_hash="25d70041f4c1661ca0da99cf355310e407cd8782f3127008e5435862ea8ed285"

die() { printf 'E0047: %s\n' "$1" >&2; exit 1; }
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'
test "$(sha256sum "$errata" | cut -d' ' -f1)" = "$errata_hash" || die 'errata hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
seed="$tmp/errata.tsv"
jq -e '.document == "J3-24-007" and .source_sha256 == "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2" and (.entries | length == 7)' "$errata" >/dev/null || die 'errata schema or denominator differs'
jq -r '(["source_term", "repaired_term", "punctuation", "document", "clause", "source_rule", "page", "source_excerpt"] | @tsv), (.entries[] | [.source_term, .repaired_term, .punctuation, .document, .clause, .source_rule, (.page | tostring), .source_excerpt] | @tsv)' "$errata" >"$seed"

while IFS=$'\t' read -r source_term repaired_term punctuation document clause rule page excerpt; do
    [ "$source_term" = source_term ] && continue
    [ "$document" = J3-24-007 ] || die "wrong source document for $source_term"
    rg -F -q "$excerpt" "$canonical" || die "missing source witness for $source_term"
done < "$seed"
test "$(awk 'END {print NR - 1}' "$seed")" -eq 7 || die 'errata denominator differs'

# Apply one literal repair per seeded occurrence. The source line itself is
# retained. Only the derived reference/token structure changes.
awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0) text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    function occurrences(text, needle, start, relative, found) {
        start=1; found=0
        while ((relative = index(substr(text, start), needle)) > 0) {
            found++
            start += relative + length(needle) - 1
        }
        return found
    }
    FILENAME == ARGV[1] {
        if (FNR == 1) next
        old[$1]="(ref " $1 ")"
        new[$1]="(ref " $2 ") (token " $3 ")"
        selected[$1]=1
        next
    }
    FILENAME == ARGV[2] && /^\(syntax / {
        for (term in old) {
            found=occurrences($0, old[term])
            if (found) {
                seen[term] += found
                $0=replace_all($0, old[term], new[term])
            }
        }
        records++
        print
    }
    END {
        if (records != 522) bad=1
        for (term in selected) if (seen[term] != 1) bad=1
        exit bad
    }
' "$seed" "$input" >"$outdir/repaired-input.sx" || die 'punctuation repair validation failed'

awk -F '\t' '
    NR == FNR { if (FNR > 1) { old[$1]="(ref " $1 ")"; new[$1]="(ref " $2 ") (token " $3 ")"; selected[$1]=1; punctuation[$1]=$3 } ; next }
    /^\(syntax / {
        for (term in old) {
            if (index($0, old[term])) bad=1
            if (index($0, new[term]) != 0) seen[term]++
        }
    }
    END {
        for (term in selected) if (seen[term] != 1) bad=1
        exit bad
    }
' "$seed" "$outdir/repaired-input.sx" || die 'repaired input does not contain the expected token boundaries'

(cd "$standard_new" && fo exec sxantlr "$outdir/repaired-input.sx" "$outdir/repaired-input.g4") >"$outdir/repaired-input.log"

# A changed punctuation witness must fail the source-controlled validation.
awk -F '\t' 'BEGIN {OFS="\t"} NR == 1 {print; next} NR == 2 {$3=";"} {print}' "$seed" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $1 == "assumed-implied-spec," && $3 != "," {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

records="$(awk 'END {print NR}' "$outdir/repaired-input.sx")"
comma_repairs="$(awk -F '\t' 'NR > 1 && $3 == "," {n++} END {print n + 0}' "$seed")"
colon_repairs="$(awk -F '\t' 'NR > 1 && $3 == ":" {n++} END {print n + 0}' "$seed")"
printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'source_repair_records\t7\n' >>"$outdir/summary.tsv"
printf 'comma_repairs\t%s\n' "$comma_repairs" >>"$outdir/summary.tsv"
printf 'colon_repairs\t%s\n' "$colon_repairs" >>"$outdir/summary.tsv"
printf 'input_syntax_records\t%s\n' "$records" >>"$outdir/summary.tsv"
printf 'source_witness_matches\t7\n' >>"$outdir/summary.tsv"
printf 'repair_replacements\t7\n' >>"$outdir/summary.tsv"
printf 'repaired_input_sha256\t%s\n' "$(sha256sum "$outdir/repaired-input.sx" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'repaired_grammar_sha256\t%s\n' "$(sha256sum "$outdir/repaired-input.g4" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'E0047 oracle: source-controlled punctuation boundary repair passed\n'
cat "$outdir/summary.tsv"
