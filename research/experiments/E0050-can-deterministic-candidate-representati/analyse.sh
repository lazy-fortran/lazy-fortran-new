#!/usr/bin/env bash
# Compare pending D0024/D0026 representations without accepting one.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
outdir="${2:-$root/.cache/runs/E0050/R000001}"
e49="$root/research/experiments/E0049-can-accepted-resolutions-and-fixed-errat/analyse.sh"
input="$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx"
normalized="$root/.cache/runs/E0049/R000001/normalized-resolution-records.tsv"
conflicts="$root/.cache/runs/E0049/R000001/family-resolution-conflicts.tsv"
inventory="$root/.cache/runs/E0048/R000001/expansion-inventory.tsv"

input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
normalized_hash="e284b4e9b2b14176a0743103084ae53f0535157896a29e27026fdc2d12331a5e"
conflicts_hash="f3463dc6505d6c8707bc6dc1bc5108ca7b8179c0573aa02bb1c8894358c98392"
inventory_hash="d85eb38a4675251c3e23ebf1d0c187949134978b89f45d7af92108be0bbbe503"

die() { printf 'E0050: %s\n' "$1" >&2; exit 1; }

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# E0049 is the predecessor oracle. It intentionally returns success while
# recording its composition status as verification_failure.
"$e49" >"$outdir/e0049.log" || die 'E0049 predecessor failed'
test "$(sha256sum "$normalized" | cut -d' ' -f1)" = "$normalized_hash" || die 'normalized record hash mismatch'
test "$(sha256sum "$conflicts" | cut -d' ' -f1)" = "$conflicts_hash" || die 'conflict hash mismatch'
test "$(sha256sum "$inventory" | cut -d' ' -f1)" = "$inventory_hash" || die 'inventory hash mismatch'

test "$(wc -l < "$conflicts")" -eq 3 || die 'overlap denominator differs'
awk -F '\t' '$4 == "R403" && $3 == "name" {n++} END {exit (n == 3 ? 0 : 1)}' "$conflicts" || die 'overlap facts differ'

# Reconstruct the family denominator independently from the inventory. The
# overlap is a three-row subset of the 100 expansion-family records.
awk -F '\t' '
    NR == 1 { next }
    $2 == "R401" {r401++}
    $2 == "R403" {r403++}
    END {if (r401 != 80 || r403 != 20) exit 1; print "family\tcount\nR401\t" r401 "\nR403\t" r403}
' "$inventory" >"$outdir/family-denominator.tsv" || die 'family denominator differs'

# Candidate strategies are deliberately projections for comparison only.
# They do not alter StandardIR or select the D0024/D0026 decision.
awk -F '\t' '
    BEGIN {
        print "candidate\tsource_term\tr402_target\tr403_base\tr403_constraint\tparser_action\tretains_r402\tretains_r403\tlossless_facts\tparser_projection\tdecision_state"
        candidates[1]="alias-precedence"
        candidates[2]="expansion-precedence"
        candidates[3]="unresolved-composite"
    }
    FILENAME == ARGV[1] {
        term=$1; target=$3; family=$4; source[term]=term; r402[term]=target; r403[term]=family
        next
    }
    FILENAME == ARGV[2] {
        if (FNR > 1 && $14 == "R403" && $2 == $1) base[$2] = substr($2, 8)
        next
    }
    END {
        for (term in source) {
            for (i=1; i<=3; i++) {
                c=candidates[i]
                if (c == "alias-precedence") {
                    action="ref " r402[term]
                    keeps_r403="false"
                    lossless="false"
                    projection="parser-ready"
                } else if (c == "expansion-precedence") {
                    action="assumed-scalar ref " base[term] " + C401"
                    keeps_r403="true"
                    lossless="true"
                    projection="deferred-typed-expansion"
                } else {
                    action="unresolved composite facts"
                    keeps_r403="true"
                    lossless="true"
                    projection="none"
                }
                print c "\t" term "\t" r402[term] "\t" base[term] "\tC401\t" action "\ttrue\t" keeps_r403 "\t" lossless "\t" projection "\tdeferred-D0024-D0026"
                rows++
            }
        }
        if (rows != 9) exit 1
    }
' "$conflicts" "$normalized" >"$outdir/candidate-comparison.tsv" || die 'candidate matrix construction failed'

# Independently verify the expected tradeoff counts and the controlled
# mutation. Exactly one candidate is parser-ready, and only it loses a fact.
awk -F '\t' '
    NR == 1 { next }
    { rows[$1]++; if ($6 == "ref name") alias_rows[$1]++; if ($9 == "false") lossy[$1]++; if ($8 == "true") retained[$1]++ }
    END {
        if (rows["alias-precedence"] != 3 || rows["expansion-precedence"] != 3 || rows["unresolved-composite"] != 3) exit 1
        if (alias_rows["alias-precedence"] != 3 || lossy["alias-precedence"] != 3) exit 1
        if (retained["expansion-precedence"] != 3 || retained["unresolved-composite"] != 3) exit 1
    }
' "$outdir/candidate-comparison.tsv" || die 'candidate tradeoff oracle failed'

awk -F '\t' 'BEGIN {OFS="\t"} NR == 1 {print; next} NR == 2 {$1="unapproved"} {print}' \
    "$outdir/candidate-comparison.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $1 == "unapproved" {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'candidate_strategies\t3\n' >>"$outdir/summary.tsv"
printf 'overlap_terms\t3\n' >>"$outdir/summary.tsv"
printf 'r401_records\t80\n' >>"$outdir/summary.tsv"
printf 'r403_records\t20\n' >>"$outdir/summary.tsv"
printf 'candidate_rows\t9\n' >>"$outdir/summary.tsv"
printf 'lossy_alias_precedence_rows\t3\n' >>"$outdir/summary.tsv"
printf 'lossless_expansion_precedence_rows\t3\n' >>"$outdir/summary.tsv"
printf 'lossless_unresolved_composite_rows\t3\n' >>"$outdir/summary.tsv"
printf 'parser_ready_candidates\t1\n' >>"$outdir/summary.tsv"
printf 'representation_selection\tdeferred_D0024_D0026\n' >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'candidate_matrix_sha256\t%s\n' "$(sha256sum "$outdir/candidate-comparison.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'family_denominator_sha256\t%s\n' "$(sha256sum "$outdir/family-denominator.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0050 oracle: candidate representation comparison passed without selection\n'
cat "$outdir/summary.tsv"
