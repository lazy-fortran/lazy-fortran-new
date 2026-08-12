#!/usr/bin/env bash
# Partition the E0052 unresolved target names by source-provenance decision
# bucket without assigning any unresolved parser meaning.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e52="$root/research/experiments/E0052-can-grouped-erratum-composition-preserve/analyse.sh"
normalized="$root/.cache/runs/E0049/R000001/normalized-resolution-records.tsv"
outdir="${1:-$root/.cache/runs/E0053/R000001}"

normalized_hash="e284b4e9b2b14176a0743103084ae53f0535157896a29e27026fdc2d12331a5e"

die() { printf 'E0053: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e52" >"$outdir/e0052.log" || die 'E0052 predecessor failed'
unresolved="$root/.cache/runs/E0052/R000001/antlr-unresolved.txt"
test "$(wc -l < "$unresolved")" -eq 103 || die 'target unresolved denominator differs'
test "$(sha256sum "$normalized" | cut -d' ' -f1)" = "$normalized_hash" || \
    die 'normalized resolution hash mismatch'

awk -F '\t' '
    FILENAME == ARGV[1] {
        if ($1 == "letter" || $1 == "digit" || $1 == "rep-char" || $1 == "xyz" || $1 == "–" || $1 == "’") {
            rule[$1]=$8
            page[$1]=$9
            source_hash[$1]=$10
            metadata[$1]=1
        }
        next
    }
    FILENAME == ARGV[2] {
        name=$0
        bucket=""
        decision=""
        source="-"
        source_rule="-"
        source_page="-"
        if (name ~ /^r_.*_x2D_list$/) {
            bucket="R401-expansion"
            decision="D0024"
            source_rule="R401"
        } else if (name ~ /^r_scalar/) {
            bucket="R403-expansion"
            decision="D0024/D0026"
            source_rule="R403"
        } else if (name == "r_letter") {
            bucket="lexical-class"
            decision="D0027"
            source="letter"
        } else if (name == "r_digit") {
            bucket="lexical-class"
            decision="D0027"
            source="digit"
        } else if (name == "r_rep_x2D_char") {
            bucket="lexical-class"
            decision="D0027"
            source="rep-char"
        } else if (name == "r_xyz") {
            bucket="metavariable"
            decision="D0024"
            source="xyz"
        } else if (name == "r__xE2__x80__x93_") {
            bucket="unicode-ambiguous"
            decision="D0020"
            source="–"
        } else if (name == "r__xE2__x80__x99_") {
            bucket="unicode-ambiguous"
            decision="D0020"
            source="’"
        } else {
            print "unclassified\t" name > "/dev/stderr"
            bad=1
        }
        if (source != "-" && !(source in metadata)) bad=1
        if (source != "-" && source_hash[source] == "") bad=1
        if (source != "-") {
            source_rule=rule[source]
            source_page=page[source]
        }
        print name "\t" bucket "\t" decision "\t" source "\t" source_rule "\t" source_page
        counts[bucket]++
        seen[name]++
    }
    END {
        for (name in seen) if (seen[name] != 1) bad=1
        if (counts["R401-expansion"] != 80 || counts["R403-expansion"] != 17 || \
            counts["lexical-class"] != 3 || counts["metavariable"] != 1 || \
            counts["unicode-ambiguous"] != 2 || bad) exit 1
    }
' "$normalized" "$unresolved" >"$outdir/residual-buckets.tsv" || \
    die 'residue partition failed'

{
    printf 'generated_name\tbucket\tdecision\tsource_term\tsource_rule\tsource_page\n'
    sort "$outdir/residual-buckets.tsv"
} >"$tmp/residual-with-header.tsv"
mv "$tmp/residual-with-header.tsv" "$outdir/residual-buckets.tsv"

awk -F '\t' '
    NR == 1 {next}
    {seen[$1]++; count++; bucket[$2]++}
    END {
        for (name in seen) if (seen[name] != 1) bad=1
        if (count != 103 || bucket["R401-expansion"] != 80 || bucket["R403-expansion"] != 17 || \
            bucket["lexical-class"] != 3 || bucket["metavariable"] != 1 || \
            bucket["unicode-ambiguous"] != 2) bad=1
        exit bad
    }
' "$outdir/residual-buckets.tsv" || die 'independent partition count failed'

awk -F '\t' 'NR == 1 {print; next} NR == 2 {$2="lexical-class"} {OFS="\t"; print}' \
    "$outdir/residual-buckets.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' '
    NR == 1 {next}
    {counts[$2]++}
    END {exit (counts["R401-expansion"] == 80 && counts["R403-expansion"] == 17 && counts["lexical-class"] == 3 && counts["metavariable"] == 1 && counts["unicode-ambiguous"] == 2 ? 0 : 1)}
' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'unresolved_target_names\t103\n' >>"$outdir/summary.tsv"
printf 'r401_unresolved\t80\n' >>"$outdir/summary.tsv"
printf 'r403_unresolved\t17\n' >>"$outdir/summary.tsv"
printf 'expansion_unresolved\t97\n' >>"$outdir/summary.tsv"
printf 'lexical_unresolved\t3\n' >>"$outdir/summary.tsv"
printf 'metavariable_unresolved\t1\n' >>"$outdir/summary.tsv"
printf 'unicode_unresolved\t2\n' >>"$outdir/summary.tsv"
printf 'source_metadata_records\t6\n' >>"$outdir/summary.tsv"
printf 'open_decision_groups\t2\n' >>"$outdir/summary.tsv"
printf 'antlr_status\t1\n' >>"$outdir/summary.tsv"
printf 'bison_status\t1\n' >>"$outdir/summary.tsv"
printf 'treesitter_status\t1\n' >>"$outdir/summary.tsv"
printf 'treesitter_structural_error\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'residual_buckets_sha256\t%s\n' "$(sha256sum "$outdir/residual-buckets.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'normalized_resolution_sha256\t%s\n' "$normalized_hash" >>"$outdir/summary.tsv"

printf 'E0053 oracle: unresolved residue partition passed\n'
cat "$outdir/summary.tsv"
