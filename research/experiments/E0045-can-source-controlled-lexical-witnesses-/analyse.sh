#!/usr/bin/env bash
# Generate the source-controlled lexical operator and literal-marker slice.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
audit="${UNRESOLVED_AUDIT:-$root/.cache/runs/E0022/R000001/reference-audit.tsv}"
outdir="${2:-$root/.cache/runs/E0045/R000001}"
base_seed="$root/research/experiments/E0043-can-a-source-controlled-d0019-resolution/seed.tsv"
lexical_seed="$root/research/experiments/E0045-can-source-controlled-lexical-witnesses-/lexical-seed.tsv"
standard_new="${STANDARD_NEW_ROOT:-$root/../standard-new}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
audit_hash="28eb6876a77345cd85de14cf23a1d9027beefc2cb7a4de5756a9f28c40d1a449"
base_seed_hash="97571cef3a15cbcd68d4b591c18333a8396153deb51dec14ac69b59c75aab896"
lexical_seed_hash="5d0e54d90b684ea38f5a24c307e3b5aba2c90fd2b012cba8e341dde6b1789e37"

die() {
    printf 'E0045: %s\n' "$1" >&2
    exit 1
}

test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || \
    die 'canonical text hash mismatch'
test "$(sha256sum "$audit" | cut -d' ' -f1)" = "$audit_hash" || die 'audit hash mismatch'
test "$(sha256sum "$base_seed" | cut -d' ' -f1)" = "$base_seed_hash" || \
    die 'base seed hash mismatch'
test "$(sha256sum "$lexical_seed" | cut -d' ' -f1)" = "$lexical_seed_hash" || \
    die 'lexical seed hash mismatch'

for excerpt in \
    'The special characters are shown in Table 6.1.' \
    'Table 6.1 — Special characters' \
    'A lexical token is a keyword,' \
    'literal constant other than a complex literal constant, .NIL., operator' \
    'R1014 rel-op is .EQ.' \
    'R1019 not-op is .NOT.' \
    'R1020 and-op is .AND.' \
    'R1021 or-op is .OR.' \
    'R1022 equiv-op is .EQV.' \
    'R725 logical-literal-constant is .TRUE.'; do
    rg -F -q "$excerpt" "$canonical" || die "missing normative source excerpt: $excerpt"
done

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Extract one source occurrence for every reference. This is evidence for
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

# Merge the E0043 witnesses, the explicit lexical seed and the audit. The
# ambiguous Unicode dash and apostrophe stay unresolved by deliberate scope.
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
        if (FNR == 1) next
        lexical_class[$1]=$2
        lexical_target[$1]=$3
        lexical_role[$1]=$4
        lexical_document[$1]=$5
        lexical_clause[$1]=$6
        lexical_rule[$1]=$7
        lexical_page[$1]=$8
        lexical_justification[$1]=$9
        next
    }
    FILENAME == ARGV[4] {
        if (FNR == 1) {
            print "source_term\tclass\tparser_target\tsemantic_role\tdocument\tclause\tsource_rule\tpage\tsource_sha256\torigin\tevidence"
            next
        }
        name=$1
        audit_seen[name]=1
        if (name in lexical_class) {
            class=lexical_class[name]
            target=lexical_target[name]
            role=lexical_role[name]
            document=lexical_document[name]
            clause=lexical_clause[name]
            rule=lexical_rule[name]
            page=lexical_page[name]
            evidence=lexical_justification[name]
            lexical_seen[name]=1
        } else if (name in seed_class) {
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
        for (name in lexical_class) if (!(name in lexical_seen)) exit 9
    }' "$base_seed" "$tmp/evidence.tsv" "$lexical_seed" "$audit" \
    >"$tmp/resolution-records-unsorted.tsv" || die 'resolution record merge failed'

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
        if ($2 == "alias") aliases++
        if ($2 == "lexical-class") {
            lexical++
            if ($1 !~ /^(letter|digit|underscore|rep-char)$/ && ($3 == "-" || $3 == "")) bad=1
        }
        if ($2 == "metavariable") metavariable++
        if ($2 == "semantic-role") semantic++
        if ($2 == "unresolved") unresolved++
        if ($2 == "disputed") disputed++
    }
    END {
        for (name in seen) if (seen[name] != 1) bad=1
        if (count != 182 || aliases != 3 || lexical != 25 || metavariable != 1 || semantic != 0 || unresolved != 153 || disputed != 0) bad=1
        exit bad
    }
' "$outdir/resolution-records.tsv" || die 'independent resolution-record validation failed'

