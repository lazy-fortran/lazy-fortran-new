#!/usr/bin/env python3
"""Render the frozen E0110 oracle pages for the visual-first control."""

import argparse
import csv
import hashlib
import json
import subprocess
from pathlib import Path


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdf", required=True)
    parser.add_argument("--e0110", required=True)
    parser.add_argument("--outdir", required=True)
    parser.add_argument("--dpi", type=int, default=200)
    args = parser.parse_args()
    if args.dpi < 72:
        raise SystemExit("E0114: dpi is too small")
    pdf = Path(args.pdf)
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    rows = []
    with Path(args.e0110).open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            if row.get("classification") == "strict-definition":
                rows.append({"name": row["name"], "page": int(row["page"])})
    if len(rows) != 6:
        raise SystemExit(f"E0114: expected 6 frozen oracle rows, got {len(rows)}")
    tasks = []
    for row in rows:
        image = outdir / f"page-{row['page']}.png"
        subprocess.run(
            [
                "pdftoppm",
                "-f",
                str(row["page"]),
                "-l",
                str(row["page"]),
                "-singlefile",
                "-png",
                "-r",
                str(args.dpi),
                str(pdf),
                str(image.with_suffix("")),
            ],
            check=True,
        )
        tasks.append(
            {
                "name": row["name"],
                "page": row["page"],
                "image": str(image),
                "image_sha256": sha256(image),
            }
        )
    with (outdir / "tasks.jsonl").open("w", encoding="utf-8", newline="\n") as stream:
        for task in tasks:
            stream.write(json.dumps(task, sort_keys=True) + "\n")
    (outdir / "render-config.json").write_text(
        json.dumps(
            {
                "pdf": str(pdf),
                "pdf_sha256": sha256(pdf),
                "dpi": args.dpi,
                "renderer": "pdftoppm",
                "oracle_rows": len(tasks),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"rendered {len(tasks)} oracle pages in {outdir}")


if __name__ == "__main__":
    main()
