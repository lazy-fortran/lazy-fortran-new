#!/usr/bin/env python3
"""Join raw source-boundary witnesses to the normalized correspondence trace."""

from __future__ import annotations

import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path


DISPOSITIONS = {"mapped", "ambiguous", "suppressed", "unsupported"}
HEX64 = re.compile(r"^[0-9a-fA-F]{64}$")
RETAINED_SOURCE_FIELDS = (
    "retained_target_source_document",
    "retained_target_source_clause",
    "retained_target_source_rule",
    "retained_target_source_page",
    "retained_target_source_end_page",
    "retained_target_source_byte_start",
    "retained_target_source_byte_length",
    "retained_target_source_hash",
    "retained_target_source_alternative",
    "retained_target_path",
    "retained_target_sequence_slot",
)
REQUIRED = {
    "kind",
    "source_document",
    "source_clause",
    "source_rule",
    "source_page",
    "source_end_page",
    "source_byte_start",
    "source_byte_length",
    "source_hash",
    "source_alternative",
    "raw_source_path",
    "source_node_kind",
    "source_node_name",
    "source_boundary_role",
    "target_rule",
    "target_lhs",
    "target_alternative",
    "target_path",
    "target_sequence_slot",
    *RETAINED_SOURCE_FIELDS,
    "transformation",
    "source_expression_sha256",
    "target_expression_sha256",
    "input_expression_sha256",
    "output_expression_sha256",
    "disposition",
    "reason",
}


def fail(message: str) -> None:
    raise SystemExit(f"error: {message}")


def integer(row: dict[str, str], field: str) -> int:
    try:
        return int(row[field])
    except (KeyError, ValueError) as exc:
        fail(f"invalid integer {field}: {exc}")


def source_key(row: dict[str, str]) -> tuple[str, ...]:
    return (
        row["rule"],
        row["source_document"],
        row["source_clause"],
        row["page"],
        row["byte_start"],
        row["source_sha256"],
        row["alternative"],
        row["path"],
    )


def trace_key(row: dict[str, object]) -> tuple[str, ...]:
    return (
        str(row["source_rule"]),
        str(row["source_document"]),
        str(row["source_clause"]),
        str(row["source_page"]),
        str(row["source_byte_start"]),
        str(row["source_hash"]),
        str(row["source_alternative"]),
        str(row["raw_source_path"]),
    )


def trace_order(row: dict[str, object]) -> tuple[object, ...]:
    return (
        str(row["source_document"]),
        str(row["source_clause"]),
        str(row["source_rule"]),
        int(row["source_page"]),
        int(row["source_end_page"]),
        int(row["source_byte_start"]),
        int(row["source_byte_length"]),
        str(row["source_hash"]),
        int(row["source_alternative"]),
        str(row["raw_source_path"]),
        int(row["source_node_kind"]),
        str(row["source_node_name"]),
        str(row["source_boundary_role"]),
        str(row["target_rule"]),
        str(row["target_lhs"]),
        int(row["target_alternative"]),
        str(row["target_path"]),
        int(row["target_sequence_slot"]),
        str(row["retained_target_source_document"]),
        str(row["retained_target_source_clause"]),
        str(row["retained_target_source_rule"]),
        int(row["retained_target_source_page"]),
        int(row["retained_target_source_end_page"]),
        int(row["retained_target_source_byte_start"]),
        int(row["retained_target_source_byte_length"]),
        str(row["retained_target_source_hash"]),
        int(row["retained_target_source_alternative"]),
        str(row["retained_target_path"]),
        int(row["retained_target_sequence_slot"]),
        str(row["transformation"]),
        str(row["input_expression_sha256"]),
        str(row["output_expression_sha256"]),
        str(row["disposition"]),
        str(row["reason"]),
    )


