#!/usr/bin/env python3
"""Run independent target-tool and mutation checks on generated grammars."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


def run(argv: list[str], cwd: Path | None = None) -> tuple[int, str]:
    result = subprocess.run(argv, cwd=cwd, text=True, capture_output=True)
    return result.returncode, result.stdout + result.stderr


def require_tool(name: str) -> None:
    if run(["bash", "-lc", f"command -v {name}"])[0] != 0:
        raise SystemExit(f"missing independent grammar validator: {name}")


def mutate(source: Path, destination: Path) -> None:
    text = source.read_text(encoding="utf-8")
    match = re.search(r"\br_[A-Za-z0-9_]+\b", text)
    if match is None:
        raise SystemExit(f"no target reference found in {source}")
    destination.write_text(
        text[: match.start()] + "r_m1m2_unknown_control" + text[match.end() :],
        encoding="utf-8",
    )


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: validate_m1m2_grammars.py RUN-DIRECTORY")
    run_dir = Path(sys.argv[1])
    for tool in ("antlr4", "bison", "tree-sitter"):
        require_tool(tool)
    validation = run_dir / "validators"
    validation.mkdir()
    (validation / "antlr").mkdir()
    (validation / "bison").mkdir()
    (validation / "tree-sitter").mkdir()

    tree_dir = validation / "tree-sitter"
    (tree_dir / "grammar.js").write_text(
        (run_dir / "grammar.js").read_text(encoding="utf-8"), encoding="utf-8"
    )
    (tree_dir / "tree-sitter.json").write_text(
        '{"grammars":["grammar.js"],"metadata":{"version":"1.0.0"}}\n',
        encoding="utf-8",
    )
    commands = {
        "antlr4": [
            "antlr4", "-Werror", "-o", str(validation / "antlr"),
            str(validation / "antlr" / "StandardIR.g4"),
        ],
        "bison": [
            "bison", "--warnings=all", "-o", str(validation / "bison" / "fortran2023.c"),
            str(run_dir / "fortran2023.y"),
        ],
        "tree-sitter": ["tree-sitter", "generate"],
    }
    # ANTLR requires the filename to match the declared grammar name. Keep
    # the public artifact name, but validate a byte-identical staged copy.
    (validation / "antlr" / "StandardIR.g4").write_text(
        (run_dir / "Fortran2023.g4").read_text(encoding="utf-8"), encoding="utf-8"
    )
    results = {}
    for name, command in commands.items():
        cwd = tree_dir if name == "tree-sitter" else None
        status, output = run(command, cwd)
        (validation / f"{name}.log").write_text(output, encoding="utf-8")
        if status != 0:
            raise SystemExit(f"{name} rejected the generated grammar")
        results[name] = {"status": "PASS", "command": command}

    mutation_dir = validation / "mutation"
    (mutation_dir / "antlr").mkdir(parents=True)
    (mutation_dir / "bison").mkdir()
    (mutation_dir / "tree-sitter").mkdir()
    mutate(run_dir / "Fortran2023.g4", mutation_dir / "Fortran2023.g4")
    mutate(run_dir / "fortran2023.y", mutation_dir / "fortran2023.y")
    mutate(run_dir / "grammar.js", mutation_dir / "grammar.js")
    (mutation_dir / "tree-sitter" / "grammar.js").write_text(
        (mutation_dir / "grammar.js").read_text(encoding="utf-8"), encoding="utf-8"
    )
    (mutation_dir / "tree-sitter" / "tree-sitter.json").write_text(
        '{"grammars":["grammar.js"],"metadata":{"version":"1.0.0"}}\n',
        encoding="utf-8",
    )
    negative_commands = {
        "antlr4": [
            "antlr4", "-Werror", "-o", str(mutation_dir / "antlr"),
            str(mutation_dir / "antlr" / "StandardIR.g4"),
        ],
        "bison": [
            "bison", "--warnings=all", "-o", str(mutation_dir / "bison" / "fortran2023.c"),
            str(mutation_dir / "fortran2023.y"),
        ],
        "tree-sitter": ["tree-sitter", "generate"],
    }
    (mutation_dir / "antlr" / "StandardIR.g4").write_text(
        (mutation_dir / "Fortran2023.g4").read_text(encoding="utf-8"), encoding="utf-8"
    )
    for name, command in negative_commands.items():
        cwd = mutation_dir / "tree-sitter" if name == "tree-sitter" else None
        status, output = run(command, cwd)
        (validation / f"{name}-negative.log").write_text(output, encoding="utf-8")
        if status == 0:
            raise SystemExit(f"{name} mutation did not fail closed")
        results[name]["negative_control"] = "observed_failure"

    (validation / "result.json").write_text(json.dumps(results, indent=2) + "\n")
    print("M1-M2 grammar validators: PASS")


if __name__ == "__main__":
    main()
