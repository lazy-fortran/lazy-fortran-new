#!/usr/bin/env python3
"""Measure deterministic unit-alias factoring on a generated Bison target."""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
from pathlib import Path


SYMBOL = re.compile(r"\b(?:r|h)_[A-Za-z0-9_]+\b")
PRODUCTION = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")


def command(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=False)


def strip_comments(text: str) -> str:
    return re.sub(r"/\*.*?\*/", " ", text, flags=re.S)


def productions(text: str) -> list[tuple[str, str, int, int]]:
    lines = text.splitlines()
    found: list[tuple[str, str, int, int]] = []
    i = 0
    while i < len(lines):
        match = PRODUCTION.match(lines[i])
        if not match:
            i += 1
            continue
        lhs, rest = match.groups()
        start = i
        block = [rest]
        i += 1
        while ";" not in block[-1] and i < len(lines):
            block.append(lines[i])
            i += 1
        cleaned = strip_comments("\n".join(block))
        alternatives = [part.strip() for part in cleaned.split("|")]
        alternatives = [part[:-1].strip() if part.endswith(";") else part
                        for part in alternatives]
        for alternative, value in enumerate(alternatives, 1):
            found.append((lhs, value, start + 1, alternative))
    return found


def unit_aliases(items: list[tuple[str, str, int, int]]) -> dict[str, str]:
    heads = {lhs for lhs, _, _, _ in items}
    by_head: dict[str, list[str]] = {}
    for lhs, rhs, _, _ in items:
        by_head.setdefault(lhs, []).append(rhs)
    aliases: dict[str, str] = {}
    for lhs, alternatives in by_head.items():
        # An alias is a whole production with exactly one alternative.  A
        # single unit alternative inside a multi-alternative production is
        # not a production alias; deleting its head would delete the other
        # alternatives and change the language.
        if len(alternatives) != 1:
            continue
        rhs = alternatives[0]
        symbols = SYMBOL.findall(rhs)
        if len(symbols) == 1 and rhs.strip() == symbols[0] and symbols[0] in heads:
            aliases[lhs] = symbols[0]
    changed = True
    while changed:
        changed = False
        for lhs, target in list(aliases.items()):
            final = aliases.get(target, target)
            if final != target:
                aliases[lhs] = final
                changed = True
    return {lhs: target for lhs, target in aliases.items()
            if lhs != target and lhs != "standardir_start"}


def replace_symbols(text: str, aliases: dict[str, str]) -> str:
    def replace(match: re.Match[str]) -> str:
        return aliases.get(match.group(0), match.group(0))
    return SYMBOL.sub(replace, text)


def factor(text: str, aliases: dict[str, str]) -> str:
    lines = text.splitlines()
    first_production = next(
        (index for index, line in enumerate(lines) if PRODUCTION.match(line)),
        len(lines),
    )
    output = lines[:first_production]
    i = first_production
    removed: set[str] = set(aliases)
    while i < len(lines):
        match = PRODUCTION.match(lines[i])
        if not match:
            output.append(lines[i])
            i += 1
            continue
        lhs = match.group(1)
        block = [lines[i]]
        i += 1
        while ";" not in block[-1] and i < len(lines):
            block.append(lines[i])
            i += 1
        if lhs in removed:
            continue
        for line_number, line in enumerate(block):
            # Keep source comments byte-for-byte.  Only target grammar text
            # is normalized; provenance comments are not target syntax.
            if "/*" in line or line_number == 0:
                if line_number == 0 and ":" in line:
                    lhs_text, rhs = line.split(":", 1)
                    output.append(lhs_text + ":" + replace_symbols(rhs, aliases))
                else:
                    output.append(line)
            else:
                output.append(replace_symbols(line, aliases))
    marker = [
        "/* target-normalization=deterministic-unit-alias-factoring */",
        "/* role aliases remain in source StandardIR; see alias-mapping.tsv */",
    ]
    return "\n".join(output[:1] + marker + output[1:]) + "\n"


def bison(path: Path, run_dir: Path, name: str) -> dict[str, int | str]:
    report = run_dir / f"{name}.output"
    stderr = run_dir / f"{name}.stderr"
    result = command(["bison", "--warnings=all", "--report=state,solved",
                      f"--report-file={report}", "-o", run_dir / f"{name}.c", path])
    stderr.write_text(result.stderr, encoding="utf-8")
    shift = reduce = 0
    if report.exists():
        for line in report.read_text(encoding="utf-8", errors="replace").splitlines():
            for count, kind in re.findall(r"(\d+) (shift/reduce|reduce/reduce)", line):
                if kind == "shift/reduce":
                    shift += int(count)
                else:
                    reduce += int(count)
    useless_nonterminals = re.search(r"warning: (\d+) nonterminals useless in grammar", result.stderr)
    useless_rules = re.search(r"warning: (\d+) rules useless in grammar", result.stderr)
    return {
        "status": "PASS" if result.returncode == 0 and "error:" not in result.stderr else "FAIL",
        "exit": result.returncode,
        "shift_reduce_conflicts": shift,
        "reduce_reduce_conflicts": reduce,
        "useless_nonterminals": int(useless_nonterminals.group(1)) if useless_nonterminals else 0,
        "useless_rules": int(useless_rules.group(1)) if useless_rules else 0,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lab-root", type=Path, required=True)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--grammar", type=Path, required=True)
    parser.add_argument("--representative", default=None,
                        help="factor only aliases resolving to this target")
    args = parser.parse_args()
    run_dir = args.run_dir.resolve()
    run_dir.mkdir(parents=True, exist_ok=True)
    source = args.grammar.resolve()
    text = source.read_text(encoding="utf-8")
    items = productions(text)
    aliases = unit_aliases(items)
    if args.representative is not None:
        aliases = {alias: target for alias, target in aliases.items()
                   if target == args.representative}
    transformed = factor(text, aliases)
    transformed_path = run_dir / "factored.y"
    transformed_path.write_text(transformed, encoding="utf-8")
    with (run_dir / "alias-mapping.tsv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(["alias", "representative", "origin"])
        for alias, target in sorted(aliases.items()):
            writer.writerow([alias, target, "MECHANICAL"])
    baseline = bison(source, run_dir, "baseline")
    factored = bison(transformed_path, run_dir, "factored")
    summary = {
        "experiment": "E0150",
        "source": str(source),
        "source_production_heads": len({lhs for lhs, _, _, _ in items}),
        "source_alternatives": len(items),
        "candidate_unit_aliases": len(aliases),
        "factored_unit_aliases": len(aliases),
        "factor_mode": ("all-single-unit-aliases" if args.representative is None
                         else "representative-family"),
        "representative": args.representative,
        "merged_role_families": len({target for target in aliases.values()
                                     if list(aliases.values()).count(target) > 1}),
        "provenance_mapping_rows": len(aliases),
        "unmapped_factored_aliases": 0,
        "baseline": baseline,
        "factored": factored,
        "status": "reported" if factored["status"] == "PASS" else "verification_failure",
    }
    (run_dir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n",
                                            encoding="utf-8")
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
