#!/usr/bin/env python3
"""Deterministic bounded evidence tools for E0115.

The episode owns the source, evidence IDs and budgets. It returns source text
and typed statuses, never a derived target or citation to the model.
"""

import csv
import hashlib
import bisect
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
RULE_ID_LINE = re.compile(r"^\s*(?:[0-9]+(?:\.[0-9]+)*\s+)?(?P<rule>[RC][0-9]{3,5})\s+")
PRODUCTION = re.compile(
    r"\b(?P<rule>R[0-9]{3,5})\s+(?P<lhs>[A-Za-z][A-Za-z0-9-]*)\s+is\s+(?P<rhs>.*)",
    re.IGNORECASE | re.DOTALL,
)

# These are the three source-defined assumed syntax rules, not parser
# conveniences.  Keeping them as a small declarative table lets the gate
# validate their instantiations without adding one branch per residue name.
ASSUMED_RULES = {
    "R401": "list",
    "R402": "name",
    "R403": "scalar",
}

# The lexical class names are source terms; their source facts are carried by
# the numbered productions and the pinned lexical projection.  The set is
# deliberately small and data-like rather than a candidate-specific rescue
# list.
LEXICAL_CLASSES = {"digit", "letter", "rep-char"}


def candidate_guidance(name):
    """Return generic search guidance derived from the candidate shape."""
    normalized = name.rstrip(",")
    if normalized.endswith("-list"):
        return (
            "This candidate is an instance of the source-defined assumed syntax "
            "family `xyz-list`: read rule R401 first. If R401 visibly has the "
            "list form, submit that rule as evidence with relation `metavariable`; "
            "do not search for a separate production for the full candidate and "
            "do not abstain merely because the candidate has no own production."
        )
    if normalized.endswith("-name"):
        return (
            "This candidate is an instance of the source-defined assumed syntax "
            "family `xyz-name`: read rule R402 first. If R402 visibly has the "
            "name form, submit that rule as evidence with relation `metavariable`; "
            "do not search for a separate production for the full candidate unless "
            "a direct prose definition for this exact candidate is found first."
        )
    if normalized.startswith("scalar-"):
        return (
            "This candidate is an instance of the source-defined assumed syntax "
            "family `scalar-xyz`: read rule R403 first. If R403 visibly has the "
            "scalar form, submit that rule as evidence with relation `metavariable`; "
            "do not search for a separate production for the full candidate and "
            "do not abstain merely because the candidate has no own production."
        )
    if normalized in LEXICAL_CLASSES or not re.fullmatch(
        r"[A-Za-z][A-Za-z0-9-]*", normalized
    ):
        return (
            "This candidate is a lexical/operator candidate, not an ordinary "
            "nonterminal. Read an indexed numbered production and submit relation "
            "`lexical` only when its right-hand side visibly contains this token."
        )
    return "Search for a direct numbered production or a normative prose definition."


def token_pattern(query):
    if query == ".":
        return re.compile(r"(?<![A-Za-z0-9_.-])\.(?![A-Za-z0-9_.-])")
    if query == "..":
        return re.compile(r"(?<![A-Za-z0-9_.-])\.\.(?![A-Za-z0-9_.-])")
    return re.compile(
        rf"(?<![A-Za-z0-9_-]){re.escape(query)}(?![A-Za-z0-9_-])",
        re.IGNORECASE,
    )


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


