#!/usr/bin/env bash
set -euo pipefail

source_sx=${1:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv>}
canonical_text=${2:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv>}
pdf=${3:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv>}
report=${4:?usage: check.sh <standardir.sx> <canonical.txt> <pdf> <report.tsv>}

for file in "$source_sx" "$canonical_text" "$pdf"; do
    [[ -f "$file" ]] || { printf 'missing input: %s\n' "$file" >&2; exit 2; }
done

python3 - "$source_sx" "$canonical_text" "$pdf" "$report" <<'PY'
from __future__ import annotations

import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path

source_path, canonical_path, pdf_path, report_path = map(Path, sys.argv[1:])
expected_pdf_sha256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
focus_rules = ("R741", "R843", "R1103", "R1307", "R1315")

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
        })
    return records

def clean_lines(value: str):
    cleaned = []
    removed_headers = 0
    for line in value.replace("\r", "").splitlines():
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
    alternatives = [part.strip() for part in re.split(r"\bor\b", match.group(1))]
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
    result = []
    index = 0
    while index < len(value):
        char = value[index]
        if char.isspace() or char in "[]":
            index += 1
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
        if value[index:index + 2] in ("::", "=>", ".."):
            result.append(("token", value[index:index + 2]))
            index += 2
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
        rows[key] == "PASS" for key in ("source_span_status", "byte_span_status", "duplicate_definition_status", "focus_status")
    ) else "FAIL"
    return rows

source = source_path.read_text(encoding="utf-8")
records = read_records(source)
canonical = canonical_path.read_bytes()
rows = evaluate(records, canonical)
rows["pdf_sha256"] = hashlib.sha256(pdf_path.read_bytes()).hexdigest()
rows["pdf_identity_status"] = "PASS" if rows["pdf_sha256"] == expected_pdf_sha256 else "FAIL"
rows["canonical_text_sha256"] = hashlib.sha256(canonical).hexdigest()

mutation = bytearray(canonical)
mutation_record = next(record for record in records if record["rule"] == "R741")
mutation_span = canonical[mutation_record["start"]:mutation_record["start"] + mutation_record["length"]]
mutation_offset = mutation_record["start"] + mutation_span.index(b"PROCEDURE")
mutation[mutation_offset] = ord("Q")
mutation_rows = evaluate(records, bytes(mutation))
rows["negative_mutation"] = "PASS" if mutation_rows["focus_status"] == "FAIL" else "FAIL"
rows["gate_status"] = "PASS" if rows["fidelity_status"] == "PASS" and rows["pdf_identity_status"] == "PASS" and rows["negative_mutation"] == "PASS" else "FAIL"

report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text("field\tvalue\n" + "".join(f"{key}\t{value}\n" for key, value in rows.items()), encoding="utf-8")
print(report_path.read_text(encoding="utf-8"), end="")
if rows["gate_status"] != "PASS":
    raise SystemExit(1)
PY
