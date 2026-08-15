#!/usr/bin/env python3
"""Reproduce the E0149 manual Bison comparison inventory.

The checked-in matrix is the adjudication. This script only counts both
grammars, replays Bison, and verifies that every declared audit lane has a
classification row. LFortran is a comparison implementation, not a source
for StandardIR.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path


LF_COMMIT = "caf87b660f803148f000046392a5da803f9fc630"
LF_PATH = "src/lfortran/parser/parser.yy"
LF_SHA256 = "112ef0ce5078ccec630a893bc51b92232348c37742b1451c833928a422907936"
STANDARD_COMMIT = "1cdd9490375199d93c755fb3c36bc9dcf2c285e6"
STANDARD_RUN = "E0147/R000016"
STANDARD_FILE = "fortran2023.y"
MATRIX = Path(__file__).with_name("comparison-matrix.tsv")
LANES = {
    "entry-points",
    "lexical-terminals",
    "program-units",
    "declarations-and-types",
    "names-and-designators",
    "expressions-and-operators",
    "executable-constructs",
    "io-format-and-edit-descriptors",
    "coarray-sync-and-teams",
    "normalization-and-provenance",
}


def command(args: list[str], *, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=False)


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def parse_productions(text: str) -> list[dict[str, int | str]]:
    """Count Bison production heads and alternatives in either file shape."""

    lines = text.splitlines()
    result: list[dict[str, int | str]] = []
    i = 0
    while i < len(lines):
        match = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$", lines[i])
        rest = ""
        if match:
            lhs = match.group(1)
            rest = match.group(2).strip()
            start_line = i + 1
            i += 1
        elif (re.match(r"^\s*[A-Za-z_][A-Za-z0-9_]*\s*$", lines[i]) and
              i + 1 < len(lines) and re.match(r"^\s*:\s*(.*)$", lines[i + 1])):
            lhs = lines[i].strip()
            rest = re.match(r"^\s*:\s*(.*)$", lines[i + 1]).group(1).strip()
            start_line = i + 1
            i += 2
        else:
            i += 1
            continue

        alternatives = 0
        if rest:
            if rest.endswith(";"):
                alternatives = 1
            else:
                current = 1
                alternatives = current
        else:
            alternatives = 1
        if rest.endswith(";"):
            result.append({"lhs": lhs, "line": start_line, "alternatives": alternatives})
            continue

        while i < len(lines):
            line = lines[i].strip()
            i += 1
            if line == ";":
                break
            if line.startswith("|"):
                alternatives += 1
        result.append({"lhs": lhs, "line": start_line, "alternatives": alternatives})
    return result


def normalized_head(lhs: str) -> str:
    """Normalize target spelling for a correspondence inventory only."""

    value = lhs.strip().lower()
    if value.startswith("r_"):
        value = value[2:]
    value = value.replace("_x2d_", "-")
    value = value.replace("_", "-")
    return value


def audit_lane(lhs: str) -> str:
    value = normalized_head(lhs)
    if any(word in value for word in ("program", "module", "subroutine", "function", "block-data", "subprogram")):
        return "program-units"
    if any(word in value for word in ("name", "designator", "data-ref", "component", "variable", "object")):
        return "names-and-designators"
    if any(word in value for word in ("expr", "operator", "op", "constant", "literal")):
        return "expressions-and-operators"
    if any(word in value for word in ("sync", "event", "lock", "team", "coarray", "image")):
        return "coarray-sync-and-teams"
    if any(word in value for word in ("io", "format", "edit", "read", "write", "open", "close", "inquire")):
        return "io-format-and-edit-descriptors"
    if any(word in value for word in ("decl", "type", "attr", "entity", "implicit", "intent", "pointer", "alloc")):
        return "declarations-and-types"
    if any(word in value for word in ("if", "do", "select", "where", "block", "associate", "action", "stmt", "construct")):
        return "executable-constructs"
    if any(word in value for word in ("letter", "digit", "char", "keyword", "token", "operator")):
        return "lexical-terminals"
    return "normalization-and-provenance"


def write_coverage(path: Path, standard: list[dict[str, int | str]],
                   lfortran: list[dict[str, int | str]]) -> dict[str, int]:
    """Write a complete inventory; it is not a language-equivalence claim."""

    standard_heads = {normalized_head(str(row["lhs"])) for row in standard}
    lfortran_heads = {normalized_head(str(row["lhs"])) for row in lfortran}
    rows = ["grammar\tlane\tlhs\tline\talternatives\tnormalized_lhs\thead_match\tcoverage_classification"]
    exact = 0
    unmatched = 0
    for grammar, values in (("standardir", standard), ("lfortran", lfortran)):
        for row in values:
            lhs = str(row["lhs"])
            normalized = normalized_head(lhs)
            match = normalized in (lfortran_heads if grammar == "standardir" else standard_heads)
            if match:
                exact += 1
                classification = "head-correspondence"
            else:
                unmatched += 1
                classification = "decomposition-or-extension-review"
            rows.append("\t".join((
                grammar, audit_lane(lhs), lhs, str(row["line"]), str(row["alternatives"]),
                normalized, "yes" if match else "no", classification,
            )))
    write(path, "\n".join(rows) + "\n")
    return {"rows": len(rows) - 1, "head_correspondences": exact, "unmatched_heads": unmatched}


def bison_metrics(report: Path, stderr: str, exit_code: int) -> dict[str, int | str]:
    shift = reduce = 0
    if report.exists():
        for line in report.read_text(encoding="utf-8", errors="replace").splitlines():
            for count, kind in re.findall(r"(\d+) (shift/reduce|reduce/reduce)", line):
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
        "status": "PASS" if exit_code == 0 and "error:" not in stderr else "FAIL",
        "exit": exit_code,
        "shift_reduce_conflicts": shift,
        "reduce_reduce_conflicts": reduce,
        "useless_nonterminals": useless_nonterminals,
        "useless_rules": useless_rules,
    }


def run_bison(source: Path, output_dir: Path, name: str) -> dict[str, int | str]:
    report = output_dir / f"{name}.output"
    stderr_path = output_dir / f"{name}.stderr"
    stdout_path = output_dir / f"{name}.stdout"
    generated = output_dir / f"{name}.c"
    result = command([
        "bison", "--warnings=all", "--report=state,solved",
        f"--report-file={report}", "-o", generated, source,
    ])
    write(stdout_path, result.stdout)
    write(stderr_path, result.stderr)
    return bison_metrics(report, result.stderr, result.returncode)


def read_matrix() -> list[dict[str, str]]:
    with MATRIX.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    required = {"id", "lane", "classification", "observation", "evidence", "action"}
    if not rows or not required.issubset(rows[0]):
        raise SystemExit("E0149 comparison matrix has an invalid header")
    ids = [row["id"] for row in rows]
    if len(ids) != len(set(ids)):
        raise SystemExit("E0149 comparison matrix has duplicate IDs")
    missing = LANES - {row["lane"] for row in rows}
    if missing:
        raise SystemExit("E0149 comparison matrix misses lanes: " + ", ".join(sorted(missing)))
    allowed = {
        "no_defect_found", "target_defect", "projection_gap", "target_specialization_gap",
        "expected_difference", "standardir_advantage", "reference_advantage",
        "lfortran_advantage", "method_gap",
    }
    bad = sorted({row["classification"] for row in rows} - allowed)
    if bad:
        raise SystemExit("E0149 comparison matrix has unknown classifications: " + ", ".join(bad))
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lab-root", type=Path, required=True)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--standard-run", default=STANDARD_RUN,
                        help="cached StandardIR run, for example E0147/R000018")
    parser.add_argument("--standard-commit", default=None)
    parser.add_argument("--scope", choices=("auto", "closure", "selected"), default="auto",
                        help="interpret the supplied StandardIR export as a closure or selected parser")
    args = parser.parse_args()
    lab_root = args.lab_root.resolve()
    run_dir = args.run_dir.resolve()
    run_dir.mkdir(parents=True, exist_ok=True)

    standard_root = lab_root.parent / "standard-new"
    lfortran_root = lab_root.parent / "lfortran-12385"
    run_parts = args.standard_run.split("/", 1)
    if len(run_parts) != 2 or not all(run_parts):
        raise SystemExit("--standard-run must be EXPERIMENT/RUN")
    source_run = lab_root / ".cache" / "runs" / run_parts[0] / run_parts[1]
    standard_path = source_run / STANDARD_FILE
    if not standard_path.is_file():
        raise SystemExit(f"missing StandardIR Bison evidence under {source_run}")
    standard_commit = args.standard_commit
    if standard_commit is None:
        metadata = source_run / "metadata.tsv"
        if metadata.is_file():
            for line in metadata.read_text(encoding="utf-8").splitlines():
                key, _, value = line.partition("\t")
                if key == "standard-new-commit":
                    standard_commit = value.strip()
                    break
    if standard_commit is None:
        standard_commit = STANDARD_COMMIT
    pinned = command(["git", "-C", str(standard_root), "rev-parse", standard_commit])
    if pinned.returncode != 0:
        raise SystemExit(f"standard-new commit is unavailable: {standard_commit}")
    lfortran = command(["git", "-C", str(lfortran_root), "show", f"{LF_COMMIT}:{LF_PATH}"])
    if lfortran.returncode != 0:
        raise SystemExit("pinned LFortran parser source is unavailable")
    lfortran_sha = hashlib.sha256(lfortran.stdout.encode("utf-8")).hexdigest()
    if lfortran_sha != LF_SHA256:
        raise SystemExit(f"pinned LFortran hash mismatch: {lfortran_sha}")

    standard_text = standard_path.read_text(encoding="utf-8")
    lfortran_text = lfortran.stdout
    standard_productions = parse_productions(standard_text)
    lfortran_productions = parse_productions(lfortran_text)
    rows = read_matrix()
    coverage = write_coverage(run_dir / "production-coverage.tsv",
                              standard_productions, lfortran_productions)
    write(run_dir / "lfortran-parser.yy", lfortran_text)
    selected_mode = args.scope == "selected" or (
        args.scope == "auto" and "target=selected-root" in standard_text[:2048])
    if selected_mode:
        standard_metrics = run_bison(standard_path, run_dir, "standardir-selected-program")
        selected_metrics = standard_metrics
    else:
        standard_metrics = run_bison(standard_path, run_dir, "standardir-all-roots")
        selected_path = run_dir / "standardir-program-root.y"
        write(selected_path, standard_text.replace("%start standardir_start", "%start r_program", 1))
        selected_metrics = run_bison(selected_path, run_dir, "standardir-program-root")
    lfortran_metrics = run_bison(run_dir / "lfortran-parser.yy", run_dir, "lfortran")

    inventory = [
        ("standardir", "all", len(standard_productions),
         sum(int(row["alternatives"]) for row in standard_productions),
         sum(str(row["lhs"]).startswith("h_r_") for row in standard_productions)),
        ("standardir", "base-r", sum(str(row["lhs"]).startswith("r_") and
                                         not str(row["lhs"]).startswith("h_r_")
                                         for row in standard_productions),
         sum(int(row["alternatives"]) for row in standard_productions
             if str(row["lhs"]).startswith("r_") and not str(row["lhs"]).startswith("h_r_")),
         0),
        ("lfortran", "all", len(lfortran_productions),
         sum(int(row["alternatives"]) for row in lfortran_productions), 0),
    ]
    write(run_dir / "inventory.tsv", "grammar\tscope\tproduction_heads\talternatives\thelper_heads\n" +
          "\n".join("\t".join(map(str, row)) for row in inventory) + "\n")
    write(run_dir / "anchors.tsv", "id\tlane\tclassification\tobservation\tevidence\n" +
          "\n".join("\t".join(row[key] for key in
                             ("id", "lane", "classification", "observation", "evidence"))
                   for row in rows) + "\n")
    write(run_dir / "findings.tsv", "id\tclassification\tlane\tobservation\tevidence\taction\n" +
          "\n".join("\t".join(row[key] for key in
                             ("id", "classification", "lane", "observation", "evidence", "action"))
                   for row in rows) + "\n")

    counts = Counter(row["classification"] for row in rows)
    summary = {
        "experiment": "E0149",
        "status": "verification_failure" if any(
            counts[k] for k in ("target_defect", "projection_gap", "target_specialization_gap", "method_gap")
        ) else "reported",
        "standard_new_commit": standard_commit,
        "lfortran_commit": LF_COMMIT,
        "lfortran_path": LF_PATH,
        "lfortran_sha256": lfortran_sha,
        "standardir_run": args.standard_run,
        "standardir_scope": "selected-program" if selected_mode else "closure-all-roots",
        "standardir": {
            "production_heads": len(standard_productions),
            "alternatives": sum(int(row["alternatives"]) for row in standard_productions),
            "helper_heads": sum(str(row["lhs"]).startswith("h_r_") for row in standard_productions),
            "bison_all_roots": standard_metrics,
            "bison_selected_program": selected_metrics,
        },
        "lfortran": {
            "production_heads": len(lfortran_productions),
            "alternatives": sum(int(row["alternatives"]) for row in lfortran_productions),
            "bison": lfortran_metrics,
        },
        "audited_lanes": sorted({row["lane"] for row in rows}),
        "audited_anchor_rows": len(rows),
        "complete_inventory": coverage,
        "findings_by_class": dict(sorted(counts.items())),
        "standardir_advantages_recorded": counts["standardir_advantage"],
    }
    write(run_dir / "summary.json", json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
