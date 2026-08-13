#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
residue="${E0106_RESIDUE:-$root/.cache/runs/E0106/R000001/residue-classifications.tsv}"
strict="${E0107_STRICT:-$root/.cache/runs/E0107/R000001/strict-candidates.tsv}"
independent="${E0108_INDEPENDENT:-$root/.cache/runs/E0108/R000001/independent-validation.tsv}"
out="${1:-$root/.cache/runs/E0109/R000001}"
die() { echo "E0109: $1" >&2; exit 1; }
for file in "$residue" "$strict" "$independent"; do test -f "$file" || die "missing $file"; done
mkdir -p "$out"

python3 - "$residue" "$strict" "$independent" "$out/summary.tsv" <<'PY'
import csv, sys
from collections import Counter

residue_path, strict_path, independent_path, summary_path = sys.argv[1:]
with open(residue_path, newline="") as stream:
    residue = list(csv.DictReader(stream, delimiter="\t"))
if len(residue) != 127: raise SystemExit("E0109: residue denominator is not 127")
residue_names = {row["name"] for row in residue}
unique_names = {row["name"] for row in residue if row["new_class"] == "new unique candidate"}
if len(unique_names) != 60: raise SystemExit("E0109: E0106 unique denominator is not 60")

def read(path):
    with open(path, newline="") as stream: rows = list(csv.DictReader(stream, delimiter="\t"))
    required = {"name", "classification", "form", "page", "byte_start", "byte_length", "source_hash", "origin"}
    if not rows or not required <= set(rows[0]): raise SystemExit(f"E0109: malformed {path}")
    if len({row["name"] for row in rows}) != len(rows): raise SystemExit(f"E0109: duplicate rows in {path}")
    return rows

strict_rows = read(strict_path)
independent_rows = read(independent_path)
if {row["name"] for row in strict_rows} != unique_names: raise SystemExit("E0109: strict denominator differs")
if {row["name"] for row in independent_rows} != unique_names: raise SystemExit("E0109: independent denominator differs")
fields = ["name", "classification", "form", "page", "byte_start", "byte_length", "source_hash", "origin"]
left = sorted(tuple(row[field] for field in fields) for row in strict_rows)
right = sorted(tuple(row[field] for field in fields) for row in independent_rows)
if left != right: raise SystemExit("E0109: independent fields differ")
allowed = {"strict-definition", "ambiguous-definition", "unsupported-definition"}
if any(row["classification"] not in allowed for row in strict_rows): raise SystemExit("E0109: unknown classification")
if any(row["origin"] != "MECHANICAL" for row in strict_rows + independent_rows): raise SystemExit("E0109: non-mechanical origin")
if any(not row["source_hash"] or int(row["page"]) <= 0 or int(row["byte_start"]) < 0 or int(row["byte_length"]) <= 0 for row in strict_rows):
    raise SystemExit("E0109: incomplete source provenance")

counts = Counter(row["classification"] for row in strict_rows)
with open(summary_path, "w") as output:
    output.write("metric\tvalue\n")
    output.write(f"denominator_rows\t{len(residue)}\n")
    output.write(f"strict_candidate_rows\t{counts['strict-definition']}\n")
    output.write(f"ambiguous_rows\t{counts['ambiguous-definition']}\n")
    output.write(f"unresolved_rows\t{counts['unsupported-definition']}\n")
    output.write("independent_disagreements\t0\nmodel_calls\t0\nsemantic_promotions\t0\n")
PY
cat "$out/summary.tsv"
