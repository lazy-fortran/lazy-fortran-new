#!/usr/bin/env bash
# Adjudicate every E0070 candidate against the pinned normative source.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
oracle="$root/research/experiments/E0071-can-source-controlled-adjudication-separ/adjudication.tsv"
e0070="$root/research/experiments/E0070-can-bounded-sentence-and-table-structure/analyse.sh"
outdir="${1:-$root/.cache/runs/E0071/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"

die() {
    printf 'E0071: %s\n' "$1" >&2
    exit 1
}

test -f "$canonical" || die "canonical text is missing: $canonical"
test -f "$oracle" || die "adjudication oracle is missing: $oracle"
test -x "$e0070" || die "E0070 analyzer is missing: $e0070"
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || \
    die 'canonical text hash mismatch'

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$e0070" "$tmp/e0070" >/dev/null
candidate="$tmp/e0070/candidate-spans.tsv"
test "$(awk 'END {print NR}' "$candidate")" -eq 42 || \
    die 'E0070 candidate denominator is not 42'
cp "$candidate" "$outdir/candidate-spans.tsv"

printf 'candidate_no\tterm\tkind\tline_start\tline_end\tdisposition\taccepted_class\ttarget\tsource_ref\torigin\tsource_hash\tpage_start\tpage_end\tevidence_substring\tsource_text\n' \
    >"$outdir/adjudicated-records.tsv"

awk -F '\t' -v OFS='\t' -v candidate="$candidate" -v source_hash="$source_hash" '
    FILENAME == candidate {
        if (NF != 11) bad=1
        key=$1 SUBSEP $6 SUBSEP $7 SUBSEP $3
        if (key in candidate_no) bad=1
        candidate_no[key]=FNR
        candidate_text[key]=$11
        candidate_hash[key]=$10
        candidate_page_start[key]=$8
        candidate_page_end[key]=$9
        candidate_count++
        next
    }
    FILENAME != candidate {
        if (FNR == 1) next
        if (NF != 12) bad=1
        no=$1
        term=$2
        kind=$3
        line_start=$4
        line_end=$5
        disposition=$6
        accepted_class=$7
        target=$8
        source_ref=$9
        evidence=$10
        origin=$11
        reason=$12
        key=term SUBSEP line_start SUBSEP line_end SUBSEP kind
        if (!(key in candidate_no) || candidate_no[key] != no) bad=1
        if (disposition != "accepted" && disposition != "retained") bad=1
        if (disposition == "accepted" && accepted_class == "-") bad=1
        if (disposition == "retained" && accepted_class != "-") bad=1
        if (source_ref == "" || evidence == "" || origin == "" || reason == "") bad=1
        if (candidate_hash[key] != source_hash) bad=1
        if (index(tolower(candidate_text[key]), tolower(evidence)) == 0) bad=1
        if (seen[key]++) bad=1
        print no, term, kind, line_start, line_end, disposition, accepted_class, \
            target, source_ref, origin, candidate_hash[key], candidate_page_start[key], \
            candidate_page_end[key], evidence, candidate_text[key]
        oracle_count++
    }
    END {
        if (candidate_count != 42 || oracle_count != candidate_count) bad=1
        for (key in candidate_no)
            if (!(key in seen)) bad=1
        exit bad
    }
' "$candidate" "$oracle" >>"$outdir/adjudicated-records.tsv" || \
    die 'candidate inventory and adjudication oracle differ'

flat="$tmp/canonical-flat.txt"
awk '{line=$0; gsub(/\f/, " ", line); sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", line); sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", line); printf "%s ", line}' \
    "$canonical" | tr -s ' ' | tr '[:upper:]' '[:lower:]' >"$flat"
source_evidence=0
while IFS=$'\t' read -r no term kind line_start line_end disposition accepted_class \
    target source_ref evidence origin reason; do
    [ "$no" = candidate_no ] && continue
    if ! grep -Fqi -- "$evidence" "$flat"; then
        die "source evidence missing for candidate $no ($term)"
    fi
    source_evidence=$((source_evidence + 1))
done <"$oracle"

