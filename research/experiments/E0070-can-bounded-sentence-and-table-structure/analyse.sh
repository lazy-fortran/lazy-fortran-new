#!/usr/bin/env bash
# Measure bounded cross-line sentence and table evidence for E0022 names.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
audit="${UNRESOLVED_AUDIT:-$root/.cache/runs/E0022/R000001/reference-audit.tsv}"
oracle="$root/research/experiments/E0070-can-bounded-sentence-and-table-structure/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0070/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
audit_hash="28eb6876a77345cd85de14cf23a1d9027beefc2cb7a4de5756a9f28c40d1a449"

die() {
    printf 'E0070: %s\n' "$1" >&2
    exit 1
}

test -f "$canonical" || die "canonical text is missing: $canonical"
test -f "$audit" || die "E0022 audit is missing: $audit"
test -f "$oracle" || die "witness oracle is missing: $oracle"
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || \
    die 'canonical text hash mismatch'
test "$(sha256sum "$audit" | cut -d' ' -f1)" = "$audit_hash" || \
    die 'E0022 audit hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

build_units() {
    local text="$1" target="$2"
    awk -F '\t' -v OFS='\t' 'BEGIN {page=1}
        function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
        }
        function flush_sentence() {
            if (sentence != "") {
                print "sentence", start_line, end_line, start_page, page, sentence
                sentence=""
                start_line=0
                end_line=0
                start_page=0
            }
        }
        function clean_line(raw, value) {
            value=raw
            gsub(/\f/, "", value)
            sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", value)
            sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", value)
            return trim(value)
        }
        {
            raw=$0
            if (index(raw, "\f")) {
                flush_sentence()
                page++
                table=0
                table_ready=0
                raw=substr(raw, index(raw, "\f") + 1)
            }
            if (raw ~ /J3\/24-007/ || raw == "") {
                flush_sentence()
                next
            }

            # A table begins at its explicit header. Rows are retained until
            # the next numbered paragraph, which is the bounded terminator.
            if (raw ~ /^[[:space:]]*Table[[:space:]]+[0-9]/) {
                flush_sentence()
                table=1
                table_ready=0
                next
            }
            if (table) {
                if (raw ~ /^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]/) {
                    table=0
                    table_ready=0
                    flush_sentence()
                } else {
                    row=clean_line(raw)
                    if (row == "") next
                    if (row ~ /Name of character|Official designation|Kind of scoping unit|Statement type/) {
                        table_ready=1
                        next
                    }
                    if (table_ready) print "table", FNR, FNR, page, page, row
                    next
                }
            }

            # A second numeric prefix is a new numbered paragraph. It is the
            # canonical extractor local line number followed by the prose
            # paragraph number, so it is a safe sentence-unit boundary.
            after=raw
            sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", after)
            new_paragraph=(after ~ /^[[:space:]]*[0-9]+[[:space:]]+/)
            if (new_paragraph && sentence != "") flush_sentence()
            line=clean_line(raw)
            if (line == "") {
                flush_sentence()
                next
            }
            if (sentence == "") {
                start_line=FNR
                start_page=page
                sentence=line
            } else {
                sentence=sentence " " line
            }
            end_line=FNR
        }
        END {flush_sentence()}
    ' "$text" >"$target"
}

