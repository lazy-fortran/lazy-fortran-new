#!/usr/bin/env python3
"""Strictly validate E0111 JSONL and compare accepted keys with E0110."""

import argparse
import csv
import json
import re
from pathlib import Path

from e0111_common import (
    DEFAULT_SOURCE_SHA256,
    InputError,
    containing_page,
    load_canonical,
    load_page_index,
    load_residue,
    normalized_name,
)


def parser():
    root = Path(__file__).resolve().parents[3]
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("responses")
    result.add_argument(
        "--residue",
        default=str(root / ".cache/runs/E0106/R000001/residue-classifications.tsv"),
    )
    result.add_argument(
        "--canonical",
        default=str(root / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"),
    )
    result.add_argument(
        "--pages",
        default=str(root / ".cache/runs/E0001/R000003/j3-24-007.pages.index"),
    )
    result.add_argument("--e0110", required=True, help="E0110 classifications.tsv")
    result.add_argument("--outdir", required=True, help="ignored-cache validation output")
    result.add_argument("--errors", help="optional model-errors.jsonl emitted by run-local.py")
    result.add_argument("--source-sha256", default=DEFAULT_SOURCE_SHA256)
    return result


def read_jsonl(path):
    try:
        with Path(path).open(encoding="utf-8") as stream:
            records = []
            for line_number, line in enumerate(stream, 1):
                try:
                    item = json.loads(line)
                except json.JSONDecodeError as exc:
                    raise InputError(f"response line {line_number} is not JSON") from exc
                records.append(item)
            return records
    except OSError as exc:
        raise InputError(f"cannot read responses {path}: {exc}") from exc


def validate_response(item, expected_names, raw, ranges, source_hash):
    if not isinstance(item, dict):
        raise InputError("response line is not an object")
    name = item.get("name")
    if name not in expected_names:
        raise InputError(f"unknown response name: {name!r}")
    decision = item.get("decision")
    if decision == "abstain":
        if set(item) != {"name", "decision"}:
            raise InputError(f"{name}: abstain must not carry proposal fields")
        return None
    if decision != "proposal":
        raise InputError(f"{name}: decision must be proposal or abstain")
    if set(item) != {"name", "decision", "relation", "target", "citation"}:
        raise InputError(f"{name}: proposal has unsupported or missing fields")
    relation = item["relation"]
    target = item["target"]
    if not isinstance(relation, str) or relation not in {"is", "is-one-of", "means", "consists-of"}:
        raise InputError(f"{name}: relation is not a short lowercase token")
    if not isinstance(target, str) or not target.strip() or len(target) > 512:
        raise InputError(f"{name}: target is empty or too long")
    citation = item["citation"]
    required = {"page", "byte_start", "byte_length", "source_sha256", "text"}
    if not isinstance(citation, dict) or set(citation) != required:
        raise InputError(f"{name}: citation fields are not exact")
    for field in ("page", "byte_start", "byte_length"):
        value = citation[field]
        if not isinstance(value, int) or isinstance(value, bool) or value < 0:
            raise InputError(f"{name}: citation {field} is not a non-negative integer")
    if citation["page"] < 1 or citation["byte_length"] < 1:
        raise InputError(f"{name}: citation page/length is invalid")
    if citation["source_sha256"] != source_hash:
        raise InputError(f"{name}: citation source hash differs")
    start = citation["byte_start"]
    length = citation["byte_length"]
    if start + length > len(raw):
        raise InputError(f"{name}: citation is outside canonical bytes")
    try:
        source_text = raw[start : start + length].decode("utf-8")
    except UnicodeDecodeError as exc:
        raise InputError(f"{name}: citation is not a UTF-8 span") from exc
    if citation["text"] != source_text:
        raise InputError(f"{name}: citation text does not match canonical bytes")
    if citation["page"] != containing_page(ranges, start, length):
        raise InputError(f"{name}: citation page does not contain the byte span")
    normalized = normalized_name(name)
    escaped = re.escape(normalized.casefold())
    source_lower = source_text.casefold()
    forms = {
        "is-one-of": rf"^\s*[0-9]+\s+(?:r[0-9]+\s+)?{escaped}\s+is\s+one\s+of\b",
        "is": rf"^\s*[0-9]+\s+(?:r[0-9]+\s+)?{escaped}\s+is\b(?!\s+one\s+of\b)",
        "means": rf"^\s*[0-9]+\s+(?:r[0-9]+\s+)?{escaped}\s+means\b",
        "consists-of": rf"^\s*[0-9]+\s+(?:r[0-9]+\s+)?{escaped}\s+consists\s+of\b",
    }
    if not re.search(forms[relation], source_lower, re.MULTILINE):
        raise InputError(f"{name}: citation lacks an exact subject-position definition")
    return {
        "normalized": normalized,
        "relation": relation,
        "page": citation["page"],
        "byte_start": start,
        "byte_length": length,
        "target": target,
        "name": name,
        "citation": citation,
    }


def read_e0110(path, raw, ranges, source_hash):
    """Read strict E0110 rows; relation falls back to its deterministic form."""
    try:
        with Path(path).open(encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream, delimiter="\t")
            fields = set(reader.fieldnames or [])
            required = {"name", "page", "byte_start", "byte_length"}
            if not required <= fields:
                raise InputError("E0110 output lacks name/page/byte span columns")
            hash_field = "source_sha256" if "source_sha256" in fields else "source_hash"
            if hash_field not in fields:
                raise InputError("E0110 output lacks source hash")
            relation_field = "relation" if "relation" in fields else "form"
            if relation_field not in fields:
                raise InputError("E0110 output lacks relation or form")
            accepted = []
            for line_number, row in enumerate(reader, 2):
                if None in row or any(value is None for value in row.values()):
                    raise InputError(f"malformed E0110 row {line_number}")
                classification = row.get("classification", "strict-definition")
                if classification not in {"strict-definition", "accepted", "resolved"}:
                    continue
                if row.get("origin", "MECHANICAL") != "MECHANICAL":
                    raise InputError(f"E0110 row {line_number} is not MECHANICAL")
                try:
                    page = int(row["page"])
                    start = int(row["byte_start"])
                    length = int(row["byte_length"])
                except ValueError as exc:
                    raise InputError(f"E0110 row {line_number} has a non-integer span") from exc
                if page < 1 or start < 0 or length < 1 or start + length > len(raw):
                    raise InputError(f"E0110 row {line_number} has an invalid span")
                if row[hash_field] != source_hash:
                    raise InputError(f"E0110 row {line_number} has the wrong source hash")
                if containing_page(ranges, start, length) != page:
                    raise InputError(f"E0110 row {line_number} has the wrong page")
                relation = row[relation_field]
                if not re.fullmatch(r"[a-z][a-z0-9_-]{0,63}", relation):
                    raise InputError(f"E0110 row {line_number} has an invalid relation/form")
                name = row["name"]
                normalized = row.get("normalized") or normalized_name(name)
                accepted.append(
                    {
                        "normalized": normalized,
                        "relation": relation,
                        "page": page,
                        "byte_start": start,
                        "byte_length": length,
                    }
                )
    except OSError as exc:
        raise InputError(f"cannot read E0110 output {path}: {exc}") from exc
    return accepted


def read_errors(path):
    if not path or not Path(path).exists():
        return 0
    with Path(path).open(encoding="utf-8") as stream:
        count = 0
        for line_number, line in enumerate(stream, 1):
            try:
                item = json.loads(line)
            except json.JSONDecodeError as exc:
                raise InputError(f"model error line {line_number} is not JSON") from exc
            if not isinstance(item, dict) or not isinstance(item.get("name"), str):
                raise InputError(f"model error line {line_number} is malformed")
            count += 1
        return count


def key(item):
    return (
        item["normalized"],
        item["relation"],
        item["page"],
        item["byte_start"],
        item["byte_length"],
    )


def main():
    args = parser().parse_args()
    try:
        raw = load_canonical(args.canonical, args.source_sha256)
        ranges = load_page_index(args.pages, len(raw))
        residue = load_residue(args.residue)
        expected_names = {row["name"] for row in residue}
        response_items = read_jsonl(args.responses)
        if len(response_items) != len(expected_names):
            raise InputError(
                f"response denominator differs: expected {len(expected_names)}, "
                f"got {len(response_items)}"
            )
        accepted = []
        rejected = []
        seen = set()
        for item in response_items:
            name = item.get("name") if isinstance(item, dict) else None
            if name in seen:
                raise InputError(f"duplicate response for {name}")
            seen.add(name)
            try:
                proposal = validate_response(item, expected_names, raw, ranges, args.source_sha256)
            except InputError as exc:
                rejected.append({"name": name, "error": str(exc)})
                continue
            if proposal is not None:
                accepted.append(proposal)
        if seen != expected_names:
            missing = sorted(expected_names - seen)
            raise InputError(f"response omits residue rows: {missing[:3]}")
        e0110 = read_e0110(args.e0110, raw, ranges, args.source_sha256)
        model_errors = read_errors(args.errors)
        e0110_keys = {key(item) for item in e0110}
        e0110_spans = {
            (
                item["normalized"],
                item["page"],
                item["byte_start"],
                item["byte_length"],
            ): {item["relation"]}
            for item in e0110
        }
        for item in e0110:
            span_key = (
                item["normalized"],
                item["page"],
                item["byte_start"],
                item["byte_length"],
            )
            e0110_spans.setdefault(span_key, set()).add(item["relation"])
        agreements = sum(key(item) in e0110_keys for item in accepted)
        disagreements = sum(
            (
                item["normalized"],
                item["page"],
                item["byte_start"],
                item["byte_length"],
            )
            in e0110_spans
            and key(item) not in e0110_keys
            for item in accepted
        )
        outdir = Path(args.outdir)
        outdir.mkdir(parents=True, exist_ok=True)
        with (outdir / "validated-proposals.jsonl").open(
            "w", encoding="utf-8", newline="\n"
        ) as stream:
            for item in accepted:
                stream.write(json.dumps(item, ensure_ascii=False, sort_keys=True) + "\n")
        with (outdir / "rejected-proposals.jsonl").open(
            "w", encoding="utf-8", newline="\n"
        ) as stream:
            for item in rejected:
                stream.write(json.dumps(item, ensure_ascii=False, sort_keys=True) + "\n")
        with (outdir / "overlap.tsv").open("w", encoding="utf-8", newline="") as stream:
            writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
            writer.writerow(
                ["name", "normalized", "relation", "page", "byte_start", "byte_length", "comparison"]
            )
            for item in accepted:
                span_key = (
                    item["normalized"],
                    item["page"],
                    item["byte_start"],
                    item["byte_length"],
                )
                comparison = "agreement" if key(item) in e0110_keys else (
                    "disagreement" if span_key in e0110_spans else "no-overlap"
                )
                writer.writerow(
                    [
                        item["name"],
                        item["normalized"],
                        item["relation"],
                        item["page"],
                        item["byte_start"],
                        item["byte_length"],
                        comparison,
                    ]
                )
        summary = [
            ("residue_rows", len(residue)),
            ("prompts_expected", len(residue)),
            ("proposals_returned", len(accepted)),
            ("strict_validator_accepts", len(accepted)),
            ("strict_validator_rejects", len(rejected)),
            ("abstentions", len(residue) - len(accepted)),
            ("overlap_rows", agreements + disagreements),
            ("overlap_agreements", agreements),
            ("overlap_disagreements", disagreements),
            ("model_errors", model_errors),
            ("semantic_promotions", 0),
        ]
        with (outdir / "summary.tsv").open("w", encoding="utf-8", newline="") as stream:
            stream.write("metric\tvalue\n")
            for metric, value in summary:
                stream.write(f"{metric}\t{value}\n")
        print("E0111 strict response and E0110 overlap gate passed")
        print((outdir / "summary.tsv").read_text(encoding="utf-8"), end="")
    except (InputError, OSError, ValueError) as exc:
        raise SystemExit(f"E0111 validate-responses: {exc}") from exc


if __name__ == "__main__":
    main()
