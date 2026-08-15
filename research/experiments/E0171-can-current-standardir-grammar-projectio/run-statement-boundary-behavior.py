#!/usr/bin/env python3
"""Run the bounded source-level statement-boundary behavior witness.

The recipe names describe the small Fortran witness construction.  The
experiment does not modify StandardIR or infer a grammar rule from a compiler:
independent compilers only adjudicate the expected source acceptance decision.
Generated source and compiler logs belong in the ignored run directory.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path


RECIPES = {
    "save-newline": "  save\n  integer :: x",
    "save-comment": "  save ! comment\n  integer :: x",
    "save-semicolon": "  save; integer :: x",
    "save-name": "  integer :: x\n  save x",
    "save-continuation": "  integer :: x\n  save &\n & x",
    "if-action-continue": "  if (.true.) continue",
    "if-action-continue-semicolon": "  if (.true.) continue; continue",
    "save-missing-separator": "  save integer :: x",
    "if-action-missing-separator": "  if (.true.) continue continue",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def render(recipe: str) -> str:
    try:
        body = RECIPES[recipe]
    except KeyError as error:
        raise SystemExit(f"unsupported behavior recipe: {recipe}") from error
    return f"program p\n{body}\nend program p\n"


def run_compiler(command: list[str], source: Path) -> tuple[str, str]:
    result = subprocess.run(command + [str(source)], text=True,
                            capture_output=True)
    outcome = "accepted" if result.returncode == 0 else "rejected"
    return outcome, result.stdout + result.stderr


def version(command: list[str]) -> str:
    result = subprocess.run(command + ["--version"], text=True,
                            capture_output=True)
    first = (result.stdout + result.stderr).splitlines()
    return first[0] if first else "version-unavailable"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("run_directory", type=Path)
    parser.add_argument("--compiler", action="append", default=None,
                        help="compiler executable; repeat to set an explicit family")
    args = parser.parse_args()
    manifest = args.manifest.resolve()
    run_directory = args.run_directory.resolve()
    if run_directory.exists():
        raise SystemExit(f"refusing to overwrite run directory: {run_directory}")
    data = tomllib.loads(manifest.read_text(encoding="utf-8"))
    cases = data.get("cases", [])
    if not cases:
        raise SystemExit(f"{manifest}: no cases")
    compiler_names = list(dict.fromkeys(args.compiler or ["gfortran", "flang-new", "lfortran"]))
    compiler_paths = [shutil.which(name) for name in compiler_names]
    if any(path is None for path in compiler_paths):
        missing = [name for name, path in zip(compiler_names, compiler_paths) if path is None]
        raise SystemExit(f"missing compiler(s): {', '.join(missing)}")

    run_directory.mkdir(parents=True)
    source_directory = run_directory / "sources"
    log_directory = run_directory / "logs"
    source_directory.mkdir()
    log_directory.mkdir()
    (run_directory / "commands.tsv").write_text(
        "compiler\tpath\tversion\n" + "\n".join(
            f"{name}\t{path}\t{version([path])}"
            for name, path in zip(compiler_names, compiler_paths)
        ) + "\n", encoding="utf-8")

    rows = []
    failures = []
    for case in cases:
        name = case["name"]
        expected = case["expected"]
        source = source_directory / f"{name}.f90"
        source.write_text(render(case["recipe"]), encoding="utf-8")
        row = {"case": name, "expected": expected, "source_sha256": sha256(source)}
        for compiler_name, compiler_path in zip(compiler_names, compiler_paths):
            flags = ["--semantics-only"] if compiler_name == "lfortran" else ["-fsyntax-only"]
            outcome, detail = run_compiler([compiler_path, *flags], source)
            row[compiler_name] = outcome
            (log_directory / f"{name}.{compiler_name}.log").write_text(detail,
                                                                        encoding="utf-8")
            if outcome != expected:
                failures.append(f"{name}:{compiler_name}={outcome},expected={expected}")
        rows.append(row)

    fields = ["case", "expected", *compiler_names, "source_sha256"]
    with (run_directory / "behavior.tsv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    summary = {
        "cases": len(rows),
        "expected_accepted": sum(row["expected"] == "accepted" for row in rows),
        "expected_rejected": sum(row["expected"] == "rejected" for row in rows),
        "failures": failures,
        "status": "PASS" if not failures else "FAIL",
    }
    import json
    (run_directory / "summary.json").write_text(json.dumps(summary, indent=2) + "\n",
                                                 encoding="utf-8")
    print(f"cases={summary['cases']}")
    print(f"failures={len(failures)}")
    print(f"status={summary['status']}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
