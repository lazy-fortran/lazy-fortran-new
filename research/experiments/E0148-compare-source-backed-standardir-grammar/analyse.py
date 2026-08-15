#!/usr/bin/env python3
"""Reproduce the E0148 LFortran/StandardIR comparison inventory."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from collections import defaultdict
from pathlib import Path


LF_COMMIT = "caf87b660f803148f000046392a5da803f9fc630"
LF_PATH = "src/lfortran/parser/parser.yy"
LF_SHA256 = "112ef0ce5078ccec630a893bc51b92232348c37742b1451c833928a422907936"
STANDARD_COMMIT = "1cdd9490375199d93c755fb3c36bc9dcf2c285e6"
STANDARD_RUN = "E0147/R000016"
STANDARD_FILE = "fortran2023.y"
SX_FILE = "input/standardir.sx"


def command(args: list[str], *, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=False)


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def parse_syntax_records(path: Path) -> list[dict[str, str]]:
    records = []
    pattern = re.compile(
        r"^\(syntax (\S+) \(lhs ([^)]+)\) \(rhs (.*)\) \(source "
        r".*?\(page (\d+)\) \(end-page (\d+)\) \(byte-start (\d+)\) "
        r"\(byte-length (\d+)\)"
    )
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = pattern.match(line)
        if not match:
            continue
        rule, lhs, rhs, page, end_page, byte_start, byte_length = match.groups()
        records.append({
            "line": str(line_number),
            "rule": rule,
            "lhs": lhs,
            "rhs": rhs,
            "page": page,
            "end_page": end_page,
            "byte_start": byte_start,
            "byte_length": byte_length,
        })
    return records


def bison_metrics(report: Path, stderr: str) -> dict[str, int | str]:
    shift = reduce = 0
    for line in report.read_text(encoding="utf-8", errors="replace").splitlines():
        match = re.search(r"conflicts?: (.*)$", line)
        if not match:
            continue
        for count, kind in re.findall(r"(\d+) (shift/reduce|reduce/reduce)", match.group(1)):
            if kind == "shift/reduce":
                shift += int(count)
            else:
                reduce += int(count)
    useless_nonterminals = 0
    useless_rules = 0
    match = re.search(r"warning: (\d+) nonterminals useless in grammar", stderr)
    if match:
        useless_nonterminals = int(match.group(1))
    match = re.search(r"warning: (\d+) rules useless in grammar", stderr)
    if match:
        useless_rules = int(match.group(1))
    return {
        "status": "PASS" if "error:" not in stderr else "FAIL",
        "exit": 0,
        "shift_reduce_conflicts": shift,
        "reduce_reduce_conflicts": reduce,
        "useless_nonterminals": useless_nonterminals,
        "useless_rules": useless_rules,
    }


def run_bison(source: Path, output_dir: Path, name: str) -> dict[str, int | str]:
    output = output_dir / f"{name}.output"
    stderr_path = output_dir / f"{name}.stderr"
    stdout_path = output_dir / f"{name}.stdout"
    generated = output_dir / f"{name}.c"
    result = command([
        "bison", "--warnings=all", "--report=state,solved",
        f"--report-file={output}", "-o", generated, source,
    ])
    write(stdout_path, result.stdout)
    write(stderr_path, result.stderr)
    metrics = bison_metrics(output, result.stderr) if output.exists() else {
        "status": "FAIL", "exit": result.returncode, "shift_reduce_conflicts": 0,
        "reduce_reduce_conflicts": 0, "useless_nonterminals": 0, "useless_rules": 0,
    }
    metrics["exit"] = result.returncode
    return metrics


def parse_lfortran_tokens(text: str) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        match = re.match(r"%token(?:\s+<[^>]+>)?\s+(\S+)(?:\s+\"([^\"]*)\")?", line)
        if match and match.group(2) is not None:
            values[match.group(1)] = match.group(2)
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lab-root", type=Path, required=True)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    lab_root = args.lab_root.resolve()
    run_dir = args.run_dir.resolve()
    run_dir.mkdir(parents=True, exist_ok=True)

    standard_root = lab_root.parent / "standard-new"
    lfortran_root = lab_root.parent / "lfortran-12385"
    source_run = lab_root / ".cache" / "runs" / "E0147" / "R000016"
    sx_path = source_run / SX_FILE
    grammar_path = source_run / STANDARD_FILE
    if not sx_path.is_file() or not grammar_path.is_file():
        raise SystemExit(f"missing E0147 evidence under {source_run}")

    standard_commit = command(["git", "-C", str(standard_root), "rev-parse", STANDARD_COMMIT])
    if standard_commit.returncode != 0:
        raise SystemExit(f"standard-new commit is unavailable: {STANDARD_COMMIT}")
    lfortran = command(["git", "-C", str(lfortran_root), "show", f"{LF_COMMIT}:{LF_PATH}"])
    if lfortran.returncode != 0:
        raise SystemExit("pinned LFortran parser source is unavailable")
    lfortran_sha = hashlib.sha256(lfortran.stdout.encode("utf-8")).hexdigest()
    if lfortran_sha != LF_SHA256:
        raise SystemExit(f"pinned LFortran hash mismatch: {lfortran_sha}")
    write(run_dir / "lfortran-parser.yy.sha256", f"{lfortran_sha}  {LF_PATH}\n")

    records = parse_syntax_records(sx_path)
    token_re = re.compile(r"\(token\s+([^\s()]+|\"[^\"]*\")\)")
    glyph_rows = []
    unicode_token_counts = defaultdict(int)
    for record in records:
        for token in token_re.findall(record["rhs"]):
            value = token.strip('"')
            if any(ord(char) > 127 for char in value):
                unicode_token_counts[value] += 1
                glyph_rows.append({
                    "kind": "unicode-token",
                    "rule": record["rule"],
                    "lhs": record["lhs"],
                    "page": record["page"],
                    "byte_start": record["byte_start"],
                    "token": value,
                    "codepoints": "+".join(f"U+{ord(char):04X}" for char in value),
                    "target_terminal": "EN_DASH" if value == "–" else "RIGHT_SINGLE_QUOTE",
                    "canonical_source_spelling": "-" if value == "–" else "'",
                    "classification": "definite lexical normalization defect",
                })
    write(run_dir / "glyphs.tsv", "kind\trule\tlhs\tpage\tbyte_start\ttoken\tcodepoints\ttarget_terminal\tcanonical_source_spelling\tclassification\n" +
          "\n".join("\t".join(row[key] for key in (
              "kind", "rule", "lhs", "page", "byte_start", "token", "codepoints",
              "target_terminal", "canonical_source_spelling", "classification"))
                      for row in glyph_rows) + "\n")

    groups = defaultdict(list)
    for record in records:
        groups[(record["lhs"], record["rhs"])].append(record)
    duplicate_rows = []
    duplicate_groups = 0
    duplicate_records = 0
    for (lhs, rhs), group in sorted(groups.items()):
        if len(group) < 2:
            continue
        duplicate_groups += 1
        duplicate_records += len(group)
        duplicate_rows.append({
            "lhs": lhs,
            "rules": "+".join(record["rule"] for record in group),
            "occurrences": str(len(group)),
            "pages": "+".join(record["page"] for record in group),
            "byte_starts": "+".join(record["byte_start"] for record in group),
            "classification": "projection gap: merge alternatives only with merged lineage",
        })
    write(run_dir / "duplicate-occurrences.tsv",
          "lhs\trules\toccurrences\tpages\tbyte_starts\tclassification\n" +
          "\n".join("\t".join(row.values()) for row in duplicate_rows) + "\n")

    lfortran_tokens = parse_lfortran_tokens(lfortran.stdout)
    token_rows = [
        {"source": "U+2013 EN DASH", "standardir": "EN_DASH", "lfortran": 'TK_MINUS "-"',
         "classification": "defect: target spelling is not Fortran source spelling"},
        {"source": "U+2019 RIGHT SINGLE QUOTATION MARK", "standardir": "RIGHT_SINGLE_QUOTE",
         "lfortran": "TK_STRING (tokenizer-delimited)",
         "classification": "defect: target spelling is not ASCII character-literal delimiter"},
    ]
    write(run_dir / "terminal-comparison.tsv",
          "source\tstandardir\tlfortran\tclassification\n" +
          "\n".join("\t".join(row.values()) for row in token_rows) + "\n")

    lfortran_source = run_dir / "lfortran-parser.yy"
    write(lfortran_source, lfortran.stdout)
    lfortran_metrics = run_bison(lfortran_source, run_dir, "lfortran")
    all_root_metrics = run_bison(grammar_path, run_dir, "standardir-all-roots")
    selected_grammar = run_dir / "standardir-program-root.y"
    selected_text = grammar_path.read_text(encoding="utf-8")
    selected_text = selected_text.replace("%start standardir_start", "%start r_program", 1)
    write(selected_grammar, selected_text)
    selected_metrics = run_bison(selected_grammar, run_dir, "standardir-program-root")

    findings = [
        {"id": "F001", "class": "defect", "scope": "R1010 twice, R712, R868",
         "finding": "U+2013 is emitted as EN_DASH instead of canonical Fortran '-'.",
         "evidence": "glyphs.tsv; terminal-comparison.tsv; LFortran TK_MINUS '-'"},
        {"id": "F002", "class": "defect", "scope": "R724, R773, R774, R775",
         "finding": "U+2019 is emitted as RIGHT_SINGLE_QUOTE instead of the canonical ASCII quote delimiter for character and BOZ constants.",
         "evidence": "glyphs.tsv; terminal-comparison.tsv; LFortran TK_STRING tokenizer"},
        {"id": "F003", "class": "projection_gap", "scope": "duplicate-occurrences.tsv",
         "finding": "Identical source occurrences remain duplicate target alternatives rather than one alternative with multiple lineage entries.",
         "evidence": "duplicate-occurrences.tsv"},
        {"id": "F004", "class": "projection_gap", "scope": "selected-root replay",
         "finding": "The default Bison wrapper emits 500 of 502 declared roots and is a closure validator, not a parser entry point.",
         "evidence": "standardir-all-roots.output; standardir-program-root.output"},
        {"id": "F005", "class": "projection_gap", "scope": "selected-root replay",
         "finding": "Selected-root reachability is not clean: Bison reports 10 useless nonterminals and 514 useless rules.",
         "evidence": "standardir-program-root.stderr"},
        {"id": "F006", "class": "gate_gap", "scope": "all projections",
         "finding": "Validator acceptance and body-bound provenance do not establish language equivalence after normalization.",
         "evidence": "findings.md; E0147 source-projection.tsv"},
        {"id": "F007", "class": "expected_difference", "scope": "LFortran comparison",
         "finding": "LFortran's units/script_unit, extensions, expression factoring and AST-oriented decomposition are not normative StandardIR defects.",
         "evidence": "findings.md; pinned parser.yy"},
        {"id": "F008", "class": "stale_prior_finding", "scope": "E0013 critique examples",
         "finding": "The previously reported R741, R843, R1103, R1307, R1417 and malformed-token cases are corrected in E0147/R000016.",
         "evidence": "findings.md; E0147 input/standardir.sx"},
        {"id": "F009", "class": "method_gap", "scope": "comparison harness",
         "finding": "The analyzer does not perform a full automatic cross-grammar body comparison; its LFortran anchors and adjudication are bounded evidence.",
         "evidence": "findings.md; analyse.py"},
    ]
    write(run_dir / "findings.tsv", "id\tclass\tscope\tfinding\tevidence\n" +
          "\n".join("\t".join(row.values()) for row in findings) + "\n")

    grammar_lines = grammar_path.read_text(encoding="utf-8").splitlines()
    start_index = grammar_lines.index("standardir_start:") + 1
    start_block = []
    for line in grammar_lines[start_index:]:
        if line.strip() == ";":
            break
        start_block.append(line)
    root_count = sum(bool(re.match(r"^\s*(?:\|\s*)?r_", line)) for line in start_block)
    declared_roots = sum(line.startswith("(root ")
                         for line in (source_run / "input" / "roots.sx").read_text(
                             encoding="utf-8").splitlines())
    summary = {
        "experiment": "E0148",
        "standard_new_commit": STANDARD_COMMIT,
        "lfortran_commit": LF_COMMIT,
        "lfortran_path": LF_PATH,
        "lfortran_sha256": lfortran_sha,
        "standardir_run": STANDARD_RUN,
        "syntax_records": len(records),
        "unique_rule_ids": len({record["rule"] for record in records}),
        "declared_roots": declared_roots,
        "emitted_start_roots": root_count,
        "unicode_token_occurrences": dict(unicode_token_counts),
        "duplicate_source_occurrence_groups": duplicate_groups,
        "duplicate_source_occurrence_records": duplicate_records,
        "all_root_start_alternatives_observed": root_count,
        "lfortran_tokens_checked": len(lfortran_tokens),
        "lfortran_bison": lfortran_metrics,
        "standardir_all_roots_bison": all_root_metrics,
        "standardir_program_root_bison": selected_metrics,
        "finding_counts": {kind: sum(row["class"] == kind for row in findings)
                            for kind in sorted({row["class"] for row in findings})},
        "status": "verification_failure",
    }
    write(run_dir / "summary.json", json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
