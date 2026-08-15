#!/usr/bin/env python3
"""Check the source witness denominator before any target generator runs."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from validate_identity import atom, field, parse, source_expressions


REQUIRED_SOURCE_FIELDS = (
    "document",
    "clause",
    "rule",
    "page",
    "byte-start",
    "byte-length",
    "source-sha256",
)


def check_source(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        expected = source_expressions(path)
    except (OSError, ValueError) as error:
        return [str(error)]

    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or not line.lstrip().startswith("(syntax "):
            continue
        try:
            node = parse(line)
            source = node[4]
            for name in REQUIRED_SOURCE_FIELDS:
                field(source, name)
            source_hash = atom(field(source, "source-sha256"))
            if not re.fullmatch(r"[0-9a-f]{64}", source_hash):
                errors.append(f"line {line_number}: malformed source-sha256")
            if int(atom(field(source, "byte-start"))) < 0:
                errors.append(f"line {line_number}: negative byte-start")
            if int(atom(field(source, "byte-length"))) <= 0:
                errors.append(f"line {line_number}: non-positive byte-length")
        except (IndexError, TypeError, ValueError) as error:
            errors.append(f"line {line_number}: {error}")

    if not expected:
        errors.append("source SX contains no syntax alternatives")
    print(f"source_alternatives\t{len(expected)}")
    print(f"source_preflight\t{'PASS' if not errors else 'FAIL'}")
    for error in errors:
        print(f"error\t{error}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    return 0 if not check_source(args.source) else 1


if __name__ == "__main__":
    raise SystemExit(main())