def read_trace(path: Path) -> list[dict[str, object]]:
    values: list[dict[str, object]] = []
    for line_number, line in enumerate(path.read_text().splitlines(), 1):
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            fail(f"{path}:{line_number}: invalid JSON: {exc}")
        if not isinstance(row, dict) or set(row) != REQUIRED:
            fail(f"{path}:{line_number}: correspondence fields differ from the contract")
        if row["kind"] != "correspondence-witness":
            fail(f"{path}:{line_number}: unexpected kind {row['kind']!r}")
        if row["disposition"] not in DISPOSITIONS:
            fail(f"{path}:{line_number}: invalid disposition {row['disposition']!r}")
        for field in (
            "source_page",
            "source_end_page",
            "source_byte_start",
            "source_byte_length",
            "source_alternative",
            "source_node_kind",
            "target_alternative",
            "target_sequence_slot",
            "retained_target_source_page",
            "retained_target_source_end_page",
            "retained_target_source_byte_start",
            "retained_target_source_byte_length",
            "retained_target_source_alternative",
            "retained_target_sequence_slot",
        ):
            try:
                row[field] = int(row[field])
            except (TypeError, ValueError) as exc:
                fail(f"{path}:{line_number}: invalid {field}: {exc}")
        if row["source_page"] < 1 or row["source_end_page"] < row["source_page"]:
            fail(f"{path}:{line_number}: invalid source page range")
        if row["source_byte_start"] < 0 or row["source_byte_length"] < 0:
            fail(f"{path}:{line_number}: invalid source byte range")
        if row["source_alternative"] < 1 or row["target_alternative"] < 1:
            fail(f"{path}:{line_number}: invalid alternative")
        if row["target_sequence_slot"] < 0:
            fail(f"{path}:{line_number}: invalid target sequence slot")
        if row["retained_target_source_page"] < 0 or row["retained_target_source_end_page"] < 0:
            fail(f"{path}:{line_number}: invalid retained target source page")
        if row["retained_target_source_end_page"] > 0 and (
            row["retained_target_source_page"] == 0
            or row["retained_target_source_end_page"] < row["retained_target_source_page"]
        ):
            fail(f"{path}:{line_number}: invalid retained target source page range")
        if row["retained_target_source_byte_start"] < 0 or row["retained_target_source_byte_length"] < 0:
            fail(f"{path}:{line_number}: invalid retained target source byte range")
        if row["retained_target_source_alternative"] < 0 or row["retained_target_sequence_slot"] < 0:
            fail(f"{path}:{line_number}: invalid retained target relation")
        if not row["raw_source_path"] or not row["source_boundary_role"] or not row["reason"]:
            fail(f"{path}:{line_number}: missing required witness text")
        for field in (
            "source_expression_sha256",
            "target_expression_sha256",
            "input_expression_sha256",
            "output_expression_sha256",
        ):
            if not HEX64.fullmatch(str(row[field])):
                fail(f"{path}:{line_number}: {field} is not a SHA-256")
        retained_present = any(
            str(row[field])
            not in {"", "0"}
            for field in RETAINED_SOURCE_FIELDS
        )
        if retained_present:
            for field in RETAINED_SOURCE_FIELDS[:3]:
                if not str(row[field]):
                    fail(f"{path}:{line_number}: incomplete retained target source")
            if row["retained_target_source_page"] < 1 or row["retained_target_source_end_page"] < 1:
                fail(f"{path}:{line_number}: retained target source lacks page provenance")
            if not HEX64.fullmatch(str(row["retained_target_source_hash"])):
                fail(f"{path}:{line_number}: retained target source hash is not a SHA-256")
            if row["retained_target_source_alternative"] < 1 or not row["retained_target_path"]:
                fail(f"{path}:{line_number}: incomplete retained target relation")
        if row["disposition"] == "suppressed" and row["transformation"] == "rule-deduplicate":
            if not retained_present:
                fail(f"{path}:{line_number}: rule deduplication lacks retained target relation")
            if row["retained_target_path"] != "rhs" or row["retained_target_sequence_slot"] != 0:
                fail(f"{path}:{line_number}: rule deduplication retained target is not the rule root")
        values.append(row)
    if not values:
        fail(f"{path}: empty correspondence witness")
    if values != sorted(values, key=trace_order):
        fail(f"{path}: rows are not in deterministic producer order")
    return values


