#!/usr/bin/env python3
"""Independent fixture and negative tests for the E0116 semantic gate."""

import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

import semantic_harness as harness
import witness


ROOT = Path(__file__).resolve().parents[3]
CANONICAL = ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"
PAGES = ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index"
E0081 = ROOT / "research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh"
PRIOR = ROOT / ".cache/runs/E0087/R000001/formalizations.tsv"


def main():
    raw = CANONICAL.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == harness.SOURCE_HASH
    ranges = harness.common.load_page_index(PAGES, len(raw))
    with tempfile.TemporaryDirectory() as directory:
        predecessor = Path(directory) / "e0081"
        subprocess.run([str(E0081), str(predecessor)], check=True)
        constraints = harness.load_constraints(predecessor / "constraint-spans.tsv")
    prior = harness.load_prior(PRIOR)
    row = next(item for item in constraints if item["constraint_id"] == "C702")
    episode = harness.ConstraintEpisode(raw, ranges, constraints, row, prior)
    evidence = episode.read_constraint()
    assert "POINTER or ALLOCATABLE" in evidence["source_text"]
    result = episode.submit_semantic(
        "C702",
        "accept",
        "type-param-value",
        "declaration of an entity",
        ["type-param-value", "entity-attributes"],
        ["checked-type-param-value"],
        {"op": "implies", "args": [
            {"op": "eq", "args": ["type-param-value", ":"]},
            {"op": "or", "args": [
                {"op": "has", "args": ["pointer-attribute"]},
                {"op": "has", "args": ["allocatable-attribute"]},
            ]},
        ]},
        [evidence["result_id"]],
        [{"label": "colon-without-attribute", "expect": False}],
    )
    assert result["status"] == "accepted"
    assert episode.accepted["origin"] == "LLM"
    expected = witness.exception_predicate(evidence["source_text"])
    assert expected == episode.accepted["predicate"]
    assert witness.evaluate(expected, {"type-param-value": ":", "pointer-attribute": True,
                                       "allocatable-attribute": False}) is True
    assert witness.evaluate(expected, {"type-param-value": ":", "pointer-attribute": False,
                                       "allocatable-attribute": False}) is False

    try:
        harness.ConstraintEpisode._validate_predicate({"op": "eval", "args": ["x"]})
    except harness.GateError:
        pass
    else:
        raise AssertionError("unsafe predicate constructor was accepted")

    try:
        harness.ConstraintEpisode._validate_predicate(
            {"op": "eq", "args": ["colon", "type-param-value"]}
        )
    except harness.GateError:
        pass
    else:
        raise AssertionError("field-to-field equality was accepted as a value relation")

    for accepted in prior.values():
        harness.ConstraintEpisode._validate_predicate(harness._parse_sx(accepted["predicate"]))

    invalid = harness.ConstraintEpisode(raw, ranges, constraints, row, prior)
    invalid_evidence = invalid.read_constraint()
    result = invalid.submit_semantic(
        "C701",
        "accept",
        "x",
        "y",
        [],
        [],
        {"op": "eq", "args": ["x", "y"]},
        [invalid_evidence["result_id"]],
    )
    assert result["status"] == "rejected"
    assert result["code"] == "wrong-constraint-id"
    print("E0116 semantic gate fixture passed")


if __name__ == "__main__":
    main()
