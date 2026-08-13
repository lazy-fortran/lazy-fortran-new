#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
canon="${CANONICAL_TEXT:-$root/../lazy-fortran-new/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
cls="${E0100_CLASSIFICATIONS:-$root/../lazy-fortran-new/.cache/runs/E0100/R000001/classifications.tsv}"
spans="${E0100_SPANS:-$root/../lazy-fortran-new/.cache/runs/E0100/R000001/candidate-spans.tsv}"
out="${1:-$root/.cache/runs/E0104/R000001}"
ch=1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e
sh=7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2
die(){ echo "E0104: $1" >&2; exit 1; }
for f in "$canon" "$cls" "$spans"; do test -f "$f" || die "missing input $f"; done
test "$(sha256sum "$canon"|cut -d' ' -f1)" = "$ch" || die 'canonical hash mismatch'
test "$(sha256sum "$cls"|cut -d' ' -f1)" = e41b87ff8561ffe6b250ddeaa4cec5539d19088b88c9aa949b6b428433e7103a || die 'E0100 classifications hash mismatch'
test "$(sha256sum "$spans"|cut -d' ' -f1)" = c458c523f4b5a7fb4edbb555823131210ebd1ec1e0322b5ed9ba7d7b5cb4f1c1 || die 'E0100 spans hash mismatch'
mkdir -p "$out"; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
awk -F '\t' 'NR==1{next} $3!="mechanically-supported candidate"{print $1"\t"$3}' "$cls" | sort -u >"$tmp/residue.tsv"
test "$(wc -l <"$tmp/residue.tsv")" -eq 127 || die 'residue is not 127 rows'

# Generic normative cues only. The source is split into physical lines; a
# window is accepted only when the term occurs in the window and the cue is in
# the same or an adjacent/continuing line. No rule identifiers or suffixes are
# used here.
python3 - "$tmp/residue.tsv" "$canon" "$out/new-spans.tsv" "$ch" <<'PY'
import re, sys
from pathlib import Path
residue, canonical, output, source_hash = map(Path, sys.argv[1:])
terms = {line.split("\t", 1)[0] for line in residue.read_text().splitlines()}
lines = canonical.read_text().split("\n")
pages, page = [], 0
for line in lines:
    pages.append(page)
    if "\f" in line:
        page += 1
cue_re = re.compile(r"(?:^|[.;:])\s*(?:is|means|denotes|refers to|consists of|shall|must|may|is defined|is specified|is described)|\s(?:is|means|denotes|refers to|consists of|shall|must|may)\s", re.I)
def hit(term, text):
    if re.fullmatch(r"[^\w\s]+", term):
        return f" {term.lower()} " in f" {text.lower()} "
    return re.search(r"(?<![a-z0-9_-])" + re.escape(term.lower()) + r"(?![a-z0-9_-])", text.lower()) is not None
rows = []
for term in sorted(terms):
    for i, line in enumerate(lines):
        following = lines[i + 1:i + 3]
        window = " ".join([line, *following])
        pattern = None
        end = i
        if hit(term, line) and cue_re.search(line):
            pattern = "baseline-line"
        elif i + 1 < len(lines) and hit(term, lines[i + 1]) and cue_re.search(line + " " + lines[i + 1]):
            pattern, end = "adjacent-line", i + 1
        elif hit(term, line) and i + 1 < len(lines) and cue_re.search(lines[i + 1]):
            pattern, end = "adjacent-line", i + 1
        elif hit(term, window) and cue_re.search(window):
            pattern, end = "two-line-window", min(i + 2, len(lines) - 1)
        elif i + 1 < len(lines) and hit(term, line + " " + lines[i + 1]) and (line.rstrip().endswith((",", ";", ":")) or lines[i + 1][:1].islower()) and cue_re.search(line + " " + lines[i + 1]):
            pattern, end = "sentence-continuation", i + 1
        if pattern:
            text = " ".join(lines[i:end + 1]).replace("\f", " ").replace("\t", " ").replace("\r", " ")
            rows.append((term, pattern, i + 1, end + 1, pages[i], pages[end], source_hash, "MECHANICAL", re.sub(r"\s+", " ", text).strip()))
