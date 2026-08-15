#!/usr/bin/env python3
"""Audit selected Bison target reachability without using reference bodies."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict, deque
from pathlib import Path


HEAD = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")
SPLIT_HEAD = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*$")
SPLIT_COLON = re.compile(r"^\s*:\s*(.*)$")
SYMBOL = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
LINEAGE = re.compile(r"source-lineage=([^ ]+)")


def parse_grammar(text: str) -> tuple[str, dict[str, list[tuple[str, str]]]]:
    start = re.search(r"^%start\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", text, re.MULTILINE)
    if not start:
        raise SystemExit("missing Bison start declaration")
    lines = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL).splitlines()
    rules: dict[str, list[tuple[str, str]]] = {}
    i = 0
    while i < len(lines):
        match = HEAD.match(lines[i])
        if match:
            lhs, rest = match.group(1), match.group(2).strip()
            i += 1
        elif i + 1 < len(lines) and SPLIT_HEAD.match(lines[i]) and SPLIT_COLON.match(lines[i + 1]):
            lhs = lines[i].strip()
            rest = SPLIT_COLON.match(lines[i + 1]).group(1).strip()
            i += 2
        else:
            i += 1
            continue
        chunks = [rest]
        while not any(chunk.rstrip().endswith(";") for chunk in chunks):
            if i >= len(lines):
                raise SystemExit(f"unterminated production: {lhs}")
            chunks.append(lines[i].strip())
            i += 1
        body_text = " ".join(chunks)
        if ";" not in body_text:
            raise SystemExit(f"unterminated production: {lhs}")
        body_text = body_text.rsplit(";", 1)[0]
        bodies = [body.strip() for body in re.split(r"\s*\|\s*", body_text)
                  if body.strip()]
        rules.setdefault(lhs, []).extend((body, "") for body in bodies)
    if not rules:
        raise SystemExit("no Bison productions found")
    return start.group(1), rules


def graph(rules: dict[str, list[tuple[str, str]]]) -> dict[str, set[str]]:
    names = set(rules)
    result: dict[str, set[str]] = defaultdict(set)
    for lhs, bodies in rules.items():
        for body, _ in bodies:
            result[lhs].update(symbol for symbol in SYMBOL.findall(body) if symbol in names)
    return result


def reachable(start: str, edges: dict[str, set[str]]) -> set[str]:
    seen = {start}
    queue = deque([start])
    while queue:
        for name in sorted(edges.get(queue.popleft(), ())):
            if name not in seen:
                seen.add(name)
                queue.append(name)
    return seen


def lineage_count(text: str, names: set[str]) -> dict[str, int]:
    result = {name: 0 for name in names}
    current = None
    for line in text.splitlines():
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:", line)
        if match:
            current = match.group(1)
        if current in result:
            result[current] += len(LINEAGE.findall(line))
    return result


def mutation_control(start: str, rules: dict[str, list[tuple[str, str]]]) -> str:
    edges = graph(rules)
    incoming: dict[str, list[str]] = defaultdict(list)
    for lhs, refs in edges.items():
        for ref in refs:
            incoming[ref].append(lhs)
    candidate = next((name for name in sorted(rules)
                      if name != start and len(incoming[name]) == 1 and name in reachable(start, edges)), None)
    if candidate is None:
        return "NOT_APPLICABLE"
    parent = incoming[candidate][0]
    mutated = {lhs: [body for body, _ in bodies] for lhs, bodies in rules.items()}
    mutated[parent] = [body.replace(candidate, "e0151_removed_edge", 1)
                       for body, _ in rules[parent]]
    before = reachable(start, edges)
    after = reachable(start, graph({lhs: [(body, "") for body in bodies]
                                    for lhs, bodies in mutated.items()}))
    return "PASS" if candidate in before and candidate not in after else "FAIL"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--grammar", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    text = args.grammar.read_text(encoding="utf-8")
    start, rules = parse_grammar(text)
    edges = graph(rules)
    reached = reachable(start, edges)
    all_names = set(rules)
    unreachable = all_names - reached
    lineages = lineage_count(text, all_names)
    rows = ["lhs\treachable\trule_count\tlineage_records"]
    for lhs in sorted(all_names):
        rows.append(f"{lhs}\t{'yes' if lhs in reached else 'no'}\t{len(rules[lhs])}\t{lineages[lhs]}")
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "reachability.tsv").write_text("\n".join(rows) + "\n", encoding="utf-8")
    control = mutation_control(start, rules)
    (args.output / "mutation.log").write_text(f"mutation_reachability_control={control}\n", encoding="utf-8")
    summary = {
        "grammar": str(args.grammar),
        "start": start,
        "normalized_target_nonterminals": len(all_names),
        "reachable_target_nonterminals": len(reached),
        "unreachable_target_nonterminals": len(unreachable),
        "unreachable_names": sorted(unreachable),
        "unreachable_rules": sum(len(rules[name]) for name in unreachable),
        "retained_source_lineage_records": sum(lineages[name] for name in reached),
        "pruned_source_lineage_records": sum(lineages[name] for name in unreachable),
        "mutation_reachability_control": control,
    }
    (args.output / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
