#!/usr/bin/env python3
"""Classify the immutable E0117 residual before an E0123 retry."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


def args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rows", type=Path)
    parser.add_argument("trajectory", type=Path)
    return parser.parse_args()


def error_class(message: str) -> str:
    if "exactly one native tool call" in message:
        return "no-single-tool-call"
    if "not JSON" in message:
        return "malformed-tool-json"
    return "other"


def main() -> None:
    parsed = args()
    rows = [json.loads(line) for line in parsed.rows.read_text(encoding="utf-8").splitlines() if line]
    residual = [row for row in rows if row.get("status") in {"unresolved", "hard_failure"}]
    errors = Counter()
    messages = Counter()
    for row in residual:
        for error in row.get("model_errors", []):
            errors[error_class(error.get("error", ""))] += 1
    for line in parsed.trajectory.read_text(encoding="utf-8").splitlines():
        event = json.loads(line)
        if event.get("row_key") not in {row["row_key"] for row in residual}:
            continue
        result = event.get("result")
        if not isinstance(result, dict):
            continue
        message = result.get("message")
        if isinstance(message, str):
            messages[message] += 1
    output = {
        "rows": len(rows),
        "residual_rows": len(residual),
        "residual_status": dict(sorted(Counter(row["status"] for row in residual).items())),
        "model_error_classes": dict(sorted(errors.items())),
        "top_gate_messages": [
            {"message": message, "count": count}
            for message, count in messages.most_common(10)
        ],
    }
    print(json.dumps(output, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