# Compare the selected lexical seed with an independent audit traversal.
awk -F '\t' 'NR > 1 {print $1}' "$lexical_seed" | sort >"$tmp/expected-lexical.tsv"
awk -F '\t' 'NR > 1 && $2 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/ {print $1}' \
    "$outdir/resolution-records.tsv" | sort >"$tmp/actual-lexical.tsv"
if ! diff -u "$tmp/expected-lexical.tsv" "$tmp/actual-lexical.tsv"; then
    die 'independent lexical closure differs from typed records'
fi

awk -F '\t' 'NR == 1 {print "source_term\tclass\tparser_target\tsource_rule\tsource_page\torigin"; next} $2 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/ {print $1 "\t" $2 "\t" $3 "\t" $7 "\t" $8 "\t" $10}' \
    "$outdir/resolution-records.tsv" >"$outdir/lexical-input.tsv"

test "$(wc -l < "$outdir/lexical-input.tsv")" -eq 22 || die 'lexical projection row count differs'

# Project selected lexical references to tokens and retain the earlier name
# aliases as references. Literal replacement avoids regex interpretation of
# punctuation such as . and <.
awk -F '\t' '
    function replace_all(text, old, new, pos) {
        while ((pos = index(text, old)) > 0)
            text = substr(text, 1, pos - 1) new substr(text, pos + length(old))
        return text
    }
    FILENAME == ARGV[1] {
        if (FNR > 1 && $2 == "alias") replacements[$1]="(ref " $3 ")"
        if (FNR > 1 && $2 == "lexical-class" && $1 !~ /^(letter|digit|underscore|rep-char)$/) replacements[$1]="(token " $3 ")"
        next
    }
    FILENAME == ARGV[2] && /^\(syntax / {
        original=$0
        for (name in replacements) $0=replace_all($0, "(ref " name ")", replacements[name])
        if ($0 != original || /\(lhs name\)|\(lhs alphanumeric-character\)/) print
    }
' "$outdir/resolution-records.tsv" "$input" >"$outdir/composite-lexical-slice.sx"

test "$(wc -l < "$outdir/composite-lexical-slice.sx")" -gt 8 || die 'composite lexical SX witness count did not grow'

(cd "$standard_new" && fo exec sxantlr \
    "$outdir/composite-lexical-slice.sx" "$outdir/composite-lexical-slice.g4") \
    >"$outdir/composite-lexical-slice.log"

# Preserve the two Unicode/punctuation cases outside this slice explicitly.
for excluded in '–' '’'; do
    awk -F '\t' -v term="$excluded" 'NR > 1 && $1 == term && $2 == "unresolved" {found=1} END {exit (found ? 0 : 1)}' \
        "$outdir/resolution-records.tsv" || die "excluded Unicode term was resolved: $excluded"
done

# A changed lexical class must be detected by the same validator.
awk -F '\t' 'NR == 1 {print; next} $1 == ".AND." {$2="unresolved"} {OFS="\t"; print}' \
    "$outdir/resolution-records.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $1 == ".AND." && !($2 == "lexical-class" && $3 == ".AND.") {bad=1} END {exit (bad ? 1 : 0)}' \
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
lexical_projection="$(awk 'END {print NR - 1}' "$outdir/lexical-input.tsv")"
syntax_witnesses="$(wc -l < "$outdir/composite-lexical-slice.sx")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'resolution_records\t%s\n' "$records" >>"$outdir/summary.tsv"
printf 'alias_records\t%s\n' "$aliases" >>"$outdir/summary.tsv"
printf 'lexical_class_records\t%s\n' "$lexical" >>"$outdir/summary.tsv"
printf 'metavariable_records\t%s\n' "$metavariable" >>"$outdir/summary.tsv"
printf 'semantic_role_records\t0\n' >>"$outdir/summary.tsv"
printf 'unresolved_records\t%s\n' "$unresolved" >>"$outdir/summary.tsv"
printf 'disputed_records\t0\n' >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_matches" >>"$outdir/summary.tsv"
printf 'lexical_projection_records\t%s\n' "$lexical_projection" >>"$outdir/summary.tsv"
printf 'unicode_exclusions_retained\t2\n' >>"$outdir/summary.tsv"
printf 'composite_syntax_witnesses\t%s\n' "$syntax_witnesses" >>"$outdir/summary.tsv"
printf 'composite_input_sha256\t%s\n' "$(sha256sum "$outdir/composite-lexical-slice.sx" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'composite_grammar_sha256\t%s\n' "$(sha256sum "$outdir/composite-lexical-slice.g4" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"

printf 'E0045 oracle: source-controlled lexical witness projection passed\n'
cat "$outdir/summary.tsv"
