#!/usr/bin/env python3
"""Generate the R401/R402/R403 closure sidecars from one StandardIR input."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def source_fields(line: str) -> tuple[str, str, str, str]:
    match = re.search(
        r"\(source \(document ([^) ]+)\) \(clause ([^) ]+)\) "
        r"\(page ([0-9]+)\) \(source-sha256 ([0-9a-f]{64})\)\)",
        line,
    )
    if not match:
        raise ValueError(f"missing lexical source record: {line}")
    return match.groups()


def main() -> None:
    if len(sys.argv) != 5:
        raise SystemExit("usage: generate_m1m2_sidecars.py STANDARDIR LEXICAL CLASSIFICATIONS ROOTS")
    standardir, lexical, classifications, roots = map(Path, sys.argv[1:])
    text = standardir.read_text(encoding="utf-8")
    lhs = list(dict.fromkeys(re.findall(r"\(lhs ([^) ]+)\)", text)))
    refs = set(re.findall(r"\(ref ([^) ]+)\)", text))
    missing = refs - set(lhs)

    # R401 list expansion may expose a base that was not itself a source ref.
    # R402 maps every *-name to the normative `name` production, not to a
    # guessed production formed by stripping the suffix.
    missing |= {
        name[:-5]
        for name in missing
        if name.endswith("-list") and name[:-5] not in lhs
    }
    source_hash = re.search(r"source-sha256 ([0-9a-f]{64})", text)
    if source_hash is None:
        raise SystemExit("StandardIR has no source hash")
    sha = source_hash.group(1)

    lexical_rows = {}
    for line in lexical.read_text(encoding="utf-8").splitlines():
        term = re.search(r"\(source-term ([^) ]+)\)", line)
        target = re.search(r"\(target ([^) ]+)\)", line)
        rule = re.search(r"\(rule ([^) ]+)\)", line)
        if term and target and rule:
            lexical_rows[term.group(1)] = (target.group(1), rule.group(1), line)

    lines = ["(classifications (format 1) (origin MECHANICAL))"]
    for name in sorted(missing):
        if name.endswith("-list"):
            lines.append(
                f'(classification (name {name}) (kind list) '
                f'(target {name[:-5]}) (separator ",") (family R401) '
                f'(suffix -list) (source (document J3-24-007) (clause 4) '
                f'(rule R401) (page 45) (source-sha256 {sha})))'
            )
        elif name.endswith("-name"):
            lines.append(
                f'(classification (name {name}) (kind alias) (target name) '
                f'(family R402) (suffix -name) (source (document J3-24-007) '
                f'(clause 4) (rule R402) (page 45) (source-sha256 {sha})))'
            )
        elif name.startswith("scalar-"):
            lines.append(
                f'(classification (name {name}) (kind scalar) '
                f'(target {name[7:]}) (family R403) (prefix scalar-) '
                f'(source (document J3-24-007) (clause 4) (rule R403) '
                f'(page 45) (source-sha256 {sha})))'
            )
        elif name == "xyz":
            lines.append(
                f'(classification (name xyz) (kind semantic-only) '
                f'(family metanotation) (source (document J3-24-007) '
                f'(clause 4) (rule R401) (page 45) (source-sha256 {sha})))'
            )
        elif name in {"letter", "digit", "rep-char"}:
            if name not in lexical_rows:
                raise SystemExit(f"missing lexical fact for {name}")
            target, rule, source_line = lexical_rows[name]
            document, clause, page, lexical_hash = source_fields(source_line)
            if lexical_hash != sha:
                raise SystemExit(f"lexical source hash differs for {name}")
            lines.append(
                f'(classification (name {name}) (kind lexical) (terminal {target}) '
                f'(family lexical) (source (document {document}) (clause {clause}) '
                f'(rule {rule}) (page {page}) (source-sha256 {sha})))'
            )
        else:
            raise SystemExit(f"unclassified assumed-syntax name: {name}")

    classifications.write_text("\n".join(lines) + "\n", encoding="utf-8")
    # sxgrammar's pinned roots reader accepts only `(root NAME)` records;
    # provenance for this mechanical sidecar is carried by the central trace.
    roots.write_text("".join(f"(root {name})\n" for name in lhs), encoding="utf-8")


if __name__ == "__main__":
    main()
