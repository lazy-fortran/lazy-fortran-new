#!/usr/bin/env python3
"""Validate selected-root entry and EOF contracts independently of generators."""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(message)


def policy(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    required = {"format", "source-root", "target-root", "entry-rule",
                "eof-policy", "artifact"}
    if not rows or any(set(row) != required for row in rows):
        fail(f"{path}: malformed profile policy")
    if len({row["format"] for row in rows}) != len(rows):
        fail(f"{path}: duplicate format")
    return rows


def metadata(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        fields = line.split("\t", 1)
        if len(fields) == 2:
            values[fields[0]] = fields[1]
    return values


def profile_header(text: str, row: dict[str, str]) -> bool:
    pattern = (r"profile\s+format=" + re.escape(row["format"]) +
               r"\s+entry=" + re.escape(row["entry-rule"]) +
               r"\s+source-root=" + re.escape(row["source-root"]) +
               r"\s+eof=" + re.escape(row["eof-policy"]) + r"(?:\s|\*/|\*)")
    return re.search(pattern, text) is not None


def rule_window(text: str, name: str, limit: int = 16) -> str:
    lines = text.splitlines()
    start = next((index for index, line in enumerate(lines)
                  if re.match(rf"^\s*{re.escape(name)}\s*:", line)), None)
    if start is None:
        return ""
    return "\n".join(lines[start:start + limit])


def entry_status(text: str, row: dict[str, str]) -> tuple[str, str]:
    fmt = row["format"]
    entry = re.escape(row["entry-rule"])
    target = re.escape(row["target-root"])
    if fmt == "ebnf":
        match = re.search(rf"(?m)^{entry}\s*::=\s*.*{target}.*$", text)
        return ("PASS", "explicit-wrapper") if match else ("FAIL", "missing-wrapper")
    if fmt == "antlr4":
        window = " ".join(rule_window(text, row["entry-rule"]).splitlines())
        match = re.search(rf"{entry}\s*:\s*{target}\s+EOF\s*;", window)
        return ("PASS", "entry-and-EOF") if match else ("FAIL", "missing-entry-or-EOF")
    if fmt == "bison":
        start = re.search(rf"(?m)^%start\s+{entry}\s*$", text)
        window = " ".join(rule_window(text, row["entry-rule"]).splitlines())
        body = re.search(rf"{entry}\s*:\s*.*?{target}.*?;", window)
        return ("PASS", "start-and-parser-EOF") if start and body else ("FAIL", "missing-start-or-body")
    if fmt == "tree-sitter":
        marker = text.find("rules:")
        if marker < 0:
            return "FAIL", "missing-rules-object"
        first_rule = None
        lines = text[marker:].splitlines()
        for line in lines[1:]:
            stripped = line.strip()
            if not stripped or stripped.startswith("//") or stripped.startswith("/*"):
                continue
            match = re.match(r"([A-Za-z_][A-Za-z0-9_]*):", stripped)
            if match:
                first_rule = match.group(1)
                break
        rules = first_rule == row["entry-rule"] and re.search(
            rf"\$\s*=>.*?\$\.{target}",
            rule_window(text, row["entry-rule"])) is not None
        return ("PASS", "first-entry-and-implicit-EOF") if rules else ("FAIL", "missing-first-entry")
    fail(f"unknown format {fmt}")


def lexer_contract(path: Path) -> tuple[str, int]:
    rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip()]
    if not rows or rows[0].get("kind") != "lexer-contract-header":
        return "FAIL", 0
    if rows[0].get("format") != 1 or rows[0].get("origin") != "MECHANICAL":
        return "FAIL", len(rows) - 1
    tokens = rows[1:]
    if not tokens or any(row.get("kind") != "lexer-token" or
                         row.get("origin") != "MECHANICAL" or
                         not re.fullmatch(r"[0-9a-f]{64}", row.get("source_hash", ""))
                         for row in tokens):
        return "FAIL", len(tokens)
    if len({row.get("token_name") for row in tokens}) != len(tokens):
        return "FAIL", len(tokens)
    return "PASS", len(tokens)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run", type=Path)
    parser.add_argument("policy", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    values = metadata(args.run / "metadata.tsv")
    rows = policy(args.policy)
    failures: list[str] = []
    report: list[dict[str, str]] = []
    for row in rows:
        artifact = args.run / row["artifact"]
        if not artifact.is_file():
            failures.append(f"{row['format']}: missing artifact")
            continue
        text = artifact.read_text(encoding="utf-8")
        header = "PASS" if profile_header(text, row) else "FAIL"
        entry, evidence = entry_status(text, row)
        status = "PASS" if header == "PASS" and entry == "PASS" else "FAIL"
        if status != "PASS":
            failures.append(f"{row['format']}: header={header}, entry={evidence}")
        report.append({"format": row["format"], "header": header,
                       "entry": entry, "evidence": evidence, "status": status})
    if values.get("selected-root") != rows[0]["source-root"]:
        failures.append("metadata selected-root disagrees with profile policy")
    lexer, lexer_rows = lexer_contract(args.run / "lexer-contract.jsonl")
    if lexer != "PASS":
        failures.append("lexer contract is not normalized mechanical evidence")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["format", "header", "entry",
                                                     "evidence", "status"], delimiter="\t")
        writer.writeheader()
        writer.writerows(report)
        handle.write(f"lexer_contract\t{lexer}\trows={lexer_rows}\n")
        handle.write(f"selected_root\t{values.get('selected-root', '')}\n")
        handle.write(f"status\t{'PASS' if not failures else 'FAIL'}\n")
        for failure in failures:
            handle.write(f"failure\t{failure}\n")
    print(args.output.read_text(encoding="utf-8"), end="")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
