#!/usr/bin/env python3
"""Deterministic bounded evidence tools for E0115.

The episode owns the source, evidence IDs and budgets. It returns source text
and typed statuses, never a derived target or citation to the model.
"""

import csv
import hashlib
import re
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent
E0111 = HERE.parent / "E0111-can-qwen3-5-2b-propose-source-cited-loca"
sys.path.insert(0, str(E0111))

import e0111_common as common  # noqa: E402


RELATIONS = {"alias", "definition", "lexical", "metavariable", "semantic", "unresolved"}
MODES = {"exact", "definition", "rule", "reference"}
RULE_LINE = re.compile(r"^\s*(?:[0-9]+(?:\.[0-9]+)*\s+)?[RC][0-9]{3,5}\s+")


class ToolError(Exception):
    """A deterministic tool rejection."""


def load_e0110(path, raw, ranges, source_hash):
    rows = {}
    with Path(path).open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            if row["classification"] != "strict-definition":
                continue
            start = int(row["byte_start"])
            length = int(row["byte_length"])
            if row["source_sha256"] != source_hash:
                raise ToolError("E0110 source hash differs from canonical source")
            page = common.containing_page(ranges, start, length)
            if page != int(row["page"]):
                raise ToolError(f"E0110 page mismatch for {row['normalized']}")
            rows[row["normalized"]] = {
                "name": row["normalized"],
                "relation": row["form"],
                "byte_start": start,
                "byte_length": length,
                "page": page,
                "source_sha256": source_hash,
                "evidence": row["evidence"],
            }
    return rows


def line_inventory(raw):
    text = raw.decode("utf-8")
    lines = []
    cursor = 0
    for line in text.splitlines(keepends=True):
        encoded = line.encode("utf-8")
        lines.append((cursor, cursor + len(encoded), line.rstrip("\n")))
        cursor += len(encoded)
    return lines


def page_for(ranges, start, length):
    return common.containing_page(ranges, start, max(1, length))


