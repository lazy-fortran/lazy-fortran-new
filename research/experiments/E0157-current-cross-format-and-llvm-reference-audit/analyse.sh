#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
run_dir=${1:?usage: analyse.sh <run-dir> <house.g4> <kaby.g4> <lfortran.yy> <flang.cpp> <lexical-report> [report-dir]}
house=${2:?usage: analyse.sh <run-dir> <house.g4> <kaby.g4> <lfortran.yy> <flang.cpp> <lexical-report> [report-dir]}
kaby=${3:?usage: analyse.sh <run-dir> <house.g4> <kaby.g4> <lfortran.yy> <flang.cpp> <lexical-report> [report-dir]}
lfortran=${4:?usage: analyse.sh <run-dir> <house.g4> <kaby.g4> <lfortran.yy> <flang.cpp> <lexical-report> [report-dir]}
flang=${5:?usage: analyse.sh <run-dir> <house.g4> <kaby.g4> <lfortran.yy> <flang.cpp> <lexical-report> [report-dir]}
lexical_report=${6:?usage: analyse.sh <run-dir> <house.g4> <kaby.g4> <lfortran.yy> <flang.cpp> <lexical-report> [report-dir]}
report_dir=${7:-"$run_dir"}

run_dir=$(cd -- "$run_dir" && pwd)
house=$(cd -- "$(dirname -- "$house")" && pwd)/$(basename -- "$house")
kaby=$(cd -- "$(dirname -- "$kaby")" && pwd)/$(basename -- "$kaby")
lfortran=$(cd -- "$(dirname -- "$lfortran")" && pwd)/$(basename -- "$lfortran")
flang=$(cd -- "$(dirname -- "$flang")" && pwd)/$(basename -- "$flang")
lexical_report=$(cd -- "$(dirname -- "$lexical_report")" && pwd)/$(basename -- "$lexical_report")
mkdir -p "$report_dir"

for file in "$run_dir/grammar.ebnf" "$run_dir/Fortran2023.g4" \
    "$run_dir/fortran2023.y" "$run_dir/grammar.js" \
    "$run_dir/source-expression-identity.tsv" "$run_dir/grammar-oracles.tsv" \
    "$house" "$kaby" "$lfortran" "$flang"; do
    [[ -f "$file" ]] || { printf 'missing input: %s\n' "$file" >&2; exit 2; }
done
[[ -f "$lexical_report" ]] || { printf 'missing lexical gate report: %s\n' "$lexical_report" >&2; exit 2; }
grep -q $'^format_gate_status\tPASS$' "$lexical_report" \
    || { printf 'lexical gate is not green: %s\n' "$lexical_report" >&2; exit 1; }

python3 - "$run_dir" "$house" "$kaby" "$lfortran" "$flang" "$lexical_report" "$report_dir" <<'PY'
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

run, house, kaby, lfortran, flang, lexical_report, report = map(Path, sys.argv[1:])
report.mkdir(parents=True, exist_ok=True)

