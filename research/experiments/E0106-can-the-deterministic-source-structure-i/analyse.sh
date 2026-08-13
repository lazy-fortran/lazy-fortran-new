#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
pages="${PAGE_INDEX:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
classes="${E0100_CLASSIFICATIONS:-$root/.cache/runs/E0100/R000001/classifications.tsv}"
out="${1:-$root/.cache/runs/E0106/R000001}"
hash=1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e
commit=ae2ee71c42d2da4cfea28c0093408e375317987b
die() { echo "E0106: $1" >&2; exit 1; }
for file in "$canonical" "$pages" "$classes"; do test -f "$file" || die "missing $file"; done
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$hash" || die "canonical hash mismatch"
test "$(git -C "$standard" rev-parse HEAD)" = "$commit" || die "standard-new commit mismatch"
mkdir -p "$out"
structure="$out/structure.jsonl"
(cd "$standard" && fo exec pdfstructure "$canonical" "$pages" "$structure" "$hash") >"$out/tool.log"

python3 - "$canonical" "$pages" "$structure" "$hash" "$out/structure-oracle.tsv" <<'PY'
import hashlib, json, sys
from pathlib import Path
canonical, pages, structure, oracle = map(Path, (sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[5]))
expected = sys.argv[4]
raw = canonical.read_bytes()
if hashlib.sha256(raw).hexdigest() != expected: raise SystemExit("canonical hash changed")
ranges = []
for line in pages.read_text().splitlines():
    f = line.split()
    if not f: continue
    if f[0] == "page":
        if len(f) != 6 or f[2] != "start" or f[4] != "length": raise SystemExit("bad page index")
        ranges.append((int(f[1]), int(f[3]), int(f[5])))
    elif f[0] == "bytes" and int(f[1]) != len(raw): raise SystemExit("page total mismatch")
allowed = {"section-heading", "rule-block-start", "rule-continuation", "cross-reference-block"}
records = []
with structure.open() as stream:
    header = json.loads(next(stream))
    if header != {"format": 1, "origin": "MECHANICAL", "source": "canonical-text", "source_sha256": expected}:
        raise SystemExit("header mismatch")
    for line in stream:
        record = json.loads(line)
        if record.get("kind") not in allowed or record.get("origin") != "MECHANICAL" or record.get("source_sha256") != expected:
            raise SystemExit("record provenance mismatch")
        start, length = record.get("byte_start"), record.get("byte_length")
        if not isinstance(start, int) or not isinstance(length, int) or raw[start:start + length].decode() != record.get("text"):
            raise SystemExit("record span mismatch")
        if not any(n == record.get("page") and b <= start and start + length <= b + size for n, b, size in ranges):
            raise SystemExit("record page mismatch")
        if any(key in record for key in ("alias", "relation", "semantic", "resolution")):
            raise SystemExit("semantic field in evidence")
        records.append(record)
with oracle.open("w") as output:
    output.write("kind\tpage\tbyte_start\tbyte_length\n")
    for record in records:
        output.write(f"{record['kind']}\t{record['page']}\t{record['byte_start']}\t{record['byte_length']}\n")
print(f"validated {len(records)} structure records")
PY

python3 - "$classes" "$structure" "$out/residue-classifications.tsv" "$out/independent-candidates.tsv" <<'PY'
import csv, json, re, sys
from pathlib import Path
classes, structure, output, independent = map(Path, sys.argv[1:])
residue = []
for row in csv.reader(classes.read_text().splitlines()[1:], delimiter="\t"):
    if len(row) >= 3 and row[2] != "mechanically-supported candidate": residue.append((row[0], row[2]))
if len(residue) != 127: raise SystemExit(f"expected 127 residue rows, got {len(residue)}")
with structure.open() as stream:
    next(stream); records = [json.loads(line) for line in stream]
def hit(term, text):
    term, text = term.casefold(), text.casefold()
    if re.fullmatch(r"[^\w\s]+", term): return f" {term} " in f" {text} "
    return re.search(r"(?<![\w-])" + re.escape(term) + r"(?![\w-])", text) is not None
matches = {name: [r for r in records if hit(name, r["text"])] for name, _ in residue}
with output.open("w") as stream:
    stream.write("name\tbaseline_class\tnew_class\tmatching_records\torigin\n")
    for name, baseline in residue:
        found = matches[name]
        kind = "new unique candidate" if len(found) == 1 else "new ambiguous candidate" if found else "new no candidate"
        refs = ",".join(f"{r['kind']}@{r['page']}:{r['byte_start']}" for r in found) or "-"
        stream.write(f"{name}\t{baseline}\t{kind}\t{refs}\tMECHANICAL\n")
independent_names = set()
with structure.open() as stream:
    next(stream)
    for line in stream:
        record = json.loads(line)
        words = set(re.findall(r"[A-Za-z][A-Za-z0-9_-]*|[^\w\s]", record["text"].casefold()))
        for name, _ in residue:
            term = name.casefold()
            if (term in record["text"].casefold() and
                    (re.fullmatch(r"[^\w\s]+", term) or
                     not re.search(r"[\w-]", term) or
                     re.search(r"(?<![\w-])" + re.escape(term) + r"(?![\w-])", record["text"].casefold()))):
                independent_names.add(name)
with independent.open("w") as stream:
    for name in sorted(independent_names): stream.write(name + "\n")
if sorted(name for name, found in matches.items() if found) != independent.read_text().splitlines():
    raise SystemExit("independent residue traversal differs")
PY

python3 - "$out/residue-classifications.tsv" "$out/summary.tsv" "$out/structure-oracle.tsv" <<'PY'
import csv, sys
from collections import Counter
with open(sys.argv[1], newline="") as stream: rows = list(csv.DictReader(stream, delimiter="\t"))
counts = Counter(row["new_class"] for row in rows)
with open(sys.argv[3]) as stream: kinds = Counter(line.split("\t", 1)[0] for line in stream if not line.startswith("kind\t"))
with open(sys.argv[2], "w") as output:
    output.write("metric\tvalue\n")
    output.write(f"e0100_residue_rows\t{len(rows)}\nstructure_records\t{sum(kinds.values())}\n")
    for kind in sorted(kinds): output.write(f"structure_records_by_kind_{kind}\t{kinds[kind]}\n")
    output.write(f"unique_residue_candidates\t{counts['new unique candidate']}\nambiguous_residue_candidates\t{counts['new ambiguous candidate']}\nno_residue_candidates\t{counts['new no candidate']}\nmodel_calls\t0\nsemantic_promotions\t0\n")
PY
cat "$out/summary.tsv"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$pages" "$tmp/bad.index"
sed -i 's/page 1 start 0 length/page 1 start 1 length/' "$tmp/bad.index"
set +e
(cd "$standard" && fo exec pdfstructure "$canonical" "$tmp/bad.index" "$tmp/bad.jsonl" "$hash") >"$tmp/bad.log" 2>&1
bad_status=$?
set -e
test "$bad_status" -ne 0 || die "malformed page index accepted"
python3 - "$canonical" "$tmp/tampered.txt" <<'PY'
from pathlib import Path
import sys
raw = bytearray(Path(sys.argv[1]).read_bytes())
raw[0] = ord("X") if raw[0] != ord("X") else ord("Y")
Path(sys.argv[2]).write_bytes(raw)
PY
set +e
(cd "$standard" && fo exec pdfstructure "$tmp/tampered.txt" "$pages" "$tmp/tampered.jsonl" "$hash") >"$tmp/tampered.log" 2>&1
tampered_status=$?
set -e
test "$tampered_status" -ne 0 || die "tampered source hash accepted"