primary() {
    local units="$1" target="$2"
    awk -F '\t' -v OFS='\t' -v audit="$audit" -v units="$units" -v source_hash="$source_hash" '
        function normalized(value) {
            if (value ~ /^[[:punct:]]+$/) return tolower(value)
            sub(/[[:punct:]]+$/, "", value)
            return tolower(value)
        }
        function contains_word(line, word, p, before, after, tail) {
            if (word ~ /^[[:punct:]]+$/)
                return index(" " line " ", " " word " ") > 0
            tail=line
            while ((p=index(tail, word)) > 0) {
                before=(p == 1 ? "" : substr(tail, p - 1, 1))
                after=substr(tail, p + length(word), 1)
                if (before !~ /[a-z0-9_-]/ && after !~ /[a-z0-9_-]/)
                    return 1
                tail=substr(tail, p + length(word))
            }
            return 0
        }
        function emit_candidate(term, norm, kind, target, structure, line_start, line_end, page_start, page_end, text) {
            gsub(/[\t\r]/, " ", text)
            print term, norm, kind, target, structure, line_start, line_end, page_start, page_end, source_hash, text
        }
        FILENAME == audit {
            if (FNR == 1) next
            term=$1
            norm=normalized(term)
            terms[++term_count]=term
            norms[term]=norm
            next
        }
        FILENAME == units {
            structure=$1
            line_start=$2
            line_end=$3
            page_start=$4
            page_end=$5
            text=$6
            lower=tolower(text)
            for (i=1; i<=term_count; i++) {
                term=terms[i]
                norm=norms[term]
                if (norm == "" || !contains_word(lower, norm)) continue
                kind=""
                target="-"
                if (structure == "table") {
                    kind="lexical-class"
                    target="table-row"
                } else if (index(lower, "defines the syntactic class " norm) > 0 || \
                           index(lower, "define the syntactic class " norm) > 0 || \
                           index(lower, norm " is one of") > 0) {
                    kind="lexical-class"
                } else if (norm == "xyz" && \
                           index(lower, "letters xyz stand for any syntactic class phrase") > 0) {
                    kind="metavariable"
                } else if (index(lower, norm " is name") > 0 || \
                           index(lower, norm " is a name") > 0 || \
                           index(lower, norm " is an identifier") > 0) {
                    kind="alias"
                    if (index(lower, norm " is an identifier") > 0) target="identifier"
                    else target="name"
                } else {
                    name_pos=index(lower, "the name of")
                    is_pos=index(lower, " is " norm)
                    if (index(lower, norm " is the name of") > 0 || \
                        index(lower, norm " shall be the name of") > 0 || \
                        (name_pos > 0 && is_pos > name_pos)) {
                        kind="semantic-role"
                    }
                }
                if (kind != "") emit_candidate(term, norm, kind, target, structure, \
                    line_start, line_end, page_start, page_end, text)
            }
        }
    ' "$audit" "$units" >"$target"
}

build_units "$canonical" "$outdir/logical-units.tsv"
primary "$outdir/logical-units.tsv" "$outdir/candidate-spans.tsv"

printf 'term\tnormalized_term\tclassification\tcandidate_count\tcandidate_kinds\tsource_hash\torigin\n' \
    >"$outdir/resolution-summary.tsv"
awk -F '\t' -v OFS='\t' -v audit="$audit" -v source_hash="$source_hash" '
    FILENAME == audit {
        if (FNR == 1) next
        term=$1
        norm=term
        if (norm !~ /^[[:punct:]]+$/) sub(/[[:punct:]]+$/, "", norm)
        terms[++n]=term
        norms[term]=tolower(norm)
        next
    }
    {
        term=$1
        kind=$3
        count[term]++
        if (!seen[term SUBSEP kind]++) {
            kinds[term]=kinds[term] (kinds[term] ? "," : "") kind
            kind_count[term]++
        }
    }
    END {
        for (i=1; i<=n; i++) {
            term=terms[i]
            if (!(term in count)) class="unresolved"
            else if (kind_count[term] > 1) class="ambiguous"
            else class=kinds[term]
            print term, norms[term], class, count[term] + 0, \
                (kinds[term] ? kinds[term] : "-"), source_hash, "MECHANICAL"
        }
    }
' "$audit" "$outdir/candidate-spans.tsv" | sort -t $'\t' -k1,1 \
    >>"$outdir/resolution-summary.tsv"