def main() -> int:
    if len(sys.argv) != 5:
        fail("usage: audit-correspondence-witness.py mapping.tsv witness.jsonl joined.tsv summary.json")
    mapping_path, trace_path, joined_path, summary_path = map(Path, sys.argv[1:])
    mapping = list(csv.DictReader(mapping_path.open(newline=""), delimiter="\t"))
    if not mapping:
        fail(f"{mapping_path}: empty mapping")
    trace = read_trace(trace_path)
    by_key: defaultdict[tuple[str, ...], list[dict[str, object]]] = defaultdict(list)
    for row in trace:
        by_key[trace_key(row)].append(row)

    fields = [
        "rule",
        "path",
        "alternative",
        "source_document",
        "source_clause",
        "page",
        "byte_start",
        "source_sha256",
        "input_disposition",
        "trace_count",
        "trace_disposition",
        "transformation",
        "target_rule",
        "target_lhs",
        "target_path",
        "target_sequence_slot",
        *RETAINED_SOURCE_FIELDS,
        "source_expression_sha256",
        "target_expression_sha256",
    ]
    joined: list[dict[str, object]] = []
    cardinalities: Counter[int] = Counter()
    dispositions: Counter[str] = Counter()
    transformations: Counter[str] = Counter()
    input_dispositions: Counter[str] = Counter()
    anomalies: list[str] = []
    for index, row in enumerate(mapping, 1):
        key = source_key(row)
        matches = by_key[key]
        cardinalities[len(matches)] += 1
        input_dispositions[row.get("disposition", "")] += 1
        if len(matches) != 1:
            anomalies.append(f"mapping row {index}: join cardinality {len(matches)}")
        match = matches[0] if len(matches) == 1 else {}
        disposition = str(match.get("disposition", "missing"))
        transformation = str(match.get("transformation", "missing"))
        dispositions[disposition] += 1
        transformations[transformation] += 1
        joined.append(
            {
                "rule": row["rule"],
                "path": row["path"],
                "alternative": row["alternative"],
                "source_document": row["source_document"],
                "source_clause": row["source_clause"],
                "page": row["page"],
                "byte_start": row["byte_start"],
                "source_sha256": row["source_sha256"],
                "input_disposition": row.get("disposition", ""),
                "trace_count": len(matches),
                "trace_disposition": disposition,
                "transformation": transformation,
                "target_rule": match.get("target_rule", ""),
                "target_lhs": match.get("target_lhs", ""),
                "target_path": match.get("target_path", ""),
                "target_sequence_slot": match.get("target_sequence_slot", ""),
                **{field: match.get(field, "") for field in RETAINED_SOURCE_FIELDS},
                "source_expression_sha256": match.get("source_expression_sha256", ""),
                "target_expression_sha256": match.get("target_expression_sha256", ""),
            }
        )

    with joined_path.open("w", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(joined)

    summary = {
        "mapping_rows": len(mapping),
        "trace_rows": len(trace),
        "join_cardinality": {str(k): cardinalities[k] for k in sorted(cardinalities)},
        "input_dispositions": dict(sorted(input_dispositions.items())),
        "trace_dispositions": dict(sorted(dispositions.items())),
        "transformations": dict(sorted(transformations.items())),
        "missing_or_multiple": anomalies,
        "status": "PASS"
        if not anomalies and not dispositions["ambiguous"] and not dispositions["unsupported"]
        else "FAIL",
        "mapping_sha256": hashlib.sha256(mapping_path.read_bytes()).hexdigest(),
        "trace_sha256": hashlib.sha256(trace_path.read_bytes()).hexdigest(),
    }
    summary_path.write_text(json.dumps(summary, sort_keys=True, indent=2) + "\n")
    print(json.dumps(summary, sort_keys=True))
    return 0 if summary["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
