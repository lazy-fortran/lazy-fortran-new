#!/usr/bin/env python3
"""Independent behavioral checks for the E0115 deterministic tool gate."""

import importlib.util
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
spec = importlib.util.spec_from_file_location("e0115_harness", HERE / "e0115_harness.py")
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)

canonical = ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"
pages = ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index"
residue_path = ROOT / ".cache/runs/E0106/R000001/residue-classifications.tsv"
e0110_path = ROOT / ".cache/runs/E0110/R000001/classifications.tsv"
raw = canonical.read_bytes()
source_hash = harness.common.sha256_bytes(raw)
ranges = harness.common.load_page_index(pages, len(raw))
residue = harness.common.load_residue(residue_path)
e0110 = harness.load_e0110(e0110_path, raw, ranges, source_hash)

episode = harness.Episode(raw, ranges, residue, e0110, "module-name")
found = episode.call("search_standard", {"query": "module-name", "mode": "definition", "max_results": 8})
assert found["status"] == "ok" and found["results"]
result_id = found["results"][0]["result_id"]
expanded = episode.call("read_span", {"result_id": result_id, "before_bytes": 2048, "after_bytes": 2048})
assert expanded["status"] == "ok" and expanded["result"]["page"] == 319
accepted = episode.call(
    "submit_pointer",
    {"name": "module-name", "decision": "accept", "relation": "semantic", "evidence_ids": [result_id]},
)
assert accepted == {"status": "accepted"}
assert episode.terminal == "accepted"
assert episode.accepted["page"] == 319

rule_episode = harness.Episode(raw, ranges, residue, e0110, "module-name")
rule = rule_episode.call("read_rule", {"rule_number": "R1409"})
assert rule["status"] == "ok" and "module-name" in rule["result"]["text"]
boundary_rule = rule_episode.call("read_rule", {"rule_number": "R705"})
assert boundary_rule["status"] == "ok" and boundary_rule["result"]["page"] == 80
try:
    rule_episode.call("read_span", {"result_id": "missing", "before_bytes": 0, "after_bytes": 0})
except harness.ToolError:
    pass
else:
    raise AssertionError("unknown result_id was accepted")

budget_episode = harness.Episode(raw, ranges, residue, e0110, "module-name", max_evidence_calls=1)
budget_episode.call("search_standard", {"query": "module-name", "mode": "exact", "max_results": 1})
try:
    budget_episode.call("read_rule", {"rule_number": "R1409"})
except harness.ToolError as exc:
    assert "budget" in str(exc)
else:
    raise AssertionError("evidence-call budget was not enforced")

print("E0115 deterministic tool gate passed")
