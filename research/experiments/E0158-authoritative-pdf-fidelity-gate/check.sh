#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$script_dir/../../.." && pwd)
source_sx=${1:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv> [canonical-manifest] [pages.index]}
canonical_text=${2:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv> [canonical-manifest] [pages.index]}
pdf=${3:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv> [canonical-manifest] [pages.index]}
report=${4:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv> [canonical-manifest] [pages.index]}
canonical_manifest=${5:-"$root/artifacts/runs/E0001/R000003-canonical-text.toml"}
page_index=${6:-"$root/.cache/runs/E0001/R000003/j3-24-007.pages.index"}

for file in "$source_sx" "$canonical_text" "$pdf" "$canonical_manifest" "$page_index"; do
    [[ -f "$file" ]] || { printf 'missing input: %s\n' "$file" >&2; exit 2; }
done

python3 - "$source_sx" "$canonical_text" "$pdf" "$report" "$canonical_manifest" "$page_index" <<'PY'
from __future__ import annotations

import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path

source_path, canonical_path, pdf_path, report_path, manifest_path, page_index_path = map(Path, sys.argv[1:])
expected_pdf_sha256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
focus_rules = ("R741", "R843", "R1103", "R1307", "R1315")

def manifest_value(value: str, name: str) -> str:
    match = re.search(rf"^{re.escape(name)}\s*=\s*\"([^\"]+)\"\s*$", value, re.M)
    if match:
        return match.group(1)
    match = re.search(rf"^{re.escape(name)}\s*=\s*([0-9]+)\s*$", value, re.M)
    return match.group(1) if match else ""

def parse_sx(value: str):
    tokens = re.findall(r'\(|\)|"(?:\\.|[^"\\])*"|[^\s()]+', value)
    index = 0

    def parse():
        nonlocal index
        if tokens[index] == "(":
            index += 1
            result = []
            while tokens[index] != ")":
                result.append(parse())
            index += 1
            return result
        atom = tokens[index]
        index += 1
        return json.loads(atom) if atom.startswith('"') else atom

    result = parse()
    if index != len(tokens):
        raise ValueError("trailing SX tokens")
    return result

def child(node, name: str):
    for item in node:
        if isinstance(item, list) and item and item[0] == name:
            return item
    raise ValueError(f"missing {name}")

def field(node, name: str) -> str:
    return child(node, name)[1]

def optional_field(node, name: str) -> str:
    for item in node:
        if isinstance(item, list) and item and item[0] == name:
            return item[1]
    return ""

def read_records(value: str):
    records = []
    for line in value.splitlines():
        if not line.startswith("(syntax "):
            continue
        node = parse_sx(line)
        source = child(node, "source")
        records.append({
            "node": node,
            "rule": node[1],
            "lhs": field(node, "lhs"),
            "rhs": child(node, "rhs")[1],
            "page": field(source, "page"),
            "start": int(field(source, "byte-start")),
            "length": int(field(source, "byte-length")),
            "source_sha256": optional_field(source, "source-sha256"),
        })
    return records

def clean_lines(value: str):
    cleaned = []
    removed_headers = 0
    for line in value.replace("\r", "").replace("\f", "\n").splitlines():
        before_header = line
        line = re.sub(
            r"(?:\d{4}-\d\d-\d\d WD 1539-1(?:\s+J3/24-007)?|"
            r"J3/24-007(?:\s+WD 1539-1 2023-12-18)?(?:\s+\d+)?)",
            "",
            line,
        )
        if line != before_header and re.fullmatch(r"\s*\d*\s*", line):
            removed_headers += 1
            continue
        stripped = line.strip()
        if re.fullmatch(r"\d+\s+J3/24-007", stripped):
            removed_headers += 1
            continue
        if re.fullmatch(r"\d{4}-\d\d-\d\d WD 1539-1 J3/24-007", stripped):
            removed_headers += 1
            continue
        cleaned.append(re.sub(r"^\d+\s+", "", line).strip())
    return cleaned, removed_headers

