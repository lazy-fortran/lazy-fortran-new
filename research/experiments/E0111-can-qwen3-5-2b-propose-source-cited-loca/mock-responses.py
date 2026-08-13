#!/usr/bin/env python3
"""Create deterministic abstentions plus one cited proposal for local tests."""

import argparse
import csv
import json
import re
from pathlib import Path

from e0111_common import InputError, jsonl_write


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("prompts", help="prompts.jsonl produced by prepare-prompts.py")
    parser.add_argument("responses", help="temporary or ignored-cache JSONL output")
    parser.add_argument("--e0110", help="optional E0110 classifications.tsv for one positive fixture")
    parser.add_argument("--canonical", help="canonical source used by the positive fixture")
    args = parser.parse_args()
    try:
        prompts = []
        with Path(args.prompts).open(encoding="utf-8") as stream:
            for line in stream:
                prompts.append(json.loads(line))
        if len(prompts) != 127:
            raise InputError(f"expected 127 prompts, got {len(prompts)}")
        positive = None
        if args.e0110:
            if not args.canonical:
                raise InputError("--canonical is required with --e0110")
            with Path(args.e0110).open(encoding="utf-8", newline="") as stream:
                for row in csv.DictReader(stream, delimiter="\t"):
                    if row.get("classification") == "strict-definition":
                        raw = Path(args.canonical).read_bytes()
                        start = int(row["byte_start"])
                        length = int(row["byte_length"])
                        positive = {
                            "name": row["name"],
                            "decision": "proposal",
                            "relation": row["form"],
                            "target": row["normalized"],
                            "citation": {
                                "page": int(row["page"]),
                                "byte_start": start,
                                "byte_length": length,
                                "source_sha256": row["source_sha256"],
                                "text": raw[start : start + length].decode("utf-8"),
                            },
                        }
                        break
        proposal_written = False
        responses = []
        for item in prompts:
            windows = item.get("windows", [])
            if not proposal_written and positive and item["name"] == positive["name"]:
                responses.append(positive)
                proposal_written = True
                continue
            normalized = item["name"].strip()
            if normalized.endswith(","):
                normalized = normalized[:-1]
            match = None
            for window in windows:
                escaped = re.escape(normalized.casefold())
                for relation, phrase in (
                    ("is-one-of", r"is\s+one\s+of"),
                    ("is", r"is"),
                    ("means", r"means"),
                    ("consists-of", r"consists\s+of"),
                ):
                    if re.search(
                        rf"^\s*[0-9]+\s+(?:r[0-9]+\s+)?{escaped}\s+{phrase}\b",
                        window["text"].casefold(),
                        re.MULTILINE,
                    ):
                        match = (window, relation)
                        break
                if match:
                    break
            if not proposal_written and match:
                window, relation = match
                responses.append(
                    {
                        "name": item["name"],
                        "decision": "proposal",
                        "relation": relation,
                        "target": item["name"],
                        "citation": {
                            "page": window["page"],
                            "byte_start": window["byte_start"],
                            "byte_length": window["byte_length"],
                            "source_sha256": item["source_sha256"],
                            "text": window["text"],
                        },
                    }
                )
                proposal_written = True
            else:
                responses.append({"name": item["name"], "decision": "abstain"})
        jsonl_write(args.responses, responses)
        print(f"wrote deterministic mock responses to {args.responses}")
    except (InputError, OSError, KeyError, IndexError, json.JSONDecodeError) as exc:
        raise SystemExit(f"E0111 mock-responses: {exc}") from exc


if __name__ == "__main__":
    main()
