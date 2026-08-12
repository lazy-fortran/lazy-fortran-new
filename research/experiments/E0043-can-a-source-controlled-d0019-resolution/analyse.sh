#!/usr/bin/env bash
# Generate the first typed, source-provenanced D0019 resolution slice.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
audit="${UNRESOLVED_AUDIT:-$root/.cache/runs/E0022/R000001/reference-audit.tsv}"
outdir="${2:-$root/.cache/runs/E0043/R000001}"
seed="$root/research/experiments/E0043-can-a-source-controlled-d0019-resolution/seed.tsv"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
audit_hash="28eb6876a77345cd85de14cf23a1d9027beefc2cb7a4de5756a9f28c40d1a449"

die() {
    printf 'E0043: %s\n' "$1" >&2
    exit 1
}

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || \
    die 'canonical text hash mismatch'
test "$(sha256sum "$audit" | cut -d' ' -f1)" = "$audit_hash" || die 'audit hash mismatch'

for excerpt in \
    'following rules, where the letters xyz stand for any syntactic class phrase' \
    'R402 xyz-name is name' \
    'The set of letters defines the syntactic class letter' \
    'The ten digits define the syntactic class digit' \
    'R602 underscore is _' \
    'character, rep-char, is defined as follows.'; do
    rg -F -q "$excerpt" "$canonical" || die "missing normative source excerpt: $excerpt"
done

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Extract the first source occurrence for every reference. This is evidence for
# unresolved records, not a resolution rule.
awk '
    /^\(syntax / {
        rule=$2
        gsub(/[()]/, "", rule)
        clause=""
        if (match($0, /\(clause [^)]*\)/)) {
            clause=substr($0, RSTART, RLENGTH)
            sub(/^\(clause /, "", clause)
            sub(/\)$/, "", clause)
        }
        page=""
        if (match($0, /\(page [0-9]+\)/)) {
            page=substr($0, RSTART, RLENGTH)
            sub(/^\(page /, "", page)
            sub(/\)$/, "", page)
        }
        rest=$0
        while (match(rest, /\(ref [^)]*\)/)) {
            ref=substr(rest, RSTART, RLENGTH)
            sub(/^\(ref /, "", ref)
            sub(/\)$/, "", ref)
            if (!seen[ref]++) print ref "\t" clause "\t" rule "\t" page
            rest=substr(rest, RSTART + RLENGTH)
        }
    }
' "$input" | sort -t $'\t' -k1,1 >"$tmp/evidence.tsv"

test "$(awk 'END {print NR}' "$tmp/evidence.tsv")" -gt 0 || die 'no reference evidence extracted'

# Merge the pinned unresolved audit, first-occurrence evidence and the
# source-controlled seed. Every audit name receives exactly one typed record.
awk -F '\t' -v source_hash="$source_hash" \
    'FILENAME == ARGV[1] {
        if (FNR == 1) next
        seed_class[$1]=$2
        seed_target[$1]=$3
        seed_role[$1]=$4
        seed_document[$1]=$5
        seed_clause[$1]=$6
        seed_rule[$1]=$7
        seed_page[$1]=$8
        seed_justification[$1]=$9
        next
    }
    FILENAME == ARGV[2] {
        if (!($1 in evidence_clause)) {
            evidence_clause[$1]=$2
            evidence_rule[$1]=$3
            evidence_page[$1]=$4
        }
        next
    }
    FILENAME == ARGV[3] {
        if (FNR == 1) {
            print "source_term\tclass\tparser_target\tsemantic_role\tdocument\tclause\tsource_rule\tpage\tsource_sha256\torigin\tevidence"
            next
        }
        name=$1
        audit_seen[name]=1
        if (name in seed_class) {
            class=seed_class[name]
            target=seed_target[name]
            role=seed_role[name]
            document=seed_document[name]
            clause=seed_clause[name]
            rule=seed_rule[name]
            page=seed_page[name]
            evidence=seed_justification[name]
        } else {
            class="unresolved"
            target="-"
            role="-"
            document="J3-24-007"
            clause=evidence_clause[name]
            rule=evidence_rule[name]
            page=evidence_page[name]
            evidence="reference occurrence only; no normative resolution witness"
        }
        if (clause == "" || rule == "" || page == "") exit 7
        print name "\t" class "\t" target "\t" role "\t" document "\t" clause "\t" rule "\t" page "\t" source_hash "\tMECHANICAL\t" evidence
    }
    END {
        for (name in seed_class) {
            if (!(name in audit_seen)) {
                print name "\t" seed_class[name] "\t" seed_target[name] "\t" seed_role[name] "\t" seed_document[name] "\t" seed_clause[name] "\t" seed_rule[name] "\t" seed_page[name] "\t" source_hash "\tMECHANICAL\t" seed_justification[name]
            }
        }
    }' "$seed" "$tmp/evidence.tsv" "$audit" >"$tmp/resolution-records-unsorted.tsv" || \
    die 'resolution record merge failed'

