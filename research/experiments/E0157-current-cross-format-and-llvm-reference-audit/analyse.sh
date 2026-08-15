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
    "$run_dir/source-expression-identity.tsv" "$run_dir/source-projection.tsv" \
    "$run_dir/grammar-oracles.tsv" \
    "$run_dir/input/standardir.sx" "$house" "$kaby" "$lfortran" "$flang"; do
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
    if name.endswith(".cpp"):
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
    # Only r_* declarations are grammar rules. Uppercase declarations such
    # as LETTER and DIGIT are lexer token definitions.
    return set(re.findall(r"^\s*(r_[A-Za-z_][A-Za-z0-9_-]*)\s*:\s*\$\s*=>", value, re.M))

def source_lineages(value: str) -> set[str]:
    return set(re.findall(r"source-lineage=([^\s*]+)", value))

def emitted_source_lineages(value: str) -> set[str]:
    result: set[str] = set()
    for line in value.splitlines():
        if "source-lineage=" not in line:
            continue
        if "target-disposition=omitted-" in line or "target-rule=omitted-" in line:
            continue
        result.update(re.findall(r"source-lineage=([^\s*]+)", line))
    return result

def parse_sx(value: str):
    tokens = re.findall(r"\(|\)|[^\s()]+", value)
    index = 0

    def read():
        nonlocal index
        if index >= len(tokens):
            raise ValueError("unexpected end of SX")
        token = tokens[index]
        index += 1
        if token == "(":
            result = []
            while index < len(tokens) and tokens[index] != ")":
                result.append(read())
            if index >= len(tokens):
                raise ValueError("unterminated SX list")
            index += 1
            return result
        if token == ")":
            raise ValueError("unexpected SX close")
        return token

    result = []
    while index < len(tokens):
        result.append(read())
    return result

def sx_field(node, name: str):
    for child in node[1:]:
        if isinstance(child, list) and child and child[0] == name:
            return child[1:]
    return []

def source_syntax_records(value: str) -> list[tuple[str, str]]:
    records: list[tuple[str, str]] = []
    for node in parse_sx(value):
        if not isinstance(node, list) or not node or node[0] != "syntax":
            continue
        rule = node[1]
        lhs = sx_field(node, "lhs")
        if len(lhs) != 1:
            raise ValueError(f"syntax {rule} has no unique lhs")
        records.append((rule, lhs[0]))
    if not records:
        raise ValueError("StandardIR contains no syntax records")
    return records

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

inventory_rows: list[tuple[str, str, str, str, str, str]] = []
for name, (path, parser) in generated.items():
    value = text(path)
    body = strip_comments(path.name, value)
    heads = parser(body)
    lineages = source_lineages(value)
    emitted = emitted_source_lineages(value)
    inventory_rows.append((
        name, "generated", str(len(heads)), str(len(lineages)),
        str(len(emitted)), sha(path),
    ))
for name, (path, parser) in references.items():
    value = text(path)
    body = strip_comments(path.name, value)
    heads = parser(body)
    inventory_rows.append((name, "reference", str(len(heads)), "", "", sha(path)))

flang_text = text(flang)
inventory_rows.append(("flang-rule-comments", "reference", str(len(set(re.findall(r"\bR\d+\b", flang_text)))), "", "", sha(flang)))
(report / "inventories.tsv").write_text(
    "name\tclass\thead_count\tlineage_count\temitted_lineage_count\tsha256\n"
    + "".join("\t".join(row) + "\n" for row in inventory_rows),
    encoding="utf-8",
)

feature_lhses = {
    "LOCK": {"lock-stmt"},
    "UNLOCK": {"unlock-stmt"},
    "FAIL IMAGE": {"fail-image-stmt"},
    "NOTIFY WAIT": {"notify-wait-stmt"},
    "SELECT RANK": {"select-rank-construct", "select-rank-stmt"},
    "SELECT TEAM": {"change-team-construct", "change-team-stmt"},
    "FORM TEAM": {"form-team-stmt"},
    "EVENT": {"event-post-stmt", "event-wait-stmt", "event-variable"},
    "ENUM": {"enum-def-stmt", "enum-def", "enumeration-type-def", "enumeration-type-stmt"},
    "SUBMODULE": {"submodule", "submodule-stmt"},
    "DO CONCURRENT": {"concurrent-header", "concurrent-control"},
}

source_text = text(run / "input/standardir.sx")
source_records = source_syntax_records(source_text)
source_rules_by_lhs: dict[str, set[str]] = {}
for rule, lhs in source_records:
    source_rules_by_lhs.setdefault(lhs, set()).add(rule)
source_feature_rules = {
    feature: sorted(
        rule
        for lhs in lhses
        for rule in source_rules_by_lhs.get(lhs, set())
    )
    for feature, lhses in feature_lhses.items()
}
generated_bodies = {
    name: strip_comments(path.name, text(path))
    for name, (path, _) in generated.items()
}
reference_bodies = {
    name: strip_comments(path.name, text(path))
    for name, (path, _) in references.items()
}
reference_bodies["flang"] = strip_comments(flang.name, flang_text)
format_names = list(generated_bodies) + list(reference_bodies)
generated_emitted_lineages = {
    name: emitted_source_lineages(text(path))
    for name, (path, _) in generated.items()
}