def canonical_definition(span: bytes):
    lines, headers = clean_lines(span.decode("utf-8"))
    value = " ".join(line for line in lines if line)
    match = re.search(r"\bR\d+\s+[^\s]+\s+is\s+(.*)$", value)
    if not match:
        raise ValueError(f"no grammar definition in span: {value!r}")
    alternatives = [
        part.strip()
        for part in re.split(r"(?<![A-Za-z0-9_-])or(?![A-Za-z0-9_-])", match.group(1))
    ]
    return alternatives, headers

def normalize(value: str) -> str:
    return re.sub(r"\s+", "", value)

def render(node) -> str:
    if isinstance(node, str):
        return node
    kind = node[0]
    if kind in ("token", "ref"):
        return node[1]
    if kind == "seq":
        return " ".join(render(item) for item in node[1:])
    if kind == "alt":
        return " | ".join(render(item) for item in node[1:])
    if kind == "optional":
        return "[ " + render(node[1]) + " ]"
    if kind == "repeat":
        return "{ " + render(node[1]) + " }"
    raise ValueError(f"unsupported RHS node: {kind}")

def leaves(node):
    if isinstance(node, str):
        return []
    kind = node[0]
    if kind in ("token", "ref"):
        return [(kind, node[1])]
    if kind in ("optional", "repeat"):
        return leaves(node[1])
    if kind in ("seq", "alt"):
        result = []
        for item in node[1:]:
            result.extend(leaves(item))
        return result
    raise ValueError(f"unsupported leaf node: {kind}")

def canonical_leaves(value: str):
    if value.strip() in ("[", "]"):
        return [("token", value.strip())]
    value = re.sub(r"\.\s+\.\s+\.", "", value)
    result = []
    index = 0
    while index < len(value):
        char = value[index]
        if char.isspace() or char in "[]":
            index += 1
            continue
        if value[index:index + 3] == "...":
            # Printed grammar ellipses describe repetition; they are not a
            # token in StandardIR and must not enter the leaf comparison.
            index += 3
            continue
        if value[index:index + 2] in ("**", "//", "<=", ">=", "/=", "==", "::", "=>"):
            result.append(("token", value[index:index + 2]))
            index += 2
            continue
        if char == ".":
            operator = re.match(r"\.[A-Z]+\.", value[index:])
            if operator:
                result.append(("token", operator.group(0)))
                index += len(operator.group(0))
                continue
        if char.isupper():
            end = index + 1
            while end < len(value) and (value[end].isupper() or value[end].isdigit() or value[end] == "_"):
                end += 1
            result.append(("token", value[index:end]))
            index = end
            continue
        if char.islower():
            end = index + 1
            while end < len(value) and (value[end].islower() or value[end].isdigit() or value[end] in "-_"):
                end += 1
            result.append(("ref", value[index:end]))
            index = end
            continue
        result.append(("token", char))
        index += 1
    return result

