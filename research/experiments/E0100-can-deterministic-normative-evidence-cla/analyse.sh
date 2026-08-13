#!/usr/bin/env bash
# Deterministic-only evidence inventory for the E0022 unresolved-name set.
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standardir="${STANDARDIR:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
audit="${UNRESOLVED_AUDIT:-$root/.cache/runs/E0022/R000001/reference-audit.tsv}"
outdir="${1:-$root/.cache/runs/E0100/R000001}"
source_hash=7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2
standardir_hash=c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7
canonical_hash=1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e
audit_hash=28eb6876a77345cd85de14cf23a1d9027beefc2cb7a4de5756a9f28c40d1a449
die() { printf 'E0100: %s\n' "$1" >&2; exit 1; }
for f in "$standardir" "$canonical" "$audit"; do test -f "$f" || die "missing pinned input: $f"; done
test "$(sha256sum "$standardir" | cut -d' ' -f1)" = "$standardir_hash" || die 'E0013 hash mismatch'
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$canonical_hash" || die 'E0001 hash mismatch'
test "$(sha256sum "$audit" | cut -d' ' -f1)" = "$audit_hash" || die 'E0022 hash mismatch'
mkdir -p "$outdir"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# Independent denominator: collect all refs and subtract every lhs in E0013.
awk '{s=$0; while (match(s, /\(lhs [^ )]+\)/)) {x=substr(s,RSTART+5,RLENGTH-6); lhs[x]=1; s=substr(s,RSTART+RLENGTH)}; s=$0; while (match(s, /\(ref [^ )]+\)/)) {x=substr(s,RSTART+5,RLENGTH-6); refs[x]=1; s=substr(s,RSTART+RLENGTH)}} END {for(x in refs) if (!(x in lhs)) print x}' "$standardir" | sort >"$tmp/e0013.names"
awk -F '\t' 'NR > 1 {print $1}' "$audit" | sort -u >"$tmp/e0022.names"
diff -u "$tmp/e0022.names" "$tmp/e0013.names" >"$outdir/denominator.diff" || die 'E0013/E0022 denominator sets differ'
test "$(wc -l <"$tmp/e0013.names")" -eq 181 || die 'denominator is not 181'