def text(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def strip_comments(name: str, value: str) -> str:
    if name.endswith(".ebnf"):
        return re.sub(r"\(\*.*?\*\)", "", value, flags=re.S)
    if name.endswith(".g4"):
        return re.sub(r"//[^\n]*", "", value)
    if name.endswith(".y"):
        value = re.sub(r"/\*.*?\*/", "", value, flags=re.S)
        return re.sub(r"//[^\n]*", "", value)
    if name.endswith(".js"):
        value = re.sub(r"/\*.*?\*/", "", value, flags=re.S)
        return re.sub(r"//[^\n]*", "", value)
    return value

def ebnf_heads(value: str) -> set[str]:
    return set(re.findall(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*::=", value, re.M))

def bison_heads(value: str) -> set[str]:
    return set(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:", value, re.M))

def antlr_heads(value: str) -> set[str]:
    lines = value.splitlines()
    heads: set[str] = set()
    for index, line in enumerate(lines):
        stripped = line.strip()
        direct = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*)\s*:", stripped)
        if direct:
            heads.add(direct.group(1))
            continue
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", stripped):
            continue
        next_index = index + 1
        while next_index < len(lines) and not lines[next_index].strip():
            next_index += 1
        if next_index < len(lines) and lines[next_index].strip().startswith(":"):
            heads.add(stripped)
    return heads

def treesitter_heads(value: str) -> set[str]:
    return set(re.findall(r"^\s{4}([A-Za-z_][A-Za-z0-9_]*)\s*:\s*\$\s*=>", value, re.M))

def source_lineages(value: str) -> set[str]:
    return set(re.findall(r"source-lineage=([^\s*]+)", value))

generated = {
    "ebnf": (run / "grammar.ebnf", ebnf_heads),
    "antlr4": (run / "Fortran2023.g4", antlr_heads),
    "bison": (run / "fortran2023.y", bison_heads),
    "tree-sitter": (run / "grammar.js", treesitter_heads),
}
references = {
    "house-antlr4": (house, antlr_heads),
    "kaby76-antlr4": (kaby, antlr_heads),
    "lfortran-bison": (lfortran, bison_heads),
}

inventory_rows: list[tuple[str, str, str, str, str]] = []
for name, (path, parser) in generated.items():
    value = text(path)
    body = strip_comments(path.name, value)
    heads = parser(body)
    lineages = source_lineages(value)
    inventory_rows.append((name, "generated", str(len(heads)), str(len(lineages)), sha(path)))
for name, (path, parser) in references.items():
    value = text(path)
    body = strip_comments(path.name, value)
    heads = parser(body)
    inventory_rows.append((name, "reference", str(len(heads)), "", sha(path)))

flang_text = text(flang)
inventory_rows.append(("flang-rule-comments", "reference", str(len(set(re.findall(r"\bR\d+\b", flang_text)))), "", sha(flang)))
(report / "inventories.tsv").write_text(
    "name\tclass\thead_count\tlineage_count\tsha256\n"
    + "".join("\t".join(row) + "\n" for row in inventory_rows),
    encoding="utf-8",
)

features = {
    "LOCK": r"\bLOCK\b",
    "UNLOCK": r"\bUNLOCK\b",
    "FAIL IMAGE": r"FAIL\s+IMAGE",
    "NOTIFY WAIT": r"NOTIFY\s+WAIT",
    "SELECT RANK": r"SELECT\s+RANK",
    "SELECT TEAM": r"SELECT\s+TEAM",
    "FORM TEAM": r"FORM\s+TEAM",
    "EVENT": r"\bEVENT\b",
    "ENUM": r"\bENUM\b",
    "SUBMODULE": r"\bSUBMODULE\b",
    "DO CONCURRENT": r"DO\s+CONCURRENT",
}

feature_inputs = {name: text(path) for name, (path, _) in generated.items()}
feature_inputs.update({name: text(path) for name, (path, _) in references.items()})
feature_inputs["flang"] = flang_text
feature_rows: list[tuple[str, str, str, str]] = []
for feature, pattern in features.items():
    generated_present = any(re.search(pattern, value, re.I) for name, value in feature_inputs.items() if name in generated)
    reference_present = any(re.search(pattern, value, re.I) for name, value in feature_inputs.items() if name not in generated)
    if generated_present and reference_present:
        classification = "both"
    elif generated_present:
        classification = "standardir_only"
    elif reference_present:
        classification = "reference_only"
    else:
        classification = "neither"
    feature_rows.append((feature, "yes" if generated_present else "no", "yes" if reference_present else "no", classification))
(report / "feature-matrix.tsv").write_text(
    "feature\tgenerated_present\treference_present\tclassification\n"
    + "".join("\t".join(row) + "\n" for row in feature_rows),
    encoding="utf-8",
)

identity = dict(
    line.split("\t", 1)
    for line in text(run / "source-expression-identity.tsv").splitlines()
    if "\t" in line
)
oracles = dict(
    line.split("\t", 1)
    for line in text(run / "grammar-oracles.tsv").splitlines()
    if "\t" in line
)
summary = {
    "generated_formats": list(generated),
    "reference_formats": list(references) + ["flang-rule-comments"],
    "source_identity": identity.get("positive_identity", ""),
    "source_alternatives": identity.get("source_alternatives", ""),
    "covered_source_alternatives": identity.get("covered_source_alternatives", ""),
    "validator_status": {name: oracles.get(name, "") for name in ("antlr4", "bison", "tree-sitter", "source-projection")},
    "lexical_gate_report": str(lexical_report),
    "lexical_gate_status": "PASS",
    "generated_lineage_sets_equal": all(
        lineages == next(iter(lineage_sets))
        for lineages in lineage_sets[1:]
    ) if (lineage_sets := [source_lineages(text(path)) for path, _ in generated.values()]) else False,
    "reference_hashes": {name: sha(path) for name, (path, _) in references.items()},
    "flang_hash": sha(flang),
    "inventory_rows": len(inventory_rows),
    "feature_rows": len(feature_rows),
    "equivalence_claim": False,
}
(report / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
(report / "hashes.tsv").write_text(
    "name\tpath\tsha256\n"
    + "".join(f"{name}\t{path}\t{sha(path)}\n" for name, (path, _) in {**generated, **references}.items())
    + f"flang-rule-comments\t{flang}\t{sha(flang)}\n",
    encoding="utf-8",
)
print(json.dumps(summary, indent=2))
if summary["source_identity"] != "PASS" or any(value != "PASS" for value in summary["validator_status"].values()):
    raise SystemExit(1)
PY
