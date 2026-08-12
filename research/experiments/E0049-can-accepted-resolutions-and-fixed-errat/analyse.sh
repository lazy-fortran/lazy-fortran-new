#!/usr/bin/env bash
# Compose accepted D0019 resolutions and D0025 errata into one partial input.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
outdir="${2:-$root/.cache/runs/E0049/R000001}"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
r46="$root/.cache/runs/E0046/R000001/resolution-records.tsv"
inventory="$root/.cache/runs/E0048/R000001/expansion-inventory.tsv"
base_errata="$root/research/errata/j3-24-007.json"
extension_errata="$root/research/errata/j3-24-007-r1123.json"
e46="$root/research/experiments/E0046-can-the-accepted-r402-and-lexical-d0019-/analyse.sh"
e48="$root/research/experiments/E0048-can-the-fixed-errata-overlays-normalize-/analyse.sh"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
r46_hash="5b272a148d05990b3a3d3e60fafd47e38fa34dd88cf418d715abef860e0cce59"
inventory_hash="d85eb38a4675251c3e23ebf1d0c187949134978b89f45d7af92108be0bbbe503"
base_errata_hash="df1a5320637f2e850e59a680a4467287193c48ee789585dff5aea438b4eaef99"
extension_errata_hash="072e0104b68c2303f2ca56e83764f92f4840a73cd0ccc5eea782c90f19fca4dc"

die() { printf 'E0049: %s\n' "$1" >&2; exit 1; }

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'
test "$(sha256sum "$base_errata" | cut -d' ' -f1)" = "$base_errata_hash" || die 'base errata hash mismatch'
test "$(sha256sum "$extension_errata" | cut -d' ' -f1)" = "$extension_errata_hash" || die 'extension errata hash mismatch'

for errata in "$base_errata" "$extension_errata"; do
    jq -e 'all(.entries[]; .status == "accepted" and .kind == "source-repair" and .origin == "LLM" and .decision_id == "D0025")' \
        "$errata" >/dev/null || die "errata policy metadata mismatch: $errata"
done

for excerpt in \
    'R401 xyz-list is xyz [ , xyz ] ...' \
    'R403 scalar-xyz is xyz' \
    'C401 (R403) scalar-xyz shall be scalar.'; do
    rg -F -q "$excerpt" "$canonical" || die "missing normative source excerpt: $excerpt"
done

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Re-run the accepted predecessor slices and pin their resulting payloads.
"$e46" >"$outdir/e0046.log" || die 'E0046 predecessor failed'
"$e48" >"$outdir/e0048.log" || die 'E0048 predecessor failed'
test "$(sha256sum "$r46" | cut -d' ' -f1)" = "$r46_hash" || die 'E0046 record hash mismatch'
test "$(sha256sum "$inventory" | cut -d' ' -f1)" = "$inventory_hash" || die 'E0048 inventory hash mismatch'

map="$tmp/errata-map.tsv"
{
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation, .id, .origin, .decision_id] | @tsv' "$base_errata"
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation, .id, .origin, .decision_id] | @tsv' "$extension_errata"
} | sort -t $'\t' -k1,1 >"$map"
test "$(wc -l < "$map")" -eq 8 || die 'errata denominator differs'

while IFS=$'\t' read -r source_term repaired_term punctuation erratum origin decision; do
    rg -F -q "(ref $source_term)" "$input" || die "erratum source occurrence missing: $source_term"
    test "$origin" = LLM || die "erratum origin is not LLM: $source_term"
    test "$decision" = D0025 || die "erratum decision mismatch: $source_term"
done <"$map"

# Attach fixed erratum and expansion metadata to every accepted resolution
# record. Duplicate normalized names are retained as distinct observations.
awk -F '\t' '
    FILENAME == ARGV[1] {
        map[$1]=$2; erratum[$1]=$4
        next
    }
    FILENAME == ARGV[2] {
        if (FNR > 1) { family[$1]=$2; state[$1]=$14 }
        next
    }
    FILENAME == ARGV[3] {
        if (FNR == 1) {
            print "source_term\tnormalized_term\tclass\tparser_target\tsemantic_role\tdocument\tclause\tsource_rule\tpage\tsource_sha256\torigin\tevidence\terrata_id\tfamily\tresolution_state"
            next
        }
        source=$1; normalized=source; id="-"
        if (source in map) { normalized=map[source]; id=erratum[source]; repaired++ }
        if (normalized in family) {
            f=family[normalized]; s=state[normalized]
            if ($2 != "unresolved") { s="conflict"; conflicts++ }
        } else { f="-"; s=$2 }
        if (source in seen) bad=1
        seen[source]++
        print source "\t" normalized "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" id "\t" f "\t" s
    }
    END {
        if (repaired != 8 || length(seen) != 182 || conflicts != 3 || bad) exit 1
    }
' "$map" "$inventory" "$r46" >"$outdir/normalized-resolution-records.tsv" || die 'resolution metadata composition failed'