# Primary scan. Every retained span has the source document hash and canonical line/page.
awk -F '\t' -v OFS='\t' -v audit="$audit" -v sh="$source_hash" '
 function norm(x) { if (x !~ /^[[:punct:]]+$/) sub(/[[:punct:]]+$/, "", x); return tolower(x) }
 function has(t,w, p,b,a,tail) { if (w ~ /^[[:punct:]]+$/) return index(" " t " "," " w " ") > 0; tail=t; while ((p=index(tail,w))) {b=(p==1?"":substr(tail,p-1,1)); a=substr(tail,p+length(w),1); if (b !~ /[a-z0-9_-]/ && a !~ /[a-z0-9_-]/) return 1; tail=substr(tail,p+length(w))} return 0 }
 function emit(t,n,k,l,p,x,ref) { ref="-"; if (match(x, /[RC][0-9][0-9]+/)) ref=substr(x,RSTART,RLENGTH); gsub(/[\t\r]/," ",x); print t,n,k,l,p,ref,sh,"MECHANICAL",x }
 FILENAME==audit {if(FNR>1){term[++n]=$1; key[$1]=norm($1)}; next}
 {if(index($0,"\f")) page++; x=$0; gsub(/\f/," ",x); low=tolower(x); for(i=1;i<=n;i++){t=term[i]; w=key[t]; if(!has(low,w)) continue; k="";
   if (index(low,w " is one of ")) k="one-of";
   else if (low ~ "^[[:space:][:punct:]]*" w "[[:space:][:punct:]]+(is|means|shall|must|may)" || index(low,w " is ") || index(low,w " means ")) k="definition";
   else if ((index(low,",") && index(low,";") ) || index(low,"|") || low ~ /[[:space:]][[:space:]][[:space:]]+/) k="list-table";
   else if (match(low,w) && (low ~ /[([][[:space:]]*[rc][0-9][0-9]+/ || low ~ /[[:space:]](see|clause|subclause)[[:space:]]/)) k="nearby-reference";
   if(k!="") emit(t,w,k,FNR,page,x)
 }}' "$audit" "$canonical" >"$outdir/candidate-spans.tsv"

printf 'name\tnormalized\tclassification\tcandidate_spans\tkinds\taudit_ref_occurrences\taudit_referring_rules\taudit_canonical_lines\tsource_hash\torigin\n' >"$outdir/classifications.tsv"
awk -F '\t' -v OFS='\t' -v spans="$outdir/candidate-spans.tsv" -v sh="$source_hash" '
 FILENAME==ARGV[1] {if(FNR>1){n++;t[n]=$1; norm[$1]=$1; sub(/[[:punct:]]+$/,"",norm[$1]); occ[$1]=$2; rr[$1]=$3; cl[$1]=$4}; next}
 {if(!($1 in c)) c[$1]=0; c[$1]++; if(!seen[$1 SUBSEP $3]++){k[$1]=k[$1](k[$1]?",":"")$3; nk[$1]++}}
 END {for(i=1;i<=n;i++){x=t[i]; cls=(c[x]==0?"no candidate":(c[x]==1?"mechanically-supported candidate":"ambiguous candidate")); print x,tolower(norm[x]),cls,c[x]+0,(k[x]?k[x]:"-"),occ[x],rr[x],cl[x],sh,"MECHANICAL"}}' "$audit" "$outdir/candidate-spans.tsv" | sort -t $'\t' -k1,1 >>"$outdir/classifications.tsv"

# Independent candidate pair traversal, deliberately separate from span emission.
awk -F '\t' -v OFS='\t' -v audit="$audit" '
 function has(l,z, p,b,a,tail) {if(z ~ /^[[:punct:]]+$/) return index(" " l " "," " z " ")>0; tail=l; while((p=index(tail,z))){b=(p==1?"":substr(tail,p-1,1));a=substr(tail,p+length(z),1);if(b !~ /[a-z0-9_-]/ && a !~ /[a-z0-9_-]/) return 1;tail=substr(tail,p+length(z))}return 0}
 FILENAME==audit{if(FNR>1){t[++n]=$1;w[$1]=$1;if($1 !~ /^[[:punct:]]+$/)sub(/[[:punct:]]+$/, "",w[$1]);w[$1]=tolower(w[$1])};next}
 {l=tolower($0);for(i=1;i<=n;i++){x=t[i];z=w[x];if(!has(l,z))continue;if(index(l,z " is one of ") || index(l,z " is ") || index(l,z " means ") || l ~ "^[[:space:][:punct:]]*" z "[[:space:][:punct:]]+(shall|must|may)" || ((index(l,",")&&index(l,";"))||index(l,"|")) || (l ~ /[([][[:space:]]*[rc][0-9][0-9]+/ || l ~ /[[:space:]](see|clause|subclause)[[:space:]]/)) print x,"candidate"}}' "$audit" "$canonical" | sort -u >"$tmp/independent.tsv"
cp "$tmp/independent.tsv" "$outdir/independent-candidates.tsv"
awk -F '\t' -v OFS='\t' '{print $1,"candidate"}' "$outdir/candidate-spans.tsv" | sort -u >"$tmp/primary.tsv"
diff -u "$tmp/primary.tsv" "$tmp/independent.tsv" >"$outdir/candidate.diff" || die 'independent candidate sets differ'

rows=$(awk -F '\t' 'NR>1{n++}END{print n+0}' "$outdir/classifications.tsv")
spans=$(wc -l <"$outdir/candidate-spans.tsv")
supported=$(awk -F '\t' '$3=="mechanically-supported candidate"{n++}END{print n+0}' "$outdir/classifications.tsv")
ambiguous=$(awk -F '\t' '$3=="ambiguous candidate"{n++}END{print n+0}' "$outdir/classifications.tsv")
none=$(awk -F '\t' '$3=="no candidate"{n++}END{print n+0}' "$outdir/classifications.tsv")
printf 'metric\tvalue\nstandardir_unresolved_names\t%s\naudit_unresolved_names\t%s\ndenominator_difference\t0\ncandidate_spans\t%s\nmechanically_supported_candidates\t%s\nambiguous_candidates\t%s\nno_candidates\t%s\nmodel_calls\t0\nalias_promotions\t0\n' "$rows" "$rows" "$spans" "$supported" "$ambiguous" "$none" >"$outdir/summary.tsv"
test "$rows" -eq 181 || die 'classification rows differ from denominator'
report="$root/research/experiments/E0100-can-deterministic-normative-evidence-cla/report.md"
{
    printf '# E0100 report\n\n'
    printf 'This report is regenerated by `research/experiments/E0100-can-deterministic-normative-evidence-cla/analyse.sh`. The run makes zero LLM calls and never promotes a candidate into a StandardIR alias.\n\n'
    printf '## Question\n\nCan deterministic normative evidence classify every E0022 unresolved name without promoting aliases?\n\n'
    printf '## Inputs and method\n\nThe run uses only the committed E0013 StandardIR, E0001 canonical normative text, and E0022 audit. It independently extracts unresolved `(ref ...)` names from E0013, subtracts E0013 `(lhs ...)` names, and compares that set with E0022. Canonical lines are searched for name-headed definitions, `X is ...`, `X means ...`, `X is one of ...`, simple list/table-like structure, and same-line nearby source references. All matching spans are retained as evidence only. One span is a **mechanically-supported candidate**, more than one is an **ambiguous candidate**, and none is **no candidate**.\n\n'
    printf '## Result\n\n| Metric | Value |\n|---|---:|\n| E0013-derived unresolved names | %s |\n| E0022 audit names | %s |\n| Denominator set difference | 0 |\n| Candidate source spans | %s |\n| Mechanically-supported candidates | %s |\n| Ambiguous candidates | %s |\n| No candidate | %s |\n| LLM calls | 0 |\n| Alias promotions | 0 |\n\n' "$rows" "$rows" "$spans" "$supported" "$ambiguous" "$none"
    printf 'The complete 181-row classification table follows. The `source_hash` is the J3/24-007 source hash; `audit_*` fields are carried from E0022 without importing its historical comparison columns.\n\n'
    printf '| Name | Classification | Spans | Kinds | Audit occurrences | Referring rules | Canonical lines |\n|---|---|---:|---|---:|---:|---:|\n'
    awk -F '\t' 'NR>1 {printf "| `%s` | %s | %s | %s | %s | %s | %s |\n",$1,$3,$4,$5,$6,$7,$8}' "$outdir/classifications.tsv"
    printf '\n## Evidence examples\n\n'
    awk -F '\t' 'NR>1 && $3=="definition" {printf "- `%s`: line %s, page %s — %s\n",$1,$4,$5,$9; n++; if(n==3) exit}' "$outdir/candidate-spans.tsv"
    awk -F '\t' 'NR>1 && $3=="one-of" {printf "- `%s`: line %s, page %s — %s\n",$1,$4,$5,$9; n++; if(n==3) exit}' "$outdir/candidate-spans.tsv"
    awk -F '\t' 'NR>1 && $3=="list-table" {printf "- `%s`: line %s, page %s — %s\n",$1,$4,$5,$9; n++; if(n==3) exit}' "$outdir/candidate-spans.tsv"
    printf '\n## Limitations\n\nThis is lexical evidence inventory, not semantic adjudication. A matching line may describe a use, a token, or a different grammatical role; multiple spans therefore remain ambiguous. The list/table heuristic is intentionally shallow and does not reconstruct table geometry or cross-line definitions. Nearby references are same-line markers, not proof that a referenced rule defines the name. No comparison repositories, comparison columns, aliases, grammar productions, or StandardIR semantic facts are claimed.\n'
} >"$report"
printf 'E0100 deterministic gate passed\n'; cat "$outdir/summary.tsv"
