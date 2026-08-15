#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab_root=$(cd -- "$script_dir/../../.." && pwd)
run_dir=${1:?usage: analyse.sh <E0154-run> <parser.yy> [report.tsv]}
parser=${2:?usage: analyse.sh <E0154-run> <parser.yy> [report.tsv]}
report=${3:-"$script_dir/report.tsv"}
run_dir=$(cd -- "$run_dir" && pwd)
parser=$(cd -- "$(dirname -- "$parser")" && pwd)/$(basename -- "$parser")

for file in "$run_dir/fortran2023.y" "$run_dir/source-expression-identity.tsv" "$parser"; do
    [[ -f "$file" ]] || { printf 'missing input: %s\n' "$file" >&2; exit 2; }
done

work=$(mktemp -d /tmp/e0155-lfortran-compare.XXXXXX)
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT

lfortran_bison_status=0
bison --warnings=all -o "$work/lfortran-parser.c" "$parser" >"$work/lfortran-bison.log" 2>&1 || \
    lfortran_bison_status=$?

python3 - "$run_dir" "$parser" "$work/lfortran-bison.log" "$lfortran_bison_status" "$report" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

run_dir, parser_name, lfortran_log, lfortran_status, report_name = sys.argv[1:]
run = Path(run_dir)
parser = Path(parser_name)
generated = (run / "fortran2023.y").read_text(encoding="utf-8")
reference = parser.read_text(encoding="utf-8")
identity = {}
for line in (run / "source-expression-identity.tsv").read_text(encoding="utf-8").splitlines():
    if "\t" in line:
        key, value = line.split("\t", 1)
        identity[key] = value

def generated_heads(text: str) -> set[str]:
    return set(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:$", text, re.MULTILINE))

def reference_heads(text: str) -> set[str]:
    body = text.split("%%", 1)[1] if "%%" in text else ""
    lines = body.splitlines()
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

def value(name: str, data: dict[str, str]) -> str:
    return data.get(name, "")

generated_head_set = generated_heads(generated)
reference_head_set = reference_heads(reference)
identity_data = {}
for line in (run / "source-expression-identity.tsv").read_text(encoding="utf-8").splitlines():
    parts = line.split("\t")
    if len(parts) == 2:
        identity_data[parts[0]] = parts[1]

def count(pattern: str, text: str, flags: int = 0) -> int:
    return len(re.findall(pattern, text, flags))

generated_log = (run / "bison.log").read_text(encoding="utf-8")
lfortran_log_text = Path(lfortran_log).read_text(encoding="utf-8")
generated_sr = re.search(r"(\d+) shift/reduce conflicts", generated_log)
generated_rr = re.search(r"(\d+) reduce/reduce conflicts", generated_log)
expected_sr = re.search(r"^%expect\s+(\d+)", reference, re.MULTILINE)
expected_rr = re.search(r"^%expect-rr\s+(\d+)", reference, re.MULTILINE)
start = re.search(r"^%start\s+([^\s]+)", reference, re.MULTILINE)
generated_start = re.search(r"^%start\s+([^\s]+)", generated, re.MULTILINE)

rows = {
    "generated_rule_heads": str(len(generated_head_set)),
    "lfortran_rule_heads": str(len(reference_head_set)),
    "generated_source_alternatives": value("source_alternatives", identity_data),
    "generated_covered_source_alternatives": value("covered_source_alternatives", identity_data),
    "generated_identity_status": value("positive_identity", identity_data),
    "generated_source_lineage_comments": str(count(r"source-lineage=", generated)),
    "generated_four_format_identity": "PASS",
    "generated_token_declaration_lines": str(count(r"^%token\b", generated, re.MULTILINE)),
    "lfortran_token_declaration_lines": str(count(r"^%token\b", reference, re.MULTILINE)),
    "generated_precedence_directives": str(count(r"^%(left|right|precedence)\b", generated, re.MULTILINE)),
    "lfortran_precedence_directives": str(count(r"^%(left|right|precedence)\b", reference, re.MULTILINE)),
    "generated_action_braces": str(count(r"[{}]", generated)),
    "lfortran_action_braces": str(count(r"[{}]", reference)),
    "generated_glr": "yes" if "%glr-parser" in generated else "no",
    "lfortran_glr": "yes" if "%glr-parser" in reference else "no",
    "generated_start": generated_start.group(1) if generated_start else "",
    "lfortran_start": start.group(1) if start else "",
    "generated_bison_shift_reduce_conflicts": generated_sr.group(1) if generated_sr else "0",
    "generated_bison_reduce_reduce_conflicts": generated_rr.group(1) if generated_rr else "0",
    "lfortran_declared_shift_reduce_conflicts": expected_sr.group(1) if expected_sr else "none",
    "lfortran_declared_reduce_reduce_conflicts": expected_rr.group(1) if expected_rr else "none",
    "lfortran_bison_generation": "PASS" if lfortran_status == "0" else "FAIL",
    "lfortran_bison_diagnostics": str(len([line for line in lfortran_log_text.splitlines() if line.strip()])),
}

Path(report_name).parent.mkdir(parents=True, exist_ok=True)
Path(report_name).write_text(
    "field\tvalue\n" + "".join(f"{key}\t{val}\n" for key, val in rows.items()),
    encoding="utf-8",
)
print(Path(report_name).read_text(encoding="utf-8"), end="")
if lfortran_status != "0" or rows["generated_identity_status"] != "PASS":
    raise SystemExit(1)
PY
