#!/usr/bin/env bash
# Inventory source-linked semantic candidates without accepting or generating rules.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
audit="${UNRESOLVED_AUDIT:-$root/.cache/runs/E0022/R000001/reference-audit.tsv}"
closure="${CORE0_CLOSURE:-$root/.cache/runs/E0014/R000001/j3-24-007.dependencies.sx}"
oracle="$root/research/experiments/E0081-can-deterministic-source-patterns-invent/witness-oracle.tsv"
outdir="${1:-$root/.cache/runs/E0081/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
audit_hash="28eb6876a77345cd85de14cf23a1d9027beefc2cb7a4de5756a9f28c40d1a449"
closure_hash="03af0b269089c90ef277189da214c3952796f86703a2aa19c904f0ec6b6510d6"

die() {
    printf 'E0081: %s\n' "$1" >&2
    exit 1
}

test -f "$canonical" || die "canonical text is missing: $canonical"
test -f "$audit" || die "E0022 audit is missing: $audit"
test -f "$closure" || die "E0014 closure is missing: $closure"
test -f "$oracle" || die "witness oracle is missing: $oracle"
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'
test "$(sha256sum "$audit" | cut -d' ' -f1)" = "$audit_hash" || die 'E0022 audit hash mismatch'
test "$(sha256sum "$closure" | cut -d' ' -f1)" = "$closure_hash" || die 'E0014 closure hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

sed -n 's/^(profile core0-v1 (member \(R[0-9][0-9]*\))).*/\1/p' "$closure" \
    | sort -u >"$tmp/core0-members.txt"
test "$(wc -l <"$tmp/core0-members.txt")" -eq 345 || die 'Core 0 closure member count differs'

primary_candidates() {
    local text="$1" target="$2"
    awk -F '\t' -v OFS='\t' -v audit="$audit" -v source_hash="$source_hash" '
        function normalized(value) {
            sub(/[[:punct:]]+$/, "", value)
            return tolower(value)
        }
        function contains_word(line, word, p, tail, before, after) {
            if (word == "") return 0
            tail=line
            while ((p=index(tail, word)) > 0) {
                before=(p == 1 ? "" : substr(tail, p - 1, 1))
                after=substr(tail, p + length(word), 1)
                if (before !~ /[a-z0-9_-]/ && after !~ /[a-z0-9_-]/) return 1
                tail=substr(tail, p + length(word))
            }
            return 0
        }
        function emit(term, norm, kind, line, page, text) {
            gsub(/[\t\r]/, " ", text)
            print term, norm, kind, "-", line, page, source_hash, "MECHANICAL", text
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
                if (!contains_word(lower, norm)) continue
                kind=""
                if (index(lower, "defines the syntactic class " norm) > 0 || \
                    index(lower, "define the syntactic class " norm) > 0 || \
                    index(lower, norm " is one of") > 0 || \
                    (norm == "xyz" && index(lower, "letters xyz stand for") > 0)) {
                    kind="definition"
                } else if (index(lower, norm) > 0 && \
                           (index(lower, " shall") > 0 || index(lower, " must") > 0)) {
                    kind="constraint"
                } else if (index(lower, norm " is the name of") > 0 || \
                           (index(lower, "the name of") > 0 && index(lower, " is " norm) > 0) || \
                           index(lower, norm " is identical to") > 0 || \
                           index(lower, norm " is the same as") > 0) {
                    kind="relation"
                }
                if (kind != "") emit(term, norm, kind, FNR, page, text)
            }
        }
    ' "$audit" "$text" >"$target"
}

primary_candidates "$canonical" "$outdir/candidate-spans.tsv"

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
' "$audit" "$outdir/candidate-spans.tsv" | sort -t $'\t' -k1,1 >>"$outdir/resolution-summary.tsv"

primary_constraints() {
    local text="$1" target="$2" members="$3"
    awk -F '\t' -v OFS='\t' -v members="$members" -v source_hash="$source_hash" '
        BEGIN {
            while ((getline r < members) > 0) core[r]=1
            close(members)
        }
        {
            if (index($0, "\f")) page++
            text=$0
            gsub(/\f/, " ", text)
            if (!match(text, /C[0-9][0-9]+/)) next
            cid=substr(text, RSTART, RLENGTH)
            rest=text
            associated=""
            while (match(rest, /R[0-9][0-9]+/)) {
                rid=substr(rest, RSTART, RLENGTH)
                if (core[rid] && index(" " associated " ", " " rid " ") == 0)
                    associated=associated (associated ? "," : "") rid
                rest=substr(rest, RSTART + RLENGTH)
            }
            if (associated == "") next
            gsub(/[\t\r]/, " ", text)
            print cid, associated, FNR, page, source_hash, "MECHANICAL", text
        }
    ' "$text" >"$target"
}

primary_constraints "$canonical" "$outdir/constraint-spans.tsv" "$tmp/core0-members.txt"

