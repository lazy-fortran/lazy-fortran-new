#!/usr/bin/env python3
"""Compare M1-M2 traces after excluding non-portable environment evidence."""

from __future__ import annotations

import difflib
import json
import sys
from pathlib import Path


def portable(path: Path) -> str:
    document = json.loads(path.read_text(encoding="utf-8"))
    reproducibility = document.get("reproducibility", {})
    reproducibility.pop("environment", None)
    return json.dumps(document, indent=2, sort_keys=True) + "\n"


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: compare_m1m2_trace.py GENERATED COMMITTED")
    generated, committed = map(Path, sys.argv[1:])
    left = portable(generated)
    right = portable(committed)
    if left != right:
        diff = difflib.unified_diff(
            right.splitlines(), left.splitlines(),
            fromfile=str(committed), tofile=str(generated), lineterm="",
        )
        raise SystemExit("portable M1-M2 traces differ:\n" + "\n".join(diff))
    print("M1-M2 portable trace: PASS (environment metadata excluded from comparison)")


if __name__ == "__main__":
    main()
