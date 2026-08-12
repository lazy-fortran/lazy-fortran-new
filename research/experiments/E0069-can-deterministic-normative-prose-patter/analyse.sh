#!/usr/bin/env bash
# Measure exact normative-prose evidence for the E0022 unresolved-name set.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
audit="${UNRESOLVED_AUDIT:-$root/.cache/runs/E0022/R000001/reference-audit.tsv}"
oracle="$root/research/experiments/E0069-can-deterministic-normative-prose-patter/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0069/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
audit_hash="28eb6876a77345cd85de14cf23a1d9027beefc2cb7a4de5756a9f28c40d1a449"

die() {
    printf 'E0069: %s\n' "$1" >&2
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

primary() {
    local text="$1" target="$2"
    awk -F '\t' -v OFS='\t' -v audit="$audit" -v source_hash="$source_hash" '
        function normalized(value) {
            sub(/[[:punct:]]+$/, "", value)
            return tolower(value)
        }
        function contains_word(line, word, p, before, after, tail) {
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
        function emit_candidate(term, norm, kind, target, line, page, text) {
            gsub(/[\t\r]/, " ", text)
            print term, norm, kind, target, line, page, source_hash, text
        }
        FILENAME == audit {
            if (FNR == 1) next
            term=$1
            norm=normalized(term)
            terms[++term_count]=term
            norms[term]=norm
            next
        }
        {
            if (index($0, "\f")) page++
            text=$0
            gsub(/\f/, " ", text)
            lower=tolower(text)
            for (i=1; i<=term_count; i++) {
                term=terms[i]
                norm=norms[term]
                if (norm == "" || !contains_word(lower, norm)) continue

                kind=""
                target="-"
                lexical_marker="defines the syntactic class " norm
                if (index(lower, lexical_marker) > 0 || \
                    index(lower, "define the syntactic class " norm) > 0 || \
                    index(lower, norm " is one of") > 0) {
                    kind="lexical-class"
                } else if (norm == "xyz" && \
                           index(lower, "letters xyz stand for any syntactic class phrase") > 0) {
                    kind="metavariable"
                } else {
                    name_pos=index(lower, "the name of")
                    is_pos=index(lower, " is ")
                    term_pos=index(lower, norm)
                    if ((name_pos > 0 && is_pos > name_pos && term_pos > is_pos) || \
                        index(lower, norm " is the name of") > 0) {
                        kind="semantic-role"
                    } else if (index(lower, norm " is name") > 0 || \
                               index(lower, norm " is a name") > 0 || \
                               index(lower, norm " is an identifier") > 0) {
                        kind="alias"
                        if (index(lower, norm " is an identifier") > 0) target="identifier"
                        else target="name"
                    }
                }
                if (kind != "") emit_candidate(term, norm, kind, target, FNR, page, text)
            }
        }
    ' "$audit" "$text" >"$target"
}

primary "$canonical" "$outdir/candidate-spans.tsv"

printf 'term\tnormalized_term\tclassification\tcandidate_count\tcandidate_kinds\tsource_hash\torigin\n' \
    >"$outdir/resolution-summary.tsv"
awk -F '\t' -v OFS='\t' -v audit="$audit" -v source_hash="$source_hash" '
    FILENAME == audit {
        if (FNR == 1) next
        term=$1
        norm=term
        sub(/[[:punct:]]+$/, "", norm)
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
    local text="$1" target="$2"
    : >"$target"
    while IFS=$'\t' read -r term occurrences referring canonical_lines standard_present kaby76_present; do
        [ "$term" = name ] && continue
        norm="$term"
        norm="${norm%,}"
        norm="${norm%;}"
        norm="${norm%:}"
        if grep -Fqi -- "defines the syntactic class $norm" "$text" || \
           grep -Fqi -- "define the syntactic class $norm" "$text" || \
           grep -Fqi -- "$norm is one of" "$text"; then
            printf '%s\tlexical-class\n' "$term" >>"$target"
        fi
        if [ "$norm" = xyz ] && grep -Fqi -- \
            'letters xyz stand for any syntactic class phrase' "$text"; then
            printf '%s\tmetavariable\n' "$term" >>"$target"
        fi
        if grep -Fqi -- "$norm is the name of" "$text" || \
           awk -v n="$norm" '
               {
                   line=tolower($0)
                   name_pos=index(line, "the name of")
                   is_pos=index(line, " is " n)
                   if (name_pos > 0 && is_pos > name_pos) found=1
               }
               END {exit found ? 0 : 1}
           ' "$text"; then
            printf '%s\tsemantic-role\n' "$term" >>"$target"
        fi
        if grep -Fqi -- "$norm is name" "$text" || \
           grep -Fqi -- "$norm is a name" "$text" || \
           grep -Fqi -- "$norm is an identifier" "$text"; then
            printf '%s\talias\n' "$term" >>"$target"
        fi
    done <"$audit"
    sort -u "$target" -o "$target"
}

independent "$canonical" "$outdir/independent-candidates.tsv"

awk -F '\t' '{print $1 "\t" $3}' "$outdir/candidate-spans.tsv" | sort -u \
    >"$tmp/primary-set.tsv"
cmp -s "$tmp/primary-set.tsv" "$outdir/independent-candidates.tsv" || \
    die 'independent candidate set differs from the primary recognizer'

# Compare the independent witness set with the primary output for the five
# source-controlled witnesses. The source substring itself is also checked.
while IFS=$'\t' read -r term expected substring purpose; do
    [ "$term" = term ] && continue
    grep -Fqi -- "$substring" "$canonical" || die "missing witness source: $term"
    if [ "$expected" = unresolved ]; then
        if awk -F '\t' -v t="$term" '$1 == t {found=1} END {exit found ? 0 : 1}' \
            "$outdir/candidate-spans.tsv"; then
            die "negative witness unexpectedly classified: $term"
        fi
    else
        if ! awk -F '\t' -v t="$term" -v k="$expected" \
            '$1 == t && $3 == k {found=1} END {exit found ? 0 : 1}' \
            "$outdir/candidate-spans.tsv"; then
            die "primary witness classification missing: $term"
        fi
        grep -Fq $'\t'"$expected" "$outdir/independent-candidates.tsv" || \
            die "independent witness classification missing: $term"
    fi
done <"$oracle"

# Every candidate must carry the pinned document hash and a derived page.
awk -F '\t' '
    { if (NF != 8 || $6 !~ /^[0-9]+$/ || $6 == 0 || \
          $7 != "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2") bad=1 }
    END { exit bad }
' "$outdir/candidate-spans.tsv"

test "$(awk 'END {print NR - 1}' "$outdir/resolution-summary.tsv")" -eq 181 || \
    die 'resolution summary does not preserve the 181-name denominator'

# Negative control: removing one exact normative marker must remove the fixed
# lexical witness and make the same source-controlled gate fail.
mutated="$tmp/mutated.canonical.txt"
sed 's/The ten digits define the syntactic class digit\./The ten digits identify the syntactic class digit./' \
    "$canonical" >"$mutated"
primary "$mutated" "$tmp/mutated-candidates.tsv"
if grep -Fq $'digit\t' "$tmp/mutated-candidates.tsv"; then
    die 'negative control did not remove the digit lexical witness'
else
    negative_control="observed_failure"
fi

unresolved_names="$(awk -F '\t' 'NR > 1 && $3 == "unresolved" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
ambiguous_names="$(awk -F '\t' 'NR > 1 && $3 == "ambiguous" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
alias_names="$(awk -F '\t' 'NR > 1 && $3 == "alias" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
lexical_names="$(awk -F '\t' 'NR > 1 && $3 == "lexical-class" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
metavariable_names="$(awk -F '\t' 'NR > 1 && $3 == "metavariable" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
semantic_names="$(awk -F '\t' 'NR > 1 && $3 == "semantic-role" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
candidate_spans="$(awk 'END {print NR}' "$outdir/candidate-spans.tsv")"
source_linked="$(awk -F '\t' 'NF == 8 && $6 ~ /^[0-9]+$/ && $6 > 0 && $7 != "" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'unresolved_names\t181\n' >>"$outdir/summary.tsv"
printf 'candidate_spans\t%s\n' "$candidate_spans" >>"$outdir/summary.tsv"
printf 'alias_names\t%s\n' "$alias_names" >>"$outdir/summary.tsv"
printf 'lexical_class_names\t%s\n' "$lexical_names" >>"$outdir/summary.tsv"
printf 'metavariable_names\t%s\n' "$metavariable_names" >>"$outdir/summary.tsv"
printf 'semantic_role_names\t%s\n' "$semantic_names" >>"$outdir/summary.tsv"
printf 'ambiguous_names\t%s\n' "$ambiguous_names" >>"$outdir/summary.tsv"
printf 'unresolved_after_patterns\t%s\n' "$unresolved_names" >>"$outdir/summary.tsv"
printf 'source_linked_candidates\t%s\n' "$source_linked" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"

printf 'E0069 oracle: deterministic normative-prose evidence inventory passed\n'
cat "$outdir/summary.tsv"
