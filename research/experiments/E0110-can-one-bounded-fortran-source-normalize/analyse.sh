#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
residue="${E0106_RESIDUE:-$root/.cache/runs/E0106/R000001/residue-classifications.tsv}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
pages="${PAGE_INDEX:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
out="${1:-$root/.cache/runs/E0110/R000001}"
source_hash=1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e

die() { printf 'E0110: %s\n' "$1" >&2; exit 1; }
for file in "$residue" "$canonical" "$pages"; do
    test -f "$file" || die "missing $file"
done
test "$(sha256sum "$canonical" | cut -d' ' -f1)" = "$source_hash" || die "canonical hash mismatch"
mkdir -p "$out"

python3 - "$residue" "$canonical" "$pages" "$source_hash" "$out" <<'PY'
import csv
import hashlib
import re
import sys
from pathlib import Path

residue_path = Path(sys.argv[1])
canonical_path = Path(sys.argv[2])
pages_path = Path(sys.argv[3])
expected_hash = sys.argv[4]
out_dir = Path(sys.argv[5])
out_dir.mkdir(parents=True, exist_ok=True)
raw = canonical_path.read_bytes()
if hashlib.sha256(raw).hexdigest() != expected_hash:
    raise SystemExit("E0110: canonical source hash mismatch")


def fail(message):
    raise SystemExit("E0110: " + message)


def page_ranges(path, raw_length):
    ranges = []
    total = None
    separator_length = 0
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "page":
            if len(fields) != 6 or fields[2] != "start" or fields[4] != "length":
                fail(f"malformed page index line {line_number}")
            number, start, length = int(fields[1]), int(fields[3]), int(fields[5])
            if number < 1 or start < 0 or length < 1 or start + length > raw_length:
                fail(f"page range outside source at line {line_number}")
            ranges.append((number, start, length))
        elif fields[0] == "bytes":
            if len(fields) != 2 or not fields[1].isdigit():
                fail(f"malformed byte total at line {line_number}")
            total = int(fields[1])
        elif fields[0] == "separator":
            if fields != ["separator", "FORM-FEED"]:
                fail(f"unsupported page separator at line {line_number}")
            separator_length = 1
        elif fields[0] in {"canonical-format", "origin", "encoding", "pages"}:
            continue
        else:
            fail(f"unrecognized page index line {line_number}")
    if total != raw_length or not ranges:
        fail("page index does not cover canonical bytes")
    ranges.sort(key=lambda item: item[1])
    previous_end = 0
    seen = set()
    for number, start, length in ranges:
        expected_start = previous_end if not seen else previous_end + separator_length
        if number in seen or start != expected_start:
            fail("page index is not a contiguous unique partition")
        seen.add(number)
        previous_end = start + length
    if previous_end != raw_length:
        fail("page index final range does not reach canonical end")
    return ranges


def containing_page(ranges, start, length):
    hits = [number for number, begin, size in ranges
            if begin <= start and start + length <= begin + size]
    if len(hits) != 1:
        fail(f"span is not contained by one page: {start}:{length}")
    return hits[0]


def source_lines(ranges):
    result = []
    offset = 0
    for chunk in raw.split(b"\n"):
        chunk_length = len(chunk)
        start = offset + (1 if chunk.startswith(b"\f") else 0)
        if chunk.startswith(b"\f"):
            chunk = chunk[1:]
        if chunk.endswith(b"\r"):
            chunk = chunk[:-1]
        if chunk.endswith(b"\f"):
            chunk = chunk[:-1]
        text = chunk.decode("utf-8")
        result.append((start, chunk, text, containing_page(ranges, start, len(chunk))))
        offset += chunk_length + 1
    return result


def normalize_name(name):
    value = name.strip()
    if not value:
        return value, "none"
    match = re.fullmatch(r"([A-Za-z][A-Za-z0-9-]*)([,;:)\]}])", value)
    if match:
        return match.group(1), "strip-attached-grammar-punctuation-v1"
    return value, "none"


FORM_PATTERNS = (
    ("is-one-of", r"is\s+one\s+of"),
    ("is", r"is"),
    ("means", r"means"),
    ("consists-of", r"consists\s+of"),
)


def definition_matches(name, lines):
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9-]*", name):
        return []
    escaped = re.escape(name.casefold())
    prefix = rf"^\s*[0-9]+\s+(?:r[0-9]+\s+)?{escaped}\s+"
    matches = []
    for start, data, text, page in lines:
        lower = text.casefold()
        forms = []
        for form, phrase in FORM_PATTERNS:
            if re.search(prefix + phrase + r"\b", lower):
                forms.append(form)
        if forms:
            for form in forms:
                matches.append((form, page, start, len(data), text))
        heading = rf"^\s*[0-9]+\s+(?:r[0-9]+\s+)?{escaped}\s*(?::|\u2013|\u2014)"
        if re.search(heading, lower):
            matches.append(("explicit-name-heading", page, start, len(data), text))
    return matches