independent_candidates="$outdir/independent-candidates.tsv"
awk -F '\t' -v OFS='\t' -v audit="$audit" '
    function normalized(value) {
        sub(/[[:punct:]]+$/, "", value)
        return tolower(value)
    }
    function has_word(line, word, p, tail, before, after) {
        if (word == "") return 0
        tail=line
        while ((p=index(tail, word)) > 0) {
            before=(p == 1 ? "" : substr(tail, p - 1, 1))
            after=substr(tail, p + length(word), 1)
            if (before !~ /[a-z0-9_-]/ && after !~ /[a-z0-9_-]/) return 1
            tail=substr(tail, p + length(word))
        }
        return 0
    }
    FILENAME == audit {
        if (FNR == 1) next
        terms[++n]=$1
        norms[$1]=normalized($1)
        next
    }
    {
        lower=tolower($0)
        for (i=1; i<=n; i++) {
            term=terms[i]
            norm=norms[term]
            if (!has_word(lower, norm)) continue
            kind=""
            if (index(lower, "defines the syntactic class " norm) > 0 || \
                index(lower, "define the syntactic class " norm) > 0 || \
                index(lower, norm " is one of") > 0 || \
                (norm == "xyz" && index(lower, "letters xyz stand for") > 0)) {
                kind="definition"
            } else if (index(lower, norm) > 0 && \
                       (index(lower, " shall") > 0 || index(lower, " must") > 0)) {
                kind="constraint"
            } else if (index(lower, norm " is the name of") > 0 || \
                       (index(lower, "the name of") > 0 && index(lower, " is " norm) > 0) || \
                       index(lower, norm " is identical to") > 0 || \
                       index(lower, norm " is the same as") > 0) {
                kind="relation"
            }
            if (kind != "") print term, kind
        }
    }
' "$audit" "$canonical" | sort -u >"$independent_candidates"

awk -F '\t' '{print $1 "\t" $3}' "$outdir/candidate-spans.tsv" | sort -u >"$tmp/primary-candidates.tsv"
cmp -s "$tmp/primary-candidates.tsv" "$independent_candidates" || die 'independent candidate set differs'

awk -F '\t' '{print $1 "\t" $2}' "$outdir/constraint-spans.tsv" | sort -u >"$tmp/primary-constraints.tsv"
awk -F '\t' -v members="$tmp/core0-members.txt" '
    BEGIN {while ((getline r < members) > 0) core[r]=1; close(members)}
    {
        text=$0
        if (!match(text, /C[0-9][0-9]+/)) next
        cid=substr(text, RSTART, RLENGTH)
        rest=text; associated=""
        while (match(rest, /R[0-9][0-9]+/)) {
            rid=substr(rest, RSTART, RLENGTH)
            if (core[rid] && index(" " associated " ", " " rid " ") == 0)
                associated=associated (associated ? "," : "") rid
            rest=substr(rest, RSTART + RLENGTH)
        }
        if (associated != "") print cid "\t" associated
    }
' "$canonical" | sort -u >"$outdir/independent-constraints.tsv"
cmp -s "$tmp/primary-constraints.tsv" "$outdir/independent-constraints.tsv" || \
    die 'independent constraint set differs'

while IFS=$'\t' read -r term expected substring _purpose; do
    [ "$term" = term ] && continue
    grep -Fqi -- "$substring" "$canonical" || die "missing witness source: $term"
    if [ "$expected" = constraint ]; then
        awk -F '\t' -v t="$term" '$1 == t && $3 == "constraint" {found=1} END {exit(found ? 0 : 1)}' \
            "$outdir/candidate-spans.tsv" || die "candidate witness missing: $term"
    else
        awk -F '\t' -v t="$term" -v k="$expected" '$1 == t && $3 == k {found=1} END {exit(found ? 0 : 1)}' \
            "$outdir/candidate-spans.tsv" || die "candidate witness missing: $term"
    fi
done <"$oracle"

mutated="$tmp/mutated.canonical.txt"
sed -e 's/program-name shall not be included/program-name may not be included/' \
    -e 's/If included, it shall be identical/If included, it may be identical/' \
    "$canonical" >"$mutated"
primary_candidates "$mutated" "$tmp/mutated-candidates.tsv"
if grep -Fq $'program-name\tprogram-name\tconstraint\t' "$tmp/mutated-candidates.tsv"; then
    die 'negative control did not remove the program-name candidate'
else
    negative_control=observed_failure
fi

