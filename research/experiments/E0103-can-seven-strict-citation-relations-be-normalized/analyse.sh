#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
model_output="${E0102_MODEL_OUTPUT:-$root/../lazy-fortran-new/.cache/runs/E0101/R000003/model-output.jsonl}"
residue="${E0102_RESIDUE_PACKAGE:-$root/../lazy-fortran-new/.cache/runs/E0101/R000003/residue.jsonl}"
standardir="${STANDARDIR:-$root/../lazy-fortran-new/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
canonical="${CANONICAL_TEXT:-$root/../lazy-fortran-new/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
outdir="${1:-$root/.cache/runs/E0103/R000001}"
mkdir -p "$outdir"

python3 - "$model_output" "$residue" "$standardir" "$canonical" "$outdir" <<'PY'
import csv
import hashlib
import json
import re
import sys
from pathlib import Path

model_path, residue_path, standardir_path, canonical_path, outdir = map(Path, sys.argv[1:])
outdir.mkdir(parents=True, exist_ok=True)
source_hash = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

def fail(message):
    raise SystemExit("E0103: " + message)

def load_jsonl(path):
    try:
        return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read JSONL {path}: {exc}")

def normalize(name):
    return name[:-1] if name.endswith(",") else name

model_items = load_jsonl(model_path)
residue_items = load_jsonl(residue_path)
relations = [x for x in model_items if x.get("decision") == "relation"]
if len(relations) != 7:
    fail(f"relation denominator is {len(relations)}, expected 7")
if len({(x.get("name"), x.get("citation", {}).get("line")) for x in relations}) != 7:
    fail("relation rows are duplicated")
residue_names = {x.get("name") for x in residue_items}
if any(x.get("name") not in residue_names for x in relations):
    fail("relation name is absent from the ignored residue package")

canonical_text = canonical_path.read_text(encoding="utf-8")
canonical_lines = canonical_text.split("\n")
if hashlib.sha256(canonical_path.read_bytes()).hexdigest() != "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e":
    fail("canonical text hash mismatch")
if hashlib.sha256(standardir_path.read_bytes()).hexdigest() != "c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7":
    fail("StandardIR hash mismatch")
lhs = set(re.findall(r"\(lhs ([^ )]+)", standardir_path.read_text(encoding="utf-8")))

rows = []
for index, item in enumerate(relations, 1):
    citation = item.get("citation", {})
    line_no, page, span = citation.get("line"), citation.get("page"), citation.get("span")
    valid = isinstance(line_no, int) and isinstance(page, int) and isinstance(span, str)
    if valid and 1 <= line_no <= len(canonical_lines):
        line = canonical_lines[line_no - 1]
        offset = sum(len(x) + 1 for x in canonical_lines[:line_no - 1])
        expected_page = canonical_text[:offset].count("\f")
        valid = (citation.get("source_hash") == source_hash and page == expected_page and span in line)
    else:
        valid = False
    name = item["name"]
    normalized = normalize(name)
    relation = item.get("relation")
    rows.append({
        "row": index, "name": name, "normalized_name": normalized,
        "relation": relation, "target": item.get("target", ""),
        "line": line_no, "page": page, "exact_source_citation": "yes" if valid else "no",
        "trailing_punctuation_artifact": "yes" if name.endswith(",") else "no",
        "standardir_lhs_exact": "yes" if name in lhs else "no",
        "standardir_lhs_after_normalization": "yes" if normalized in lhs else "no",
        "target_class": "semantic/non-parser" if relation == "rank" else "parser-target",
        "origin": "LLM",
    })
    if not valid:
        fail(f"citation does not match canonical evidence: {name}")

fields = ["row", "name", "normalized_name", "relation", "target", "line", "page",
          "exact_source_citation", "trailing_punctuation_artifact", "standardir_lhs_exact",
          "standardir_lhs_after_normalization", "target_class", "origin"]
with (outdir / "audit.tsv").open("w", encoding="utf-8", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)

# Independent traversal: reread the source JSONL and compare row keys.
independent = []
for item in load_jsonl(model_path):
    if item.get("decision") == "relation":
        independent.append((item["name"], normalize(item["name"]), item["citation"]["line"], item["relation"]))
expected = [(x["name"], x["normalized_name"], x["line"], x["relation"]) for x in rows]
if independent != expected:
    fail("independent relation traversal differs")
if sum(x["standardir_lhs_after_normalization"] == "yes" for x in rows) != 5:
    fail("normalized StandardIR lhs match count differs")
if sum(x["target_class"] == "semantic/non-parser" for x in rows) != 2:
    fail("semantic target count differs")

summary = {
    "accepted_relation_rows": len(rows),
    "exact_source_citation_validity": sum(x["exact_source_citation"] == "yes" for x in rows),
    "trailing_punctuation_name_artifacts": sum(x["trailing_punctuation_artifact"] == "yes" for x in rows),
    "standardir_lhs_matches_after_normalization": sum(x["standardir_lhs_after_normalization"] == "yes" for x in rows),
    "semantic_non_parser_targets": sum(x["target_class"] == "semantic/non-parser" for x in rows),
    "parser_targets": sum(x["target_class"] == "parser-target" for x in rows),
    "standardir_promotions": 0, "model_calls": 0, "independent_difference": 0,
    "canonical_sha256": hashlib.sha256(canonical_path.read_bytes()).hexdigest(),
    "standardir_sha256": hashlib.sha256(standardir_path.read_bytes()).hexdigest(),
}
with (outdir / "summary.tsv").open("w", encoding="utf-8") as handle:
    handle.write("metric\tvalue\n")
    for key, value in summary.items():
        handle.write(f"{key}\t{value}\n")
print("E0103 audit gate passed")
for key, value in summary.items():
    print(f"{key}\t{value}")
PY