with output.open("w") as f:
    for row in sorted(rows, key=lambda x: (x[0], x[2], x[1])):
        f.write("\t".join(map(str, row)) + "\n")
PY
printf 'name\tbaseline_class\tnew_class\tnew_spans\tpatterns\tline_ranges\tpage_ranges\tsource_hash\torigin\n' >"$out/classifications.tsv"
awk -F '\t' -v OFS='\t' -v spans="$out/new-spans.tsv" -v hash="$ch" 'FILENAME==ARGV[1]{b[$1]=$2;n++;next}{c[$1]++;p[$1]=p[$1](p[$1]?",":"")$2;r[$1]=r[$1](r[$1]?";":"")$3"-"$4;q[$1]=q[$1](q[$1]?";":"")$5"-"$6}END{for(x in b){k=(c[x]? (c[x]==1?"new unique candidate":"new ambiguous candidate"):"new no candidate");print x,b[x],k,c[x]+0,(p[x]?p[x]:"-"),(r[x]?r[x]:"-"),(q[x]?q[x]:"-"),hash,"MECHANICAL"}}' "$tmp/residue.tsv" "$out/new-spans.tsv" | sort -t $'\t' -k1,1 >>"$out/classifications.tsv"

# Independent traversal: distinct candidate keys only, with separate line/page
# bookkeeping and no use of new-spans.tsv.
python3 - "$tmp/residue.tsv" "$canon" "$out/independent-candidates.tsv" <<'PY'
import re, sys
from pathlib import Path
residue, canonical, output = map(Path, sys.argv[1:])
terms = {line.split("\t", 1)[0] for line in residue.read_text().splitlines()}
lines = canonical.read_text().split("\n")
cue = re.compile(r"(?:^|[.;:])\s*(?:is|means|denotes|refers to|consists of|shall|must|may)|\s(?:is|means|denotes|refers to|consists of|shall|must|may)\s", re.I)
def hit(term, text):
    return re.search(re.escape(term.lower()), text.lower()) is not None
keys = set()
for term in terms:
    for i, line in enumerate(lines):
        window = " ".join(lines[i:i + 3])
        if hit(term, window) and cue.search(window):
            keys.add(term)
            break
output.write_text("".join(term + "\n" for term in sorted(keys)))
PY
awk -F '\t' '$1!=""{print $1}' "$out/new-spans.tsv" | sort -u >"$tmp/primary.keys"; diff -u "$tmp/primary.keys" "$out/independent-candidates.tsv" >"$out/independent.diff" || die 'independent traversal differs'
rows=$(awk 'END{print NR-1}' "$out/classifications.tsv"); unique=$(awk -F '\t' '$3=="new unique candidate"{n++}END{print n+0}' "$out/classifications.tsv"); amb=$(awk -F '\t' '$3=="new ambiguous candidate"{n++}END{print n+0}' "$out/classifications.tsv"); none=$(awk -F '\t' '$3=="new no candidate"{n++}END{print n+0}' "$out/classifications.tsv"); total=$(wc -l <"$out/new-spans.tsv")
printf 'metric\tvalue\ne0100_residue_rows\t%s\ne0100_mechanically_supported_baseline\t54\ne0100_ambiguous_baseline\t46\ne0100_no_candidate_baseline\t81\nnew_unique_candidates\t%s\nnew_ambiguous_candidates\t%s\nnew_no_candidates\t%s\nretained_source_spans\t%s\nmodel_calls\t0\nalias_promotions\t0\n' "$rows" "$unique" "$amb" "$none" "$total" >"$out/summary.tsv"
test "$rows" -eq 127 || die 'classification rows differ'; cat "$out/summary.tsv"
