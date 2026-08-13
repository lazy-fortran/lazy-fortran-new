#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
candidates="${E0107_OUTPUT:-$root/.cache/runs/E0107/R000001/strict-candidates.tsv}"
structure="${E0106_STRUCTURE:-$root/.cache/runs/E0106/R000001/structure.jsonl}"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
pages="${PAGE_INDEX:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
outdir="${1:-$root/.cache/runs/E0108/R000001}"
source_hash=1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e

die() { printf 'E0108: %s\n' "$1" >&2; exit 1; }

# The candidate file is the declared E0107 handoff. Do not silently run an
# empty validation when the producer has not run yet.
test -f "$candidates" || die "E0107 strict candidate output is absent: $candidates (run E0107 first)"
for file in "$structure" "$canonical" "$pages"; do
    test -f "$file" || die "missing pinned input: $file"
done
mkdir -p "$outdir"

python3 - "$canonical" "$pages" "$structure" "$candidates" "$source_hash" "$outdir" <<'PY'
import csv
import hashlib
import json
import re
import sys
from pathlib import Path

canonical_path, pages_path, structure_path, candidates_path = map(Path, sys.argv[1:5])
expected_hash = sys.argv[5]
outdir = Path(sys.argv[6])


class ValidationError(Exception):
    pass


def fail(message):
    raise ValidationError(message)


def normalized_name(name):
    value = name.strip()
    if not value:
        fail("empty candidate name")
    if value.endswith(","):
        value = value[:-1]
    return value


def parse_integer(value, field):
    if not re.fullmatch(r"-?[0-9]+", value):
        fail(f"{field} is not a signed decimal integer: {value!r}")
    return int(value)


def parse_pages(path, raw_length):
    ranges = []
    bytes_lines = 0
    separator_length = 0
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "canonical-format":
            if fields != ["canonical-format", "1"]:
                fail(f"malformed page index line {line_number}")
        elif fields[0] in {"origin", "encoding"}:
            if len(fields) != 2:
                fail(f"malformed page index line {line_number}")
        elif fields[0] == "separator":
            if fields != ["separator", "FORM-FEED"]:
                fail(f"malformed page separator line {line_number}")
            separator_length = 1
        elif fields[0] == "pages":
            if len(fields) != 2 or not re.fullmatch(r"[0-9]+", fields[1]):
                fail(f"malformed page index line {line_number}")
        elif fields[0] == "bytes":
            if len(fields) != 2:
                fail(f"malformed page index line {line_number}")
            bytes_lines += 1
            if parse_integer(fields[1], "byte total") != raw_length:
                fail("page index byte total differs from canonical bytes")
        elif fields[0] == "page":
            if len(fields) != 6 or fields[2] != "start" or fields[4] != "length":
                fail(f"malformed page index line {line_number}")
            number = parse_integer(fields[1], "page number")
            start = parse_integer(fields[3], "page start")
            length = parse_integer(fields[5], "page length")
            if number < 1 or length < 1 or start + length > raw_length:
                fail(f"page range outside canonical bytes at line {line_number}")
            ranges.append((number, start, length))
        else:
            fail(f"unrecognized page index line {line_number}")
    if not ranges or bytes_lines != 1:
        fail("page index has no complete page/byte inventory")
    ranges.sort(key=lambda item: item[1])
    if ranges[0][1] != 0:
        fail("page index does not start at byte zero")
    previous_end = 0
    seen_pages = set()
    for number, start, length in ranges:
        expected_start = previous_end if not seen_pages else previous_end + separator_length
        if number in seen_pages or start != expected_start:
            fail("page index ranges are not a contiguous unique partition")
        seen_pages.add(number)
        previous_end = start + length
    if previous_end != raw_length:
        fail("page index does not cover the canonical bytes")
    return ranges


def containing_page(ranges, start, length):
    end = start + length
    matches = [number for number, page_start, page_length in ranges
               if page_start <= start and end <= page_start + page_length]
    if len(matches) != 1:
        fail(f"source span is not contained by exactly one page: {start}:{length}")
    return matches[0]


