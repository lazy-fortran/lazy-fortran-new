#!/usr/bin/env python3
"""Replay and validate E0116 rows without calling a model."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import semantic_harness as harness


def parse_args():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("rows")
    result.add_argument("--constraints", required=True)
    result.add_argument("--prior", required=True)
    result.add_argument("--trajectory", required=True, action="append",
                        help="one or more append-only trajectory files")
    result.add_argument("--expected", type=int, default=287)
    result.add_argument("--allow-subset", action="store_true",
                        help="validate an explicitly selected ordered subset")
    result.add_argument("--outdir", required=True)
    return result.parse_args()


def main():
    args = parse_args()
    rows = [json.loads(line) for line in Path(args.rows).read_text(encoding="utf-8").splitlines() if line]
    constraints = harness.load_constraints(args.constraints)
    prior = harness.load_prior(args.prior)
    if len(rows) != args.expected:
        raise SystemExit(f"E0116 validator: expected {args.expected} rows, got {len(rows)}")
    expected_ids = [row["row_key"] for row in constraints]
    actual_ids = [row.get("row_key") for row in rows]
    by_id = {row["row_key"]: row for row in constraints}
    if args.allow_subset:
        if any(row_key not in by_id for row_key in actual_ids):
            raise SystemExit("E0116 validator: subset contains an unknown row")
        positions = [expected_ids.index(row_key) for row_key in actual_ids]
        if positions != sorted(positions):
            raise SystemExit("E0116 validator: subset is not in source order")
        expected_rows = [by_id[row_key] for row_key in actual_ids]
    else:
        if actual_ids != expected_ids:
            raise SystemExit("E0116 validator: row order or denominator differs")
        expected_rows = constraints
    if len(set(actual_ids)) != len(actual_ids):
        raise SystemExit("E0116 validator: duplicate constraint rows")

    trajectory_results = {}
    for trajectory_path in args.trajectory:
        for line in Path(trajectory_path).read_text(encoding="utf-8").splitlines():
            event = json.loads(line)
            if event.get("kind") != "tool":
                continue
            result = event.get("result")
            if isinstance(result, dict) and isinstance(result.get("result"), dict):
                for evidence in [result["result"]]:
                    if "result_id" in evidence:
                        trajectory_results.setdefault(event["row_key"], set()).add(evidence["result_id"])
            if isinstance(result, dict) and isinstance(result.get("proposal"), dict):
                proposal = result["proposal"]
                trajectory_results.setdefault(event["row_key"], set()).update(proposal.get("evidence_ids", []))

    accepted = 0
    unresolved = 0
    failures = 0
    control_exact = 0
    proposals = []
    for row, expected in zip(rows, expected_rows):
        status = row.get("status")
        proposal = row.get("proposal")
        if status == "reference-only":
            if expected["primary"]:
                raise SystemExit("E0116 validator: primary constraint was marked reference-only")
            continue
        if status == "accepted":
            accepted += 1
            if not isinstance(proposal, dict):
                raise SystemExit(f"E0116 validator: accepted row lacks proposal: {expected['constraint_id']}")
            if proposal.get("constraint_id") != expected["constraint_id"]:
                raise SystemExit("E0116 validator: proposal constraint ID differs")
            if (proposal.get("source_sha256") != harness.SOURCE_HASH or
                    proposal.get("standard_sha256") != harness.STANDARD_HASH):
                raise SystemExit("E0116 validator: proposal source hash differs")
            harness.ConstraintEpisode._validate_facts(proposal.get("required_facts"), "required_facts")
            harness.ConstraintEpisode._validate_facts(proposal.get("provided_facts"), "provided_facts")
            harness.ConstraintEpisode._validate_predicate(proposal.get("predicate"))
            if not set(proposal.get("evidence_ids", [])) <= trajectory_results.get(expected["row_key"], set()):
                raise SystemExit("E0116 validator: proposal cites unavailable evidence")
            if expected["constraint_id"] in prior:
                old = prior[expected["constraint_id"]]
                if proposal["predicate"] != harness._parse_sx(old["predicate"]):
                    raise SystemExit("E0116 validator: accepted control predicate differs")
                if proposal["required_facts"] != old["required_facts"] or proposal["provided_facts"] != old["provided_facts"]:
                    raise SystemExit("E0116 validator: accepted control facts differ")
                control_exact += 1
            proposals.append(proposal)
        elif status == "unresolved":
            unresolved += 1
        elif status == "hard_failure":
            failures += 1
        else:
            raise SystemExit(f"E0116 validator: unknown row status {status!r}")

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    header = "constraint_id\tassociated_rules\tline\tpage\tsource_sha256\torigin\tsubject\tapplicability\trequired_facts\tprovided_facts\tpredicate\tevidence_ids\n"
    with (outdir / "semantic-proposals.tsv").open("w", encoding="utf-8", newline="") as stream:
        stream.write(header)
        for proposal in proposals:
            stream.write(
                "\t".join(
                    [
                        proposal["constraint_id"],
                        ",".join(proposal.get("associated_rules", [])),
                        str(proposal["line"]),
                        str(proposal["page"]),
                        proposal["source_sha256"],
                        proposal["origin"],
                        proposal["subject"],
                        proposal["applicability"],
                        " ".join(proposal["required_facts"]),
                        " ".join(proposal["provided_facts"]),
                        json.dumps(proposal["predicate"], sort_keys=True, separators=(",", ":")),
                        ",".join(proposal["evidence_ids"]),
                    ]
                )
                + "\n"
            )

    try:
        harness.ConstraintEpisode._validate_predicate({"op": "not-allowed", "args": ["x"]})
    except harness.GateError:
        negative_control = "observed_failure"
    else:
        raise SystemExit("E0116 validator: mutated constructor was accepted")

    summary = {
        "eligible_constraints": len(rows),
        "proposal_rows": len(proposals),
        "schema_accepted_rows": accepted,
        "source_gate_accepted_rows": accepted,
        "prior_control_exact_rows": control_exact,
        "unresolved_rows": unresolved,
        "hard_failures": failures,
        "reference_only_rows": sum(row["status"] == "reference-only" for row in rows),
        "duplicate_constraint_rows": 0,
        "parser_projection_records": 0,
        "semantic_promotions": 0,
        "negative_control": negative_control,
        "semantic_proposals_sha256": harness.source_digest(outdir / "semantic-proposals.tsv"),
    }
    (outdir / "summary.tsv").write_text(
        "metric\tvalue\n" + "\n".join(f"{key}\t{value}" for key, value in summary.items()) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
