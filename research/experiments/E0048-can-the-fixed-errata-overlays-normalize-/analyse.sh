#!/usr/bin/env bash
# Normalize the punctuation residue and inventory R401/R403 terms.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
audit="${UNRESOLVED_AUDIT:-$root/.cache/runs/E0022/R000001/reference-audit.tsv}"
base_errata="$root/research/errata/j3-24-007.json"
extension_errata="$root/research/errata/j3-24-007-r1123.json"
outdir="${2:-$root/.cache/runs/E0048/R000001}"

source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
input_hash="c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
canonical_hash="1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
audit_hash="28eb6876a77345cd85de14cf23a1d9027beefc2cb7a4de5756a9f28c40d1a449"
base_errata_hash="df1a5320637f2e850e59a680a4467287193c48ee789585dff5aea438b4eaef99"
extension_errata_hash="072e0104b68c2303f2ca56e83764f92f4840a73cd0ccc5eea782c90f19fca4dc"

die() { printf 'E0048: %s\n' "$1" >&2; exit 1; }
test "$(sha256sum "$input" | cut -d' ' -f1)" = "$input_hash" || die 'StandardIR input hash mismatch'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'canonical text hash mismatch'
test "$(sha256sum "$audit" | cut -d' ' -f1)" = "$audit_hash" || die 'audit hash mismatch'
test "$(sha256sum "$base_errata" | cut -d' ' -f1)" = "$base_errata_hash" || die 'base errata hash mismatch'
test "$(sha256sum "$extension_errata" | cut -d' ' -f1)" = "$extension_errata_hash" || die 'extension errata hash mismatch'

for errata in "$base_errata" "$extension_errata"; do
    jq -e 'all(.entries[]; .status == "accepted" and .kind == "source-repair" and .origin == "LLM" and .decision_id == "D0025")' \
        "$errata" >/dev/null || die "errata policy metadata mismatch: $errata"
done

for excerpt in \
    'R401 xyz-list is xyz [ , xyz ] ...' \
    'R403 scalar-xyz is xyz' \
    'C401 (R403) scalar-xyz shall be scalar.' \
    'R1123 loop-control is [ , ] do-variable = scalar-int-expr, scalar-int-expr'; do
    rg -F -q "$excerpt" "$canonical" || die "missing normative source excerpt: $excerpt"
done

mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
map="$tmp/errata-map.tsv"
{
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation, .id, .origin, .decision_id] | @tsv' "$base_errata"
    jq -r '.entries[] | [.source_term, .repaired_term, .punctuation, .id, .origin, .decision_id] | @tsv' "$extension_errata"
} | sort -t $'\t' -k1,1 >"$map"
test "$(wc -l < "$map")" -eq 8 || die 'errata entry count differs'

# Apply errata only to the derived audit view. The original audit remains the
# pinned source record. Duplicate normalized names are retained as rows and
# aggregated by the inventory below.
awk -F '\t' '
    BEGIN { while ((getline < ARGV[1]) > 0) map[$1]=$2; close(ARGV[1]); ARGV[1]="" }
    FNR == 1 { print; next }
    {
        name=$1
        if (name in map) { repairs++; name=map[name] }
        $1=name
        OFS="\t"
        print
    }
    END { if (repairs != 8) exit 1 }
' "$map" "$audit" >"$outdir/normalized-audit.tsv" || die 'errata normalization failed'

awk -F '\t' 'NR > 1 {seen[$1]=1} END {for (name in seen) count++; print count}' "$outdir/normalized-audit.tsv" >"$tmp/normalized-count"
normalized_unique=$(<"$tmp/normalized-count")
test "$normalized_unique" -eq 178 || die 'normalized audit denominator differs'

# Extract the first normalized reference occurrence with its StandardIR
# provenance. This is independent of the audit aggregation.
awk -F '\t' '
    BEGIN { while ((getline < ARGV[1]) > 0) map[$1]=$2; close(ARGV[1]); ARGV[1]="" }
    /^\(syntax / {
        rule=$2; gsub(/[()]/, "", rule)
        clause=""; page=""
        if (match($0, /\(clause [^)]*\)/)) { clause=substr($0,RSTART,RLENGTH); sub(/^\(clause /,"",clause); sub(/\)$/,"",clause) }
        if (match($0, /\(page [0-9]+\)/)) { page=substr($0,RSTART,RLENGTH); sub(/^\(page /,"",page); sub(/\)$/,"",page) }
        rest=$0
        while (match(rest, /\(ref [^)]*\)/)) {
            name=substr(rest,RSTART,RLENGTH); sub(/^\(ref /,"",name); sub(/\)$/,"",name)
            if (name in map) name=map[name]
            if (!(name in seen)) print name "\t" clause "\t" rule "\t" page
            seen[name]=1
            rest=substr(rest,RSTART+RLENGTH)
        }
    }
' "$map" "$input" | sort -t $'\t' -k1,1 >"$tmp/reference-evidence.tsv"

awk '/^\(syntax / {name=$4; gsub(/[()]/, "", name); print name}' "$input" \
    | sort -u >"$tmp/definitions"

