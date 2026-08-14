#!/usr/bin/env python3
"""Run one bounded retry for every incomplete row in a durable base cell."""

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent
RUNNER = HERE / "run-local-tools.py"


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-rows", required=True)
    parser.add_argument("--out-root", required=True)
    parser.add_argument("--api-url", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--max-turns", type=int, required=True)
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--thinking", choices=("off", "on"), default="off")
    parser.add_argument("--quantization", default="unspecified")
    parser.add_argument("--model-file", default="unspecified")
    parser.add_argument("--model-sha256", default="unspecified")
    return parser.parse_args()


def incomplete_names(path):
    names = []
    seen = set()
    with Path(path).open(encoding="utf-8") as stream:
        for line in stream:
            row = json.loads(line)
            if row["status"] != "accepted" and row["name"] not in seen:
                names.append(row["name"])
                seen.add(row["name"])
    return names


def main():
    args = parse_args()
    out_root = Path(args.out_root)
    out_root.mkdir(parents=True, exist_ok=True)
    names = incomplete_names(args.base_rows)
    print(f"retrying {len(names)} unique incomplete names", flush=True)
    failures = 0
    for name in names:
        slug = hashlib.sha256(name.encode("utf-8")).hexdigest()[:16]
        outdir = out_root / slug
        command = [
            sys.executable,
            str(RUNNER),
            "--api-url",
            args.api_url,
            "--model",
            args.model,
            "--candidate",
            args.candidate,
            "--outdir",
            str(outdir),
            "--timeout",
            str(args.timeout),
            "--max-turns",
            str(args.max_turns),
            "--thinking",
            args.thinking,
            "--only-name",
            name,
            "--quantization",
            args.quantization,
            "--model-file",
            args.model_file,
            "--model-sha256",
            args.model_sha256,
        ]
        print(name, flush=True)
        completed = subprocess.run(command, cwd=HERE.parents[2], check=False)
        if completed.returncode:
            failures += 1
    if failures:
        raise SystemExit(f"{failures} retry subprocesses failed")


if __name__ == "__main__":
    main()
