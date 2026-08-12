#!/usr/bin/env bash
# Compare D0027 lexical projection candidates without selecting one.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e53="$root/research/experiments/E0053-can-the-remaining-target-failures-be-par/analyse.sh"
outdir="${1:-$root/.cache/runs/E0054/R000001}"

bucket_hash="fb6ddd7f206e420fe8027c133fac89b5d0f162ddb5c105ea218beb435a335a40"

die() { printf 'E0054: %s\n' "$1" >&2; exit 1; }

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e53" >"$outdir/e0053.log" || die 'E0053 predecessor failed'
buckets="$root/.cache/runs/E0053/R000001/residual-buckets.tsv"
test "$(sha256sum "$buckets" | cut -d' ' -f1)" = "$bucket_hash" || die 'residue bucket hash mismatch'

awk -F '\t' 'NR > 1 && ($2 == "lexical-class" || $2 == "unicode-ambiguous") {print $4}' \
    "$buckets" | sort -u >"$outdir/lexical-residue.tsv"
printf '%s\n' 'digit' 'letter' 'rep-char' '–' '’' | sort >"$tmp/expected-residue.tsv"
diff -u "$tmp/expected-residue.tsv" "$outdir/lexical-residue.tsv" >/dev/null || \
    die 'source-driven lexical residue differs'

awk -F '\t' '
    BEGIN {
        print "candidate\tsource_term\tclass\tparser_projection\tunicode_policy\tretains_source_fact\tlossless\tdecision_state"
        candidates[1]="primitive-lexer-export"
        candidates[2]="schema-lexical-facts"
        candidates[3]="retain-unresolved"
    }
    {
        source=$1
        is_unicode=(source == "–" || source == "’")
        is_lexical=!is_unicode
        for (i = 1; i <= 3; i++) {
            c=candidates[i]
            if (c == "primitive-lexer-export") {
                if (is_lexical) projection="generated-lexer-class"
                else projection="unresolved"
                policy="retain-ambiguous-unicode"
            } else if (c == "schema-lexical-facts") {
                if (is_lexical) projection="schema-lexical-fact"
                else projection="unresolved"
                policy="retain-ambiguous-unicode"
            } else {
                projection="unresolved"
                policy="retain-all-unresolved"
            }
            print c "\t" source "\t" (is_unicode ? "unicode-ambiguous" : "lexical-class") "\t" projection "\t" policy "\ttrue\ttrue\tdeferred-D0027"
            rows[c]++
            if (c == "primitive-lexer-export" && is_lexical) primitive++
            if (c == "schema-lexical-facts" && is_lexical) schema++
            if (c == "retain-unresolved") unresolved_candidate++
        }
    }
    END {
        if (rows["primitive-lexer-export"] != 5 || rows["schema-lexical-facts"] != 5 || rows["retain-unresolved"] != 5 ||
            primitive != 3 || schema != 3 || unresolved_candidate != 5) exit 1
    }
' "$outdir/lexical-residue.tsv" >"$outdir/lexical-candidates.tsv" || die 'candidate matrix construction failed'

awk -F '\t' '
    NR == 1 {next}
    {rows[$1]++; if ($4 == "generated-lexer-class") primitive++; if ($4 == "schema-lexical-fact") schema++; if ($1 == "retain-unresolved") unresolved_candidate++}
    END {
        if (rows["primitive-lexer-export"] != 5 || rows["schema-lexical-facts"] != 5 || rows["retain-unresolved"] != 5 ||
            primitive != 3 || schema != 3 || unresolved_candidate != 5) exit 1
    }
' "$outdir/lexical-candidates.tsv" || die 'candidate tradeoff oracle failed'

awk -F '\t' 'BEGIN {OFS="\t"} NR == 1 {print; next} NR == 2 {$1="unapproved"} {print}' \
    "$outdir/lexical-candidates.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' '
    NR == 1 {next}
    {rows[$1]++}
    END {exit (rows["primitive-lexer-export"] == 5 && rows["schema-lexical-facts"] == 5 && rows["retain-unresolved"] == 5 ? 0 : 1)}
' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'candidate_strategies\t3\n' >>"$outdir/summary.tsv"
printf 'residue_terms\t5\n' >>"$outdir/summary.tsv"
printf 'candidate_rows\t15\n' >>"$outdir/summary.tsv"
printf 'lexical_rows\t3\n' >>"$outdir/summary.tsv"
printf 'unicode_rows\t2\n' >>"$outdir/summary.tsv"
printf 'primitive_export_rows\t3\n' >>"$outdir/summary.tsv"
printf 'schema_export_rows\t3\n' >>"$outdir/summary.tsv"
printf 'unresolved_rows\t5\n' >>"$outdir/summary.tsv"
printf 'complete_projection_candidates\t0\n' >>"$outdir/summary.tsv"
printf 'representation_selection\tdeferred_D0027\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'lexical_residue_sha256\t%s\n' "$(sha256sum "$outdir/lexical-residue.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'candidate_matrix_sha256\t%s\n' "$(sha256sum "$outdir/lexical-candidates.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0054 oracle: D0027 candidate comparison passed without selection\n'
cat "$outdir/summary.tsv"
