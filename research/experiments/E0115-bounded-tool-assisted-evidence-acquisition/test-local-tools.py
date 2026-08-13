#!/usr/bin/env python3
"""Exercise the native tool-call loop with a deterministic local-model fake."""

import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


harness = load("e0115_harness", HERE / "e0115_harness.py")
runner = load("e0115_runner", HERE / "run-local-tools.py")
canonical = ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"
raw = canonical.read_bytes()
source_hash = harness.common.sha256_bytes(raw)
ranges = harness.common.load_page_index(ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index", len(raw))
residue = harness.common.load_residue(ROOT / ".cache/runs/E0106/R000001/residue-classifications.tsv")
e0110 = harness.load_e0110(ROOT / ".cache/runs/E0110/R000001/classifications.tsv", raw, ranges, source_hash)
args = SimpleNamespace(
    model="fixture-local-model",
    api_url="http://127.0.0.1:8080/v1/chat/completions",
    temperature=0.0,
    top_p=1.0,
    seed=1101,
    max_tokens=128,
    timeout=1.0,
    max_turns=4,
    candidate="fixture",
    thinking="off",
)

calls = []


def fake_call(_url, payload, _timeout):
    turn = len(calls) + 1
    calls.append(payload)
    if turn == 1:
        function = {
            "name": "search_standard",
            "arguments": json.dumps({"query": "module-name", "mode": "definition", "max_results": 1}),
        }
    else:
        evidence = json.loads(payload["messages"][-1]["content"])["results"][0]["result_id"]
        function = {
            "name": "submit_pointer",
            "arguments": json.dumps(
                {"name": "module-name", "decision": "accept", "relation": "semantic", "evidence_ids": [evidence]}
            ),
        }
    return {
        "role": "assistant",
        "tool_calls": [{"id": f"fixture-{turn}", "type": "function", "function": function}],
    }, {"usage": {"total_tokens": 1}}


runner.call_model = fake_call
result = runner.run_row(args, raw, ranges, residue, e0110, "module-name", [])
assert result["status"] == "accepted"
assert result["oracle"] == "exact"
assert result["evidence_calls"] == 1
assert result["submissions"] == 1


def content_only(_url, _payload, _timeout):
    return {"role": "assistant", "content": "I cannot use tools"}, {"usage": {}}


runner.call_model = content_only
failed = runner.run_row(args, raw, ranges, residue, e0110, "module-name", [])
assert failed["status"] == "hard_failure"
assert failed["model_errors"]
novel = runner.run_row(args, raw, ranges, residue, e0110, "scalar-int-variable", [])
assert novel["oracle"] is None
print("E0115 native local-tool loop passed")