class Episode:
    """One bounded model episode for one candidate name."""

    def __init__(
        self,
        raw,
        ranges,
        residue,
        e0110,
        name,
        *,
        max_evidence_calls=8,
        max_submissions=3,
        max_source_bytes=32768,
    ):
        names = {row["name"].rstrip(",") for row in residue}
        if name.rstrip(",") not in names:
            raise ToolError(f"candidate is outside the residue denominator: {name}")
        self.raw = raw
        self.ranges = ranges
        self.lines = line_inventory(raw)
        self.name = name.rstrip(",")
        self.e0110 = e0110
        self.max_evidence_calls = max_evidence_calls
        self.max_submissions = max_submissions
        self.max_source_bytes = max_source_bytes
        self.evidence_calls = 0
        self.submissions = 0
        self.source_bytes = 0
        self._counter = 0
        self._results = {}
        self.terminal = None
        self.accepted = None

    def _next_id(self, prefix):
        self._counter += 1
        return f"{prefix}{self._counter:04d}"

    def _evidence_call(self):
        if self.evidence_calls >= self.max_evidence_calls:
            raise ToolError("evidence-call budget exhausted")
        self.evidence_calls += 1

    def _budget_bytes(self, size):
        if self.source_bytes + size > self.max_source_bytes:
            raise ToolError("source-byte budget exhausted")
        self.source_bytes += size

    def _evidence(self, start, end, kind, *, anchor=None):
        if start < 0 or end <= start or end > len(self.raw):
            raise ToolError("evidence span is outside canonical source")
        text = self.raw[start:end].decode("utf-8")
        self._budget_bytes(len(text.encode("utf-8")))
        result_id = self._next_id("e")
        record = {
            "result_id": result_id,
            "kind": kind,
            "page": page_for(self.ranges, start, end - start),
            "byte_start": start,
            "byte_length": end - start,
            "text": text,
        }
        if anchor is not None:
            record["anchor"] = anchor
        self._results[result_id] = record
        return record

    def _matching_lines(self, query, mode):
        if mode == "rule":
            pattern = re.compile(rf"\b{re.escape(query.upper())}\b")
        elif mode == "definition":
            token = re.escape(query.rstrip(","))
            pattern = re.compile(
                rf"^\s*(?:(?:[0-9]+(?:\.[0-9]+)*|[RC][0-9]+)\s+)*"
                rf"(?:a|an|the\s+)?{token}[,;]?\s+"
                rf"(?:is\s+one\s+of|is|means|consists\s+of)\b",
                re.IGNORECASE,
            )
        else:
            pattern = re.compile(re.escape(query), re.IGNORECASE)
        matches = []
        for start, end, line in self.lines:
            if mode == "reference" and query.casefold() not in line.casefold():
                continue
            if pattern.search(line):
                matches.append((start, end, line))
        return matches

    def search_standard(self, query, mode, max_results):
        if not isinstance(query, str) or not 1 <= len(query) <= 160:
            raise ToolError("query must contain 1..160 characters")
        if mode not in MODES:
            raise ToolError(f"unsupported search mode: {mode}")
        if not isinstance(max_results, int) or not 1 <= max_results <= 8:
            raise ToolError("max_results must be in 1..8")
        self._evidence_call()
        results = []
        for start, end, _line in self._matching_lines(query, mode)[:max_results]:
            results.append(self._evidence(start, end, "search", anchor=start))
        return {"status": "ok", "query": query, "mode": mode, "results": results}

    def read_span(self, result_id, before_bytes, after_bytes):
        self._evidence_call()
        if result_id not in self._results:
            raise ToolError("result_id is not from this episode")
        if not isinstance(before_bytes, int) or not 0 <= before_bytes <= 2048:
            raise ToolError("before_bytes must be in 0..2048")
        if not isinstance(after_bytes, int) or not 0 <= after_bytes <= 2048:
            raise ToolError("after_bytes must be in 0..2048")
        source = self._results[result_id]
        page_start, page_length = next(
            (start, length) for number, start, length in self.ranges if number == source["page"]
        )
        page_end = page_start + page_length
        start = max(page_start, source["byte_start"] - before_bytes)
        end = min(page_end, source["byte_start"] + source["byte_length"] + after_bytes)
        return {"status": "ok", "result": self._evidence(start, end, "span", anchor=source["byte_start"])}

    def read_rule(self, rule_number):
        self._evidence_call()
        if not isinstance(rule_number, str) or not re.fullmatch(r"[RC][0-9]{3,5}", rule_number):
            raise ToolError("rule_number must match R/C followed by 3..5 digits")
        for index, (start, end, line) in enumerate(self.lines):
            if not re.search(rf"\b{re.escape(rule_number)}\b", line):
                continue
            page = page_for(self.ranges, start, max(1, end - start))
            final = end
            for next_start, next_end, next_line in self.lines[index + 1 :]:
                if page_for(self.ranges, next_start, max(1, next_end - next_start)) != page:
                    break
                if RULE_LINE.match(next_line):
                    break
                final = next_end
            return {"status": "ok", "result": self._evidence(start, final, "rule", anchor=start)}
        raise ToolError("rule not found")

    def _definition_match(self, evidence):
        token = re.escape(self.name)
        pattern = re.compile(
            rf"^\s*(?:(?:[0-9]+(?:\.[0-9]+)*|[RC][0-9]+)\s+)*"
            rf"(?:a|an|the\s+)?{token}[,;]?\s+"
            rf"(?:is\s+one\s+of|is|means|consists\s+of)\b",
            re.IGNORECASE | re.MULTILINE,
        )
        match = pattern.search(evidence["text"])
        if match is None:
            return None
        absolute = evidence["byte_start"] + len(evidence["text"][: match.start()].encode("utf-8"))
        return {
            "name": self.name,
            "relation": "definition",
            "page": page_for(self.ranges, absolute, max(1, len(match.group(0).encode("utf-8")))),
            "byte_start": absolute,
            "byte_length": len(match.group(0).encode("utf-8")),
            "source_sha256": hashlib.sha256(self.raw).hexdigest(),
            "evidence_ids": [evidence["result_id"]],
            "origin": "LLM",
        }

    def submit_pointer(self, name, decision, relation, evidence_ids):
        if self.terminal is not None:
            raise ToolError("episode is already terminal")
        if self.submissions >= self.max_submissions:
            raise ToolError("submission budget exhausted")
        self.submissions += 1
        if name.rstrip(",") != self.name:
            return {"status": "rejected", "code": "wrong-candidate-name"}
        if decision not in {"accept", "abstain"}:
            return {"status": "rejected", "code": "invalid-decision"}
        if relation not in RELATIONS:
            return {"status": "rejected", "code": "invalid-relation"}
        if not isinstance(evidence_ids, list) or len(evidence_ids) > 8:
            return {"status": "rejected", "code": "invalid-evidence-list"}
        if decision == "abstain":
            self.terminal = "abstained_after_budget"
            return {"status": "abstained"}
        if not evidence_ids:
            return {"status": "rejected", "code": "evidence-required"}
        for evidence_id in evidence_ids:
            if evidence_id not in self._results:
                return {"status": "rejected", "code": "unknown-evidence-id"}
        accepted = None
        for evidence_id in evidence_ids:
            accepted = self._definition_match(self._results[evidence_id])
            if accepted is not None:
                accepted["relation"] = relation
                accepted["evidence_ids"] = list(evidence_ids)
                break
        if accepted is None:
            return {"status": "rejected", "code": "no-source-backed-definition"}
        self.accepted = accepted
        self.terminal = "accepted"
        return {"status": "accepted"}

    def call(self, name, arguments):
        if name == "search_standard":
            return self.search_standard(**arguments)
        if name == "read_span":
            return self.read_span(**arguments)
        if name == "read_rule":
            return self.read_rule(**arguments)
        if name == "submit_pointer":
            return self.submit_pointer(**arguments)
        raise ToolError(f"unknown tool: {name}")