unresolved_names="$(awk -F '\t' 'NR > 1 {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
definition_names="$(awk -F '\t' 'NR > 1 && $3 == "definition" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
relation_names="$(awk -F '\t' 'NR > 1 && $3 == "relation" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
constraint_names="$(awk -F '\t' 'NR > 1 && $3 == "constraint" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
ambiguous_names="$(awk -F '\t' 'NR > 1 && $3 == "ambiguous" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
unresolved_after_patterns="$(awk -F '\t' 'NR > 1 && $3 == "unresolved" {n++} END {print n + 0}' "$outdir/resolution-summary.tsv")"
candidate_spans="$(wc -l <"$outdir/candidate-spans.tsv")"
definition_candidate_spans="$(awk -F '\t' '$3 == "definition" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
relation_candidate_spans="$(awk -F '\t' '$3 == "relation" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
constraint_candidate_spans="$(awk -F '\t' '$3 == "constraint" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
definition_candidate_names="$(awk -F '\t' '$3 == "definition" {seen[$1]=1} END {for (x in seen) n++; print n + 0}' "$outdir/candidate-spans.tsv")"
relation_candidate_names="$(awk -F '\t' '$3 == "relation" {seen[$1]=1} END {for (x in seen) n++; print n + 0}' "$outdir/candidate-spans.tsv")"
constraint_candidate_names="$(awk -F '\t' '$3 == "constraint" {seen[$1]=1} END {for (x in seen) n++; print n + 0}' "$outdir/candidate-spans.tsv")"
core0_members="$(wc -l <"$tmp/core0-members.txt")"
core0_constraints="$(wc -l <"$outdir/constraint-spans.tsv")"
source_linked_candidates="$(awk -F '\t' 'NF == 9 && $6 ~ /^[0-9]+$/ && $6 > 0 && $7 != "" {n++} END {print n + 0}' "$outdir/candidate-spans.tsv")"
source_linked_constraints="$(awk -F '\t' 'NF == 7 && $4 ~ /^[0-9]+$/ && $4 > 0 && $5 != "" {n++} END {print n + 0}' "$outdir/constraint-spans.tsv")"
accepted_standardir_facts=0

[ "$unresolved_names" -eq 181 ] || die 'unresolved denominator differs'
[ "$source_linked_candidates" -eq "$candidate_spans" ] || die 'candidate provenance fields incomplete'
[ "$source_linked_constraints" -eq "$core0_constraints" ] || die 'constraint provenance fields incomplete'

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'unresolved_names\t%s\n' "$unresolved_names" >>"$outdir/summary.tsv"
printf 'candidate_spans\t%s\n' "$candidate_spans" >>"$outdir/summary.tsv"
printf 'definition_candidate_spans\t%s\n' "$definition_candidate_spans" >>"$outdir/summary.tsv"
printf 'relation_candidate_spans\t%s\n' "$relation_candidate_spans" >>"$outdir/summary.tsv"
printf 'constraint_candidate_spans\t%s\n' "$constraint_candidate_spans" >>"$outdir/summary.tsv"
printf 'definition_candidate_names\t%s\n' "$definition_candidate_names" >>"$outdir/summary.tsv"
printf 'relation_candidate_names\t%s\n' "$relation_candidate_names" >>"$outdir/summary.tsv"
printf 'constraint_candidate_names\t%s\n' "$constraint_candidate_names" >>"$outdir/summary.tsv"
printf 'definition_names\t%s\n' "$definition_names" >>"$outdir/summary.tsv"
printf 'relation_names\t%s\n' "$relation_names" >>"$outdir/summary.tsv"
printf 'constraint_names\t%s\n' "$constraint_names" >>"$outdir/summary.tsv"
printf 'ambiguous_names\t%s\n' "$ambiguous_names" >>"$outdir/summary.tsv"
printf 'unresolved_after_patterns\t%s\n' "$unresolved_after_patterns" >>"$outdir/summary.tsv"
printf 'core0_closure_members\t%s\n' "$core0_members" >>"$outdir/summary.tsv"
printf 'core0_constraint_records\t%s\n' "$core0_constraints" >>"$outdir/summary.tsv"
printf 'source_linked_candidates\t%s\n' "$source_linked_candidates" >>"$outdir/summary.tsv"
printf 'source_linked_constraints\t%s\n' "$source_linked_constraints" >>"$outdir/summary.tsv"
printf 'accepted_standardir_facts\t%s\n' "$accepted_standardir_facts" >>"$outdir/summary.tsv"
printf 'model_calls\t0\n' >>"$outdir/summary.tsv"
printf 'independent_candidate_difference\t0\n' >>"$outdir/summary.tsv"
printf 'independent_constraint_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'canonical_sha256\t%s\n' "$canonical_hash" >>"$outdir/summary.tsv"
printf 'audit_sha256\t%s\n' "$audit_hash" >>"$outdir/summary.tsv"
printf 'closure_sha256\t%s\n' "$closure_hash" >>"$outdir/summary.tsv"
printf 'candidate_sha256\t%s\n' "$(sha256sum "$outdir/candidate-spans.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"
printf 'constraint_sha256\t%s\n' "$(sha256sum "$outdir/constraint-spans.tsv" | cut -d' ' -f1)" >>"$outdir/summary.tsv"

printf 'E0081 oracle: deterministic semantic candidate inventory passed\n'
cat "$outdir/summary.tsv"
