#!/usr/bin/env python3
"""Validate the declared M1-M2 regression-corpus entry."""

from __future__ import annotations

import hashlib
import json
import sys
import tomllib
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(
            "usage: validate_m1m2_regression.py CORPUS FIXTURE REPOSITORY-ROOT"
        )
    corpus_path, fixture_path, repository_root = map(Path, sys.argv[1:])
    corpus = tomllib.loads(corpus_path.read_text(encoding="utf-8"))
    fixture = tomllib.loads(fixture_path.read_text(encoding="utf-8"))
    root = repository_root.resolve()
    corpus_rel = corpus_path.resolve().relative_to(root).as_posix()
    fixture_rel = fixture_path.resolve().relative_to(root).as_posix()

    checks = {
        "name": corpus.get("name") == "m1m2-source-backed-v0",
        "milestone": corpus.get("milestone") == "M1-M2",
        "corpus_status": corpus.get("status") == "PASS",
        "fixture_status": fixture.get("regression_status") == "PASS",
        "fixture_link": fixture.get("regression_corpus") == corpus_rel,
        "fixture_path": corpus.get("fixture") == fixture_rel,
        "fixture_hash": corpus.get("fixture_sha256") == digest(fixture_path),
        "regenerate": corpus.get("regenerate") == "scripts/verify_active_milestone.sh",
        "verifier": corpus.get("verifier") == "tests/e2e/run-m1m2.sh",
        "oracle": corpus.get("oracle") == fixture.get("oracle"),
    }
    failed = [name for name, passed in checks.items() if not passed]
    if failed:
        raise SystemExit("M1-M2 regression manifest failed: " + ", ".join(failed))

    result = {
        "manifest": corpus_rel,
        "manifest_sha256": digest(corpus_path),
        "fixture": fixture_rel,
        "fixture_sha256": digest(fixture_path),
        "status": "PASS",
        "checks": checks,
        "origin": "MECHANICAL",
    }
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
