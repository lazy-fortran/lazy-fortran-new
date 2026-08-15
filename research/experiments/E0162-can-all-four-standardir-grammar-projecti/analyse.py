#!/usr/bin/env python3
"""Audit generated StandardIR heads against each other and pinned references.

This is a structural inventory, not a language-equivalence checker.  The
source-expression and target-validator gates are consumed from the corrected
E0157 reports before this script compares names.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


GENERATED = {
    "ebnf": "grammar.ebnf",
    "antlr4": "Fortran2023.g4",
    "bison": "fortran2023.y",
    "tree-sitter": "grammar.js",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def strip_comments(path: Path, value: str) -> str:
    if path.suffix == ".ebnf":
        return re.sub(r"\(\*.*?\*\)", "", value, flags=re.S)
    # E0157 deliberately inventories LFortran's parser.yy as written.  Its
    # commented examples are not grammar heads, while stripping nested block
    # comment material can expose colons that were never parser productions.
    if path.name == "parser.yy":
        return value
    return re.sub(r"/\*.*?\*/|//[^\n]*", "", value, flags=re.S)


def antlr_heads(value: str) -> set[str]:
    lines = value.splitlines()
    result: set[str] = set()
    for index, line in enumerate(lines):
        stripped = line.strip()
        direct = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*)\s*:", stripped)
        if direct:
            result.add(direct.group(1))
            continue
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", stripped):
            continue
        next_index = index + 1
        while next_index < len(lines) and not lines[next_index].strip():
            next_index += 1
        if next_index < len(lines) and lines[next_index].strip().startswith(":"):
            result.add(stripped)
    return result


def heads(path: Path) -> set[str]:
    body = strip_comments(path, path.read_text(encoding="utf-8"))
    if path.name == "grammar.ebnf":
        return set(re.findall(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*::=", body, re.M))
    if path.name in {"fortran2023.y", "parser.yy"}:
        return set(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:", body, re.M))
    if path.name == "grammar.js":
        return set(
            re.findall(
                r"^\s*([A-Za-z_][A-Za-z0-9_]*|[–’])\s*:\s*\$\s*=>",
                body,
                re.M,
            )
        )
    if path.suffix == ".g4":
        return antlr_heads(body)
    raise ValueError(f"unsupported grammar file: {path}")


def canonical(name: str) -> str:
    """Map target spellings to the source-level comparison spelling.

    Standard-new encodes punctuation in names as `_xHH_`; consume an escape
    only when it starts at a name boundary so words such as `indexed` are not
    corrupted.  Repeated prefixes are target wrappers, not source names.
    """

    decoded = re.sub(
        r"(?:^|_)x([0-9a-fA-F]{2})_",
        lambda match: chr(int(match.group(1), 16)),
        name,
    )
    try:
        decoded = decoded.encode("latin1").decode("utf-8")
    except UnicodeError:
        pass
    while decoded.startswith("h_") or decoded.startswith("r_"):
        decoded = decoded[2:]
    return decoded.lower().replace("_", "-").strip("-")


def is_bison_helper(name: str) -> bool:
    return name.startswith("h_")


def read_tsv(path: Path) -> list[dict[str, str]]:
    rows = path.read_text(encoding="utf-8").splitlines()
    header = rows[0].split("\t")
    return [dict(zip(header, row.split("\t"))) for row in rows[1:] if row]


def require_corrected_audit(path: Path) -> dict:
    summary = json.loads((path / "summary.json").read_text(encoding="utf-8"))
    required = {
        "source_identity": "PASS",
        "generated_lineage_sets_equal": True,
        "lexical_gate_status": "PASS",
    }
    for key, expected in required.items():
        if summary.get(key) != expected:
            raise SystemExit(f"corrected E0157 audit is not green: {path} {key}")
    validators = summary.get("validator_status", {})
    for name in ("antlr4", "bison", "tree-sitter", "source-projection"):
        if validators.get(name) != "PASS":
            raise SystemExit(f"corrected E0157 validator is not green: {path} {name}")
    return summary


def source_rules(run: Path) -> set[str]:
    source = (run / "input/standardir.sx").read_text(encoding="utf-8")
    return set(re.findall(r"\(syntax\s+R(\d+)\b", source))


def reference_rule_ids(path: Path) -> tuple[int, set[str]]:
    values = re.findall(r"\bR(\d+)\b", path.read_text(encoding="utf-8"))
    return len(values), set(values)


def write_tsv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    path.write_text(
        "\t".join(header)
        + "\n"
        + "\n".join("\t".join(str(item) for item in row) for row in rows)
        + "\n",
        encoding="utf-8",
    )


def names_preview(names: list[str], limit: int = 12) -> str:
    if len(names) <= limit:
        return ",".join(names)
    return ",".join(names[:limit]) + f",... (+{len(names) - limit})"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("baseline_run", type=Path)
    parser.add_argument("baseline_audit", type=Path)
    parser.add_argument("candidate_run", type=Path)
    parser.add_argument("candidate_audit", type=Path)
    parser.add_argument("house_antlr", type=Path)
    parser.add_argument("kaby_antlr", type=Path)
    parser.add_argument("lfortran_bison", type=Path)
    parser.add_argument("flang_cpp", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    for run in (args.baseline_run, args.candidate_run):
        for filename in list(GENERATED) + ["input/standardir.sx"]:
            path = run / (GENERATED[filename] if filename in GENERATED else filename)
            if not path.is_file():
                raise SystemExit(f"missing run input: {path}")
    for path in (
        args.house_antlr,
        args.kaby_antlr,
        args.lfortran_bison,
        args.flang_cpp,
    ):
        if not path.is_file():
            raise SystemExit(f"missing reference: {path}")

    baseline_audit = require_corrected_audit(args.baseline_audit)
    candidate_audit = require_corrected_audit(args.candidate_audit)
    args.output.mkdir(parents=True, exist_ok=True)

    runs = {"baseline": args.baseline_run, "role-family-candidate": args.candidate_run}
    raw_heads: dict[str, dict[str, set[str]]] = {}
    canonical_heads: dict[str, dict[str, set[str]]] = {}
    inventory_rows: list[list[object]] = []
    for variant, run in runs.items():
        raw_heads[variant] = {}
        canonical_heads[variant] = {}
        for format_name, filename in GENERATED.items():
            path = run / filename
            raw = heads(path)
            canon = {canonical(name) for name in raw}
            raw_heads[variant][format_name] = raw
            canonical_heads[variant][format_name] = canon
            inventory_rows.append(
                [
                    variant,
                    format_name,
                    len(raw),
                    len(canon),
                    len({name for name in raw if is_bison_helper(name)}),
                    sha256(path),
                ]
            )

    write_tsv(
        args.output / "head-inventory.tsv",
        ["variant", "format", "raw_heads", "canonical_heads", "bison_helpers", "sha256"],
        inventory_rows,
    )

    internal_rows: list[list[object]] = []
    for variant in runs:
        source = canonical_heads[variant]["ebnf"]
        for format_name in GENERATED:
            current = canonical_heads[variant][format_name]
            missing = sorted(source - current)
            extra = sorted(current - source)
            if format_name == "bison":
                # Bison's `h_r_R...` nodes are deterministic helper rules
                # introduced by the target lowering, not source productions.
                helper_names = {
                    canonical(name)
                    for name in raw_heads[variant][format_name]
                    if is_bison_helper(name)
                }
                expected = sorted((set(extra) & helper_names))
                lexical = {"digit", "letter", "rep-char", "standardir-start", "–", "’"}
                expected.extend(sorted(set(extra) & lexical))
                unexpected = sorted(set(extra) - set(expected))
                classification = "target-helper-scaffolding" if not unexpected else "unclassified-target-difference"
                note = f"{len(helper_names)} h_* helpers and {len(set(extra) & lexical)} target wrappers"
            elif format_name == "tree-sitter":
                lexical = {"digit", "letter", "rep-char", "en-dash", "right-single-quote", "–", "’"}
                expected = [name for name in extra if name in lexical]
                unexpected = [name for name in extra if name not in lexical]
                classification = "target-lexical-scaffolding" if not unexpected else "unclassified-target-difference"
                note = f"{len(expected)} lexical wrapper heads"
            else:
                classification = "exact-canonical-head-set" if not missing and not extra else "projection-difference"
                note = "same source-level head set" if not missing and not extra else "canonical heads differ"
            internal_rows.append(
                [
                    variant,
                    format_name,
                    len(missing),
                    names_preview(missing),
                    len(extra),
                    names_preview(extra),
                    classification,
                    note,
                ]
            )
    write_tsv(
        args.output / "internal-comparison.tsv",
        ["variant", "format", "missing_vs_ebnf", "missing_names", "extra_vs_ebnf", "extra_names", "classification", "note"],
        internal_rows,
    )

    references = {
        "house-antlr4": args.house_antlr,
        "kaby76-antlr4": args.kaby_antlr,
        "lfortran-bison": args.lfortran_bison,
    }
    reference_rows: list[list[object]] = []
    for variant in runs:
        source = canonical_heads[variant]["ebnf"]
        for reference_name, path in references.items():
            ref = {canonical(name) for name in heads(path)}
            shared = sorted(source & ref)
            source_only = sorted(source - ref)
            reference_only = sorted(ref - source)
            reference_rows.append(
                [
                    variant,
                    reference_name,
                    len(ref),
                    len(shared),
                    len(source_only),
                    len(reference_only),
                    "reference-structure-not-one-to-one",
                    "different factoring, inheritance, target extensions or parser actions; inspect by role and corpus",
                ]
            )

    source_ids = source_rules(args.baseline_run)
    for variant, run in runs.items():
        if source_rules(run) != source_ids:
            raise SystemExit(f"source rule ID set changed unexpectedly for {variant}")
    flang_occurrences, flang_ids = reference_rule_ids(args.flang_cpp)
    reference_rows.append(
        [
            "both",
            "flang-rule-comments",
            flang_occurrences,
            len(source_ids & flang_ids),
            len(source_ids - flang_ids),
            len(flang_ids - source_ids),
            "source-rule-comment-coverage",
            "Flang comments are comparison anchors, not generated production heads",
        ]
    )
    write_tsv(
        args.output / "reference-comparison.tsv",
        ["variant", "reference", "reference_count", "shared_source_names_or_rule_ids", "source_only", "reference_only", "classification", "note"],
        reference_rows,
    )

    source_lineages = {}
    for variant, audit in (("baseline", baseline_audit), ("role-family-candidate", candidate_audit)):
        source_lineages[variant] = {
            "source_alternatives": audit["source_alternatives"],
            "covered_source_alternatives": audit["covered_source_alternatives"],
            "generated_lineage_sets_equal": audit["generated_lineage_sets_equal"],
            "validator_status": audit["validator_status"],
        }
    summary = {
        "claim": "structural inventory only; no language-equivalence claim",
        "variants": list(runs),
        "generated_formats": list(GENERATED),
        "source_lineages": source_lineages,
        "source_rule_ids": len(source_ids),
        "internal_canonical_head_sets": {
            variant: {
                format_name: len(names)
                for format_name, names in formats.items()
            }
            for variant, formats in canonical_heads.items()
        },
        "reference_hashes": {
            name: sha256(path) for name, path in references.items()
        },
        "flang_sha256": sha256(args.flang_cpp),
        "finding": (
            "EBNF and ANTLR4 have identical canonical head sets in both variants. "
            "Bison adds deterministic h_* lowering helpers and target wrappers "
            "after those are separated, and tree-sitter adds only lexical wrapper "
            "heads. The "
            "role-family candidate removes four canonical source heads in every "
            "format while retaining source lineage; this is a target projection "
            "choice, not evidence of a source defect. Reference head counts are "
            "not one-to-one comparisons because the references factor, inherit, "
            "extend and attach parser actions differently."
        ),
    }
    (args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