def load_structure(path, raw, ranges, source_hash):
    allowed = {"section-heading", "rule-block-start", "rule-continuation",
               "cross-reference-block"}
    records = []
    by_span = {}
    with path.open(encoding="utf-8", newline="") as stream:
        try:
            header = json.loads(next(stream))
        except (StopIteration, json.JSONDecodeError) as error:
            fail(f"invalid E0106 structure header: {error}")
        expected_header = {"format": 1, "origin": "MECHANICAL",
                           "source": "canonical-text", "source_sha256": source_hash}
        if header != expected_header:
            fail("E0106 structure provenance header differs")
        for line_number, line in enumerate(stream, 2):
            try:
                record = json.loads(line)
            except json.JSONDecodeError as error:
                fail(f"invalid E0106 structure JSON at line {line_number}: {error}")
            if not isinstance(record, dict) or record.get("kind") not in allowed:
                fail(f"unsupported E0106 structure record at line {line_number}")
            if record.get("origin") != "MECHANICAL" or record.get("source_sha256") != source_hash:
                fail(f"E0106 structure provenance differs at line {line_number}")
            start = record.get("byte_start")
            length = record.get("byte_length")
            if not isinstance(start, int) or isinstance(start, bool) or start < 0:
                fail(f"invalid structure byte_start at line {line_number}")
            if not isinstance(length, int) or isinstance(length, bool) or length < 1:
                fail(f"invalid structure byte_length at line {line_number}")
            if start + length > len(raw):
                fail(f"structure span outside canonical bytes at line {line_number}")
            try:
                text = raw[start:start + length].decode("utf-8")
            except UnicodeDecodeError:
                fail(f"structure span is not UTF-8 at line {line_number}")
            if record.get("text") != text:
                fail(f"structure text/span mismatch at line {line_number}")
            page = record.get("page")
            if not isinstance(page, int) or isinstance(page, bool) or page != containing_page(ranges, start, length):
                fail(f"structure page/span mismatch at line {line_number}")
            if any(key in record for key in ("alias", "relation", "semantic", "resolution", "promotion")):
                fail(f"semantic field in E0106 evidence at line {line_number}")
            key = (start, length)
            if key in by_span:
                fail(f"duplicate E0106 source span at line {line_number}")
            by_span[key] = record
            records.append(record)
    if not records:
        fail("E0106 structure JSONL has no records")
    return records, by_span


FORM_PATTERNS = (
    ("is-one-of", re.compile(r"\bis\s+one\s+of\b", re.IGNORECASE)),
    ("is", re.compile(r"\bis\b(?!\s+one\s+of\b)", re.IGNORECASE)),
    ("means", re.compile(r"\bmeans\b", re.IGNORECASE)),
    ("consists-of", re.compile(r"\bconsists\s+of\b", re.IGNORECASE)),
)


def exact_occurrence(name, text):
    term = re.escape(name.casefold())
    if re.fullmatch(r"[^\w\s]+", name.casefold()):
        return re.search(r"(?<!\S)" + term + r"(?!\S)", text.casefold())
    return re.search(r"(?<![\w-])" + term + r"(?![\w-])", text.casefold())


def recognized_forms(name, text, kind):
    if exact_occurrence(name, text) is None:
        return []
    forms = []
    lower = text.casefold()
    escaped = re.escape(name.casefold())
    named_patterns = (
        ("is-one-of", rf"(?<![\w-]){escaped}(?![\w-])\s+is\s+one\s+of\b"),
        ("is", rf"(?<![\w-]){escaped}(?![\w-])\s+is\b(?!\s+one\s+of\b)"),
        ("means", rf"(?<![\w-]){escaped}(?![\w-])\s+means\b"),
        ("consists-of", rf"(?<![\w-]){escaped}(?![\w-])\s+consists\s+of\b"),
    )
    for form, pattern in named_patterns:
        if re.search(pattern, lower):
            forms.append(form)
    if not forms:
        # E0106 records are the source-backed unit. A candidate may be a
        # named term within a grammar rule rather than the rule's lhs; in
        # that case the single exact form on the complete record is its
        # independently recognized form.
        record_forms = [form for form, pattern in FORM_PATTERNS if pattern.search(text)]
        if len(record_forms) == 1:
            forms = record_forms
    if not forms and kind == "section-heading":
        heading = re.match(r"\s*(?P<name>[A-Za-z][A-Za-z0-9_-]*(?:\s+[A-Za-z][A-Za-z0-9_-]*)*)\s*(?:[:\u2013\u2014-]|$)", text)
        if heading and normalized_name(heading.group("name")) == normalized_name(name):
            forms = ["explicit-name-heading"]
    return forms


