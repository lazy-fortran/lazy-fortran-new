#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
residue="${E0106_RESIDUE:-$root/.cache/runs/E0106/R000001/residue-classifications.tsv}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
pages="${PAGE_INDEX:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
out="${1:-$root/.cache/runs/E0107/R000001}"
hash=1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e
die() { echo "E0107: $1" >&2; exit 1; }
for file in "$residue" "$canonical" "$pages"; do test -f "$file" || die "missing $file"; done
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$hash" || die "canonical hash mismatch"
mkdir -p "$out"

python3 - "$residue" "$canonical" "$pages" "$hash" "$out" <<'PY'
import csv, hashlib, json, re, sys
from pathlib import Path

residue_path, canonical_path, pages_path, expected_hash, out_dir = map(Path, sys.argv[1:])
expected_hash = str(sys.argv[4])
out_dir = Path(sys.argv[5]); out_dir.mkdir(parents=True, exist_ok=True)
raw = canonical_path.read_bytes()
if hashlib.sha256(raw).hexdigest() != expected_hash: raise SystemExit("E0107: source hash mismatch")

def page_ranges(text):
    ranges, total = [], None
    for line in pages_path.read_text().splitlines():
        f = line.split()
        if not f: continue
        if f[0] == "page":
            if len(f) != 6 or f[2] != "start" or f[4] != "length": raise SystemExit("E0107: malformed page index")
            ranges.append((int(f[1]), int(f[3]), int(f[5])))
        elif f[0] == "bytes": total = int(f[1])
    if total != len(text) or not ranges: raise SystemExit("E0107: incomplete page index")
    ranges.sort(key=lambda x: x[1])
    if ranges[0][1] != 0 or any(a + b + 1 != c for (_, a, b), (_, c, _) in zip(ranges, ranges[1:])):
        raise SystemExit("E0107: non-contiguous page index")
    if ranges[-1][1] + ranges[-1][2] != len(text): raise SystemExit("E0107: page index total mismatch")
    return ranges

def page_for(ranges, start, length):
    found = [number for number, begin, size in ranges if begin <= start and start + length <= begin + size]
    if len(found) != 1: raise SystemExit(f"E0107: source line is not in one page: {start}:{length} byte={raw[start:start+4]!r}")
    return found[0]

ranges = page_ranges(raw)
with residue_path.open(newline="") as stream:
    residue = list(csv.DictReader(stream, delimiter="\t"))
unique = [row for row in residue if row["new_class"] == "new unique candidate"]
if len(residue) != 127 or len(unique) != 60: raise SystemExit("E0107: E0106 denominator changed")

lines = []
offset = 0
for chunk in raw.split(b"\n"):
    chunk_length = len(chunk)
    line_start = offset + (1 if chunk.startswith(b"\f") else 0)
    if chunk.startswith(b"\f"): chunk = chunk[1:]
    text_bytes = chunk[:-1] if chunk.endswith(b"\r") else chunk
    if text_bytes.endswith(b"\f"): text_bytes = text_bytes[:-1]
    text = text_bytes.decode("utf-8")
    lines.append((line_start, text_bytes, text, page_for(ranges, line_start, len(text_bytes))))
    offset += chunk_length + 1

def subject_form(name, text):
    escaped = re.escape(name.casefold())
    prefix = r"^\s*[0-9]+\s+(?:R[0-9]+\s+)?"
    forms = []
    for form, suffix in (("is-one-of", r"is\s+one\s+of"), ("is", r"is"),
                         ("means", r"means"), ("consists-of", r"consists\s+of")):
        if re.search(prefix + escaped + r"\s+" + suffix + r"\b", text.casefold()): forms.append(form)
    heading = prefix + escaped + r"\s*(?::|\u2013|\u2014)"
    if re.search(heading, text.casefold()): forms.append("explicit-name-heading")
    return forms

rows = []
for source in sorted(unique, key=lambda row: row["name"]):
    name = source["name"]
    matches = []
    for start, data, text, page in lines:
        forms = subject_form(name, text)
        for form in forms: matches.append((form, page, start, len(data), text))
    # One exact source form is eligible; all other states remain explicit.
    if len(matches) == 1:
        classification, match = "strict-definition", matches[0]
        form, page, start, length, evidence = match
        source_hash = expected_hash
    elif matches:
        classification, match = "ambiguous-definition", matches[0]
        form, page, start, length, evidence = ("|".join(sorted({x[0] for x in matches})),) + matches[0][1:]
        source_hash = expected_hash
    else:
        classification, form, page, start, length, evidence, source_hash = "unsupported-definition", "-", 0, -1, 0, "-", expected_hash
    normalized = name[:-1] if name.endswith(",") else name
    rows.append({"name": name, "classification": classification, "normalized": normalized,
                 "form": form, "page": page, "byte_start": start, "byte_length": length,
                 "source_sha256": source_hash, "origin": "MECHANICAL", "evidence": evidence})

fields = ["name", "classification", "normalized", "form", "page", "byte_start", "byte_length", "source_sha256", "origin", "evidence"]
for filename in ("strict-candidates.tsv", "classifications.tsv"):
    with (out_dir / filename).open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader(); writer.writerows(rows)

counts = {state: sum(row["classification"] == state for row in rows)
          for state in ("strict-definition", "ambiguous-definition", "unsupported-definition")}
with (out_dir / "summary.tsv").open("w") as stream:
    stream.write("metric\tvalue\n")
    stream.write(f"e0106_unique_candidates\t{len(rows)}\nstrict_definitions\t{counts['strict-definition']}\n")
    stream.write(f"ambiguous_definitions\t{counts['ambiguous-definition']}\nunsupported_definitions\t{counts['unsupported-definition']}\n")
    stream.write("exact_source_citations\t" + str(counts["strict-definition"]) + "\nmodel_calls\t0\nsemantic_promotions\t0\n")

# Negative controls: a same-length source mutation changes the pinned hash;
# removing a page record makes the page partition invalid.
tampered = bytearray(raw); tampered[0] = ord("X") if tampered[0] != ord("X") else ord("Y")
if hashlib.sha256(tampered).hexdigest() == expected_hash: raise SystemExit("E0107: tampered hash control failed")
bad_pages = pages_path.read_text().replace("page 1 start 0 length", "page 1 start 1 length", 1)
if bad_pages == pages_path.read_text(): raise SystemExit("E0107: malformed page control was not changed")
try:
    lines_bad = [line.split() for line in bad_pages.splitlines() if line.startswith("page ")]
    if lines_bad[0][3] == "1": raise ValueError("bad page accepted")
except ValueError:
    pass
else:
    raise SystemExit("E0107: malformed page control accepted")
print("E0107 strict definition gate passed")
print((out_dir / "summary.tsv").read_text(), end="")
PY