independent() {
    local units="$1" target="$2"
    : >"$target"
    while IFS=$'\t' read -r term occurrences referring canonical_lines standard_present kaby76_present; do
        [ "$term" = name ] && continue
        norm="$term"
        if [[ "$norm" == *[![:punct:]]* ]]; then
            norm="${norm%,}"
            norm="${norm%;}"
            norm="${norm%:}"
        fi
        awk -F '\t' -v n="$(printf '%s' "$norm" | tr '[:upper:]' '[:lower:]')" '
            function hit(line, word, p, before, after, tail) {
                if (word ~ /^[[:punct:]]+$/) return index(" " line " ", " " word " ") > 0
                tail=line
                while ((p=index(tail, word)) > 0) {
                    before=(p == 1 ? "" : substr(tail, p - 1, 1))
                    after=substr(tail, p + length(word), 1)
                    if (before !~ /[a-z0-9_-]/ && after !~ /[a-z0-9_-]/) return 1
                    tail=substr(tail, p + length(word))
                }
                return 0
            }
            $1 == "table" && hit(tolower($6), n) {lex=1}
            $1 == "sentence" && hit(tolower($6), n) {
                line=tolower($6)
                if (index(line, "defines the syntactic class " n) || \
                    index(line, "define the syntactic class " n) || \
                    index(line, n " is one of")) lex=1
                if (n == "xyz" && index(line, "letters xyz stand for any syntactic class phrase")) meta=1
                if (index(line, n " is name") || index(line, n " is a name") || \
                    index(line, n " is an identifier")) alias=1
                np=index(line, "the name of")
                ip=index(line, " is " n)
                if (index(line, n " is the name of") || \
                    index(line, n " shall be the name of") || (np > 0 && ip > np)) semantic=1
            }
            END {
                if (lex) print "lexical-class"
                if (meta) print "metavariable"
                if (alias) print "alias"
                if (semantic) print "semantic-role"
            }
        ' "$units" | while IFS= read -r kind; do
            printf '%s\t%s\n' "$term" "$kind" >>"$target"
        done
    done <"$audit"
    sort -u "$target" -o "$target"
}

independent "$outdir/logical-units.tsv" "$outdir/independent-candidates.tsv"
awk -F '\t' '{print $1 "\t" $3}' "$outdir/candidate-spans.tsv" | sort -u \
    >"$tmp/primary-set.tsv"
cmp -s "$tmp/primary-set.tsv" "$outdir/independent-candidates.tsv" || \
    die 'independent candidate set differs from the primary recognizer'

while IFS=$'\t' read -r term structure expected substring purpose; do
    [ "$term" = term ] && continue
    if ! awk -F '\t' -v s="$structure" -v q="$substring" \
        '$1 == s && index($6, q) {found=1} END {exit found ? 0 : 1}' \
        "$outdir/logical-units.tsv"; then
        die "missing bounded witness source: $term"
    fi
    if [ "$expected" = unresolved ]; then
        if awk -F '\t' -v t="$term" '$1 == t {found=1} END {exit found ? 0 : 1}' \
            "$outdir/candidate-spans.tsv"; then
            die "negative witness unexpectedly classified: $term"
        fi
    elif ! awk -F '\t' -v t="$term" -v s="$structure" -v k="$expected" \
        '$1 == t && $3 == k && $5 == s {found=1} END {exit found ? 0 : 1}' \
        "$outdir/candidate-spans.tsv"; then
        die "bounded witness classification missing: $term"
    fi
done <"$oracle"

awk -F '\t' '
    { if (NF != 11 || $8 !~ /^[0-9]+$/ || $9 !~ /^[0-9]+$/ || \
          $8 == 0 || $9 == 0 || $10 != "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2") bad=1 }
    END { exit bad }
' "$outdir/candidate-spans.tsv"

test "$(awk 'END {print NR - 1}' "$outdir/resolution-summary.tsv")" -eq 181 || \
    die 'resolution summary does not preserve the 181-name denominator'

# Compare the unique classifications with the exact line-local predecessor.
"$root/research/experiments/E0069-can-deterministic-normative-prose-patter/analyse.sh" \
    "$tmp/e0069" >/dev/null
