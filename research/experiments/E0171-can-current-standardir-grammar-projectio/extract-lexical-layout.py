#!/usr/bin/env python3
"""Extract source-backed lexical-layout facts from page-local PDF witnesses.

The pattern table is the only Fortran-specific input. The extractor performs
no rule-number inference: it verifies the pinned PDF, locates each phrase on
the declared page after whitespace normalization, and emits both a replayable
anchor table and the v1 companion SX input.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import os
import re
import subprocess
import tempfile
from pathlib import Path


HASH_LENGTH = 64
FIELDS = (
    "document",
    "clause",
    "page",
    "source_sha256",
    "kind",
    "source_form",
    "field",
    "value",
    "locator",
    "phrase",
)
KINDS = {
    "statement-boundary": {"field": "terminator", "values": {"end-of-line", "semicolon", "comment"}},
    "continuation": {"field": "signal", "values": {"trailing-ampersand", "leading-ampersand", "fixed-form-marker"}},
    "keyword-name-policy": {"field": "policy", "values": {"not-reserved"}},
}
SOURCE_FORMS = {"all", "free-form", "fixed-form"}


def fail(message: str) -> None:
    raise SystemExit(f"error: {message}")


def normalize(text: str) -> str:
    # J3 page text carries printed line/paragraph numbers at the start of
    # lines. Remove those presentation columns before joining a phrase that
    # crosses a PDF line break; do not infer content from the numbers.
    text = re.sub(r"(?m)^\s*\d+\s+(?:\d+\s+)?", "", text)
    return re.sub(r"\s+", " ", text).strip()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def read_patterns(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    if not rows or tuple(rows[0]) != FIELDS:
        fail(f"pattern header must be: {' '.join(FIELDS)}")
    seen: set[tuple[str, ...]] = set()
    for row in rows:
        if tuple(row) != FIELDS or any(not row[field].strip() for field in FIELDS):
            fail("pattern row has missing or unknown fields")
        try:
            page = int(row["page"])
        except ValueError:
            fail(f"page is not an integer: {row['page']}")
        if page < 1:
            fail(f"page is not positive: {page}")
        if len(row["source_sha256"]) != HASH_LENGTH or not re.fullmatch(r"[0-9a-fA-F]{64}", row["source_sha256"]):
            fail(f"invalid source hash on page {page}")
        kind = KINDS.get(row["kind"])
        if kind is None or row["field"] != kind["field"] or row["value"] not in kind["values"]:
            fail(f"invalid fact domain in row on page {page}")
        if row["source_form"] not in SOURCE_FORMS:
            fail(f"invalid source form in row on page {page}")
        key = tuple(row[field] for field in FIELDS[:-1])
        if key in seen:
            fail(f"duplicate fact row: {key}")
        seen.add(key)
    return rows


def page_text(pdf: Path, page: int) -> str:
    result = subprocess.run(
        ["pdftotext", "-f", str(page), "-l", str(page), "-layout", str(pdf), "-"],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode:
        fail(f"pdftotext failed for page {page}: {result.stderr.strip()}")
    return normalize(result.stdout)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(content)
    os.replace(temporary, path)


def sx(row: dict[str, str]) -> str:
    source = (
        f"(source-ref (document {row['document']}) (clause {row['clause']}) "
        f"(locator {row['locator']}) (page {row['page']}) "
        f"(source-hash {row['source_sha256']}))"
    )
    if row["kind"] == "statement-boundary":
        fact = f"(statement-boundary (source-form {row['source_form']}) (terminator {row['value']})"
    elif row["kind"] == "continuation":
        fact = f"(continuation (source-form {row['source_form']}) (signal {row['value']})"
    else:
        fact = f"(keyword-name-policy (source-form {row['source_form']}) (policy {row['value']})"
    return f"{fact} (source {source}) (origin mechanical))"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf", type=Path)
    parser.add_argument("patterns", type=Path)
    parser.add_argument("anchors", type=Path)
    parser.add_argument("layout_sx", type=Path)
    args = parser.parse_args()

    for output in (args.anchors, args.layout_sx):
        if output.exists():
            fail(f"refusing to overwrite existing output: {output}")
    actual_hash = sha256(args.pdf)
    rows = read_patterns(args.patterns)
    pages: dict[int, str] = {}
    for row in rows:
        expected_hash = row["source_sha256"].lower()
        if expected_hash != actual_hash:
            fail(f"PDF hash mismatch: expected {expected_hash}, got {actual_hash}")
        page = int(row["page"])
        pages.setdefault(page, page_text(args.pdf, page))
        phrase = normalize(row["phrase"])
        if phrase not in pages[page]:
            fail(f"phrase not found on page {page}: {row['phrase']}")
        row["source_sha256"] = actual_hash

    lines = ["\t".join(FIELDS)]
    lines.extend("\t".join(row[field] for field in FIELDS) for row in rows)
    atomic_write(args.anchors, "\n".join(lines) + "\n")
    atomic_write(args.layout_sx, "\n".join(sx(row) for row in rows) + "\n")
    print(f"verified {len(rows)} layout facts on {len(pages)} pages")


if __name__ == "__main__":
    main()
