#!/usr/bin/env bash
# Preserve repaired reference-plus-punctuation groups through partial-input
# composition, then validate the result in three target grammar tools.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e49="$root/research/experiments/E0049-can-accepted-resolutions-and-fixed-errat/analyse.sh"
input="$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx"
normalized="$root/.cache/runs/E0049/R000001/normalized-resolution-records.tsv"
base_errata="$root/research/errata/j3-24-007.json"
extension_errata="$root/research/errata/j3-24-007-r1123.json"
outdir="${1:-$root/.cache/runs/E0052/R000001}"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"

input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
normalized_hash="e284b4e9b2b14176a0743103084ae53f0535157896a29e27026fdc2d12331a5e"

die() { printf 'E0052: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e49" >"$outdir/e0049.log" || die 'E0049 predecessor failed'
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
test "$(sha256sum "$normalized" | cut -d' ' -f1)" = "$normalized_hash" || die 'normalized resolution hash mismatch'

map="$tmp/errata-map.tsv"
{
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation, .id, .origin, .decision_id] | @tsv' "$base_errata"
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation, .id, .origin, .decision_id] | @tsv' "$extension_errata"
} | sort -t $'\t' -k1,1 >"$map"
test "$(wc -l < "$map")" -eq 8 || die 'errata denominator differs'

projection="$tmp/projection.tsv"
awk -F '\t' '
    NR > 1 && $3 == "alias" {print $1 "\tref\t" $4; n++}
    NR > 1 && $3 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/ {print $1 "\ttoken\t" $4; n++}
    END {if (n != 70) exit 1}
' "$normalized" >"$projection" || die 'resolution projection denominator differs'