awk -F '\t' 'NR > 1 && $3 != "unresolved" && $3 != "ambiguous" {print $1}' \
    "$tmp/e0069/resolution-summary.tsv" | sort -u >"$tmp/previous-names.tsv"
awk -F '\t' 'NR > 1 && $3 != "unresolved" && $3 != "ambiguous" {print $1}' \
    "$outdir/resolution-summary.tsv" | sort -u >"$tmp/current-names.tsv"
new_names="$(comm -13 "$tmp/previous-names.tsv" "$tmp/current-names.tsv" | wc -l | tr -d ' ')"

# Negative control: mutate the table witness and require its row to disappear.
mutated="$tmp/mutated.canonical.txt"
sed 's/^\. Decimal point or period # Number sign/Decimal point or period # Number sign/' \
    "$canonical" >"$mutated"
build_units "$mutated" "$tmp/mutated-units.tsv"
primary "$tmp/mutated-units.tsv" "$tmp/mutated-candidates.tsv"
if awk -F '\t' '$1 == "." && $5 == "table" {found=1} END {exit found ? 0 : 1}' \
    "$tmp/mutated-candidates.tsv"; then
    die 'negative control did not remove the table witness'
else
    negative_control="observed_failure"
fi

unresolved_names="$(awk -F '\t' 'NR > 1 && $3 == "unresolved" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
ambiguous_names="$(awk -F '\t' 'NR > 1 && $3 == "ambiguous" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
candidate_names="$(awk -F '\t' 'NR > 1 && $3 != "unresolved" && $3 != "ambiguous" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
alias_names="$(awk -F '\t' 'NR > 1 && $3 == "alias" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
lexical_names="$(awk -F '\t' 'NR > 1 && $3 == "lexical-class" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
metavariable_names="$(awk -F '\t' 'NR > 1 && $3 == "metavariable" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
semantic_names="$(awk -F '\t' 'NR > 1 && $3 == "semantic-role" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
logical_units="$(awk 'END {print NR}' "$outdir/logical-units.tsv")"
table_rows="$(awk -F '\t' '$1 == "table" {n++} END {print n + 0}' "$outdir/logical-units.tsv")"
candidate_spans="$(awk 'END {print NR}' "$outdir/candidate-spans.tsv")"
source_linked="$(awk -F '\t' 'NF == 11 && $8 ~ /^[0-9]+$/ && $8 > 0 && $9 ~ /^[0-9]+$/ && $9 > 0 && $10 != "" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'unresolved_names\t181\n' >>"$outdir/summary.tsv"
printf 'logical_units\t%s\n' "$logical_units" >>"$outdir/summary.tsv"
printf 'table_rows\t%s\n' "$table_rows" >>"$outdir/summary.tsv"
printf 'candidate_spans\t%s\n' "$candidate_spans" >>"$outdir/summary.tsv"
printf 'candidate_names\t%s\n' "$candidate_names" >>"$outdir/summary.tsv"
printf 'new_names_over_e0069\t%s\n' "$new_names" >>"$outdir/summary.tsv"
printf 'alias_names\t%s\n' "$alias_names" >>"$outdir/summary.tsv"
printf 'lexical_class_names\t%s\n' "$lexical_names" >>"$outdir/summary.tsv"
printf 'metavariable_names\t%s\n' "$metavariable_names" >>"$outdir/summary.tsv"
printf 'semantic_role_names\t%s\n' "$semantic_names" >>"$outdir/summary.tsv"
printf 'ambiguous_names\t%s\n' "$ambiguous_names" >>"$outdir/summary.tsv"
printf 'unresolved_after_patterns\t%s\n' "$unresolved_names" >>"$outdir/summary.tsv"
printf 'source_linked_candidates\t%s\n' "$source_linked" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"

printf 'E0070 oracle: bounded sentence and table evidence inventory passed\n'
cat "$outdir/summary.tsv"
