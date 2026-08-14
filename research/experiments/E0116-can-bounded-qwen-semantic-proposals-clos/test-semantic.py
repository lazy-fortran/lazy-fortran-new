#!/usr/bin/env python3
"""Independent fixture and negative tests for the E0116 semantic gate."""

import hashlib
import importlib.util
import io
import json
import subprocess
import tempfile
import urllib.error
from pathlib import Path

import semantic_harness as harness
import witness


RUNNER_PATH = Path(__file__).resolve().parent / "run-semantic.py"
RUNNER_SPEC = importlib.util.spec_from_file_location("e0116_runner", RUNNER_PATH)
assert RUNNER_SPEC and RUNNER_SPEC.loader
runner = importlib.util.module_from_spec(RUNNER_SPEC)
RUNNER_SPEC.loader.exec_module(runner)


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

    witnessed_episode = harness.ConstraintEpisode(
        raw, ranges, constraints, row, prior, require_witnesses=True
    )
    witnessed_evidence = witnessed_episode.read_constraint()
    missing = witnessed_episode.submit_semantic(
        "C702", "accept", "type-param-value", "declaration of an entity",
        ["type-param-value", "entity-attributes"], ["checked-type-param-value"],
        expected, [witnessed_evidence["result_id"]]
    )
    assert missing == {"status": "rejected", "code": "witnesses-required"}
    accepted_with_witness = witnessed_episode.submit_semantic(
        "C702", "accept", "type-param-value", "declaration of an entity",
        ["type-param-value", "entity-attributes"], ["checked-type-param-value"],
        expected, [witnessed_evidence["result_id"]], [
            {"label": "pointer", "expect": True,
             "facts": {"type-param-value": ":", "pointer-attribute": True,
                       "allocatable-attribute": False}},
            {"label": "missing-attribute", "expect": False,
             "facts": {"type-param-value": ":", "pointer-attribute": False,
                       "allocatable-attribute": False}},
        ]
    )
    assert accepted_with_witness["status"] == "accepted"

    malformed_episode = harness.ConstraintEpisode(
        raw, ranges, constraints, row, prior, require_witnesses=True
    )
    malformed_evidence = malformed_episode.read_constraint()
    try:
        malformed_episode.submit_semantic(
            "C702", "accept", "type-param-value", "declaration of an entity",
            ["type-param-value"], ["checked-type-param-value"],
            {"op": "and", "args": ["colon-used", {"op": "has", "args": ["pointer-attribute"]}]},
            [malformed_evidence["result_id"]], [{
                "label": "malformed", "expect": True,
                "facts": {"colon-used": True, "pointer-attribute": True},
            }]
        )
    except harness.GateError as exc:
        assert "nested predicates" in str(exc)
    else:
        raise AssertionError("strict witness mode accepted malformed logical arguments")

    adapted = runner.content_tool_call(
        "<tool_call><function=read_rule>\n"
        "<parameter=rule_number>\nR911\n</parameter>\n"
        "</function></tool_call>",
        4,
    )
    assert adapted["function"]["name"] == "read_rule"
    assert json.loads(adapted["function"]["arguments"]) == {"rule_number": "R911"}
    assert runner.content_tool_call("<tool_call><function=read_rule></tool_call>", 5) is None

    assert runner.proposal_fingerprint({"b": 2, "a": 1}) == runner.proposal_fingerprint({"a": 1, "b": 2})
    assert "LOOP RECOVERY" in runner.submission_repair_message(
        {"message": "bad predicate"}, 2
    )
    assert "same-as" in runner.submission_repair_message(
        {"message": "bad predicate"}, 2
    )

    class FakeResponse:
        def __init__(self, payload):
            self.payload = payload

        def __enter__(self):
            return self

        def __exit__(self, *_args):
            return False

        def read(self):
            return self.payload

    original_urlopen = runner.urllib.request.urlopen
    original_sleep = runner.time.sleep
    calls = []

    def fake_urlopen(_request, timeout):
        calls.append(timeout)
        if len(calls) == 1:
            raise urllib.error.HTTPError(
                "http://127.0.0.1:1", 503, "busy", {}, io.BytesIO(b"busy")
            )
        return FakeResponse(json.dumps({
            "id": "test-response",
            "choices": [{
                "message": {"role": "assistant", "tool_calls": []},
                "finish_reason": "tool_calls",
            }],
            "timings": {"predicted_n": 3},
        }).encode())

    runner.urllib.request.urlopen = fake_urlopen
    runner.time.sleep = lambda _seconds: None
    try:
        _message, _response, telemetry = runner.call_model(
            "http://127.0.0.1:1/v1/chat/completions", {}, 0.1, 1
        )
    finally:
        runner.urllib.request.urlopen = original_urlopen
        runner.time.sleep = original_sleep
    assert len(calls) == 2
    assert telemetry["transport_retries"] == 1
    assert telemetry["finish_reason"] == "tool_calls"
    assert telemetry["timings"] == {"predicted_n": 3}

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

    harness.ConstraintEpisode._validate_predicate({
        "op": "relation",
        "args": ["type-compatible", "allocate-object", "type-spec"],
    })
    try:
        harness.ConstraintEpisode._validate_predicate({
            "op": "relation",
            "args": ["type-compatible", "allocate-object", "not a fact"],
        })
    except harness.GateError:
        pass
    else:
        raise AssertionError("malformed relation subject was accepted")

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