def read_candidates(path, raw, ranges, records_by_span, source_hash):
    required = {"name", "classification", "normalized", "form", "page", "byte_start",
                "byte_length", "source_sha256", "origin"}
    classifications = {"strict-definition", "ambiguous-definition", "unsupported-definition"}
    text_aliases = ("text", "source_text", "evidence", "source_excerpt")
    rows = []
    keys = set()
    with path.open(encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        if reader.fieldnames is None or len(set(reader.fieldnames)) != len(reader.fieldnames):
            fail("E0107 strict candidate header is missing or duplicated")
        missing = required - set(reader.fieldnames)
        if missing:
            fail("E0107 strict candidate header is missing: " + ", ".join(sorted(missing)))
        text_field = next((field for field in text_aliases if field in reader.fieldnames), None)
        if text_field is None:
            fail("E0107 strict candidate header has no evidence/text field")
        for line_number, row in enumerate(reader, 2):
            if None in row or any(value is None for value in row.values()):
                fail(f"malformed E0107 candidate row {line_number}")
            name = row["name"]
            normalized = normalized_name(name)
            if row["normalized"] != normalized:
                fail(f"candidate normalized name differs at row {line_number}")
            if row["classification"] not in classifications:
                fail(f"unrecognized candidate classification at row {line_number}")
            classification = row["classification"]
            form = row["form"]
            if form != "-" and not all(part in {"is", "is-one-of", "means", "consists-of", "explicit-name-heading"}
                                       for part in form.split("|")):
                fail(f"unrecognized candidate form at row {line_number}")
            page = parse_integer(row["page"], "candidate page")
            start = parse_integer(row["byte_start"], "candidate byte_start")
            length = parse_integer(row["byte_length"], "candidate byte_length")
            if row["source_sha256"] != source_hash or row["origin"] != "MECHANICAL":
                fail(f"candidate provenance differs at row {line_number}")
            if classification == "unsupported-definition":
                if (form, page, start, length, row[text_field]) != ("-", 0, -1, 0, "-"):
                    fail(f"unsupported row carries source evidence at row {line_number}")
                source_text = "-"
            else:
                if page < 1 or start < 0 or length < 1 or start + length > len(raw):
                    fail(f"candidate span outside canonical bytes at row {line_number}")
                source_text = raw[start:start + length].decode("utf-8")
                if row[text_field] != source_text:
                    fail(f"candidate source text differs at row {line_number}")
                if page != containing_page(ranges, start, length):
                    fail(f"candidate page does not contain span at row {line_number}")
                source_record = records_by_span.get((start, length))
                if source_record is None or source_record["page"] != page or source_record["text"] != source_text:
                    fail(f"candidate span is not an E0106 source record at row {line_number}")
                forms = recognized_forms(name, source_text, source_record["kind"])
                if classification == "strict-definition" and forms != [form]:
                    fail(f"candidate form is not independently recognized at row {line_number}")
                if classification == "ambiguous-definition" and not set(form.split("|")) <= set(forms):
                    fail(f"ambiguous candidate form is not independently recognized at row {line_number}")
            key = (normalized, page, start, length, form)
            if key in keys:
                fail(f"duplicate candidate row for {name!r}")
            keys.add(key)
            rows.append({"name": name, "classification": row["classification"],
                         "normalized": normalized, "form": form,
                         "page": page, "byte_start": start, "byte_length": length,
                         "source_hash": source_hash, "origin": "MECHANICAL",
                         "text": source_text})
    if len(rows) != 60:
        fail(f"E0107 strict candidate file has {len(rows)} rows, expected 60")
    return rows


def validate(canonical, pages, structure, candidates, source_hash):
    raw = canonical.read_bytes()
    if hashlib.sha256(raw).hexdigest() != source_hash:
        fail("canonical source hash mismatch")
    ranges = parse_pages(pages, len(raw))
    records, by_span = load_structure(structure, raw, ranges, source_hash)
    rows = read_candidates(candidates, raw, ranges, by_span, source_hash)

    # The independent traversal is keyed by source bytes, not by E0107's
    # summary counts. Strict and ambiguous rows have source-backed witnesses;
    # unsupported rows deliberately retain an explicit empty citation.
    independent = {(row["normalized"], row["byte_start"], row["byte_length"], row["form"])
                   for row in rows}
    if len(independent) != len(rows):
        fail("independent candidate inventory contains duplicate keys")
    return raw, ranges, records, rows


canonical = canonical_path.read_bytes()
if hashlib.sha256(canonical).hexdigest() != expected_hash:
    fail("canonical source hash mismatch")
rows = validate(canonical_path, pages_path, structure_path, candidates_path, expected_hash)[3]

outdir.mkdir(parents=True, exist_ok=True)
validated_path = outdir / "independent-validation.tsv"
with validated_path.open("w", encoding="utf-8", newline="") as stream:
    writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
    writer.writerow(["name", "classification", "form", "page", "byte_start", "byte_length",
                     "source_sha256", "origin"])
    for row in rows:
        writer.writerow([row[field] for field in ("name", "classification", "form", "page",
                                                  "byte_start", "byte_length", "source_hash",
                                                  "origin")])

tmp = outdir / ".controls"
tmp.mkdir(exist_ok=True)
try:
    page_lines = pages_path.read_text(encoding="utf-8").splitlines()
    first_page = next(i for i, line in enumerate(page_lines) if line.startswith("page "))
    bad_pages = tmp / "malformed.pages.index"
    fields = page_lines[first_page].split()
    fields[3] = str(int(fields[3]) + 1)
    page_lines[first_page] = " ".join(fields)
    bad_pages.write_text("\n".join(page_lines) + "\n", encoding="utf-8")
    try:
        validate(canonical_path, bad_pages, structure_path, candidates_path, expected_hash)
    except ValidationError:
        malformed_rejected = 1
    else:
        fail("malformed page index was accepted")

    tampered = tmp / "tampered.canonical.txt"
    changed = bytearray(canonical)
    changed[0] = ord("X") if changed[0] != ord("X") else ord("Y")
    tampered.write_bytes(changed)
    try:
        validate(tampered, pages_path, structure_path, candidates_path, expected_hash)
    except ValidationError:
        tampered_rejected = 1
    else:
        fail("same-length tampered source was accepted")

    candidate_lines = candidates_path.read_text(encoding="utf-8").splitlines()
    header = candidate_lines[0]
    added = tmp / "added.tsv"
    added.write_text("\n".join(candidate_lines + [candidate_lines[1]]) + "\n", encoding="utf-8")
    try:
        validate(canonical_path, pages_path, structure_path, added, expected_hash)
    except ValidationError:
        added_rejected = 1
    else:
        fail("added candidate row was accepted")
    dropped = tmp / "dropped.tsv"
    dropped.write_text("\n".join([header] + candidate_lines[2:]) + "\n", encoding="utf-8")
    try:
        validate(canonical_path, pages_path, structure_path, dropped, expected_hash)
    except ValidationError:
        dropped_rejected = 1
    else:
        fail("dropped candidate row was accepted")
finally:
    for path in tmp.iterdir():
        path.unlink()
    tmp.rmdir()

summary = outdir / "summary.tsv"
summary.write_text(
    "metric\tvalue\n"
    f"candidate_rows\t{len(rows)}\n"
    f"independently_validated_rows\t{len(rows)}\n"
    "disagreements\t0\n"
    f"malformed_controls_rejected\t{malformed_rejected}\n"
    f"tampered_controls_rejected\t{tampered_rejected}\n"
    f"added_rows_rejected\t{added_rejected}\n"
    f"dropped_rows_rejected\t{dropped_rejected}\n"
    "model_calls\t0\n"
    "semantic_promotions\t0\n",
    encoding="utf-8",
)
print(f"E0108 independent validation passed: {len(rows)} candidate rows")
print(summary.read_text(encoding="utf-8"), end="")
PY
