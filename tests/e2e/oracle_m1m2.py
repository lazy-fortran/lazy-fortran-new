#!/usr/bin/env python3
"""Independent source/provenance oracle for the M1-M2 gate."""

from __future__ import annotations

import hashlib
import json
import re
import sys
import tomllib
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(message: str) -> None:
    raise SystemExit(f"M1-M2 oracle failure: {message}")


def records(path: Path) -> list[dict]:
    try:
        return [
            row
            for row in (json.loads(line) for line in path.read_text().splitlines() if line.strip())
            if row.get("kind") in {"production-start", "production-continuation"}
        ]
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"invalid production JSONL: {exc}")


def main() -> None:
    if len(sys.argv) < 8:
        raise SystemExit(
            "usage: oracle_m1m2.py FIXTURE PDF ALL.JSONL SELECTED.JSONL "
            "STANDARDIR CLASSIFICATIONS ROOTS LEXICAL [GRAMMAR ...]"
        )
    fixture, pdf, all_jsonl, selected_jsonl, standardir, classifications, roots, lexical = map(
        Path, sys.argv[1:9]
    )
    doc = tomllib.loads(fixture.read_text(encoding="utf-8"))
    golden = tomllib.loads((fixture.parent.parent / "golden" / "m1m2-source-backed-v0.oracle.toml").read_text())
    if digest(pdf) != golden["source_sha256"] or pdf.stat().st_size != golden["source_bytes"]:
        fail("pinned PDF identity differs")

    all_rows = records(all_jsonl)
    selected_rows = records(selected_jsonl)
    starts = lambda rows: [row for row in rows if row.get("kind") == "production-start"]
    continuations = lambda rows: [row for row in rows if row.get("kind") == "production-continuation"]
    all_starts, selected_starts = starts(all_rows), starts(selected_rows)
    if len(all_starts) != doc["expected_production_starts"]:
        fail("full-document production-start count differs")
    if len(selected_starts) != doc["expected_production_starts"]:
        fail("selected production-start count differs")
    if len(selected_rows) != doc["expected_production_starts"] + doc["expected_production_continuations"]:
        fail("selected production record count differs")
    if {row["rule"] for row in all_starts} != {row["rule"] for row in selected_starts}:
        fail("full and selected production rule sets differ")
    for row in all_rows + selected_rows:
        if row.get("origin") != "MECHANICAL":
            fail(f"non-mechanical production origin: {row}")

    standard_lines = standardir.read_text(encoding="utf-8").splitlines()
    if len(standard_lines) != doc["expected_standardir_lines"]:
        fail("StandardIR line count differs")
    if sum(line.startswith("(syntax ") for line in standard_lines) != doc["expected_syntax_records"]:
        fail("StandardIR syntax-record count differs")
    if sum(golden["source_sha256"] in line for line in standard_lines) != len(standard_lines):
        fail("StandardIR source hash coverage is incomplete")
    if not standard_lines[0].startswith("(standardir (format 1) (origin MECHANICAL)"):
        fail("StandardIR header is not mechanical")

    grouped: dict[str, list[dict]] = {}
    current = None
    for row in selected_rows:
        if row["kind"] == "production-start":
            current = row["rule"]
            grouped[current] = [row]
        elif current is not None:
            grouped[current].append(row)
    for witness in golden["witnesses"]:
        rows = grouped.get(witness["rule"])
        if not rows:
            fail(f"missing witness {witness['rule']}")
        start = rows[0]
        for key in ("lhs", "page", "byte_start", "byte_length", "text"):
            expected_key = "start_text" if key == "text" else key
            if start.get(key) != witness[expected_key]:
                fail(f"{witness['rule']} {key} differs")
        actual_continuations = [row["text"] for row in rows[1:]]
        if actual_continuations != witness["continuations"]:
            fail(f"{witness['rule']} continuation sequence differs")

    class_text = classifications.read_text(encoding="utf-8")
    root_text = roots.read_text(encoding="utf-8")
    class_lines = [line for line in class_text.splitlines() if line.startswith("(classification ")]
    root_lines = [line for line in root_text.splitlines() if line.startswith("(root ")]
    if not class_text.startswith("(classifications (format 1) (origin MECHANICAL))"):
        fail("classifications origin is not mechanical")
    if len(class_lines) != doc["expected_classifications"] or len(root_lines) != doc["expected_roots"]:
        fail("closure sidecar count differs")
    if any(golden["source_sha256"] not in line for line in class_lines if "family lexical" not in line):
        fail("closure sidecar source hash coverage is incomplete")

    def sx_value(value: str) -> str:
        if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
            return value[1:-1]
        return value

    lexical_rows = {}
    for line in lexical.read_text(encoding="utf-8").splitlines():
        term = re.search(r"\(source-term ([^) ]+)\)", line)
        target = re.search(r"\(target ([^) ]+)\)", line)
        rule = re.search(r"\(rule ([^) ]+)\)", line)
        page = re.search(r"\(page ([^) ]+)\)", line)
        codepoint = re.search(r"\(codepoint ([^)]+)\)", line)
        canonical = re.search(r"\(canonical-spelling ([^)]+)\)", line)
        source_hash = re.search(r"\(source-sha256 ([0-9a-f]{64})\)", line)
        if term and target and rule and page and codepoint and source_hash:
            lexical_rows[sx_value(term.group(1))] = {
                "target": target.group(1),
                "rule": rule.group(1),
                "page": page.group(1),
                "codepoint": codepoint.group(1),
                "canonical_spelling": sx_value(canonical.group(1)) if canonical else "",
                "source_sha256": source_hash.group(1),
            }
    witnesses = golden.get("lexical_witnesses", [])
    if len(witnesses) != doc["expected_lexical_witnesses"]:
        fail("lexical witness count differs")
    for witness in witnesses:
        actual = lexical_rows.get(witness["source_term"])
        if actual is None:
            fail(f"missing lexical witness {witness['source_term']}")
        for key in ("target", "rule", "page", "codepoint"):
            if actual[key] != witness[key]:
                fail(f"lexical witness {witness['source_term']} {key} differs")
        if actual["canonical_spelling"] != witness.get("canonical_spelling", ""):
            fail(f"lexical witness {witness['source_term']} canonical spelling differs")
        if actual["source_sha256"] != golden["source_sha256"]:
            fail(f"lexical witness {witness['source_term']} source hash differs")

    extra = sys.argv[9:]
    negative = None
    if "--negative" in extra:
        marker = extra.index("--negative")
        if len(extra) != marker + 3:
            fail("negative oracle arguments are incomplete")
        negative = Path(extra[marker + 1])
        negative_golden = tomllib.loads(
            Path(extra[marker + 2]).read_text(encoding="utf-8")
        )
        extra = extra[:marker]
        negative_text = negative.read_text(encoding="utf-8")
        if negative_text.count("(") <= negative_text.count(")"):
            fail("negative fixture was not an unclosed SX neighbor")
        if negative_golden.get("oracle") != "balanced-parentheses":
            fail("negative fixture oracle is not the declared independent oracle")
        if negative_golden.get("diagnostic") != "unclosed-sx-list":
            fail("negative fixture diagnostic golden differs")
    if negative is not None:
        print("M1-M2 negative oracle: PASS")

    if extra:
        patterns = {
            "antlr": re.compile(r"^\s*(r_[A-Za-z0-9_]+)\s*:", re.M),
            "bison": re.compile(r"^\s*(r_[A-Za-z0-9_]+)\s*:", re.M),
            "tree-sitter": re.compile(r"^\s*(r_[A-Za-z0-9_]+):\s*\$\s*=>", re.M),
        }
        for path, expected_name in zip(map(Path, extra), patterns):
            text = path.read_text(encoding="utf-8")
            definitions = patterns[expected_name].findall(text)
            if len(definitions) != doc["expected_target_definitions"]:
                fail(f"{expected_name} target definition count differs")
            if len(set(definitions)) != len(definitions):
                fail(f"{expected_name} has duplicate target definitions")
            for witness in witnesses:
                if f"source-term={witness['source_term']}" not in text:
                    fail(f"{expected_name} lexical source spelling is missing")
                if witness["target"] not in text:
                    fail(f"{expected_name} lexical target is missing")
                if witness.get("canonical_spelling") and (
                    f"canonical-spelling={witness['canonical_spelling']}" not in text
                ):
                    fail(f"{expected_name} lexical canonical spelling is missing")

    print("M1-M2 source oracle: PASS")


if __name__ == "__main__":
    main()
