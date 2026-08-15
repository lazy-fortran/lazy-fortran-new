#!/usr/bin/env python3
"""Adjudicate the already-gated generic role-family parser projection."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def table(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines()[1:]:
        fields = line.split("\t")
        if len(fields) >= 2:
            result[fields[0]] = fields[1]
    return result


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("baseline_summary", type=Path)
    parser.add_argument("all_root_candidate_oracles", type=Path)
    parser.add_argument("selected_candidate_oracles", type=Path)
    parser.add_argument("role_witness", type=Path)
    parser.add_argument("language_report", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    baseline = json.loads(args.baseline_summary.read_text(encoding="utf-8"))
    all_root = table(args.all_root_candidate_oracles)
    selected = table(args.selected_candidate_oracles)
    role = table(args.role_witness)
    language = json.loads(args.language_report.read_text(encoding="utf-8"))

    require(baseline["status"] == "PASS", "E0159 conflict inventory is not green")
    require(baseline["selected_program"] == {"shift_reduce": 427, "reduce_reduce": 2266}, "unexpected baseline conflict totals")
    require(baseline["all_roots"] == {"shift_reduce": 758, "reduce_reduce": 3885}, "unexpected all-root baseline totals")
    require(all_root["bison_shift_reduce_conflicts"] == "760", "unexpected all-root candidate shift/reduce total")
    require(all_root["bison_reduce_reduce_conflicts"] == "3894", "unexpected all-root candidate reduce/reduce total")
    require(selected["bison_shift_reduce_conflicts"] == "425", "unexpected selected candidate shift/reduce total")
    require(selected["bison_reduce_reduce_conflicts"] == "2135", "unexpected selected candidate reduce/reduce total")
    require(selected["bison_useless_nonterminals"] == "0" and selected["bison_useless_rules"] == "0", "candidate has useless Bison output")
    require(all_root["bison_useless_nonterminals"] == "0" and all_root["bison_useless_rules"] == "0", "all-root candidate has useless Bison output")
    require(role.get("status") == "PASS", "role-family witness is not green")
    require(language.get("status") == "PASS", "language corpus is not green")
    require(language.get("positive_cases") == 359 and language.get("negative_cases") == 636, "language corpus denominator changed")
    require(language.get("negative_candidate_acceptances") == 0, "candidate accepted a baseline-rejected negative")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        "metric\tvalue\n"
        "conflict_inventory\tPASS\n"
        "lfortran_policy_comparison\tPASS-R000329\n"
        "selected_baseline_shift_reduce\t427\n"
        "selected_baseline_reduce_reduce\t2266\n"
        "selected_candidate_shift_reduce\t425\n"
        "selected_candidate_reduce_reduce\t2135\n"
        "selected_delta_shift_reduce\t-2\n"
        "selected_delta_reduce_reduce\t-131\n"
        "all_root_baseline_shift_reduce\t758\n"
        "all_root_baseline_reduce_reduce\t3885\n"
        "all_root_candidate_shift_reduce\t760\n"
        "all_root_candidate_reduce_reduce\t3894\n"
        "all_root_promotion\tREJECTED-WORSE\n"
        "role_family_witness\tPASS\n"
        "language_corpus\tPASS\n"
        "positive_cases\t359\n"
        "negative_cases\t636\n"
        "negative_candidate_acceptances\t0\n"
        "production_default_change\tNONE\n"
        "status\tPASS\n",
        encoding="utf-8",
    )
    print(args.output.read_text(encoding="utf-8"), end="")


if __name__ == "__main__":
    main()
