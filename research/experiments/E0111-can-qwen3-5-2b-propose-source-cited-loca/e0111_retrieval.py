#!/usr/bin/env python3
"""Deterministically retrieve bounded definition windows for E0113.

This is deliberately a small declarative recognizer.  It finds candidate
subject-position definitions in the complete canonical text; it does not
decide whether a candidate is a StandardIR fact.
"""

import re

from e0111_common import InputError, containing_page, normalized_name, utf8_window


RELATIONS = {
    "is-one-of": re.compile(r"\bis\s+one\s+of\b", re.IGNORECASE),
    "consists-of": re.compile(r"\bconsists\s+of\b", re.IGNORECASE),
    "means": re.compile(r"\bmeans\b", re.IGNORECASE),
    "is": re.compile(r"\bis\b", re.IGNORECASE),
}


def _subject_pattern(name):
    token = re.escape(normalized_name(name))
    return re.compile(
        rf"^\s*(?:(?:[0-9]+(?:\.[0-9]+)*|r[0-9]+)\s+)*"
        rf"(?:(?:a|an|the)\s+)?{token}\s+"
        rf"(?:is\s+one\s+of|is|means|consists\s+of)\b",
        re.IGNORECASE,
    )


def _relation(match_text):
    lowered = match_text.casefold()
    if "is one of" in lowered:
        return "is-one-of"
    if "consists of" in lowered:
        return "consists-of"
    if "means" in lowered:
        return "means"
    return "is"


def _line_windows(raw, ranges, line_start, line_end, window_bytes):
    """Return one exact UTF-8 window containing the complete candidate line."""
    page = containing_page(ranges, line_start, max(1, line_end - line_start))
    page_start, page_length = next(
        (start, length) for number, start, length in ranges if number == page
    )
    if line_end - line_start > window_bytes:
        raise InputError("definition candidate line exceeds the bounded window")
    before = max(0, (window_bytes - (line_end - line_start)) // 3)
    start = max(page_start, line_start - before)
    end = min(page_start + page_length, start + window_bytes)
    return utf8_window(raw, page, start, ranges, end - start)


def retrieve(raw, ranges, residue, e0110, window_bytes=768):
    """Return deterministic definition candidates keyed by residue name.

    E0110 exact windows are placed first so the model/evaluator has a stable
    overlap set.  Additional windows come only from the generic anchored
    definition pattern above.
    """
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise InputError("canonical source is not UTF-8") from exc
    lines = text.splitlines(keepends=True)
    offsets = []
    cursor = 0
    for line in lines:
        encoded = line.encode("utf-8")
        offsets.append((cursor, cursor + len(encoded), line))
        cursor += len(encoded)
    by_name = {row["name"]: [] for row in residue}
    for row in residue:
        name = row["name"]
        seen = set()
        for overlap in e0110.get(name, []):
            item = dict(overlap)
            item["kind"] = "e0110-overlap"
            seen.add((item["page"], item["byte_start"], item["byte_length"]))
            by_name[name].append(item)
        pattern = _subject_pattern(name)
        for line_start, line_end, line in offsets:
            match = pattern.search(line)
            if match is None:
                continue
            page = containing_page(ranges, line_start, max(1, line_end - line_start))
            window = _line_windows(raw, ranges, line_start, line_end, window_bytes)
            key = (window["page"], window["byte_start"], window["byte_length"])
            if key in seen:
                continue
            seen.add(key)
            by_name[name].append(
                {
                    **window,
                    "kind": "retrieved-definition",
                    "relation": _relation(match.group(0)),
                    "match_byte_start": line_start
                    + len(line[: match.start()].encode("utf-8")),
                }
            )
    return by_name
