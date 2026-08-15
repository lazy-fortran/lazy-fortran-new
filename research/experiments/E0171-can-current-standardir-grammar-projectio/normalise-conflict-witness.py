#!/usr/bin/env python3
"""Normalize parser-generator conflict evidence without adjudicating it.

The output is an inventory for later classification.  It deliberately does
not infer a precedence, conflict declaration, or language result from a
diagnostic.  The lossless Bison and Tree-sitter logs remain the evidence.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
from pathlib import Path


TREE_SYMBOL = re.compile(r"\br_[A-Za-z0-9_x]+\b")
TREE_RULE = re.compile(
    r"^\s*(r_[A-Za-z0-9_x]+)\s*:.*?//\s*rule=([^\s]+).*?source-lineage=([^\s]+)"
)
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def tree_source_rules(grammar: Path) -> dict[str, set[str]]:
    values: dict[str, set[str]] = {}
    for line in grammar.read_text(encoding="utf-8").splitlines():
        match = TREE_RULE.match(line)
        if match:
            rule = match.group(2)
            lineage_rules = [part.split(":", 1)[0] for part in match.group(3).split(",")]
            values.setdefault(match.group(1), set()).update(
                lineage_rules or [rule]
            )
    return values


def tree_rows(log: Path, grammar: Path) -> list[dict[str, str]]:
    lines = ANSI.sub("", log.read_text(encoding="utf-8")).splitlines()
    mapping = tree_source_rules(grammar)
    rows: list[dict[str, str]] = []
    index = 0
    while index < len(lines):
        if "Unresolved conflict for symbol sequence:" not in lines[index]:
            index += 1
            continue
        start = index
        index += 1
        while index < len(lines) and not lines[index].startswith("    Possible resolutions:"):
            index += 1
        block = lines[start:index]
        symbols = sorted(set(TREE_SYMBOL.findall("\n".join(block))))
        sources = sorted({
            source
            for symbol in symbols
            for source in mapping.get(symbol, set())
        })
        rows.append({
            "target": "tree-sitter",
            "profile": "selected-program",
            "kind": "unresolved",
            "lookahead_or_prefix": " ".join(line.strip() for line in block[1:]),
            "participants": ",".join(symbols),
            "source_rule_ids": ",".join(sources),
            "evidence_status": "generator-diagnostic",
            "classification": "UNCLASSIFIED",
            "evidence_sha256": hashlib.sha256(
                ("\n".join(block) + "\n").encode("utf-8")
            ).hexdigest(),
        })
    return rows


def bison_rows(path: Path, profile: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            if row["profile"] != profile:
                continue
            rows.append({
                "target": "bison",
                "profile": row["profile"],
                "kind": row["kind"],
                "lookahead_or_prefix": row["lookahead"],
                "participants": row["rule_symbols"],
                "source_rule_ids": row["source_rule_ids"],
                "evidence_status": row["witness_status"],
                "classification": "UNCLASSIFIED",
                "evidence_sha256": ";".join((
                    row["first_example_sha256"],
                    row["second_example_sha256"],
                )),
            })
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("bison_tsv", type=Path)
    parser.add_argument("tree_sitter_log", type=Path)
    parser.add_argument("tree_sitter_grammar", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    rows = bison_rows(args.bison_tsv, "selected-program")
    rows.extend(tree_rows(args.tree_sitter_log, args.tree_sitter_grammar))
    fields = [
        "target", "profile", "kind", "lookahead_or_prefix", "participants",
        "source_rule_ids", "evidence_status", "classification", "evidence_sha256",
    ]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
    print(f"normalized_conflicts\t{len(rows)}")
    print(f"output\t{args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