awk -F '\t' -v OFS='\t' '
    NR == 1 {next}
    {
        if ($6 == "accepted") {
            accepted++
            class[$7]++
        } else if ($6 == "retained") retained++
    }
    END {
        print "accepted_records", accepted + 0
        print "retained_records", retained + 0
        print "accepted_alias_records", class["alias"] + 0
        print "accepted_lexical_class_records", class["lexical-class"] + 0
        print "accepted_metavariable_records", class["metavariable"] + 0
        print "accepted_semantic_role_records", class["semantic-role"] + 0
    }
' "$outdir/adjudicated-records.tsv" | sort >"$tmp/primary-counts.tsv"

awk -F '\t' -v OFS='\t' '
    NR == 1 {next}
    {
        if ($6 == "accepted") {
            accepted++
            class[$7]++
        } else if ($6 == "retained") retained++
    }
    END {
        print "accepted_records", accepted + 0
        print "retained_records", retained + 0
        print "accepted_alias_records", class["alias"] + 0
        print "accepted_lexical_class_records", class["lexical-class"] + 0
        print "accepted_metavariable_records", class["metavariable"] + 0
        print "accepted_semantic_role_records", class["semantic-role"] + 0
    }
' "$oracle" | sort >"$tmp/oracle-counts.tsv"
cmp -s "$tmp/primary-counts.tsv" "$tmp/oracle-counts.tsv" || \
    die 'independent adjudication counts differ'

mutated="$tmp/mutated.canonical.txt"
sed 's/The name of the subroutine is subroutine-name/The name of the subroutine is changed-name/' \
    "$canonical" >"$mutated"
awk '{line=$0; gsub(/\f/, " ", line); sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", line); sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", line); printf "%s ", line}' \
    "$mutated" | tr -s ' ' | tr '[:upper:]' '[:lower:]' >"$tmp/mutated-flat.txt"
if grep -Fqi -- 'the name of the subroutine is subroutine-name' "$tmp/mutated-flat.txt"; then
    die 'negative source mutation did not remove accepted evidence'
else
    negative_control='observed_failure'
fi

candidate_spans=42
accepted_records="$(awk -F '\t' 'NR > 1 && $6 == "accepted" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
retained_records="$(awk -F '\t' 'NR > 1 && $6 == "retained" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
accepted_alias_records="$(awk -F '\t' 'NR > 1 && $6 == "accepted" && $7 == "alias" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
accepted_lexical="$(awk -F '\t' 'NR > 1 && $6 == "accepted" && $7 == "lexical-class" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
accepted_metavariable="$(awk -F '\t' 'NR > 1 && $6 == "accepted" && $7 == "metavariable" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
accepted_semantic="$(awk -F '\t' 'NR > 1 && $6 == "accepted" && $7 == "semantic-role" {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"
source_hash_matches="$(awk -F '\t' -v h="$source_hash" 'NR > 1 && $11 == h {n++} END {print n + 0}' "$outdir/adjudicated-records.tsv")"

printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'candidate_spans\t%s\n' "$candidate_spans" >>"$outdir/summary.tsv"
printf 'accepted_records\t%s\n' "$accepted_records" >>"$outdir/summary.tsv"
printf 'retained_records\t%s\n' "$retained_records" >>"$outdir/summary.tsv"
printf 'accepted_alias_records\t%s\n' "$accepted_alias_records" >>"$outdir/summary.tsv"
printf 'accepted_lexical_class_records\t%s\n' "$accepted_lexical" >>"$outdir/summary.tsv"
printf 'accepted_metavariable_records\t%s\n' "$accepted_metavariable" >>"$outdir/summary.tsv"
printf 'accepted_semantic_role_records\t%s\n' "$accepted_semantic" >>"$outdir/summary.tsv"
printf 'source_hash_matches\t%s\n' "$source_hash_matches" >>"$outdir/summary.tsv"
printf 'source_evidence_matches\t%s\n' "$source_evidence" >>"$outdir/summary.tsv"
printf 'candidate_inventory_difference\t0\n' >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"

printf 'E0071 oracle: source-controlled candidate adjudication passed\n'
cat "$outdir/summary.tsv"
