#!/usr/bin/env python3
"""Check that local and cloud reasoning controls are sent distinctly."""

import importlib.util
import json
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("e0111_run_local", HERE / "run-local.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


off = {}
assert module.apply_reasoning_control(off, "off") == {
    "chat_template_kwargs": {"enable_thinking": False}
}

on = {}
assert module.apply_reasoning_control(on, "on") == {
    "chat_template_kwargs": {"enable_thinking": True}
}

cloud = {}
assert module.apply_reasoning_control(cloud, "off", deepseek_cloud=True) == {
    "thinking": {"type": "disabled"}
}

print("E0111 per-request reasoning controls passed")

pointer_schema = module.response_format("x", True, 2, pointer_only=True)
pointer_properties = pointer_schema["json_schema"]["schema"]["properties"]
assert set(pointer_properties) == {"name", "decision", "relation", "window"}
assert "target" not in pointer_properties
assert module.response_format("x", True, 2, pointer_only=False)["json_schema"]["schema"]["properties"].get("target")
assert module.infer_pointer_contract(
    [{"pointer_only": True}], True, False
) == (True, True)
try:
    module.infer_pointer_contract([{"pointer_only": False}], True, True)
except module.InputError:
    pass
else:
    raise AssertionError("pointer-only mismatch was not rejected")
print("E0111 pointer-only response contract passed")

with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "stream.jsonl"
    module.jsonl_append(path, {"name": "first"})
    assert json.loads(path.read_text(encoding="utf-8").splitlines()[0])["name"] == "first"
    module.jsonl_append(path, {"name": "second"})
    assert len(path.read_text(encoding="utf-8").splitlines()) == 2
print("E0111 incremental JSONL publication passed")
