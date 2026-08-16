#!/usr/bin/env python3
"""Compare E0172 residual errors with the immutable E0123 baseline."""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path


STRUCTURAL_PREFIXES = (
    "binary value relation compares",
    "and arguments must be nested predicates",
    "implies requires two nested predicates",
    "in requires a fact and a literal list",
    "relation name must be a lowercase fact identifier",
    "not requires exactly one nested predicate",
    "predicate args must contain 1..8 values",
    "has requires one fact identifier",
    "or arguments must be nested predicates",
    "exists requires one fact identifier",
    "present requires one fact identifier",
    "predicate must be an object with exactly op and args",
    "relation subjects must be fact identifiers or predicates",
    "ge requires a fact on the left and one literal on the right",
    "le requires a fact on the left and one literal on the right",
)


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def rows(path: Path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]


def structural_errors(path: Path):
    counts = Counter()
    total = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line:
            continue
        event = json.loads(line)
        result = event.get("result")
        message = result.get("message") if isinstance(result, dict) else None
        if not isinstance(message, str):
            continue
        for prefix in STRUCTURAL_PREFIXES:
            if message.startswith(prefix):
                counts[prefix] += 1
                total += 1
                break
    return {"total": total, "by_class": dict(sorted(counts.items()))}


def row_metrics(path: Path):
    values = rows(path)
    statuses = Counter(row.get("status") for row in values)
    return {
        "rows": len(values),
        "status": dict(sorted(statuses.items())),
        "gate_rejections": sum(row.get("gate_rejections", 0) for row in values),
        "model_errors": sum(len(row.get("model_errors", [])) for row in values),
        "loop_recoveries": sum(row.get("loop_recoveries", 0) for row in values),
        "evidence_calls": sum(row.get("evidence_calls", 0) for row in values),
        "submissions": sum(row.get("submissions", 0) for row in values),
        "prompt_tokens": sum(row.get("prompt_tokens", 0) for row in values),
        "completion_tokens": sum(row.get("completion_tokens", 0) for row in values),
        "total_tokens": sum(row.get("total_tokens", 0) for row in values),
        "wall_s_total": sum(row.get("wall_s", 0.0) for row in values),
    }


def main() -> None:
    if len(sys.argv) != 8:
        raise SystemExit(
            "usage: compare.py CANDIDATE-REPORT BASELINE-REPORT "
            "CANDIDATE-ROWS BASELINE-ROWS CANDIDATE-TRAJECTORY "
            "BASELINE-TRAJECTORY OUTPUT"
        )
    candidate_report, baseline_report, candidate_rows, baseline_rows, candidate_trajectory, baseline_trajectory, output = map(Path, sys.argv[1:])
    candidate = read_json(candidate_report)
    baseline = read_json(baseline_report)
    candidate_row_values = rows(candidate_rows)
    baseline_row_values = rows(baseline_rows)
    candidate_keys = {row["row_key"] for row in candidate_row_values}
    baseline_keys = {row["row_key"] for row in baseline_row_values}
    if candidate_keys != baseline_keys:
        raise SystemExit("E0172 residual row set differs from E0123")

    candidate_validation = candidate["validation"]
    candidate_witness = candidate["witness"]
    baseline_validation = baseline["validation"]
    baseline_witness = baseline["witness"]
    checks = {
        "candidate_rows": candidate["merge"]["selected_rows"] == 287,
        "replacement_set_exact": candidate["merge"]["replacement_set_exact"] is True,
        "candidate_schema_not_lower": candidate_validation["schema_accepted_rows"] >= baseline_validation["schema_accepted_rows"],
        "candidate_schema_source_not_lower": candidate_validation["source_gate_accepted_rows"] >= baseline_validation["source_gate_accepted_rows"],
        "candidate_witness_rows": candidate_witness["rows"] == 287,
        "candidate_witness_disputed_not_higher": candidate_witness["disputed_rows"] <= baseline_witness["disputed_rows"],
        "candidate_witness_unwitnessed_not_higher": candidate_witness["unwitnessed_rows"] <= baseline_witness["unwitnessed_rows"],
        "candidate_promotions_zero": candidate_witness["promoted_rows"] == 0 and candidate_validation["semantic_promotions"] == 0,
        "candidate_parser_projections_zero": candidate_validation["parser_projection_records"] == 0,
        "candidate_negative_control": candidate_validation["negative_control"] == "observed_failure",
    }
    failed = [name for name, passed in checks.items() if not passed]
    if failed:
        raise SystemExit("E0172 validity gate failed: " + ", ".join(failed))

    candidate_structural = structural_errors(candidate_trajectory)
    baseline_structural = structural_errors(baseline_trajectory)
    result = {
        "experiment": "E0172",
        "status": "improved" if candidate_structural["total"] < baseline_structural["total"] else "not_improved",
        "checks": checks,
        "baseline": {
            "report": str(baseline_report),
            "rows": row_metrics(baseline_rows),
            "structural_errors": baseline_structural,
        },
        "candidate": {
            "report": str(candidate_report),
            "rows": row_metrics(candidate_rows),
            "structural_errors": candidate_structural,
            "witness": candidate_witness,
            "validation": candidate_validation,
        },
        "delta": {
            "structural_error_total": candidate_structural["total"] - baseline_structural["total"],
            "hard_failure_rows": candidate["merge"]["selected_hard_failure"] - baseline["merge"]["selected_hard_failure"],
            "unresolved_rows": candidate["merge"]["selected_unresolved"] - baseline["merge"]["selected_unresolved"],
        },
        "origin": "MECHANICAL",
    }
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
