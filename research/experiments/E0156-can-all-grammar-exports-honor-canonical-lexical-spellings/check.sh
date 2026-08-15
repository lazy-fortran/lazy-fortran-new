#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
run_dir=${1:?usage: check.sh <E0154-run> [report.tsv]}
report=${2:-"$script_dir/report.tsv"}
run_dir=$(cd -- "$run_dir" && pwd)

for file in grammar.ebnf Fortran2023.g4 fortran2023.y grammar.js input/lexical-facts-v0.sx; do
    [[ -f "$run_dir/$file" ]] || { printf 'missing input: %s\n' "$run_dir/$file" >&2; exit 2; }
done

python3 - "$run_dir" "$report" <<'PY'
from __future__ import annotations

import re
import shutil
import sys
import tempfile
from pathlib import Path

run = Path(sys.argv[1])
report = Path(sys.argv[2])

def strip_comments(name: str, text: str) -> str:
    if name == "grammar.ebnf":
        return re.sub(r"\(\*.*?\*\)", "", text, flags=re.S)
    if name == "fortran2023.y":
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
        return re.sub(r"//[^\n]*", "", text)
    if name == "Fortran2023.g4":
        return re.sub(r"//[^\n]*", "", text)
    if name == "grammar.js":
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
        return re.sub(r"//[^\n]*", "", text)
    raise ValueError(name)

def lexical_facts(text: str) -> list[tuple[str, str]]:
    facts = re.findall(
        r'\(lexical-fact\s+\(source-term\s+"(.*?)"\)\s+'
        r'\(canonical-spelling\s+"(.*?)"\)', text
    )
    if not facts:
        raise ValueError("no canonical lexical facts in source input")
    return facts

def evaluate(directory: Path) -> dict[str, str]:
    source = (directory / "input/lexical-facts-v0.sx").read_text(encoding="utf-8")
    facts = lexical_facts(source)
    rows: dict[str, str] = {}
    all_ok = True
    for name in ("grammar.ebnf", "Fortran2023.g4", "fortran2023.y", "grammar.js"):
        text = (directory / name).read_text(encoding="utf-8")
        body = strip_comments(name, text)
        raw_counts = [body.count(source_term) for source_term, _ in facts]
        canonical_counts = [body.count(canonical) for _, canonical in facts]
        source_witnesses = all(source_term in text for source_term, _ in facts)
        canonical_witnesses = all(
            f"canonical-spelling={canonical}" in text for _, canonical in facts
        )
        body_clean = all(count == 0 for count in raw_counts)
        body_has_canonical = all(
            canonical_count >= raw_count
            for canonical_count, raw_count in zip(canonical_counts, raw_counts)
        )
        if name == "Fortran2023.g4":
            body_has_canonical = body_has_canonical and "EN_DASH : '-'" in body and \
                "RIGHT_SINGLE_QUOTE : '\\''" in body
        elif name == "fortran2023.y":
            body_has_canonical = body_has_canonical and 'EN_DASH "-"' in body and \
                'RIGHT_SINGLE_QUOTE "\'"' in body
        elif name == "grammar.js":
            body_has_canonical = body_has_canonical and "EN_DASH: $ => '-'" in body and \
                "RIGHT_SINGLE_QUOTE: $ => '\\''" in body
        ok = source_witnesses and canonical_witnesses and body_clean and body_has_canonical
        all_ok = all_ok and ok
        prefix = name.replace('.', '_')
        rows[f"{prefix}_source_witnesses"] = "PASS" if source_witnesses else "FAIL"
        rows[f"{prefix}_canonical_witnesses"] = "PASS" if canonical_witnesses else "FAIL"
        rows[f"{prefix}_raw_u2013_u2019_in_body"] = str(sum(raw_counts))
        rows[f"{prefix}_canonical_body_witnesses"] = "PASS" if body_has_canonical else "FAIL"
        rows[f"{prefix}_status"] = "PASS" if ok else "FAIL"
    rows["format_gate_status"] = "PASS" if all_ok else "FAIL"
    return rows

rows = evaluate(run)

with tempfile.TemporaryDirectory(prefix="e0156-mutation-") as temporary:
    mutation = Path(temporary)
    shutil.copytree(run, mutation, dirs_exist_ok=True)
    mutated = mutation / "grammar.ebnf"
    value = mutated.read_text(encoding="utf-8")
    value = value.replace("canonical-spelling=-", "canonical-spelling=–", 1)
    mutated.write_text(value, encoding="utf-8")
    mutation_failed = False
    try:
        mutation_failed = evaluate(mutation)["format_gate_status"] == "FAIL"
    except (ValueError, UnicodeError):
        mutation_failed = True
rows["negative_mutation"] = "PASS" if mutation_failed else "FAIL"

report.parent.mkdir(parents=True, exist_ok=True)
report.write_text(
    "field\tvalue\n" + "".join(f"{key}\t{value}\n" for key, value in rows.items()),
    encoding="utf-8",
)
print(report.read_text(encoding="utf-8"), end="")
if rows["format_gate_status"] != "PASS" or rows["negative_mutation"] != "PASS":
    raise SystemExit(1)
PY
