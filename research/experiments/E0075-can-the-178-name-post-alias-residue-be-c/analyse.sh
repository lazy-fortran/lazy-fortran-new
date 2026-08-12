#!/usr/bin/env bash
# Classify post-alias unresolved names from existing source-provenanced facts.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
e74="$root/research/experiments/E0074-can-the-accepted-e0072-aliases-integrate/analyse.sh"
e74out="$root/.cache/runs/E0074/R000001"
facts="$root/.cache/runs/E0072/R000001/composite-resolution-facts.tsv"
outdir="${1:-$root/.cache/runs/E0075/R000001}"
integrated_hash="3c62ea0c5816348c7dbff2b8d9895725ba61c02507949ea978d62be21a52a8c5"
facts_hash="9da21d15972d2ba559690fedcacbe6f58593d307227e4c210e44bf6a49118a08"

die() {
    printf 'E0075: %s\n' "$1" >&2
    exit 1
}

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e74" >"$outdir/e0074.log" || die 'E0074 predecessor failed'
integrated="$e74out/integrated-syntax.sx"
test "$(sha256sum "$integrated" | cut -d' ' -f1)" = "$integrated_hash" || die 'integrated syntax hash mismatch'
test "$(sha256sum "$facts" | cut -d' ' -f1)" = "$facts_hash" || die 'composite facts hash mismatch'

# Extract unique refs that have no lhs production after the accepted aliases.
awk '
    /^\(syntax / {
        if (match($0, /\(lhs [^ )]+\)/)) defined[substr($0, RSTART + 5, RLENGTH - 6)]=1
    }
    END {
        while ((getline line < ARGV[1]) > 0) {
            while (match(line, /\(ref [^ )]+\)/)) {
                name=substr(line, RSTART + 5, RLENGTH - 6)
                if (!(name in defined)) seen[name]=1
                line=substr(line, RSTART + RLENGTH)
            }
        }
        close(ARGV[1])
        for (name in seen) print name
    }
' "$integrated" | sort >"$outdir/residue-names.txt"
residue_records="$(wc -l <"$outdir/residue-names.txt")"
test "$residue_records" -eq 178 || die 'residue denominator differs'

# Select the strongest existing source fact for each residue term. Semantic
# facts outrank lexical facts, which outrank metanotation and unresolved rows.
classified="$outdir/residue-classification.tsv"
awk -F '\t' -v OFS='\t' '
    function rank(class) {
        if (class == "semantic-role") return 1
        if (class == "lexical-class") return 2
        if (class == "metavariable") return 3
        if (class == "unresolved") return 4
        return 9
    }
    FILENAME == ARGV[1] {
        if (FNR == 1) next
        term=$2
        r=rank($3)
        if (!(term in best) || r < best_rank[term]) {
            best[term]=1
            best_rank[term]=r
            class[term]=$3
            target[term]=$4
            role[term]=$5
            document[term]=$6
            clause[term]=$7
            rule[term]=$8
            page[term]=$9
            hash[term]=$10
            origin[term]=$11
            evidence[term]=$12
        }
        next
    }
    FILENAME == ARGV[2] {
        term=$1
        if (!(term in best)) {missing++; next}
        print term, class[term], target[term], role[term], document[term], clause[term], rule[term], page[term], hash[term], origin[term], "MECHANICAL", evidence[term]
        emitted[term]=1
    }
    END {
        if (missing) exit 7
    }
' "$facts" "$outdir/residue-names.txt" | sort -t $'\t' -k1,1 >"$tmp/classification-body.tsv" || die 'fact join failed'
{
    printf 'source_term\tclass\tparser_target\tsemantic_role\tdocument\tclause\tsource_rule\tpage\tsource_sha256\tsource_origin\tclassification_origin\tevidence\n'
    cat "$tmp/classification-body.tsv"
} >"$classified"

classified_records="$(awk 'END {print NR - 1}' "$classified")"
test "$classified_records" -eq 178 || die 'classified record count differs'