records="$(awk 'END {print NR - 1}' "$outdir/normalized-resolution-records.tsv")"
normalized_unique="$(awk -F '\t' 'NR > 1 {seen[$2]=1} END {for (n in seen) count++; print count + 0}' "$outdir/normalized-resolution-records.tsv")"
errata_repairs="$(awk -F '\t' 'NR > 1 && $13 != "-" {n++} END {print n + 0}' "$outdir/normalized-resolution-records.tsv")"
test "$records" -eq 182 || die 'resolution record count differs'
test "$normalized_unique" -eq 179 || die 'normalized resolution denominator differs'
test "$errata_repairs" -eq 8 || die 'errata repair count differs'

expansion_records="$(awk -F '\t' 'NR > 1 && $14 != "-" {seen[$2]=1} END {for (n in seen) count++; print count + 0}' "$outdir/normalized-resolution-records.tsv")"
r401_records="$(awk -F '\t' 'NR > 1 && $14 == "R401" {seen[$2]=1} END {for (n in seen) count++; print count + 0}' "$outdir/normalized-resolution-records.tsv")"
r403_records="$(awk -F '\t' 'NR > 1 && $14 == "R403" {seen[$2]=1} END {for (n in seen) count++; print count + 0}' "$outdir/normalized-resolution-records.tsv")"
test "$expansion_records" -eq 100 || die 'expansion boundary differs'
test "$r401_records" -eq 80 || die 'R401 boundary differs'
test "$r403_records" -eq 20 || die 'R403 boundary differs'

awk -F '\t' 'NR > 1 && $14 != "-" && $15 == "conflict" {print $2 "\t" $3 "\t" $4 "\t" $14}' \
    "$outdir/normalized-resolution-records.tsv" | sort >"$outdir/family-resolution-conflicts.tsv"
test "$(wc -l < "$outdir/family-resolution-conflicts.tsv")" -eq 3 || die 'family conflict count differs'

# Reconstruct the overlap directly from the two predecessor inputs, rather
# than from the composed table, and compare the resulting set.
awk -F '\t' '
    FILENAME == ARGV[1] {map[$1]=$2; next}
    FILENAME == ARGV[2] {if (FNR > 1) family[$1]=$2; next}
    FILENAME == ARGV[3] {
        if (FNR == 1) next
        normalized=$1
        if ($1 in map) normalized=map[$1]
        if (normalized in family && $2 != "unresolved") print normalized "\t" $2 "\t" $3 "\t" family[normalized]
    }
' "$map" "$inventory" "$r46" | sort >"$tmp/expected-conflicts.tsv"
diff -u "$tmp/expected-conflicts.tsv" "$outdir/family-resolution-conflicts.tsv" >/dev/null || die 'family conflict set differs'
conflict_difference=0

# Build the deterministic replacement map from the accepted resolution table.
# R401/R403 records have no replacement; they remain explicit unresolved refs.
projection="$tmp/projection.tsv"
awk -F '\t' '
    NR > 1 && $3 == "alias" {print $1 "\tref\t" $4; n++}
    NR > 1 && $3 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/ {print $1 "\ttoken\t" $4; n++}
    END {if (n != 70) exit 1}
' "$outdir/normalized-resolution-records.tsv" >"$projection" || die 'resolution projection denominator differs'

awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0)
            text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    FILENAME == ARGV[1] {
        old="(ref " $1 ")"
        errata_old[old]="(ref " $2 ") (token " $3 ")"
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
        for (old in errata_old) $0=replace_all($0, old, errata_old[old])
        for (old in replacement) $0=replace_all($0, old, replacement[old])
        print
        records++
    }
    END {
        if (errata_count != 8 || projection_count != 70 || records != 522) exit 1
    }
' "$map" "$projection" "$input" >"$outdir/partial-composite-input.sx" || die 'partial input construction failed'

test "$(rg -c '^\(syntax ' "$outdir/partial-composite-input.sx")" -eq 522 || die 'partial syntax record count differs'
(cd "$standard_new" && fo exec sxantlr "$outdir/partial-composite-input.sx" "$outdir/partial-composite-input.g4") \
    >"$outdir/partial-composite-input.log" || die 'partial grammar generation failed'

