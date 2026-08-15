#!/usr/bin/env python3
"""Independent fixture tests for the statement-sequence witness."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("derive-statement-sequences.py")
SPEC = importlib.util.spec_from_file_location("derive_statement_sequences", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules["derive_statement_sequences"] = MODULE
SPEC.loader.exec_module(MODULE)


def test_nested_statement_is_not_itself_a_sequence_boundary() -> None:
    rules = [
        MODULE.Rule("R0", "save-stmt", ["seq", ["token", "SAVE"]], "J3", "5", "1", "0", "a" * 64),
        MODULE.Rule("R1", "action-stmt", ["alt", ["seq", ["ref", "save-stmt"]]], "J3", "5", "1", "1", "a" * 64),
        MODULE.Rule("R2", "if-stmt", ["seq", ["token", "IF"], ["ref", "action-stmt"]], "J3", "5", "1", "2", "a" * 64),
        MODULE.Rule("R3", "execution-part", ["seq", ["ref", "executable-construct"], ["repeat", ["ref", "execution-part-construct"], 0, "unbounded"]], "J3", "5", "1", "3", "a" * 64),
        MODULE.Rule("R4", "executable-construct", ["alt", ["seq", ["ref", "action-stmt"]]], "J3", "5", "1", "4", "a" * 64),
        MODULE.Rule("R5", "execution-part-construct", ["alt", ["seq", ["ref", "executable-construct"]]], "J3", "5", "1", "5", "a" * 64),
    ]
    candidates, reachable = MODULE.derive_candidates(rules, "-stmt")
    assert "save-stmt" in reachable
    assert any(row["container"] == "execution-part" for row in candidates)
    assert not any(row["container"] == "if-stmt" for row in candidates)


def test_reader_requires_source_suffix_fact() -> None:
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "layout.sx"
        path.write_text("(statement-class-suffix (suffix -stmt))\n", encoding="utf-8")
        assert MODULE.read_suffix(path) == "-stmt"


def test_compound_repeat_is_witnessed_without_an_exception() -> None:
    rules = [
        MODULE.Rule("R0", "case-stmt", ["seq", ["token", "CASE"]], "J3", "5", "1", "0", "a" * 64),
        MODULE.Rule("R1", "block", ["repeat", ["ref", "case-stmt"], 0, "unbounded"], "J3", "5", "1", "1", "a" * 64),
        MODULE.Rule("R2", "case-construct", [
            "seq", ["ref", "case-stmt"],
            ["repeat", ["seq", ["ref", "case-stmt"], ["ref", "block"]], 0, "unbounded"],
        ], "J3", "5", "1", "2", "a" * 64),
    ]
    candidates, _ = MODULE.derive_candidates(rules, "-stmt")
    assert any(row["kind"] == "compound-repeat-item" for row in candidates)
    assert any(row["kind"] == "compound-internal" for row in candidates)
    assert all(row["status"] == "candidate" for row in candidates)


if __name__ == "__main__":
    test_nested_statement_is_not_itself_a_sequence_boundary()
    test_reader_requires_source_suffix_fact()
    test_compound_repeat_is_witnessed_without_an_exception()
    print("statement-sequence witness tests passed")