semantic_role_records="$(awk -F '\t' 'NR > 1 && $2 == "semantic-role" {n++} END {print n + 0}' "$classified")"
lexical_class_records="$(awk -F '\t' 'NR > 1 && $2 == "lexical-class" {n++} END {print n + 0}' "$classified")"
metavariable_records="$(awk -F '\t' 'NR > 1 && $2 == "metavariable" {n++} END {print n + 0}' "$classified")"
unresolved_records="$(awk -F '\t' 'NR > 1 && $2 == "unresolved" {n++} END {print n + 0}' "$classified")"
missing_fact_records="$(awk -F '\t' 'NR > 1 && ($5 == "" || $7 == "" || $8 == "" || $9 == "") {n++} END {print n + 0}' "$classified")"
additional_alias_records="$(awk -F '\t' 'NR > 1 && $2 == "alias" {n++} END {print n + 0}' "$classified")"
source_hash_matches="$(awk -F '\t' 'NR > 1 && $9 == "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2" {n++} END {print n + 0}' "$classified")"
source_evidence_records="$(awk -F '\t' 'NR > 1 && $12 != "" {n++} END {print n + 0}' "$classified")"
test "$semantic_role_records" -eq 18 || die 'semantic-role count differs'
test "$lexical_class_records" -eq 8 || die 'lexical-class count differs'
test "$metavariable_records" -eq 1 || die 'metavariable count differs'
test "$unresolved_records" -eq 151 || die 'unresolved count differs'
test "$missing_fact_records" -eq 0 || die 'source fact fields missing'
test "$additional_alias_records" -eq 0 || die 'new parser alias introduced'
test "$source_hash_matches" -eq 178 || die 'source hash count differs'
test "$source_evidence_records" -eq 178 || die 'source evidence count differs'

# No semantic-role fact may have a parser target or enter the parser map.
semantic_projection_leaks="$(awk -F '\t' 'NR > 1 && $2 == "semantic-role" && $3 != "-" {n++} END {print n + 0}' "$classified")"
test "$semantic_projection_leaks" -eq 0 || die 'semantic role has parser target'

# Independent set/count traversal from the classification output.
independent_difference="$(awk -F '\t' '
    FILENAME == ARGV[1] && FNR > 1 {seen[$1]=1; count[$2]++; next}
    FILENAME == ARGV[2] {if (!($1 in seen)) difference++; names[$1]=1}
    END {
        for (name in seen) if (!(name in names)) difference++
        if (length(seen) != 178 || count["semantic-role"] != 18 || count["lexical-class"] != 8 || count["metavariable"] != 1 || count["unresolved"] != 151) difference++
        print difference + 0
    }
' "$classified" "$outdir/residue-names.txt")"
test "$independent_difference" -eq 0 || die 'independent residue comparison differs'

# A semantic-to-alias mutation must be rejected by the same class gate.
awk -F '\t' -v OFS='\t' 'NR == 1 {print; next} !changed && $2 == "semantic-role" {$2="alias"; changed=1} {print}' \
    "$classified" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $2 == "alias" {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'residue_records\t%s\n' "$residue_records" >>"$outdir/summary.tsv"
printf 'semantic_role_records\t%s\n' "$semantic_role_records" >>"$outdir/summary.tsv"
printf 'lexical_class_records\t%s\n' "$lexical_class_records" >>"$outdir/summary.tsv"
printf 'metavariable_records\t%s\n' "$metavariable_records" >>"$outdir/summary.tsv"
printf 'unresolved_records\t%s\n' "$unresolved_records" >>"$outdir/summary.tsv"
printf 'missing_fact_records\t%s\n' "$missing_fact_records" >>"$outdir/summary.tsv"
printf 'additional_alias_records\t%s\n' "$additional_alias_records" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'source_evidence_records\t%s\n' "$source_evidence_records" >>"$outdir/summary.tsv"
printf 'semantic_projection_leaks\t%s\n' "$semantic_projection_leaks" >>"$outdir/summary.tsv"
printf 'independent_difference\t%s\n' "$independent_difference" >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'integrated_sha256\t%s\n' "$integrated_hash" >>"$outdir/summary.tsv"
printf 'facts_sha256\t%s\n' "$facts_hash" >>"$outdir/summary.tsv"
printf 'classification_sha256\t%s\n' "$(sha256sum "$classified" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0075 oracle: deterministic residue classification completed\n'
cat "$outdir/summary.tsv"
