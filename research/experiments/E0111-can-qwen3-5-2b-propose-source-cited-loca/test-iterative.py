#!/usr/bin/env python3
"""Exercise repair accounting with a deterministic API substitute."""

import importlib.util
import json
import sys
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
spec = importlib.util.spec_from_file_location("e0113_iterative", HERE / "run-iterative.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


calls = {}


def fake_response(_args, item):
    calls[item["name"]] = calls.get(item["name"], 0) + 1
    if calls[item["name"]] == 1:
        return {"name": item["name"], "decision": "proposal", "relation": "is", "window": 0}
    return {"name": item["name"], "decision": "abstain"}


module.response_from_api = fake_response
with tempfile.TemporaryDirectory(prefix="e0113-iterative-test-") as temp:
    prompts = ROOT / ".cache/runs/E0113-prep/prompts.jsonl"
    sys.argv = [
        str(HERE / "run-iterative.py"),
        str(prompts),
        "--outdir",
        temp,
        "--api-url",
        "mock://unused",
        "--model",
        "mock",
        "--candidate",
        "mock",
        "--e0110",
        str(ROOT / ".cache/runs/E0110/R000001/classifications.tsv"),
    ]
    module.main()
    summary = json.loads((Path(temp) / "summary.json").read_text(encoding="utf-8"))
    assert summary["residue_rows"] == 127
    assert summary["gate_green"] == 127
    assert summary["hard_failures"] == 0
    assert summary["total_model_calls"] == 254
    assert summary["repair_iterations"] == 127
    assert summary["oracle_rows"] == 6
    assert summary["oracle_abstentions"] == 6
print("E0113 bounded repair accounting passed")
