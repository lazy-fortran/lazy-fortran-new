#!/usr/bin/env python3
"""Shared input and canonical-source checks for the E0111 runner."""

import csv
import hashlib
import json
import re
from pathlib import Path


DEFAULT_SOURCE_SHA256 = (
    "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
)
EXPECTED_RESIDUE_ROWS = 127
RESIDUE_FIELDS = {
    "name",
    "baseline_class",
    "new_class",
    "matching_records",
    "origin",
}
ALLOWED_RESIDUE_CLASSES = {
    "new ambiguous candidate",
    "new no candidate",
    "new unique candidate",
}


class InputError(Exception):
    """An input did not satisfy the E0111 data contract."""


def sha256_bytes(raw):
    return hashlib.sha256(raw).hexdigest()


def parse_uint(value, field):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]+", value):
        raise InputError(f"{field} is not a non-negative decimal integer: {value!r}")
    return int(value)


def load_canonical(path, expected_hash):
    try:
        raw = Path(path).read_bytes()
    except OSError as exc:
        raise InputError(f"cannot read canonical source {path}: {exc}") from exc
    actual = sha256_bytes(raw)
    if actual != expected_hash:
        raise InputError(
            f"canonical source hash mismatch: expected {expected_hash}, got {actual}"
        )
    return raw


def load_page_index(path, raw_length):
    ranges = []
    bytes_lines = 0
    declared_pages = None
    separator_length = 0
    try:
        lines = Path(path).read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise InputError(f"cannot read page index {path}: {exc}") from exc
    for line_number, line in enumerate(lines, 1):
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "canonical-format":
            if fields != ["canonical-format", "1"]:
                raise InputError(f"malformed page index line {line_number}")
        elif fields[0] in {"origin", "encoding"}:
            if len(fields) != 2:
                raise InputError(f"malformed page index line {line_number}")
        elif fields[0] == "separator":
            if fields != ["separator", "FORM-FEED"]:
                raise InputError(f"malformed page separator line {line_number}")
            separator_length = 1
        elif fields[0] == "pages":
            if len(fields) != 2:
                raise InputError(f"malformed page index line {line_number}")
            declared_pages = parse_uint(fields[1], "page count")
        elif fields[0] == "bytes":
            if len(fields) != 2:
                raise InputError(f"malformed page index line {line_number}")
            bytes_lines += 1
            if parse_uint(fields[1], "byte total") != raw_length:
                raise InputError("page index byte total differs from canonical bytes")
        elif fields[0] == "page":
            if len(fields) != 6 or fields[2] != "start" or fields[4] != "length":
                raise InputError(f"malformed page index line {line_number}")
            number = parse_uint(fields[1], "page number")
            start = parse_uint(fields[3], "page start")
            length = parse_uint(fields[5], "page length")
            if number < 1 or length < 1 or start + length > raw_length:
                raise InputError(f"page range outside canonical bytes at line {line_number}")
            ranges.append((number, start, length))
        else:
            raise InputError(f"unrecognized page index line {line_number}")
    if not ranges or bytes_lines != 1:
        raise InputError("page index has no complete page/byte inventory")
    if declared_pages is not None and declared_pages != len(ranges):
        raise InputError("page index page count differs from page records")
    ordered = sorted(ranges, key=lambda item: item[1])
    if ordered[0][1] != 0:
        raise InputError("page index does not start at byte zero")
    previous_end = 0
    seen_pages = set()
    for number, start, length in ordered:
        expected_start = previous_end if not seen_pages else previous_end + separator_length
        if number in seen_pages or start != expected_start:
            raise InputError("page index ranges are not a contiguous unique partition")
        seen_pages.add(number)
        previous_end = start + length
    if previous_end != raw_length:
        raise InputError("page index does not cover the canonical bytes")
    if seen_pages != set(range(1, len(ordered) + 1)):
        raise InputError("page index page numbers are not 1-based and contiguous")
    return ordered


def containing_page(ranges, start, length):
    if not isinstance(start, int) or isinstance(start, bool) or start < 0:
        raise InputError(f"invalid byte_start: {start!r}")
    if not isinstance(length, int) or isinstance(length, bool) or length < 1:
        raise InputError(f"invalid byte_length: {length!r}")
    matches = [
        number
        for number, page_start, page_length in ranges
        if page_start <= start and start + length <= page_start + page_length
    ]
    if len(matches) != 1:
        raise InputError(f"source span is not contained by exactly one page: {start}:{length}")
    return matches[0]


def normalized_name(name):
    if not isinstance(name, str) or not name.strip():
        raise InputError("empty residue name")
    value = name.strip()
    if value.endswith(","):
        value = value[:-1]
    return value


_MATCHING_RECORD = re.compile(r"(?P<kind>[a-z-]+)@(?P<page>[0-9]+):(?P<start>[0-9]+)")


def parse_matching_records(value):
    if value == "-":
        return []
    records = []
    for item in value.split(","):
        match = _MATCHING_RECORD.fullmatch(item)
        if match is None:
            raise InputError(f"malformed matching record: {item!r}")
        records.append(
            {
                "kind": match.group("kind"),
                "page": int(match.group("page")),
                "byte_start": int(match.group("start")),
            }
        )
    if len({(item["page"], item["byte_start"]) for item in records}) != len(records):
        raise InputError("duplicate matching record anchor")
    return records


def load_residue(path):
    try:
        with Path(path).open(encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream, delimiter="\t")
            if reader.fieldnames is None or set(reader.fieldnames) != RESIDUE_FIELDS:
                raise InputError("E0106 residue header differs from the pinned format")
            rows = []
            for line_number, row in enumerate(reader, 2):
                if None in row or any(value is None for value in row.values()):
                    raise InputError(f"malformed E0106 residue row {line_number}")
                if row["origin"] != "MECHANICAL":
                    raise InputError(f"residue row {line_number} is not MECHANICAL")
                if row["new_class"] not in ALLOWED_RESIDUE_CLASSES:
                    raise InputError(f"unknown residue class at row {line_number}")
                records = parse_matching_records(row["matching_records"])
                rows.append({**row, "matching": records})
    except OSError as exc:
        raise InputError(f"cannot read E0106 residue {path}: {exc}") from exc
    if len(rows) != EXPECTED_RESIDUE_ROWS:
        raise InputError(f"expected 127 E0106 residue rows, got {len(rows)}")
    names = [row["name"] for row in rows]
    if len(set(names)) != EXPECTED_RESIDUE_ROWS:
        raise InputError("E0106 residue names are not distinct")
    return sorted(rows, key=lambda row: row["name"])


def utf8_window(raw, page, anchor, ranges, window_bytes):
    page_number, page_start, page_length = next(
        item for item in ranges if item[0] == page
    )
    if not page_start <= anchor < page_start + page_length:
        raise InputError(f"matching anchor is outside its claimed page: {anchor} on {page}")
    if window_bytes < 32:
        raise InputError("window size must be at least 32 bytes")
    start = max(page_start, anchor - window_bytes // 3)
    end = min(page_start + page_length, start + window_bytes)
    for _ in range(8):
        try:
            text = raw[start:end].decode("utf-8")
            return {
                "page": page_number,
                "byte_start": start,
                "byte_length": end - start,
                "text": text,
            }
        except UnicodeDecodeError as exc:
            if exc.start == 0 and start < anchor:
                start += 1
            elif end < page_start + page_length:
                end += 1
            else:
                start += 1
    raise InputError("source window is not valid UTF-8")


def jsonl_write(path, records):
    with Path(path).open("w", encoding="utf-8", newline="\n") as stream:
        for record in records:
            stream.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