{
    head -n 1 "$tmp/resolution-records-unsorted.tsv"
    tail -n +2 "$tmp/resolution-records-unsorted.tsv" | sort -t $'\t' -k1,1
} >"$outdir/resolution-records.tsv"

awk -F '\t' '
    NR == 1 {
        expected="source_term class parser_target semantic_role document clause source_rule page source_sha256 origin evidence"
        actual=$1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 " " $10 " " $11
        if (actual != expected) exit 2
        next
    }
    {
    if (NF != 11 || $1 == "" || $5 != "J3-24-007" || $8 !~ /^[0-9]+$/ || $9 != "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2" || $10 != "MECHANICAL") bad=1
    seen[$1]++
    count++
    if ($2 == "alias") {
        aliases++
        if ($3 != "name") bad=1
    }
    if ($2 == "lexical-class") lexical++
    if ($2 == "metavariable") metavariable++
    if ($2 == "semantic-role") semantic++
    if ($2 == "unresolved") unresolved++
    if ($2 == "disputed") disputed++
    }
    END {
        for (name in seen) if (seen[name] != 1) bad=1
    if (count != 182 || aliases != 3 || lexical != 4 || metavariable != 1 || semantic != 0 || unresolved != 174 || disputed != 0) bad=1
        exit bad
    }
' "$outdir/resolution-records.tsv" || die 'independent resolution-record validation failed'

awk -F '\t' 'NR == 1 {print "source_term\tparser_target\tsemantic_role\tsource_rule\tsource_page\torigin"; next} $2 == "alias" {print $1 "\t" $3 "\t" $4 "\t" $7 "\t" $8 "\t" $10}' \
    "$outdir/resolution-records.tsv" >"$outdir/composite-alias-input.tsv"

# Project only the proven aliases. This is deliberately a partial grammar
# input. Lexical facts and unresolved terms are retained in the record table.
awk '
    /^\(syntax / && /\(ref (program-name|entity-name|type-name)\)/ {
        gsub(/\(ref program-name\)/, "(ref name)")
        gsub(/\(ref entity-name\)/, "(ref name)")
        gsub(/\(ref type-name\)/, "(ref name)")
        print
        next
    }
    /^\(syntax / && /\(lhs name\)|\(lhs alphanumeric-character\)/ {print}
' "$input" >"$outdir/composite-alias-slice.sx"

test "$(wc -l < "$outdir/composite-alias-input.tsv")" -eq 4 || \
    die 'alias projection row count differs'
test "$(wc -l < "$outdir/composite-alias-slice.sx")" -eq 8 || \
    die 'composite alias SX witness count differs'

(cd "$standard_new" && fo exec sxantlr \
    "$outdir/composite-alias-slice.sx" "$outdir/composite-alias-slice.g4") \
    >"$outdir/composite-alias-slice.log"

# A changed typed class must be detected by the same validator.
awk -F '\t' 'NR == 1 {print; next} $1 == "program-name" {$2="unresolved"} {OFS="\t"; print}' \
    "$outdir/resolution-records.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $1 == "program-name" && !($2 == "alias" && $3 == "name") {bad=1} END {exit (bad ? 1 : 0)}' \
    "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

records="$(awk 'END {print NR - 1}' "$outdir/resolution-records.tsv")"
aliases="$(awk -F '\t' 'NR > 1 && $2 == "alias" {count++} END {print count + 0}' "$outdir/resolution-records.tsv")"
lexical="$(awk -F '\t' 'NR > 1 && $2 == "lexical-class" {count++} END {print count + 0}' "$outdir/resolution-records.tsv")"
metavariable="$(awk -F '\t' 'NR > 1 && $2 == "metavariable" {count++} END {print count + 0}' "$outdir/resolution-records.tsv")"
unresolved="$(awk -F '\t' 'NR > 1 && $2 == "unresolved" {count++} END {print count + 0}' "$outdir/resolution-records.tsv")"
source_matches="$(awk -F '\t' 'NR > 1 && $9 == "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2" {count++} END {print count + 0}' "$outdir/resolution-records.tsv")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'resolution_records\t%s\n' "$records" >>"$outdir/summary.tsv"
printf 'alias_records\t%s\n' "$aliases" >>"$outdir/summary.tsv"
printf 'lexical_class_records\t%s\n' "$lexical" >>"$outdir/summary.tsv"
printf 'metavariable_records\t%s\n' "$metavariable" >>"$outdir/summary.tsv"
printf 'semantic_role_records\t0\n' >>"$outdir/summary.tsv"
printf 'unresolved_records\t%s\n' "$unresolved" >>"$outdir/summary.tsv"
printf 'disputed_records\t0\n' >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_matches" >>"$outdir/summary.tsv"
printf 'alias_projection_records\t%s\n' "$aliases" >>"$outdir/summary.tsv"
printf 'composite_input_sha256\t%s\n' "$(sha256sum "$outdir/composite-alias-slice.sx" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'composite_grammar_sha256\t%s\n' "$(sha256sum "$outdir/composite-alias-slice.g4" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"

printf 'E0043 oracle: typed D0019 resolution records and partial alias projection passed\n'
cat "$outdir/summary.tsv"