ranges = page_ranges(pages_path, len(raw))
lines = source_lines(ranges)
with residue_path.open(encoding="utf-8", newline="") as stream:
    residue = list(csv.DictReader(stream, delimiter="\t"))
if len(residue) != 127 or len({row["name"] for row in residue}) != 127:
    fail("E0106 denominator changed")

rows = []
for input_row in sorted(residue, key=lambda row: row["name"]):
    raw_name = input_row["name"]
    normalized, normalization = normalize_name(raw_name)
    matches = definition_matches(normalized, lines)
    if len(matches) == 1:
        form, page, start, length, evidence = matches[0]
        classification = "strict-definition"
    elif matches:
        classification = "ambiguous-definition"
        form = "|".join(sorted({item[0] for item in matches}))
        _, page, start, length, evidence = matches[0]
    else:
        classification, form, page, start, length, evidence = (
            "unsupported-definition", "-", 0, -1, 0, "-"
        )
    rows.append({
        "name": raw_name,
        "input_class": input_row["new_class"],
        "normalized": normalized,
        "normalization": normalization,
        "classification": classification,
        "form": form,
        "page": page,
        "byte_start": start,
        "byte_length": length,
        "source_sha256": expected_hash,
        "origin": "MECHANICAL",
        "evidence": evidence,
    })

fields = ["name", "input_class", "normalized", "normalization", "classification",
          "form", "page", "byte_start", "byte_length", "source_sha256", "origin",
          "evidence"]
for filename, selected in (("classifications.tsv", rows),
                           ("accepted-definitions.tsv",
                            [row for row in rows if row["classification"] == "strict-definition"])):
    with (out_dir / filename).open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(selected)

counts = {name: sum(row["classification"] == name for row in rows)
          for name in ("strict-definition", "ambiguous-definition", "unsupported-definition")}
normalized_count = sum(row["normalization"] != "none" for row in rows)
with (out_dir / "summary.tsv").open("w", encoding="utf-8") as stream:
    stream.write("metric\tvalue\n")
    for key, value in (
        ("residue_rows", len(rows)),
        ("unique_candidates", sum(row["input_class"] == "new unique candidate" for row in rows)),
        ("normalized_candidates", normalized_count),
        ("strict_definitions", counts["strict-definition"]),
        ("ambiguous_definitions", counts["ambiguous-definition"]),
        ("unsupported_definitions", counts["unsupported-definition"]),
        ("candidate_specific_branches", 0),
        ("model_calls", 0),
        ("semantic_promotions", 0),
    ):
        stream.write(f"{key}\t{value}\n")

# Independent table validation and negative controls.
with (out_dir / "classifications.tsv").open(encoding="utf-8", newline="") as stream:
    checked = list(csv.DictReader(stream, delimiter="\t"))
if len(checked) != len(rows) or {row["name"] for row in checked} != {row["name"] for row in rows}:
    fail("classification output changed its denominator")
for row in checked:
    if row["source_sha256"] != expected_hash or row["origin"] != "MECHANICAL":
        fail("classification provenance mismatch")
    if row["classification"] == "strict-definition":
        if int(row["page"]) < 1 or int(row["byte_start"]) < 0 or int(row["byte_length"]) < 1:
            fail("strict row lacks a source span")
        page = containing_page(ranges, int(row["byte_start"]), int(row["byte_length"]))
        if page != int(row["page"]):
            fail("strict row page differs from source span")
    elif row["classification"] == "unsupported-definition":
        if (row["form"], int(row["page"]), int(row["byte_start"]), int(row["byte_length"])) != ("-", 0, -1, 0):
            fail("unsupported row carries a citation")

tampered = bytearray(raw)
tampered[0] = ord("X") if tampered[0] != ord("X") else ord("Y")
if hashlib.sha256(tampered).hexdigest() == expected_hash:
    fail("tampered hash control failed")
bad_pages = pages_path.read_text(encoding="utf-8").replace("page 1 start 0 length", "page 1 start 1 length", 1)
if bad_pages == pages_path.read_text(encoding="utf-8"):
    fail("page negative control was not changed")
bad_page_path = out_dir / ".bad.pages"
bad_page_path.write_text(bad_pages, encoding="utf-8")
try:
    page_ranges(bad_page_path, len(raw))
except SystemExit:
    pass
else:
    fail("malformed-page control was accepted")
bad_page_path.unlink()
print("E0110 final bounded mechanical pass passed")
print((out_dir / "summary.tsv").read_text(encoding="utf-8"), end="")
PY
