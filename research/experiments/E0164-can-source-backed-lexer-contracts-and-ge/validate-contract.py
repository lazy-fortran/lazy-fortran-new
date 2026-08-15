#!/usr/bin/env python3
"""Independently validate a selected standardir-grammar-v0 contract."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def tokens(text: str) -> list[str]:
    result: list[str] = []
    index = 0
    while index < len(text):
        if text[index].isspace():
            index += 1
            continue
        if text[index] in "()":
            result.append(text[index])
            index += 1
            continue
        if text[index] == '"':
            index += 1
            value: list[str] = []
            while index < len(text) and text[index] != '"':
                if text[index] == "\\" and index + 1 < len(text):
                    index += 1
                value.append(text[index])
                index += 1
            if index == len(text):
                raise ValueError("unterminated quoted atom")
            result.append("".join(value))
            index += 1
            continue
        start = index
        while index < len(text) and not text[index].isspace() and text[index] not in "()":
            index += 1
        result.append(text[start:index])
    return result


def parse(text: str) -> list:
    stream = tokens(text)
    position = 0

    def node() -> list | str:
        nonlocal position
        if position >= len(stream):
            raise ValueError("unexpected end")
        value = stream[position]
        position += 1
        if value != "(":
            if value == ")":
                raise ValueError("unexpected close")
            return value
        result: list = []
        while position < len(stream) and stream[position] != ")":
            result.append(node())
        if position == len(stream):
            raise ValueError("unclosed list")
        position += 1
        return result

    result = node()
    if position != len(stream) or not isinstance(result, list):
        raise ValueError("trailing SX")
    return result


def children(record: list, name: str) -> list:
    for item in record[1:]:
        if isinstance(item, list) and item and item[0] == name:
            return item[1:]
    return []


def required(record: list, name: str) -> str:
    value = children(record, name)
    if len(value) != 1 or not isinstance(value[0], str) or not value[0]:
        raise ValueError(f"missing {name}")
    return value[0]


def source_key(source: list, fallback_rule: str | None = None) -> tuple[str, ...]:
    values = {item[0]: item[1] for item in source
              if isinstance(item, list) and len(item) >= 2 and isinstance(item[0], str)}
    rule = values.get("rule", fallback_rule)
    if not all(values.get(name) for name in ("document", "clause", "page", "source-sha256", "source-hash")):
        # Classification/lexical source records use source-hash; raw syntax
        # records use source-sha256. Normalize both to one lineage key.
        source_hash = values.get("source-sha256", values.get("source-hash"))
    else:
        source_hash = values["source-sha256"]
    required_values = (values.get("document"), values.get("clause"), rule,
                       values.get("page"), source_hash)
    if not all(required_values):
        raise ValueError("incomplete source lineage")
    return tuple(required_values)


def source_records(path: Path, kind: str) -> set[tuple[str, ...]]:
    result: set[tuple[str, ...]] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith(f"({kind} "):
            continue
        record = parse(line)
        nested = next((item[1:] for item in record[1:]
                       if isinstance(item, list) and item and item[0] == "source"), [])
        fallback = None
        if kind == "lexical-fact":
            value = children(record, "rule")
            fallback = value[0] if value else None
        result.add(source_key(nested, fallback))
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("contract", type=Path)
    parser.add_argument("standardir", type=Path)
    parser.add_argument("classifications", type=Path)
    parser.add_argument("lexical_facts", type=Path)
    parser.add_argument("--root", default="program")
    args = parser.parse_args()

    lineage = source_records(args.standardir, "syntax")
    lineage |= source_records(args.classifications, "classification")
    lineage |= source_records(args.lexical_facts, "lexical-fact")
    rows = 0
    lhs: set[str] = set()
    refs: set[str] = set()
    lineage_failures = 0
    origin_failures = 0
    resolution_failures = 0
    identities: set[str] = set()
    for line in args.contract.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = parse(line)
        if record[0] != "syntax-rule":
            raise SystemExit("contract contains a non-syntax-rule row")
        rows += 1
        identities.add(required(record, "id"))
        lhs.add(required(record, "lhs"))
        if required(record, "origin") != "mechanical":
            origin_failures += 1
        if required(record, "resolution") != "resolved":
            resolution_failures += 1
        source = children(record, "source")
        if len(source) != 1 or not isinstance(source[0], list) or source[0][0] != "source-ref":
            lineage_failures += 1
        else:
            values = source[0][1:]
            key = source_key(values)
            if key not in lineage:
                lineage_failures += 1
        nodes = children(record, "nodes")
        if len(nodes) != 1 or not isinstance(nodes[0], list):
            raise SystemExit("contract row has malformed node list")
        for item in nodes[0][1:]:
            if isinstance(item, list) and len(item) >= 3 and item[0] == "grammar-node":
                if item[1] == "reference":
                    refs.add(item[2])
    missing = refs - lhs
    root_status = "PASS" if args.root in lhs else "FAIL"
    values = {
        "contract_rows": rows,
        "unique_identities": len(identities),
        "unique_lhs": len(lhs),
        "unique_references": len(refs),
        "missing_references": len(missing),
        "missing_reference_names": ",".join(sorted(missing)),
        "source_lineage_failures": lineage_failures,
        "origin_failures": origin_failures,
        "resolution_failures": resolution_failures,
        "root_status": root_status,
        "status": "PASS" if rows and not missing and not lineage_failures and
        not origin_failures and not resolution_failures and root_status == "PASS" else "FAIL",
    }
    print("field\tvalue")
    for key, value in values.items():
        print(f"{key}\t{value}")
    if values["status"] != "PASS":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