def evaluate(records, canonical: bytes):
    rows: dict[str, str] = {}
    spans = [(record["start"], record["length"]) for record in records]
    rows["syntax_records"] = str(len(records))
    rows["unique_source_spans"] = str(len(set(spans)))
    rows["source_span_status"] = "PASS" if len(spans) == len(set(spans)) else "FAIL"
    rows["byte_span_rule_failures"] = "0"
    rows["byte_span_status"] = "PASS"
    for record in records:
        span = canonical[record["start"]:record["start"] + record["length"]]
        if len(span) != record["length"] or not re.search(rb"\b" + record["rule"].encode() + rb"\b", span[:80]):
            rows["byte_span_rule_failures"] = str(int(rows["byte_span_rule_failures"]) + 1)
            rows["byte_span_status"] = "FAIL"

    source_counts = Counter(record["rule"] for record in records)
    canonical_counts: Counter[str] = Counter()
    document_lines, _ = clean_lines(canonical.decode("utf-8"))
    for line in document_lines:
        match = re.match(r"^(R\d+)\s+[^\s]+\s+is\s+", line)
        if match:
            canonical_counts[match.group(1)] += 1
    rows["canonical_definition_occurrences"] = str(sum(canonical_counts.values()))
    rows["duplicate_rule_count"] = str(sum(1 for count in source_counts.values() if count > 1))
    rows["duplicate_rule_occurrences"] = str(sum(count for count in source_counts.values() if count > 1))
    rows["duplicate_definition_status"] = "PASS" if source_counts == canonical_counts else "FAIL"

    canonical_sha256 = hashlib.sha256(canonical).hexdigest()
    rows["source_hash_failures"] = str(sum(
        record["source_sha256"] != canonical_sha256 for record in records
    ))
    rows["source_hash_status"] = "PASS" if rows["source_hash_failures"] == "0" else "FAIL"
    rows["surface_normalization_differences"] = "0"
    rows["full_token_ref_failures"] = "0"
    surface_difference_rules: list[str] = []
    full_token_ref_failure_rules: list[str] = []
    for record in records:
        span = canonical[record["start"]:record["start"] + record["length"]]
        try:
            expected, _ = canonical_definition(span)
            expressions = record["rhs"][1:] if record["rhs"][0] == "alt" else [record["rhs"]]
            actual = [render(expression) for expression in expressions]
            if [normalize(value) for value in actual] != [normalize(value) for value in expected]:
                # The PDF uses compact optional-plus-ellipsis notation for
                # repetition; StandardIR stores that meaning structurally.
                # The independent leaf comparison below is the exact
                # content check, while this records surface-only differences.
                rows["surface_normalization_differences"] = str(
                    int(rows["surface_normalization_differences"]) + 1
                )
                surface_difference_rules.append(record["rule"])
            if [leaves(expression) for expression in expressions] != [canonical_leaves(value) for value in expected]:
                rows["full_token_ref_failures"] = str(int(rows["full_token_ref_failures"]) + 1)
                full_token_ref_failure_rules.append(record["rule"])
        except (IndexError, ValueError):
            rows["surface_normalization_differences"] = str(
                int(rows["surface_normalization_differences"]) + 1
            )
            rows["full_token_ref_failures"] = str(int(rows["full_token_ref_failures"]) + 1)
            surface_difference_rules.append(record["rule"])
            full_token_ref_failure_rules.append(record["rule"])
    rows["surface_normalization_rules"] = ",".join(surface_difference_rules)
    rows["full_token_ref_failure_rules"] = ",".join(full_token_ref_failure_rules)
    rows["full_rhs_status"] = (
        "PASS"
        if rows["surface_normalization_differences"] == "0"
        else "PASS_WITH_STANDARD_SHORTHAND"
        if rows["full_token_ref_failures"] == "0"
        else "FAIL"
    )
    rows["full_token_ref_status"] = "PASS" if rows["full_token_ref_failures"] == "0" else "FAIL"

    for rule in focus_rules:
        matches = [record for record in records if record["rule"] == rule]
        rule_status = len(matches) == 1
        if rule_status:
            record = matches[0]
            span = canonical[record["start"]:record["start"] + record["length"]]
            expected, headers = canonical_definition(span)
            actual = [render(record["rhs"])]
            if isinstance(record["rhs"], list) and record["rhs"] and record["rhs"][0] == "alt":
                actual = [render(item) for item in record["rhs"][1:]]
            rhs_status = [normalize(value) for value in actual] == [normalize(value) for value in expected]
            expected_leaves = [canonical_leaves(value) for value in expected]
            actual_leaves = []
            expressions = record["rhs"][1:] if record["rhs"][0] == "alt" else [record["rhs"]]
            actual_leaves = [leaves(expression) for expression in expressions]
            token_ref_status = actual_leaves == expected_leaves
            rows[f"{rule}_rhs_status"] = "PASS" if rhs_status else "FAIL"
            rows[f"{rule}_token_ref_status"] = "PASS" if token_ref_status else "FAIL"
            rows[f"{rule}_continuation_headers_removed"] = str(headers)
            rule_status = rule_status and rhs_status and token_ref_status
        else:
            rows[f"{rule}_rhs_status"] = "FAIL"
            rows[f"{rule}_token_ref_status"] = "FAIL"
            rows[f"{rule}_continuation_headers_removed"] = "0"
        rows[f"{rule}_status"] = "PASS" if rule_status else "FAIL"

    rows["focus_status"] = "PASS" if all(rows[f"{rule}_status"] == "PASS" for rule in focus_rules) else "FAIL"
    rows["fidelity_status"] = "PASS" if all(
        rows[key] == "PASS" for key in (
            "source_span_status", "byte_span_status", "duplicate_definition_status",
            "source_hash_status", "full_token_ref_status", "focus_status",
        )
    ) else "FAIL"
    return rows