def page_at(ranges, start, page_starts=None):
    if page_starts is None:
        page_starts = [page_start for _number, page_start, _length in ranges]
    index = bisect.bisect_right(page_starts, start) - 1
    if index < 0:
        raise ToolError(f"byte offset is not contained by exactly one page: {start}")
    number, page_start, page_length = ranges[index]
    if not page_start <= start < page_start + page_length:
        raise ToolError(f"byte offset is not contained by exactly one page: {start}")
    return number


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
        self.page_starts = [page_start for _number, page_start, _length in ranges]
        self.lines = line_inventory(raw)
        self.rule_indices = {}
        for index, (_start, _end, line) in enumerate(self.lines):
            match = RULE_ID_LINE.match(line)
            if match is not None:
                self.rule_indices.setdefault(match.group("rule"), index)
        self.rule_ranges = {
            rule: self._rule_range(index)
            for rule, index in self.rule_indices.items()
        }
        self.name = name.rstrip(",")
        self.direct_definition_available = bool(
            self._matching_lines(self.name, "definition")
        )
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
        # Page and byte limits are measured in bytes, while the canonical
        # source is UTF-8.  A clipped span may therefore end in the middle of
        # an en dash, apostrophe, or another multibyte source character. Keep
        # the provenance byte span bounded, but expose only a decodable inner
        # span to the model.
        text_start, text_end = None, None
        for left in range(4):
            for right in range(4):
                candidate_start = start + left
                candidate_end = end - right
                if candidate_end <= candidate_start:
                    continue
                try:
                    text = self.raw[candidate_start:candidate_end].decode("utf-8")
                except UnicodeDecodeError:
                    continue
                text_start, text_end = candidate_start, candidate_end
                break
            if text_start is not None:
                break
        if text_start is None:
            raise ToolError("evidence span cannot be decoded as UTF-8")
        self._budget_bytes(len(text.encode("utf-8")))
        result_id = self._next_id("e")
        record = {
            "result_id": result_id,
            "kind": kind,
            "page": page_for(self.ranges, start, end - start),
            "byte_start": text_start,
            "byte_length": text_end - text_start,
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
        if mode == "rule":
            pattern = token_pattern(query)
            results = []
            for rule in sorted(self.rule_ranges, key=lambda value: int(value[1:])):
                if not rule.startswith("R"):
                    continue
                start, end = self.rule_ranges[rule]
                text = self.raw[start:end].decode("utf-8")
                production = PRODUCTION.search(text)
                grammar = self._grammar_rhs(text, production) if production else ""
                if (production and pattern.search(production.group("lhs"))) or pattern.search(grammar):
                    results.append(self._evidence(start, end, "rule", anchor=start))
                    if len(results) == max_results:
                        break
            return {"status": "ok", "query": query, "mode": mode, "results": results}
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

    def _rule_range(self, index):
        start, end, _line = self.lines[index]
        page = page_at(self.ranges, start, self.page_starts)
        final = end
        for next_start, next_end, next_line in self.lines[index + 1 :]:
            if not next_line.strip(" \t\r\n\f"):
                continue
            if page_at(self.ranges, next_start, self.page_starts) != page:
                break
            if RULE_LINE.match(next_line):
                break
            final = next_end
        return start, final

    @staticmethod
    def _grammar_rhs(text, production):
        if production is None:
            return ""
        rhs = production.group("rhs").splitlines()
        parts = [rhs[0]] if rhs else []
        for line in rhs[1:]:
            normalized = re.sub(r"^\s*[0-9]+\s+", "", line).strip()
            if re.match(r"or\b", normalized, re.IGNORECASE):
                parts.append(normalized)
            else:
                break
        return " ".join(parts)

    def rule_hints(self):
        """Return source rule IDs found by the deterministic pre-index."""
        candidate = self.name
        pattern = token_pattern(candidate)
        direct = []
        terminals = []
        for rule in sorted(self.rule_ranges, key=lambda value: int(value[1:])):
            if not rule.startswith("R"):
                continue
            start, end = self.rule_ranges[rule]
            text = self.raw[start:end].decode("utf-8")
            production = PRODUCTION.search(text)
            if production is not None and production.group("lhs").casefold() == candidate.casefold():
                direct.append(rule)
            elif production is not None and pattern.search(self._grammar_rhs(text, production)):
                terminals.append(rule)
        assumed = (
            "R401" if candidate.endswith("-list") else
            "R402" if candidate.endswith("-name") else
            "R403" if candidate.startswith("scalar-") else None
        )
        hints = direct[:6]
        if not direct and assumed is not None:
            hints.append(assumed)
        for rule in terminals:
            if rule not in hints:
                hints.append(rule)
            if len(hints) == 6:
                break
        return hints

    def read_rule(self, rule_number):
        self._evidence_call()
        if not isinstance(rule_number, str) or not re.fullmatch(r"[RC][0-9]{3,5}", rule_number):
            raise ToolError("rule_number must match R/C followed by 3..5 digits")
        if rule_number not in self.rule_ranges:
            raise ToolError("rule not found")
        start, final = self.rule_ranges[rule_number]
        return {"status": "ok", "result": self._evidence(start, final, "rule", anchor=start)}

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

    def _production_match(self, evidence):
        """Classify a numbered source production without deriving a target."""
        text = evidence["text"]
        candidate = self.name
        candidate_re = re.escape(candidate)
        for match in PRODUCTION.finditer(text):
            rule = match.group("rule").upper()
            lhs = match.group("lhs")
            rhs = self._grammar_rhs(text, match)
            if lhs.casefold() == candidate.casefold():
                return match, "definition"
            assumed = ASSUMED_RULES.get(rule)
            if (
                assumed == "list"
                and candidate.casefold().endswith("-list")
                and not self.direct_definition_available
            ):
                return match, "metavariable"
            if (
                assumed == "name"
                and candidate.casefold().endswith("-name")
                and not self.direct_definition_available
            ):
                return match, "metavariable"
            if (
                assumed == "scalar"
                and candidate.casefold().startswith("scalar-")
                and not self.direct_definition_available
            ):
                return match, "metavariable"

            # A residue term that is a lexical class or a punctuation/operator
            # is a terminal when it occurs in the RHS of a numbered production.
            # Ordinary RHS nonterminals are not accepted by this fallback:
            # they need their own source definition or an assumed rule.
            terminal = candidate in LEXICAL_CLASSES or not re.fullmatch(
                r"[A-Za-z][A-Za-z0-9-]*", candidate
            )
            if terminal and re.search(
                rf"(?<![A-Za-z0-9_-]){candidate_re}(?![A-Za-z0-9_-])",
                rhs,
                re.IGNORECASE,
            ):
                return match, "lexical"
        return None

    def _source_match(self, evidence):
        direct = self._definition_match(evidence)
        if direct is not None:
            direct["source_relation"] = "definition"
            return direct
        production = self._production_match(evidence)
        if production is None:
            return None
        match, source_relation = production
        absolute = evidence["byte_start"] + len(
            evidence["text"][: match.start()]
        .encode("utf-8")
        )
        return {
            "name": self.name,
            "relation": "metavariable" if source_relation == "metavariable" else "lexical",
            "source_relation": source_relation,
            "rule": match.group("rule").upper(),
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
            accepted = self._source_match(self._results[evidence_id])
            if accepted is not None:
                accepted["relation"] = relation
                accepted["evidence_ids"] = list(evidence_ids)
                break
        if accepted is None:
            guidance = candidate_guidance(self.name)
            return {
                "status": "rejected",
                "code": "no-source-backed-definition",
                "message": (
                    "Evidence must contain a direct definition, one of the "
                    "source-defined assumed rules R401/R402/R403, or a "
                    "numbered production that defines a lexical/operator token. "
                    f"Re-read the candidate guidance: {guidance}"
                ),
            }
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