awk -F '\t' '
    FILENAME == ARGV[1] {
        if (FNR > 1) {
            name=$1
            rows[name]+=$2
            rules[name]+=$3
            lines[name]+=$4
            standard[name]=$5
            kaby[name]=$6
        }
        next
    }
    FILENAME == ARGV[2] {
        evidence_clause[$1]=$2
        evidence_rule[$1]=$3
        evidence_page[$1]=$4
        next
    }
    FILENAME == ARGV[3] {
        definitions[$1]=1
        next
    }
    END {
        print "source_term\tfamily\tbase_term\tref_occurrences\treferring_rules\tcanonical_lines\tstandard_present\tkaby76_present\tevidence_clause\tevidence_rule\tevidence_page\tsource_sha256\torigin\tresolution_state"
        for (name in rows) {
            if (name ~ /-list$/) {
                family="R401"
                base=substr(name, 1, length(name) - 5)
            } else if (name ~ /^scalar-/) {
                family="R403"
                base=substr(name, 8)
            } else {
                continue
            }
            if (base == "" || !(name in evidence_clause)) bad=1
            if (name in definitions) conflicts++
            print name "\t" family "\t" base "\t" rows[name] "\t" rules[name] "\t" lines[name] "\t" standard[name] "\t" kaby[name] "\t" evidence_clause[name] "\t" evidence_rule[name] "\t" evidence_page[name] "\t7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2\tMECHANICAL\tunresolved"
            if (family == "R401") r401++
            if (family == "R403") r403++
        }
        if (r401 != 80 || r403 != 20 || conflicts != 0 || bad) exit 1
    }
' "$outdir/normalized-audit.tsv" "$tmp/reference-evidence.tsv" "$tmp/definitions" >"$tmp/inventory-unsorted.tsv" || die 'expansion inventory construction failed'
{
    head -n 1 "$tmp/inventory-unsorted.tsv"
    tail -n +2 "$tmp/inventory-unsorted.tsv" | sort -t $'\t' -k1,1
} >"$outdir/expansion-inventory.tsv"

# Independently reconstruct the selected set from the normalized audit and
# compare it with the inventory. No parser representation is selected here.
awk -F '\t' 'NR > 1 && ($1 ~ /-list$/ || $1 ~ /^scalar-/) {print $1}' "$outdir/normalized-audit.tsv" | sort -u >"$tmp/expected.tsv"
awk -F '\t' 'NR > 1 {print $1}' "$outdir/expansion-inventory.tsv" | sort -u >"$tmp/actual.tsv"
diff -u "$tmp/expected.tsv" "$tmp/actual.tsv" >/dev/null || die 'independent expansion set differs'

awk -F '\t' 'NR == 1 {next} $2 == "R401" && $3 == "" {bad=1} $2 == "R403" && $3 == "" {bad=1} END {exit bad}' "$outdir/expansion-inventory.tsv" || die 'invalid expansion base term'

# Mutating one normative family must be detected.
awk -F '\t' 'BEGIN {OFS="\t"} NR == 1 {print; next} NR == 2 {$2="R403"} {print}' "$outdir/expansion-inventory.tsv" >"$tmp/mutated.tsv"
if awk -F '\t' 'NR > 1 && $1 ~ /-list$/ && $2 != "R401" {bad=1} END {exit (bad ? 1 : 0)}' "$tmp/mutated.tsv"; then
    die 'negative control did not fail'
else
    negative_control="observed_failure"
fi

records="$(awk 'END {print NR - 1}' "$outdir/expansion-inventory.tsv")"
r401="$(awk -F '\t' 'NR > 1 && $2 == "R401" {n++} END {print n + 0}' "$outdir/expansion-inventory.tsv")"
r403="$(awk -F '\t' 'NR > 1 && $2 == "R403" {n++} END {print n + 0}' "$outdir/expansion-inventory.tsv")"
printf 'metric\tvalue\n' >"$outdir/summary.tsv"
printf 'original_audit_unique_names\t181\n' >>"$outdir/summary.tsv"
printf 'normalized_audit_unique_names\t%s\n' "$normalized_unique" >>"$outdir/summary.tsv"
printf 'errata_records\t8\n' >>"$outdir/summary.tsv"
printf 'errata_repairs\t8\n' >>"$outdir/summary.tsv"
printf 'expansion_records\t%s\n' "$records" >>"$outdir/summary.tsv"
printf 'r401_records\t%s\n' "$r401" >>"$outdir/summary.tsv"
printf 'r403_records\t%s\n' "$r403" >>"$outdir/summary.tsv"
printf 'explicit_definition_conflicts\t0\n' >>"$outdir/summary.tsv"
printf 'source_witness_matches\t%s\n' "$records" >>"$outdir/summary.tsv"
printf 'independent_difference\t0\n' >>"$outdir/summary.tsv"
printf 'representation_selection\tdeferred_D0024\n' >>"$outdir/summary.tsv"
printf 'negative_control\t%s\n' "$negative_control" >>"$outdir/summary.tsv"
printf 'E0048 oracle: fixed errata normalization and R401/R403 inventory passed\n'
cat "$outdir/summary.tsv"