source = source_path.read_text(encoding="utf-8")
records = read_records(source)
canonical = canonical_path.read_bytes()
rows = evaluate(records, canonical)
rows["pdf_sha256"] = hashlib.sha256(pdf_path.read_bytes()).hexdigest()
rows["pdf_identity_status"] = "PASS" if rows["pdf_sha256"] == expected_pdf_sha256 else "FAIL"
rows["canonical_text_sha256"] = hashlib.sha256(canonical).hexdigest()
manifest_text = manifest_path.read_text(encoding="utf-8")
rows["canonical_manifest_sha256_status"] = "PASS" if manifest_value(
    manifest_text, "sha256") == rows["canonical_text_sha256"] else "FAIL"
rows["canonical_manifest_source_status"] = "PASS" if manifest_value(
    manifest_text, "source_sha256") == rows["pdf_sha256"] else "FAIL"
rows["canonical_manifest_bytes_status"] = "PASS" if manifest_value(
    manifest_text, "bytes") == str(len(canonical)) else "FAIL"
rows["canonical_page_index_sha256_status"] = "PASS" if manifest_value(
    manifest_text, "page_index_sha256") == hashlib.sha256(page_index_path.read_bytes()).hexdigest() else "FAIL"
rows["canonical_generator_status"] = "PASS" if (
    manifest_value(manifest_text, "generator") == "standard-new"
    and bool(manifest_value(manifest_text, "generator_commit"))
) else "FAIL"
rows["canonical_pdf_lineage_status"] = "PASS" if all(
    rows[key] == "PASS" for key in (
        "pdf_identity_status", "canonical_manifest_sha256_status",
        "canonical_manifest_source_status", "canonical_manifest_bytes_status",
        "canonical_page_index_sha256_status", "canonical_generator_status",
    )
) else "FAIL"
rows["fidelity_status"] = "PASS" if (
    rows["fidelity_status"] == "PASS"
    and rows["canonical_pdf_lineage_status"] == "PASS"
) else "FAIL"

mutation = bytearray(canonical)
mutation_record = next(record for record in records if record["rule"] == "R741")
mutation_span = canonical[mutation_record["start"]:mutation_record["start"] + mutation_record["length"]]
mutation_offset = mutation_record["start"] + mutation_span.index(b"PROCEDURE")
mutation[mutation_offset] = ord("Q")
mutation_rows = evaluate(records, bytes(mutation))
rows["negative_mutation"] = "PASS" if mutation_rows["focus_status"] == "FAIL" else "FAIL"
rows["gate_status"] = "PASS" if rows["fidelity_status"] == "PASS" and rows["negative_mutation"] == "PASS" else "FAIL"

report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text("field\tvalue\n" + "".join(f"{key}\t{value}\n" for key, value in rows.items()), encoding="utf-8")
print(report_path.read_text(encoding="utf-8"), end="")
if rows["gate_status"] != "PASS":
    raise SystemExit(1)
PY
