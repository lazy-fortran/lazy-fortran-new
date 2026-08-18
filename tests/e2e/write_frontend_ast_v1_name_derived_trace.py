#!/usr/bin/env python3
"""Write the canonical trace for the source-derived typed AST replay."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tomllib
from pathlib import Path


def digest(path: Path, source: Path) -> str:
    payload = path.read_text(encoding="utf-8").replace(f"(file {source})", "(file SOURCE)")
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def tool(command: list[str]) -> str:
    return subprocess.run(command, text=True, capture_output=True, check=False).stdout.splitlines()[0]


def main() -> int:
    if len(sys.argv) != 4:
        raise SystemExit("usage: write_frontend_ast_v1_name_derived_trace.py replay-manifest run-dir frontend")
    root = Path(__file__).resolve().parents[2]
    replay_path, run_dir_name, frontend = sys.argv[1:]
    replay = tomllib.loads((root / replay_path).read_text(encoding="utf-8"))
    run_dir = Path(run_dir_name)
    contract = tomllib.loads((root / replay["contract_manifest"]).read_text(encoding="utf-8"))
    cases = []
    for case in contract["case"]:
        source = (root / case["source"]).resolve()
        cases.append({
            "id": case["id"],
            "source": {"path": case["source"], "sha256": case["source_sha256"]},
            "ast_sha256": digest(run_dir / f"case-{case['id']}.ast.sx", source),
        })
    trace = {
        "milestone": "L3",
        "fixture": replay["id"],
        "boundary": replay["boundary"],
        "cases": cases,
        "components": {"fortfront-new": frontend},
        "toolchain": {"fo": tool(["fo", "version"]), "python": tool(["python3", "--version"])},
        "model_calls": 0,
        "semantic_promotions": 0,
    }
    (run_dir / "trace.json").write_text(json.dumps(trace, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    main()
