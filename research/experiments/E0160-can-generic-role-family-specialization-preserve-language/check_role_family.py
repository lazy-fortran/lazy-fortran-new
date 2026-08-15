#!/usr/bin/env python3
"""Independently validate emitted role-family witnesses."""

from __future__ import annotations

import argparse
import re
import sys
import tempfile
from pathlib import Path

E0154 = Path(__file__).resolve().parents[1] / "E0154-can-exact-source-expression-identity-and"
sys.path.insert(0, str(E0154))
from validate_identity import SourceKey, source_expressions  # noqa: E402


FORMATS = ("grammar.ebnf", "Fortran2023.g4", "fortran2023.y", "grammar.js")
REQUIRED = (
    "alias", "representative", "disposition", "reason", "source-roles",
    "alias-lineage", "source-expression-sha256", "target-expression-sha256",
    "representative-lineage", "representative-source-expression-sha256",
    "representative-target-expression-sha256",
)
LINEAGE = re.compile(r"([^,:]+):(\d+)@(\d+)\+(\d+)")
HASH = re.compile(r"^[0-9a-f]{64}$")


def fields(line: str) -> dict[str, str]:
    start = line.index("target-role-family") + len("target-role-family")
    payload = line[start:]
    result: dict[str, str] = {}
    for match in re.finditer(r"(\S+?)=([^\s*)]+)", payload):
        result[match.group(1)] = match.group(2)
    return result


def lineage_hashes(value: str, expected: dict[SourceKey, str]) -> tuple[list[str], list[str]]:
    if value == "none":
        return [], []
    entries = value.split(",")
    hashes: list[str] = []
    errors: list[str] = []
    for entry in entries:
        match = LINEAGE.fullmatch(entry)
        if match is None:
            errors.append(f"malformed lineage {entry}")
            continue
        rule, alternative, start, length = match.groups()
        key = (rule, int(alternative), int(start), int(length))
        if key not in expected:
            errors.append(f"lineage absent from StandardIR {entry}")
            continue
        hashes.append(expected[key])
    return hashes, errors


def check_text(text: str, expected: dict[SourceKey, str]) -> tuple[list[tuple[str, ...]], list[str]]:
    rows: list[tuple[str, ...]] = []
    errors: list[str] = []
    for number, line in enumerate(text.splitlines(), 1):
        if "target-role-family" not in line:
            continue
        value = fields(line)
        missing = [name for name in REQUIRED if name not in value]
        if missing:
            errors.append(f"line {number}: missing fields {','.join(missing)}")
            continue
        alias_hashes, alias_errors = lineage_hashes(value["alias-lineage"], expected)
        representative_hashes, representative_errors = lineage_hashes(
            value["representative-lineage"], expected
        )
        errors.extend(f"line {number}: {error}" for error in alias_errors + representative_errors)
        actual_alias_hashes = value["source-expression-sha256"].split(",")
        actual_representative_hashes = value["representative-source-expression-sha256"].split(",")
        if actual_alias_hashes != alias_hashes:
            errors.append(f"line {number}: alias source-expression lineage mismatch")
        if actual_representative_hashes != representative_hashes:
            errors.append(f"line {number}: representative source-expression lineage mismatch")
        for label in ("target-expression-sha256", "representative-target-expression-sha256"):
            if not HASH.fullmatch(value[label]):
                errors.append(f"line {number}: malformed {label}")
        if value["representative"] not in value["source-roles"].split(","):
            errors.append(f"line {number}: representative missing from source roles")
        rows.append(tuple(value[name] for name in REQUIRED))
    if not rows:
        errors.append("no role-family witness rows")
    return rows, errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("run", type=Path)
    parser.add_argument("report", type=Path)
    args = parser.parse_args()
    expected = source_expressions(args.source)
    by_format: dict[str, list[tuple[str, ...]]] = {}
    errors: list[str] = []
    for name in FORMATS:
        path = args.run / name
        if not path.is_file():
            errors.append(f"missing format {name}")
            continue
        rows, local_errors = check_text(path.read_text(encoding="utf-8"), expected)
        by_format[name] = rows
        errors.extend(f"{name}: {error}" for error in local_errors)
    if by_format:
        first = next(iter(by_format.values()))
        for name, rows in by_format.items():
            if rows != first:
                errors.append(f"{name}: role-family witness rows differ from first format")

    negative = "FAIL"
    reference = next((args.run / name for name in FORMATS if (args.run / name).is_file()), None)
    if reference is not None:
        text = reference.read_text(encoding="utf-8")
        match = re.search(r"representative-source-expression-sha256=([^\s*)]+)", text)
        if match is not None and HASH.fullmatch(match.group(1).split(",")[0]):
            mutated = text[:match.start(1)] + ("0" * 64) + text[match.start(1) + 64:]
            with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=reference.suffix) as stream:
                stream.write(mutated)
                stream.flush()
                _, mutation_errors = check_text(mutated, expected)
            negative = "PASS" if mutation_errors else "FAIL"
        else:
            errors.append("could not construct representative-lineage mutation")

    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("w", encoding="utf-8") as report:
        report.write("metric\tvalue\n")
        report.write(f"format_count\t{len(by_format)}\n")
        report.write(f"role_family_rows\t{len(next(iter(by_format.values()), []))}\n")
        report.write(f"lineage_status\t{'PASS' if not errors else 'FAIL'}\n")
        report.write(f"format_consistency\t{'PASS' if not any('differ' in error for error in errors) else 'FAIL'}\n")
        report.write(f"negative_mutation\t{negative}\n")
        report.write(f"status\t{'PASS' if not errors and negative == 'PASS' else 'FAIL'}\n")
        for error in errors:
            report.write(f"error\t{error}\n")
    print(args.report.read_text(encoding="utf-8"), end="")
    return 0 if not errors and negative == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