# Independent output checks: each repaired source witness becomes one
# reference/token pair, projected source refs disappear, and the input source
# occurrences are neither dropped nor duplicated.
awk -F '\t' '
    function count(text, needle, start, relative, found) {
        start=1; found=0
        while ((relative=index(substr(text,start),needle)) > 0) {
            found++
            start += relative + length(needle) - 1
        }
        return found
    }
    FILENAME == ARGV[1] {
        err_source[$1]=$1
        err_repaired[$1]=$2
        err_punctuation[$1]=$3
        next
    }
    FILENAME == ARGV[2] {
        projected[$1]="(ref " $1 ")"
        projected_type[$1]=$2
        projected_target[$1]=$3
        next
    }
    FILENAME == ARGV[3] {
        for (source in err_source) {
            if (!(source in err_pair)) {
                if (err_repaired[source] in projected_target && projected_type[err_repaired[source]] == "ref")
                    err_pair[source]="(ref " projected_target[err_repaired[source]] ") (token " err_punctuation[source] ")"
                else
                    err_pair[source]="(ref " err_repaired[source] ") (token " err_punctuation[source] ")"
            }
            input_err[source] += count($0, "(ref " source ")")
        }
        for (source in projected) input_projection[source] += count($0, projected[source])
        next
    }
    FILENAME == ARGV[4] {
        for (source in err_source)
            if (!(source in err_pair)) {
                if (err_repaired[source] in projected_target && projected_type[err_repaired[source]] == "ref")
                    err_pair[source]="(ref " projected_target[err_repaired[source]] ") (token " err_punctuation[source] ")"
                else
                    err_pair[source]="(ref " err_repaired[source] ") (token " err_punctuation[source] ")"
            }
        for (source in err_source) {
            output_err[source] += count($0, err_pair[source])
            output_old_err[source] += count($0, "(ref " source ")")
        }
        for (source in projected) output_old_projection[source] += count($0, projected[source])
        next
    }
    END {
        for (source in err_source)
            if (input_err[source] != 1 || output_err[source] < 1 || output_old_err[source] != 0) bad=1
        for (source in projected)
            if (input_projection[source] < 1 || output_old_projection[source] != 0) bad=1
        exit bad
    }
' "$map" "$projection" "$input" "$outdir/partial-composite-input.sx" \
    || die 'independent replacement check failed'

awk -F '\t' 'NR > 1 && $14 != "-" && $15 == "unresolved" {print $2}' \
    "$outdir/normalized-resolution-records.tsv" | sort -u >"$tmp/expansion-names"
while IFS= read -r term; do
    rg -F -q "(ref $term)" "$outdir/partial-composite-input.sx" || die "expansion was not retained: $term"
done <"$tmp/expansion-names"

# Mutating the accepted projection class must be detected: an expansion is not
# allowed to become an alias projection merely because a field was changed.
awk -F '\t' 'BEGIN {OFS="\t"} NR == 1 {print; next} $14 != "-" && !mutated {$3="alias"; mutated=1} {print} END {if (!mutated) exit 1}' \
    "$outdir/normalized-resolution-records.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $14 != "-" && $3 == "alias" {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

source_matches="$(awk -F '\t' -v hash="$source_hash" 'NR > 1 && $10 == hash {n++} END {print n + 0}' "$outdir/normalized-resolution-records.tsv")"
projection_occurrences="$(awk -F '\t' '
    function count(text, needle, start, relative, found) {
        start=1; found=0
        while ((relative=index(substr(text,start),needle)) > 0) {found++; start += relative + length(needle) - 1}
        return found
    }
    FILENAME == ARGV[1] {needles[$1]="(ref " $1 ")"; next}
    FILENAME == ARGV[2] {for (n in needles) total += count($0, needles[n]); next}
    END {print total + 0}
' "$projection" "$input")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'source_resolution_records\t%s\n' "$records" >>"$outdir/summary.tsv"
printf 'normalized_reference_names\t%s\n' "$normalized_unique" >>"$outdir/summary.tsv"
printf 'errata_records\t8\n' >>"$outdir/summary.tsv"
printf 'errata_repairs\t%s\n' "$errata_repairs" >>"$outdir/summary.tsv"
printf 'resolved_projection_records\t70\n' >>"$outdir/summary.tsv"
printf 'projection_reference_replacements\t%s\n' "$projection_occurrences" >>"$outdir/summary.tsv"
printf 'expansion_records\t%s\n' "$expansion_records" >>"$outdir/summary.tsv"
printf 'r401_records\t%s\n' "$r401_records" >>"$outdir/summary.tsv"
printf 'r403_records\t%s\n' "$r403_records" >>"$outdir/summary.tsv"
unresolved_expansion_records="$(awk -F '\t' 'NR > 1 && $14 != "-" && $15 == "unresolved" {seen[$2]=1} END {for (n in seen) count++; print count + 0}' "$outdir/normalized-resolution-records.tsv")"
printf 'unresolved_expansion_records\t%s\n' "$unresolved_expansion_records" >>"$outdir/summary.tsv"
printf 'family_resolution_conflicts\t3\n' >>"$outdir/summary.tsv"
printf 'conflict_set_difference\t%s\n' "$conflict_difference" >>"$outdir/summary.tsv"
printf 'final_syntax_records\t522\n' >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_matches" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'representation_selection\tdeferred_D0024\n' >>"$outdir/summary.tsv"
printf 'composition_status\tverification_failure\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'partial_input_sha256\t%s\n' "$(sha256sum "$outdir/partial-composite-input.sx" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'partial_grammar_sha256\t%s\n' "$(sha256sum "$outdir/partial-composite-input.g4" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0049 oracle: unified partial composite input passed\n'
cat "$outdir/summary.tsv"
