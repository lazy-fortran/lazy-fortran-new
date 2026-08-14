#!/usr/bin/env python3
"""Check that local and cloud reasoning controls are sent distinctly."""

import importlib.util
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