def source_rule_ids(lineages: set[str]) -> set[str]:
    return {lineage.split(":", 1)[0] for lineage in lineages}

# Reference files do not carry StandardIR lineage. Their feature result is a
# structural rule-head witness only, not a normative-source claim.
reference_head_aliases = {
    "LOCK": {"lock-stmt", "lock_stmt", "lockStmt", "lock_stmt_f2023"},
    "UNLOCK": {"unlock-stmt", "unlock_stmt", "unlockStmt"},
    "FAIL IMAGE": {"fail-image-stmt", "fail_image_stmt", "failImageStmt"},
    "NOTIFY WAIT": {"notify-wait-stmt", "notify_wait_stmt", "notifyWaitStmt", "notify_wait_stmt_f2023"},
    "SELECT RANK": {"select-rank-construct", "select_rank_construct", "selectRankConstruct"},
    "SELECT TEAM": {"change-team-construct", "change_team_construct", "changeTeamConstruct"},
    "FORM TEAM": {"form-team-stmt", "form_team_stmt", "formTeamStmt"},
    "EVENT": {"event-post-stmt", "event_post_stmt", "eventPostStmt", "event-wait-stmt", "event_wait_stmt", "eventWaitStmt"},
    "ENUM": {"enum-def-stmt", "enum_def_stmt", "enumDefStmt", "enumeration-type-def", "enumeration_type_def", "enumerationTypeDef"},
    "SUBMODULE": {"submodule", "submodule-stmt", "submodule_stmt", "submoduleStmt"},
    "DO CONCURRENT": {"concurrent-header", "concurrent_header", "concurrentHeader"},
}
reference_heads = {
    name: parser(strip_comments(path.name, text(path)))
    for name, (path, parser) in references.items()
}
reference_heads["flang"] = set()

feature_rows: list[tuple[str, ...]] = []
for feature in feature_lhses:
    expected_rules = set(source_feature_rules[feature])
    generated_presence = [
        bool(expected_rules & source_rule_ids(generated_emitted_lineages[name]))
        for name in generated_bodies
    ]
    reference_presence = [
        bool(reference_head_aliases[feature] & reference_heads[name])
        for name in references
    ] + [False]
    format_presence = generated_presence + reference_presence
    source_present = bool(expected_rules)
    generated_present = any(generated_presence)
    reference_present = any(reference_presence)
    if source_present and generated_present and reference_present:
        classification = "both"
    elif source_present and generated_present:
        classification = "standardir_only"
    elif source_present and not generated_present:
        classification = "selected_profile_gap"
    elif reference_present:
        classification = "reference_only"
    else:
        classification = "neither"
    feature_rows.append((
        feature,
        ",".join(source_feature_rules[feature]),
        "yes" if source_present else "no",
        *("yes" if present else "no" for present in format_presence),
        classification,
    ))
(report / "feature-matrix.tsv").write_text(
    "feature\tnormative_source_rule_ids\tnormative_source_present\t"
    + "\t".join(f"{name}_body_present" for name in format_names)
    + "\tclassification\n"
    + "".join("\t".join(row) + "\n" for row in feature_rows),
    encoding="utf-8",
)

identity: dict[str, str] = {}
for line in text(run / "source-expression-identity.tsv").splitlines():
    if "\t" in line:
        fields = line.split("\t")
        key, value = fields[0], fields[1]
        identity[key] = value
projection: dict[str, dict[str, str]] = {}
projection_header: list[str] = []
for line in text(run / "source-projection.tsv").splitlines():
    fields = line.split("\t")
    if not fields or fields[0] in {"format", "negative-control"}:
        if fields and fields[0] == "format":
            projection_header = fields
        continue
    if projection_header and len(fields) == len(projection_header):
        projection[fields[0]] = dict(zip(projection_header, fields))
oracles: dict[str, str] = {}
for line in text(run / "grammar-oracles.tsv").splitlines():
    if "\t" in line:
        fields = line.split("\t")
        key, value = fields[0], fields[1]
        oracles[key] = value
summary = {
    "generated_formats": list(generated),
    "reference_formats": list(references) + ["flang-rule-comments"],
    "source_identity": identity.get("positive_identity", ""),
    "source_alternatives": identity.get("source_alternatives", ""),
    "covered_source_alternatives": identity.get("covered_source_alternatives", ""),
    "identity_coverage": {
        "expected": identity.get("source_alternatives", ""),
        "covered": identity.get("covered_source_alternatives", ""),
    },
    "emitted_body_coverage": {
        name: {
            "expected": values.get("expected", ""),
            "covered": values.get("covered", ""),
            "skipped": values.get("skipped", ""),
            "missing": values.get("missing", ""),
        }
        for name, values in projection.items()
    },
    "validator_status": {name: oracles.get(name, "") for name in ("antlr4", "bison", "tree-sitter", "source-projection")},
    "lexical_gate_report": str(lexical_report),
    "lexical_gate_status": "PASS",
    "source_feature_rule_ids": source_feature_rules,
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
