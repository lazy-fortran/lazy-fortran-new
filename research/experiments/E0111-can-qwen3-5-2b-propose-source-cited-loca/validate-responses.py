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
    result.add_argument("--prompts", help="prepared prompts, required by pointer mode")
    result.add_argument("--pointer-mode", action="store_true")
    result.add_argument(
        "--pointer-only",
        action="store_true",
        help="derive target and citation from the selected canonical window",
    )
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


def read_prompt_windows(path):
    if not path:
        raise InputError("pointer mode requires --prompts")
    try:
        with Path(path).open(encoding="utf-8") as stream:
            rows = [json.loads(line) for line in stream]
    except (OSError, json.JSONDecodeError) as exc:
        raise InputError(f"cannot read pointer prompts {path}: {exc}") from exc
    if len(rows) != 127 or any(not isinstance(row, dict) for row in rows):
        raise InputError("pointer prompts do not contain 127 objects")
    result = {}
    for row in rows:
        name = row.get("name")
        windows = row.get("windows")
        if not isinstance(name, str) or not isinstance(windows, list):
            raise InputError("pointer prompt lacks name or windows")
        if name in result:
            raise InputError(f"duplicate pointer prompt: {name}")
        result[name] = windows
    return result


def validate_pointer_response(
    item, expected_names, prompt_windows, raw, ranges, source_hash, pointer_only=False
):
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
    expected_fields = {"name", "decision", "relation", "window"}
    if not pointer_only:
        expected_fields.add("target")
    if decision != "proposal" or set(item) != expected_fields:
        raise InputError(f"{name}: pointer proposal fields are not exact")
    relation = item["relation"]
    if relation not in {"is", "is-one-of", "means", "consists-of"}:
        raise InputError(f"{name}: relation is not allowed")
    if not pointer_only and (
        not isinstance(item["target"], str)
        or not item["target"].strip()
        or len(item["target"]) > 512
    ):
        raise InputError(f"{name}: target is empty or too long")
    window_index = item["window"]
    if not isinstance(window_index, int) or isinstance(window_index, bool):
        raise InputError(f"{name}: window is not an integer")
    windows = prompt_windows[name]
    if window_index < 1 or window_index > len(windows):
        raise InputError(f"{name}: window is outside supplied evidence")
    window = windows[window_index - 1]
    required = {"page", "byte_start", "byte_length", "text"}
    if not isinstance(window, dict) or not required <= set(window):
        raise InputError(f"{name}: supplied window metadata is malformed")
    start = window["byte_start"]
    length = window["byte_length"]
    if not isinstance(start, int) or not isinstance(length, int) or start < 0 or length < 1:
        raise InputError(f"{name}: supplied window span is invalid")
    try:
        source_text = raw[start : start + length].decode("utf-8")
    except UnicodeDecodeError as exc:
        raise InputError(f"{name}: supplied window is not UTF-8") from exc
    if source_text != window["text"]:
        raise InputError(f"{name}: supplied window differs from canonical bytes")
    normalized = normalized_name(name)
    escaped = re.escape(normalized.casefold())
    prefix = rf"^\s*(?:(?:[0-9]+(?:\.[0-9]+)*|r[0-9]+)\s+)*(?:(?:a|an|the)\s+)?"
    patterns = {
        "is-one-of": rf"{prefix}{escaped}\s+is\s+one\s+of\b",
        "is": rf"{prefix}{escaped}\s+is\b(?!\s+one\s+of\b)",
        "means": rf"{prefix}{escaped}\s+means\b",
        "consists-of": rf"{prefix}{escaped}\s+consists\s+of\b",
    }
    matches = list(re.finditer(patterns[relation], source_text.casefold(), re.MULTILINE))
    if len(matches) != 1:
        raise InputError(f"{name}: selected window has {len(matches)} exact subject definitions")
    match = matches[0]
    line_start = source_text.rfind("\n", 0, match.start()) + 1
    line_end = source_text.find("\n", match.end())
    if line_end < 0:
        line_end = len(source_text)
    citation_start = start + len(source_text[:line_start].encode("utf-8"))
    citation_end = start + len(source_text[:line_end].encode("utf-8"))
    citation = raw[citation_start:citation_end]
    page = containing_page(ranges, citation_start, len(citation))
    target = source_text[match.end() : line_end].strip()
    if not target:
        raise InputError(f"{name}: selected definition has no target text")
    if not pointer_only:
        target = item["target"]
    return {
        "normalized": normalized,
        "relation": relation,
        "page": page,
        "byte_start": citation_start,
        "byte_length": len(citation),
        "target": target,
        "name": name,
        "citation": {
            "page": page,
            "byte_start": citation_start,
            "byte_length": len(citation),
            "source_sha256": source_hash,
            "text": citation.decode("utf-8"),
        },
    }


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
                        "name": name,
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
        pointer_validation = args.pointer_mode or args.pointer_only
        prompt_windows = read_prompt_windows(args.prompts) if pointer_validation else None
        if prompt_windows is not None and set(prompt_windows) != expected_names:
            raise InputError("pointer prompt names differ from the residue denominator")
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
                proposal = (
                    validate_pointer_response(
                        item,
                        expected_names,
                        prompt_windows,
                        raw,
                        ranges,
                        args.source_sha256,
                        pointer_only=args.pointer_only,
                    )
                    if pointer_validation
                    else validate_response(item, expected_names, raw, ranges, args.source_sha256)
                )
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
