#!/usr/bin/env python3
"""Inventory generated grammar projections and pinned comparison files.

This is deliberately an inventory, not a pairwise grammar-equivalence claim.
The source-backed candidate is authoritative; reference files are classified
as parser-engineering comparisons only.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


def lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines()


def bison_inventory(path: Path) -> tuple[dict[str, int], int | None, int]:
    heads: dict[str, int] = {}
    alternatives = 0
    provenance = 0
    current = None
    source = lines(path)
    for index, line in enumerate(source):
        if "source-lineage=" in line:
            provenance += 1
        if line.lstrip().startswith(("/*", "//")):
            continue
        match = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$", line)
        if match:
            current = match.group(1)
            body = match.group(2).strip()
            heads[current] = 1 if body and not body.startswith("/*") else 0
            continue
        split_match = re.match(r"^\s*([a-z_][A-Za-z0-9_]*)\s*$", line)
        if split_match and index + 1 < len(source) and source[index + 1].lstrip().startswith(":"):
            current = split_match.group(1)
            heads.setdefault(current, 0)
            continue
        if current is None:
            continue
        if line.strip() == ";":
            current = None
            continue
        stripped = line.strip()
        if stripped.startswith("|"):
            heads[current] += 1
        elif heads[current] == 0 and stripped and not stripped.startswith("/*"):
            heads[current] = 1
        if stripped.endswith(";"):
            current = None
    return heads, sum(heads.values()), provenance


def ebnf_inventory(path: Path) -> tuple[dict[str, int], int | None, int]:
    heads: dict[str, int] = {}
    provenance = 0
    current = None
    for line in lines(path):
        if "source-lineage=" in line:
            provenance += 1
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*::=", line)
        if match:
            current = match.group(1)
            heads[current] = 1
            continue
        if current is None:
            continue
        if "|" in line:
            heads[current] += line.count("|")
        if line.rstrip().endswith(";"):
            current = None
    return heads, sum(heads.values()), provenance


def strip_line_comment(line: str) -> str:
    quote = None
    escaped = False
    for index, char in enumerate(line):
        if escaped:
            escaped = False
            continue
        if char == "\\" and quote is not None:
            escaped = True
            continue
        if char in {"'", '"'}:
            quote = None if quote == char else char if quote is None else quote
            continue
        if quote is None and line.startswith("//", index):
            return line[:index]
    return line


def antlr_inventory(path: Path) -> tuple[dict[str, int], int | None, int]:
    heads: dict[str, int] = {}
    provenance = 0
    current = None
    source = lines(path)
    for index, line in enumerate(source):
        if "source-lineage=" in line:
            provenance += 1
        code = strip_line_comment(line)
        match = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$", line)
        split_match = re.match(r"^\s*([a-z_][A-Za-z0-9_]*)\s*$", line)
        if match:
            current = match.group(1)
            heads.setdefault(current, 0)
            body = strip_line_comment(match.group(2)).strip()
            if body:
                heads[current] += 1
            continue
        if split_match and index + 1 < len(source) and source[index + 1].lstrip().startswith(":"):
            current = split_match.group(1)
            heads.setdefault(current, 0)
            continue
        if current is None:
            continue
        if not code.strip():
            continue
        if heads[current] == 0:
            heads[current] = 1
        elif code.lstrip().startswith("|"):
            heads[current] += 1
        if code.rstrip().endswith(";"):
            current = None
    return heads, sum(heads.values()), provenance


def choice_alternatives(block: str) -> int:
    match = re.search(r"\bchoice\s*\(", block)
    if not match:
        return 1
    start = match.end()
    depth = 0
    commas = 0
    quote = None
    escaped = False
    for char in block[start:]:
        if escaped:
            escaped = False
            continue
        if char == "\\" and quote is not None:
            escaped = True
            continue
        if char in {"'", '"'}:
            quote = None if quote == char else char if quote is None else quote
            continue
        if quote is not None:
            continue
        if char in "([{":
            depth += 1
        elif char in ")]}":
            if depth == 0:
                break
            depth -= 1
        elif char == "," and depth == 0:
            commas += 1
    return commas + 1


def treesitter_inventory(path: Path) -> tuple[dict[str, int], int | None, int]:
    heads: dict[str, int] = {}
    source = path.read_text(encoding="utf-8")
    starts = list(re.finditer(r"(?m)^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*\$\s*=>", source))
    for index, match in enumerate(starts):
        line = source[match.start(): starts[index + 1].start() if index + 1 < len(starts) else len(source)]
        heads[match.group(1)] = choice_alternatives(line)
    provenance = len(re.findall(r"source-lineage=([^\s*]+)", source))
    return heads, sum(heads.values()), provenance


def flang_inventory(path: Path) -> tuple[dict[str, int], int | None, int]:
    heads: dict[str, int] = {}
    occurrences = 0
    for line in lines(path):
        for rule in re.findall(r"\bR[0-9]{3,4}\b", line):
            heads[rule] = heads.get(rule, 0) + 1
            occurrences += 1
    return heads, None, occurrences


def verified_artifact(source: Path, expected: str, destination: Path) -> Path:
    destination.parent.mkdir(parents=True, exist_ok=True)
    data = source.read_bytes()
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected:
        raise SystemExit(f"reference hash mismatch for {source}: {actual} != {expected}")
    destination.write_bytes(data)
    return destination


def inventory(kind: str, path: Path) -> tuple[dict[str, int], int | None, int]:
    if kind == "bison":
        return bison_inventory(path)
    if kind == "ebnf":
        return ebnf_inventory(path)
    if kind == "antlr4":
        return antlr_inventory(path)
    if kind == "tree-sitter":
        return treesitter_inventory(path)
    if kind == "flang":
        return flang_inventory(path)
    raise ValueError(kind)


def canonical_head(name: str) -> str:
    if name.startswith("r_"):
        name = name[2:]
    return name.replace("_x2D_", "-")


def comparable_heads(values: dict[str, int]) -> set[str]:
    lexical = {
        "LETTER", "DIGIT", "REP_CHAR", "EN_DASH", "RIGHT_SINGLE_QUOTE",
        "letter", "digit", "rep-char", "_xE2__x80__x93_", "_xE2__x80__x99_",
    }
    result = set()
    for value in values:
        name = canonical_head(value)
        if name in lexical or name == "standardir_start" or name.startswith("h_") or "__left_recursion" in name:
            continue
        result.add(name)
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    run_dir = args.run_dir.resolve()
    refs = run_dir / "references"
    refs.mkdir(parents=True, exist_ok=True)
    generated = {
        "ebnf": ("ebnf", run_dir / "grammar.ebnf"),
        "antlr4": ("antlr4", run_dir / "Fortran2023.g4"),
        "bison": ("bison", run_dir / "fortran2023.y"),
        "tree-sitter": ("tree-sitter", run_dir / "grammar.js"),
    }
    if not all(path.exists() for _, path in generated.values()):
        missing = [str(path) for _, path in generated.values() if not path.exists()]
        raise SystemExit(f"missing generated inputs: {', '.join(missing)}")

    generated_hashes = {
        "ebnf": "0ceff425b67e546d125394ac8bb3a04253a1c8ea4690a1367c5837eebb7236e0",
        "antlr4": "72675a8614329122a5e247ab248675e63e8f38b3ee675974193d24cf8b20b801",
        "bison": "ca581902fb9816b1072ffcfa69355663e6b7e763899bed8333b09682d4edbf7e",
        "tree-sitter": "86fef515edbbfd5cd9e272e0bc155ecfaa0375f1c34cb9fdbccd02ef97adcebf",
    }
    for name, (_, path) in generated.items():
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != generated_hashes[name]:
            raise SystemExit(f"generated hash mismatch for {name}: {actual} != {generated_hashes[name]}")

    reference_specs = [
        ("lfortran-bison", "bison", ROOT / ".cache/lfortran-parser-yy.bin", "112ef0ce5078ccec630a893bc51b92232348c37742b1451c833928a422907936"),
        ("kaby76-antlr4", "antlr4", ROOT / ".cache/kaby76-fortran2023-parser.bin", "8f1f55ee4f61f82d732d41bd9452917bc1ce293f64e19615649a5170fb2705a8"),
        ("house-antlr4", "antlr4", ROOT / ".cache/standard-fortran2023-parser.bin", "d8bb1b600e30be245a2d8c87e32660a3b4ad83aa94728cf50cebf37c1e8b67ce"),
        ("flang-rule-comments", "flang", ROOT / ".cache/flang-fortran-parsers.bin", "abb4126d6c0c4e516628ba9836c428f83f0ccf883439e67cbfdd061aa42d83b9"),
    ]
    for name, _, source, expected in reference_specs:
        if not source.exists():
            raise SystemExit(f"missing verified reference artifact: {source}")
        verified_artifact(source, expected, refs / name)

    source_specs = [
        (ROOT / ".cache/runs/E0151/R000002-candidate/input/standardir.sx", "e0816b4b3280e5a7945bf50dfd24036050c1f415daa864166b56741b4cd7b18f", run_dir / "source/standardir.sx"),
        (ROOT / ".cache/runs/E0151/R000002-candidate/source-projection.tsv", "64035bf921e816a6e64899c699a921c6c3e5425f488cdd48192bfba20782ad1d", run_dir / "source/source-projection.tsv"),
        (ROOT / ".cache/runs/E0151/R000002-candidate/grammar-oracles.tsv", "3348bb3bf3a9e3e29ddb32b8961cd0f33828a87095366bdd6108168c5ff0792b", run_dir / "source/grammar-oracles.tsv"),
    ]
    for source, expected, destination in source_specs:
        if not source.exists():
            raise SystemExit(f"missing verified source evidence: {source}")
        verified_artifact(source, expected, destination)

    rows: list[dict[str, object]] = []
    inventories: dict[str, dict[str, int]] = {}
    alternative_counts: dict[str, int | None] = {}
    provenance_sets: dict[str, set[str]] = {}
    for name, (kind, path) in generated.items():
        heads, alternative_count, provenance = inventory(kind, path)
        inventories[name] = heads
        alternative_counts[name] = alternative_count
        provenance_sets[name] = set(re.findall(r"source-lineage=([^\s*]+)", path.read_text(encoding="utf-8")))
        rows.append({"name": name, "kind": kind, "path": str(path), "heads": len(heads), "alternatives": alternative_count, "provenance_headers": provenance, "origin": "MECHANICAL"})
    reference_aux: dict[str, int] = {}
    for name, kind, _, _ in reference_specs:
        heads, alternative_count, auxiliary_count = inventory(kind, refs / name)
        inventories[name] = heads
        reference_aux[name] = auxiliary_count
        rows.append({"name": name, "kind": kind, "path": str(refs / name), "heads": len(heads), "alternatives": alternative_count if alternative_count is not None else "", "provenance_headers": auxiliary_count if name == "flang-rule-comments" else 0, "origin": "DIFFERENTIAL"})

    generated_names = [comparable_heads(inventories[name]) for name in generated]
    common = set.intersection(*generated_names)
    union = set.union(*generated_names)
    diffs = []
    for name in generated:
        names = comparable_heads(inventories[name])
        missing = sorted(union - names)
        extra = sorted(names - common)
        diffs.append({"format": name, "missing_from_format_union": len(missing), "format_specific_heads": len(extra), "missing_sample": ",".join(missing[:12]), "specific_sample": ",".join(extra[:12])})

    oracle_path = run_dir / "grammar-oracles.tsv"
    validator_status = {}
    if oracle_path.exists():
        for line in lines(oracle_path):
            fields = line.split("\t")
            if len(fields) >= 2 and fields[0] in {"antlr4", "bison", "tree-sitter", "source-projection", "overall"}:
                validator_status[fields[0]] = fields[1]

    source_projection = run_dir / "source/source-projection.tsv"
    projection = {}
    if source_projection.exists():
        for line in lines(source_projection):
            fields = line.split("\t")
            if len(fields) >= 7 and fields[0] in generated:
                projection[fields[0]] = {
                    "status": fields[1],
                    "expected": int(fields[2]),
                    "covered": int(fields[3]),
                    "skipped": int(fields[4]),
                    "missing": int(fields[5]),
                    "header_gaps": int(fields[6]),
                }
    first_format = next(iter(generated))
    lineage_disagreement = {
        name: sorted(provenance_sets[name] ^ provenance_sets[first_format])
        for name in generated
    }
    validator_report_hash = hashlib.sha256((run_dir / "source/grammar-oracles.tsv").read_bytes()).hexdigest()

    summary = {
        "generated": {name: {"heads": len(inventories[name]), "alternatives": alternative_counts[name], "provenance_headers": next(row["provenance_headers"] for row in rows if row["name"] == name), "unique_provenance": len(provenance_sets[name]), "source_projection": projection.get(name)} for name in generated},
        "references": {name: {"heads": len(inventories[name]), **({"alternatives": next(row["alternatives"] for row in rows if row["name"] == name)} if name != "flang-rule-comments" else {"rule_comment_occurrences": reference_aux[name]})} for name, *_ in reference_specs},
        "cross_format_common_heads": len(common),
        "cross_format_union_heads": len(union),
        "cross_format_provenance_disagreement": {name: values for name, values in lineage_disagreement.items() if values},
        "source_projection": projection,
        "validator_report_sha256": validator_report_hash,
        "validator_status": validator_status,
        "standardir_advantages": ["source rule/page/byte/hash lineage", "normative role preservation", "same source-backed input across four targets"],
        "reference_advantages": ["LFortran executable lexer/actions/precedence", "ANTLR reference ecosystem", "Flang rule-ID parser comparison"],
        "equivalence_claim": False,
    }
    (run_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    with (run_dir / "inventories.tsv").open("w", encoding="utf-8") as output:
        output.write("name\tkind\tpath\theads\talternatives\tprovenance_headers\torigin\n")
        for row in rows:
            output.write("\t".join(str(row[key]) for key in ("name", "kind", "path", "heads", "alternatives", "provenance_headers", "origin")) + "\n")
    with (run_dir / "head-diffs.tsv").open("w", encoding="utf-8") as output:
        output.write("format\tmissing_from_format_union\tformat_specific_heads\tmissing_sample\tspecific_sample\n")
        for row in diffs:
            output.write("\t".join(str(row[key]) for key in ("format", "missing_from_format_union", "format_specific_heads", "missing_sample", "specific_sample")) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
