#!/usr/bin/env python3
"""Run the independent corpus recognizer against the generated runtime.

The EBNF recognizer creates the bounded corpus.  fortfront-new consumes the
same cases through its generic batch CLI, loading the contract once per root.
No source-language rule is named here.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path


SCRIPT = Path(__file__).resolve().parent
COMPARE = SCRIPT.parent / "E0161-can-an-opt-in-role-family-projection-pre" / "compare_language.py"


def die(message: str) -> "NoReturn":
    raise SystemExit(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(command: list[str], *, cwd: Path, output: Path | None = None,
        timeout: float | None = None) -> tuple[int, str]:
    if output is None:
        try:
            result = subprocess.run(command, cwd=cwd, text=True, capture_output=True,
                                    timeout=timeout)
            return result.returncode, result.stdout + result.stderr
        except subprocess.TimeoutExpired as error:
            return 124, (error.stdout or "") + (error.stderr or "") + "\ncommand-timeout\n"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8") as stream:
        try:
            result = subprocess.run(command, cwd=cwd, text=True, stdout=stream,
                                    stderr=subprocess.STDOUT, timeout=timeout)
            code = result.returncode
        except subprocess.TimeoutExpired:
            stream.write("\ncommand-timeout\n")
            code = 124
    return code, output.read_text(encoding="utf-8")


def load_rows(path: Path, default_root: str) -> list[dict]:
    rows = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        row = json.loads(line)
        row["root"] = row.get("root", default_root)
        row["case_id"] = f"{path.stem}-{number}"
        row["expected"] = "accepted" if row["baseline_accepts"] else "rejected"
        if row["candidate_accepts"] != row["baseline_accepts"]:
            die(f"independent corpus disagreement at {path}:{number}")
        rows.append(row)
    return rows


def read_lexical_token_map(path: Path) -> dict[str, str]:
    """Read source lexical classes and their generated target token names."""
    token_map: dict[str, str] = {}
    source_pattern = re.compile(r"\(source-term\s+(?:\"([^\"]*)\"|([^\s)]+))\)")
    class_pattern = re.compile(r"\(class\s+lexical-class\)")
    target_pattern = re.compile(r"\(target\s+(?:\"([^\"]*)\"|([^\s)]+))\)")
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.startswith("(lexical-fact ") or not class_pattern.search(line):
            continue
        source = source_pattern.search(line)
        target = target_pattern.search(line)
        if source is None or target is None:
            die(f"{path}:{number}: lexical class has no source term or target")
        source_term = source.group(1) or source.group(2)
        target_token = target.group(1) or target.group(2)
        if source_term in token_map and token_map[source_term] != target_token:
            die(f"{path}:{number}: lexical source term has conflicting targets")
        token_map[source_term] = target_token
    if not token_map:
        die(f"{path}: no lexical-class token mappings")
    return token_map


def write_cases(rows: list[dict], directory: Path, token_map: dict[str, str]) -> dict[str, list[dict]]:
    by_root: dict[str, list[dict]] = {}
    for row in rows:
        by_root.setdefault(row["root"], []).append(row)
    directory.mkdir(parents=True, exist_ok=True)
    for root, root_rows in by_root.items():
        path = directory / f"{root}.tsv"
        with path.open("w", encoding="utf-8") as stream:
            for row in root_rows:
                tokens = [token_map.get(token, token) for token in row["tokens"]]
                stream.write("\t".join([row["case_id"], *tokens]) + "\n")
    return by_root


def parse_batch_output(text: str, root: str) -> dict[str, tuple[str, str]]:
    outcomes: dict[str, tuple[str, str]] = {}
    for line in text.splitlines():
        fields = line.split("\t", 2)
        if len(fields) != 3 or not fields[0] or fields[0] in {"case-id", "rules="}:
            continue
        case_id, outcome, message = fields
        if not re.fullmatch(r"[A-Za-z0-9_-]+", case_id):
            continue
        if case_id in outcomes:
            die(f"duplicate runtime outcome for {case_id} ({root})")
        outcomes[case_id] = (outcome, message)
    return outcomes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_directory", type=Path)
    parser.add_argument("grammar_run", type=Path)
    parser.add_argument("contract", type=Path)
    parser.add_argument("fortfront_root", type=Path)
    parser.add_argument("--lexical-facts", type=Path, required=True)
    parser.add_argument("--expected-fortfront-commit", required=True)
    parser.add_argument("--language-family-report", type=Path, required=True)
    parser.add_argument("--root-timeout-seconds", type=float, default=180.0)
    args = parser.parse_args()

    run_dir = args.run_directory.resolve()
    if run_dir.exists():
        die(f"refusing to overwrite run directory: {run_dir}")
    grammar_run = args.grammar_run.resolve()
    contract = args.contract.resolve()
    fortfront = args.fortfront_root.resolve()
    lexical_facts = args.lexical_facts.resolve()
    grammar = grammar_run / "grammar.ebnf"
    oracles = grammar_run / "grammar-oracles.tsv"
    family_roots_report = args.language_family_report.resolve()
    if (not grammar.is_file() or not contract.is_file() or not oracles.is_file() or
            not family_roots_report.is_file() or not lexical_facts.is_file()):
        die("missing pinned grammar, oracle table or contract")

    status = subprocess.run(["git", "status", "--porcelain"], cwd=fortfront,
                            text=True, capture_output=True, check=True)
    if status.stdout.strip():
        die("fortfront-new worktree is dirty")
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=fortfront,
                                   text=True).strip()
    if head != args.expected_fortfront_commit:
        die(f"fortfront-new commit {head} differs from {args.expected_fortfront_commit}")

    oracle_text = oracles.read_text(encoding="utf-8")
    if "overall\tPASS" not in oracle_text or "source-projection\tPASS" not in oracle_text:
        die("pinned four-format oracle gate is not PASS")

    run_dir.mkdir(parents=True)
    corpus_dir = run_dir / "corpus"
    report_dir = run_dir / "reports"
    command_log = run_dir / "commands.log"
    fo_log = run_dir / "fo.log"
    fo_code, fo_text = run(["fo"], cwd=fortfront, output=fo_log)
    if fo_code != 0:
        die(f"fortfront-new bare fo failed; see {fo_log}")
    warning_lines = [
        line for line in fo_text.splitlines()
        if re.search(r"\bwarning\b", line, re.IGNORECASE)
        and not re.search(r"\b0\s+warnings?\b", line, re.IGNORECASE)
    ]
    if warning_lines:
        die(f"fortfront-new fo emitted warnings; see {fo_log}")
    all_rows: list[dict] = []
    generated: list[tuple[str, list[str], Path]] = []

    family_corpus = corpus_dir / "language-family.jsonl"
    family_report = report_dir / "language-family.json"
    family_roots = json.loads(family_roots_report.read_text(encoding="utf-8")).get("roots", [])
    family_roots = [root for root in family_roots if root != "data-ref"]
    if not family_roots:
        die(f"{family_roots_report}: no retained language-family roots")
    family_command = [sys.executable, str(COMPARE), str(grammar), str(grammar),
                      *sum((["--root", root] for root in family_roots), []),
                      "--corpus", str(family_corpus),
                      "--report", str(family_report), "--max-depth", "8",
                      "--max-tokens", "4", "--max-words", "256", "--max-negative", "64",
                      "--repeat-limit", "1"]
    data_ref_corpus = corpus_dir / "data-ref.jsonl"
    data_ref_report = report_dir / "data-ref.json"
    data_ref_command = [sys.executable, str(COMPARE), str(grammar), str(grammar),
                        "--root", "data-ref", "--corpus", str(data_ref_corpus),
                        "--report", str(data_ref_report), "--max-depth", "8",
                        "--max-tokens", "4", "--max-words", "256", "--max-negative", "64",
                        "--repeat-limit", "1"]
    for label, command, corpus in (("language-family", family_command, family_corpus),
                                   ("data-ref", data_ref_command, data_ref_corpus)):
        code, text = run(command, cwd=SCRIPT.parent.parent.parent,
                         output=report_dir / f"{label}-recognizer.log")
        if code != 0:
            die(f"independent recognizer failed for {label}")
        report = json.loads((report_dir / f"{label}.json").read_text(encoding="utf-8"))
        if report.get("status") != "PASS":
            die(f"independent recognizer did not pass for {label}")
        rows = load_rows(corpus, "data-ref" if label == "data-ref" else "program")
        all_rows.extend(rows)
        generated.append((label, command, corpus))

    token_map = read_lexical_token_map(lexical_facts)
    mapping_path = run_dir / "runtime-token-map.tsv"
    with mapping_path.open("w", encoding="utf-8") as mapping:
        mapping.write("source_term\ttarget_token\n")
        for source_term, target_token in sorted(token_map.items()):
            mapping.write(f"{source_term}\t{target_token}\n")
    by_root = write_cases(all_rows, run_dir / "cases", token_map)
    expected = {row["case_id"]: row for row in all_rows}
    if len(expected) != len(all_rows):
        die("corpus case identifiers are not unique")

    commands: list[list[str]] = [command for _, command, _ in generated]
    start = time.monotonic()
    max_rss = 0
    all_outcomes: dict[str, tuple[str, str]] = {}
    with command_log.open("w", encoding="utf-8") as log:
        log.write("# independent recognizer commands\n")
        for command in commands:
            log.write(shlex.join(command) + "\n")
        for root, root_rows in sorted(by_root.items()):
            timing = run_dir / "timing" / f"{root}.txt"
            output = run_dir / "runtime" / f"{root}.log"
            case_file = run_dir / "cases" / f"{root}.tsv"
            timing.parent.mkdir(parents=True, exist_ok=True)
            command = ["/usr/bin/time", "-f", "elapsed_seconds=%e max_rss_kb=%M",
                       "-o", str(timing), "fo", "exec", "--no-build", "--cwd",
                       str(fortfront), "fortfront-grammar-runtime", str(contract), root,
                       "--case-file", str(case_file)]
            log.write(shlex.join(command) + "\n")
            code, text = run(command, cwd=fortfront, output=output,
                             timeout=args.root_timeout_seconds)
            if code != 0:
                die(f"runtime batch failed for root {root}; see {output}")
            match = re.search(r"max_rss_kb=(\d+)", timing.read_text(encoding="utf-8"))
            if match:
                max_rss = max(max_rss, int(match.group(1)))
            outcomes = parse_batch_output(text, root)
            if set(outcomes) != {row["case_id"] for row in root_rows}:
                die(f"runtime output case set differs for root {root}")
            all_outcomes.update(outcomes)
    elapsed = time.monotonic() - start

    result_rows = []
    mismatches = 0
    abnormal = 0
    ambiguous = 0
    for row in all_rows:
        actual, message = all_outcomes[row["case_id"]]
        if actual == "ambiguous":
            ambiguous += 1
        if actual not in {"accepted", "rejected", "ambiguous"}:
            abnormal += 1
        actual_accepts = actual in {"accepted", "ambiguous"}
        expected_accepts = row["expected"] == "accepted"
        if actual_accepts != expected_accepts:
            mismatches += 1
        result_rows.append((row, actual, message))
    with (run_dir / "case-results.tsv").open("w", encoding="utf-8") as stream:
        stream.write("case_id\troot\tkind\texpected\tactual\tmessage\n")
        for row, actual, message in result_rows:
            stream.write("\t".join([row["case_id"], row["root"], row["kind"],
                                     row["expected"], actual, message]) + "\n")

    positive = sum(row["expected"] == "accepted" for row in all_rows)
    negative = len(all_rows) - positive
    summary = {
        "status": "PASS" if mismatches == 0 and abnormal == 0 else "FAIL",
        "corpus_cases": len(all_rows),
        "positive_cases": positive,
        "negative_cases": negative,
        "expected_outcome_mismatches": mismatches,
        "accepted_outcomes": sum(actual == "accepted" for actual, _ in all_outcomes.values()),
        "rejected_outcomes": sum(actual == "rejected" for actual, _ in all_outcomes.values()),
        "ambiguous_cases": ambiguous,
        "runtime_abnormal_outcomes": abnormal,
        "roots": sorted(by_root),
        "contract_sha256": sha256(contract),
        "grammar_sha256": sha256(grammar),
        "fortfront_commit": head,
        "fo_status": "PASS",
        "warning_count": len(warning_lines),
        "elapsed_seconds": round(elapsed, 3),
        "peak_rss_kb": max_rss,
        "model_calls": 0,
    }
    (run_dir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n",
                                              encoding="utf-8")
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0 if summary["status"] == "PASS" else 1


if __name__ == "__main__":
    main()