# Apply the special optional-group replacement before the generic replacement.
# The second pass cannot match the inner source reference after this pass.
awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0)
            text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    FILENAME == ARGV[1] {
        old="(ref " $1 ")"
        errata_old[old]="(ref " $2 ") (token " $3 ")"
        optional_old["(optional " old ")"]="(optional (seq (ref " $2 ") (token " $3 ")))"
        errata_count++
        next
    }
    FILENAME == ARGV[2] {
        old="(ref " $1 ")"
        replacement[old]="(" $2 " " $3 ")"
        projection_count++
        next
    }
    FILENAME == ARGV[3] && /^\(syntax / {
        for (old in optional_old) {
            before=$0
            $0=replace_all($0, old, optional_old[old])
            if ($0 != before) grouped++
        }
        for (old in errata_old) $0=replace_all($0, old, errata_old[old])
        for (old in replacement) $0=replace_all($0, old, replacement[old])
        print
        records++
    }
    END {
        if (errata_count != 8 || projection_count != 70 || records != 522 || grouped != 2) exit 1
    }
' "$map" "$projection" "$input" >"$outdir/grouped-partial-input.sx" || \
    die 'grouped partial input construction failed'

test "$(rg -c '^\(syntax ' "$outdir/grouped-partial-input.sx")" -eq 522 || die 'syntax record count differs'
(cd "$standard_new" && fo exec sxantlr "$outdir/grouped-partial-input.sx" "$outdir/Fortran2023.g4") \
    >"$outdir/sxantlr.log" 2>&1
(cd "$standard_new" && fo exec sxbison "$outdir/grouped-partial-input.sx" "$outdir/Fortran2023.y") \
    >"$outdir/sxbison.log" 2>&1
(cd "$standard_new" && fo exec sxtreesitter "$outdir/grouped-partial-input.sx" "$outdir/grammar.js") \
    >"$outdir/sxtreesitter.log" 2>&1

set +e
antlr4 -Werror -Dlanguage=Java -o "$outdir/antlr" "$outdir/Fortran2023.g4" \
    >"$outdir/antlr.log" 2>&1
antlr_status=$?
bison -Wall -Werror -o "$outdir/bison.c" "$outdir/Fortran2023.y" \
    >"$outdir/bison.log" 2>&1
bison_status=$?
mkdir -p "$outdir/treesitter"
cp "$outdir/grammar.js" "$outdir/treesitter/grammar.js"
(cd "$outdir/treesitter" && tree-sitter generate) >"$outdir/treesitter.log" 2>&1
treesitter_status=$?
set -e

antlr_definitions="$(awk '/^r_[A-Za-z0-9_]+$/ {n++} END {print n + 0}' "$outdir/Fortran2023.g4")"
bison_definitions="$(awk '/^r_[A-Za-z0-9_]+:/ {n++} END {print n + 0}' "$outdir/Fortran2023.y")"
treesitter_definitions="$(awk '/^r_[A-Za-z0-9_]+: \$ => / {n++} END {print n + 0}' "$outdir/grammar.js")"
test "$antlr_definitions" -eq 502 || die 'ANTLR definition count differs'
test "$bison_definitions" -eq 502 || die 'Bison definition count differs'
test "$treesitter_definitions" -eq 502 || die 'tree-sitter definition count differs'

sed -n 's/.*reference to undefined rule: \([^[:space:]]*\).*/\1/p' "$outdir/antlr.log" | sort -u >"$outdir/antlr-unresolved.txt"
sed -n "s/.*symbol '\([^']*\)' is used.*/\1/p" "$outdir/bison.log" | sort -u >"$outdir/bison-unresolved.txt"
antlr_unresolved="$(wc -l < "$outdir/antlr-unresolved.txt")"
bison_unresolved="$(wc -l < "$outdir/bison-unresolved.txt")"
diff -u "$outdir/antlr-unresolved.txt" "$outdir/bison-unresolved.txt" >"$outdir/antlr-bison-unresolved.diff" || \
    die 'ANTLR/Bison unresolved sets differ'

if rg -F -q 'SyntaxError: Unexpected token' "$outdir/treesitter.log"; then
    treesitter_structural_error=1
else
    treesitter_structural_error=0
fi

# The grouped witnesses are derived from source occurrences, not from a broad
# output regex that would count unrelated pre-existing optional sequences.
awk -F '\t' '
    FILENAME == ARGV[1] {repaired[$1]=$2; punctuation[$1]=$3; next}
    FILENAME == ARGV[2] {target[$1]=$3; next}
    FILENAME == ARGV[3] {
        for (name in repaired)
            if (index($0, "(optional (ref " name "))") > 0) {
                final=repaired[name]
                if (final in target) final=target[final]
                print name "\t" final "\t" punctuation[name]
            }
    }
' "$map" "$projection" "$input" | sort >"$outdir/optional-errata-witnesses.tsv"
grouped_witnesses="$(wc -l < "$outdir/optional-errata-witnesses.tsv")"
test "$grouped_witnesses" -eq 2 || die 'optional errata witness denominator differs'
while IFS=$'\t' read -r source repaired punctuation; do
    grouped="(optional (seq (ref ${repaired}) (token ${punctuation})))"
    rg -F -q "$grouped" "$outdir/grouped-partial-input.sx" || die "grouped witness missing: $source"
    rg -F -q "(optional (ref $source))" "$outdir/grouped-partial-input.sx" &&
        die "ungrouped witness remains: $source"
done <"$outdir/optional-errata-witnesses.tsv"
awk 'BEGIN {removed=0} /\(optional \(seq \(ref [^)]*\) \(token [, :]\)\)\)/ && !removed {removed=1; next} {print}' \
    "$outdir/grouped-partial-input.sx" >"$tmp/mutated.sx"
mutated_witnesses="$(rg -c '\(optional \(seq \(ref [^)]*\) \(token [, :]\)\)\)' "$tmp/mutated.sx" || true)"
if test "$mutated_witnesses" -eq "$grouped_witnesses"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

if test "$antlr_status" -eq 1 && test "$bison_status" -eq 1 && \
    test "$treesitter_status" -eq 1 && test "$treesitter_structural_error" -eq 0; then
    target_boundary="verification_failure_unresolved_names"
else
    target_boundary="verification_failure_structural_or_unresolved"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'final_syntax_records\t522\n' >>"$outdir/summary.tsv"
printf 'errata_repairs\t8\n' >>"$outdir/summary.tsv"
printf 'grouped_optional_repairs\t%s\n' "$grouped_witnesses" >>"$outdir/summary.tsv"
printf 'antlr_definitions\t%s\n' "$antlr_definitions" >>"$outdir/summary.tsv"
printf 'bison_definitions\t%s\n' "$bison_definitions" >>"$outdir/summary.tsv"
printf 'treesitter_definitions\t%s\n' "$treesitter_definitions" >>"$outdir/summary.tsv"
printf 'antlr_status\t%s\n' "$antlr_status" >>"$outdir/summary.tsv"
printf 'bison_status\t%s\n' "$bison_status" >>"$outdir/summary.tsv"
printf 'treesitter_status\t%s\n' "$treesitter_status" >>"$outdir/summary.tsv"
printf 'treesitter_structural_error\t%s\n' "$treesitter_structural_error" >>"$outdir/summary.tsv"
printf 'antlr_unresolved_rule_names\t%s\n' "$antlr_unresolved" >>"$outdir/summary.tsv"
printf 'bison_unresolved_symbol_names\t%s\n' "$bison_unresolved" >>"$outdir/summary.tsv"
printf 'antlr_bison_unresolved_set_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'target_boundary\t%s\n' "$target_boundary" >>"$outdir/summary.tsv"
printf 'grouped_input_sha256\t%s\n' "$(sha256sum "$outdir/grouped-partial-input.sx" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'antlr_grammar_sha256\t%s\n' "$(sha256sum "$outdir/Fortran2023.g4" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'bison_grammar_sha256\t%s\n' "$(sha256sum "$outdir/Fortran2023.y" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'treesitter_grammar_sha256\t%s\n' "$(sha256sum "$outdir/grammar.js" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0052 oracle: grouped erratum composition validated\n'
cat "$outdir/summary.tsv"
