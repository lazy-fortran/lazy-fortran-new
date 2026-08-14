"""Deterministic source and typed-predicate gate for E0116."""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
E0115 = HERE.parent / "E0115-bounded-tool-assisted-evidence-acquisition"
spec = importlib.util.spec_from_file_location("e0115_harness", E0115 / "e0115_harness.py")
e0115 = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(e0115)
common = e0115.common

STANDARD_HASH = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
SOURCE_HASH = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
FACT_RE = re.compile(r"^[a-z][a-z0-9-]*$")
RULE_RE = re.compile(r"\bR[0-9]{3,5}\b")
CONSTRAINT_RE = re.compile(r"\bC[0-9]{3,5}\b")
ALLOWED_OPS = {
    "and", "or", "not", "implies", "eq", "ne", "lt", "le", "gt", "ge",
    "in", "not-in", "present", "absent", "has", "type-is", "rank-is",
    "scalar", "constant", "unique", "same-as", "named", "accessible",
    "derived", "processor-supports", "count-le", "count-ge",
    "value", "name-length", "exists", "named-constant", "has-kind-param",
    "contains-deferred-binding", "inherits-deferred-binding", "resolved",
    "has-deferred-type-parameter", "unlimited-polymorphic", "abstract-type",
    "derived-type", "intrinsic-module", "nonintrinsic-module",
    "intrinsic-type-name", "intrinsic-procedure", "abstract-interface",
    "explicit-interface-procedure", "procedure-declaration", "declared-earlier",
    "use-accessible", "declared-in-specification", "has-attribute", "bind-type", "sequence-type",
    "in-table-16-2", "generic-name", "procedure-name",
}


class GateError(Exception):
    """A deterministic rejection of a model proposal or tool call."""


def _line_inventory(raw: bytes):
    lines = []
    offset = 0
    for number, line in enumerate(raw.splitlines(keepends=True), 1):
        text = line.decode("utf-8").rstrip("\n")
        lines.append((number, offset, offset + len(line), text))
        offset += len(line)
    return lines


def load_constraints(path: str | Path):
    rows = []
    occurrences = {}
    with Path(path).open(encoding="utf-8", newline="") as stream:
        for raw in stream:
            fields = raw.rstrip("\n").split("\t")
            if len(fields) != 7:
                raise GateError("malformed E0081 constraint row")
            cid, associated, line, page, source_hash, origin, text = fields
            occurrences[cid] = occurrences.get(cid, 0) + 1
            occurrence = occurrences[cid]
            primary = bool(re.match(rf"^\s*[0-9]+\s+{re.escape(cid)}\b", text))
            rows.append({
                    "constraint_id": cid,
                    "row_key": f"{cid}@{occurrence}",
                    "occurrence": occurrence,
                    "primary": primary,
                    "associated_rules": associated.split(","),
                    "line": int(line),
                    "page": int(page),
                    "source_hash": source_hash,
                    "origin": origin,
                    "source_text": text,
                })
    if len(rows) != 287:
        raise GateError("E0081 constraint denominator is not 287 rows")
    return rows


def load_prior(path: str | Path):
    prior = {}
    with Path(path).open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            if row["status"] == "resolved":
                prior[row["constraint_id"]] = {
                    "predicate": row["predicate_a"],
                    "required_facts": row["required_facts"].split(),
                    "provided_facts": row["provided_facts"].split(),
                }
    if len(prior) != 21:
        raise GateError("prior accepted-control count is not 21")
    return prior


def _content(text: str):
    return re.sub(r"^\s*[0-9]+\s+", "", text).strip()


def _join(parts):
    result = ""
    for part in parts:
        part = _content(part)
        if not result:
            result = part
        elif result.endswith("-"):
            result += part
        else:
            result += " " + part
    return result


class ConstraintEpisode:
    """One bounded model episode; all derived provenance remains gate-owned."""

    def __init__(self, raw, ranges, rows, row, prior, max_evidence_calls=10,
                 max_source_bytes=32768):
        self.raw = raw
        self.ranges = ranges
        self.lines = _line_inventory(raw)
        self.rows = {item["constraint_id"]: item for item in rows}
        self.row = row
        self.prior = prior
        self.max_evidence_calls = max_evidence_calls
        self.max_source_bytes = max_source_bytes
        self.evidence_calls = 0
        self.submissions = 0
        self.source_bytes = 0
        self.results = {}
        self.counter = 0
        self.terminal = None
        self.accepted = None

    @property
    def constraint_id(self):
        return self.row["constraint_id"]

    def _next_id(self):
        self.counter += 1
        return f"e{self.counter:04d}"

    def _budget(self):
        if self.evidence_calls >= self.max_evidence_calls:
            raise GateError("evidence-call budget exhausted")
        self.evidence_calls += 1

    def _span(self, start, end, kind):
        if start < 0 or end <= start or end > len(self.raw):
            raise GateError("evidence span is outside canonical source")
        try:
            text = self.raw[start:end].decode("utf-8")
        except UnicodeDecodeError as exc:
            raise GateError("evidence span is not UTF-8 aligned") from exc
        self.source_bytes += len(text.encode("utf-8"))
        if self.source_bytes > self.max_source_bytes:
            raise GateError("source-byte budget exhausted")
        result_id = self._next_id()
        try:
            page = common.containing_page(self.ranges, start, end - start)
        except common.InputError as exc:
            raise GateError(f"evidence span is not contained by one page: {exc}") from exc
        record = {
            "result_id": result_id,
            "kind": kind,
            "page": page,
            "byte_start": start,
            "byte_length": end - start,
            "text": text,
        }
        self.results[result_id] = record
        return record

    def _row_span(self, row):
        index = row["line"] - 1
        if index < 0 or index >= len(self.lines):
            raise GateError("constraint line is outside canonical source")
        _number, start, end, text = self.lines[index]
        parts = [text]
        current = _content(text)
        for _number, _start, _end, next_text in self.lines[index + 1 : index + 10]:
            if CONSTRAINT_RE.search(_content(next_text)) or RULE_RE.search(_content(next_text)):
                break
            if re.match(r"^NOTE\b", _content(next_text), re.IGNORECASE):
                break
            if current.endswith((".", ":", ";")):
                break
            parts.append(next_text)
            current = _join(parts)
            if current.endswith((".", ":", ";")):
                break
            end = _end
        return start, end, _join(parts)

    def _rule_span(self, rule):
        for index, (_number, start, end, text) in enumerate(self.lines):
            if re.search(rf"\b{re.escape(rule)}\b", text) and re.match(
                r"^\s*[0-9]+\s+R[0-9]{3,5}\b", text
            ):
                final = end
                for _n, _s, next_end, next_text in self.lines[index + 1 : index + 20]:
                    if CONSTRAINT_RE.search(_content(next_text)) or RULE_RE.search(
                        _content(next_text)
                    ):
                        break
                    final = next_end
                return start, final
        raise GateError(f"rule not found: {rule}")

    def read_constraint(self):
        self._budget()
        start, end, text = self._row_span(self.row)
        return self._span(start, end, "constraint") | {"source_text": text}

    def search_standard(self, query, mode, max_results):
        if not isinstance(query, str) or not 1 <= len(query) <= 160:
            raise GateError("query must contain 1..160 characters")
        if mode not in {"exact", "rule", "reference"}:
            raise GateError("unsupported search mode")
        if not isinstance(max_results, int) or not 1 <= max_results <= 8:
            raise GateError("max_results must be in 1..8")
        self._budget()
        results = []
        pattern = re.compile(re.escape(query), re.IGNORECASE)
        if mode == "rule":
            start, end = self._rule_span(query.upper())
            return {"status": "ok", "results": [self._span(start, end, "rule")]}
        for _number, start, end, text in self.lines:
            if pattern.search(text):
                results.append(self._span(start, end, "search"))
                if len(results) == max_results:
                    break
        return {"status": "ok", "results": results}

    def read_span(self, result_id, before_bytes, after_bytes):
        self._budget()
        if result_id not in self.results:
            raise GateError("unknown evidence result")
        if not isinstance(before_bytes, int) or not 0 <= before_bytes <= 4096:
            raise GateError("before_bytes must be in 0..4096")
        if not isinstance(after_bytes, int) or not 0 <= after_bytes <= 4096:
            raise GateError("after_bytes must be in 0..4096")
        result = self.results[result_id]
        page = common.containing_page(self.ranges, result["byte_start"], 1)
        page_start, page_length = next(
            (start, length) for number, start, length in self.ranges if number == page
        )
        page_end = page_start + page_length
        start = max(page_start, result["byte_start"] - before_bytes)
        end = min(page_end, result["byte_start"] + result["byte_length"] + after_bytes)
        return {"status": "ok", "result": self._span(start, end, "span")}

    @staticmethod
    def _validate_term(term):
        if isinstance(term, (str, int, bool)) or term is None:
            return
        if isinstance(term, list):
            for item in term:
                ConstraintEpisode._validate_term(item)
            return
        raise GateError("predicate term has an unsupported JSON type")

    @classmethod
    def _validate_predicate(cls, node):
        if not isinstance(node, dict) or set(node) != {"op", "args"}:
            raise GateError("predicate must be an object with exactly op and args")
        op = node["op"]
        args = node["args"]
        if op not in ALLOWED_OPS:
            raise GateError(f"predicate constructor is not allowed: {op}")
        if not isinstance(args, list) or not 1 <= len(args) <= 8:
            raise GateError("predicate args must contain 1..8 values")
        if op in {"eq", "ne", "lt", "le", "gt", "ge"} and len(args) >= 2:
            left, right = args[0], args[1]
            if (isinstance(left, str) and FACT_RE.fullmatch(left) and
                    isinstance(right, str) and FACT_RE.fullmatch(right)):
                raise GateError(
                    "binary value relation compares two fact-like names; "
                    "use a literal on the right or same-as for two fields"
                )
        for arg in args:
            if isinstance(arg, dict) and "op" in arg:
                cls._validate_predicate(arg)
            else:
                cls._validate_term(arg)

    @staticmethod
    def _validate_facts(values, field):
        if not isinstance(values, list) or len(values) > 16:
            raise GateError(f"{field} must be a list of at most 16 facts")
        if any(not isinstance(value, str) or not FACT_RE.fullmatch(value) for value in values):
            raise GateError(f"{field} contains a malformed fact identifier")

    @staticmethod
    def _contains_op(node, wanted):
        if isinstance(node, dict):
            return node.get("op") == wanted or any(
                ConstraintEpisode._contains_op(value, wanted)
                for value in node.get("args", [])
            )
        if isinstance(node, list):
            return any(ConstraintEpisode._contains_op(value, wanted) for value in node)
        return False

    def submit_semantic(
        self,
        constraint_id,
        decision,
        subject,
        applicability,
        required_facts,
        provided_facts,
        predicate,
        evidence_ids,
        witnesses=None,
    ):
        if self.terminal is not None:
            raise GateError("episode is already terminal")
        self.submissions += 1
        if constraint_id != self.constraint_id:
            return {"status": "rejected", "code": "wrong-constraint-id"}
        if decision not in {"accept", "abstain"}:
            return {"status": "rejected", "code": "invalid-decision"}
        if decision == "abstain":
            self.terminal = "unresolved"
            return {"status": "unresolved", "code": "model-abstained"}
        if not isinstance(subject, str) or not subject.strip():
            return {"status": "rejected", "code": "subject-required"}
        if not isinstance(applicability, str) or not applicability.strip():
            return {"status": "rejected", "code": "applicability-required"}
        if not isinstance(evidence_ids, list) or not evidence_ids:
            return {"status": "rejected", "code": "source-evidence-required"}
        if any(evidence_id not in self.results for evidence_id in evidence_ids):
            return {"status": "rejected", "code": "unknown-evidence-id"}
        self._validate_facts(required_facts, "required_facts")
        self._validate_facts(provided_facts, "provided_facts")
        self._validate_predicate(predicate)
        if (re.search(r"\bshall\s+not\b.*\bexcept\b", self.row["source_text"], re.IGNORECASE)
                and not self._contains_op(predicate, "implies")):
            return {
                "status": "rejected",
                "code": "exception-constraint-needs-implication",
            }
        if witnesses is not None:
            if not isinstance(witnesses, list) or len(witnesses) > 8:
                return {"status": "rejected", "code": "invalid-witness-list"}
            for witness in witnesses:
                if not isinstance(witness, dict) or set(witness) != {"label", "expect"}:
                    return {"status": "rejected", "code": "invalid-witness"}
                if not isinstance(witness["label"], str) or not witness["label"].strip():
                    return {"status": "rejected", "code": "invalid-witness-label"}
                if not isinstance(witness["expect"], bool):
                    return {"status": "rejected", "code": "invalid-witness-expectation"}
        covered = False
        for evidence_id in evidence_ids:
            text = self.results[evidence_id]["text"]
            if CONSTRAINT_RE.search(text) or any(RULE_RE.search(text) and rule in text for rule in self.row["associated_rules"]):
                covered = True
                break
        if not covered:
            return {"status": "rejected", "code": "evidence-does-not-cover-constraint"}
        proposal = {
            "constraint_id": constraint_id,
            "associated_rules": self.row["associated_rules"],
            "line": self.row["line"],
            "page": self.row["page"],
            "source_sha256": SOURCE_HASH,
            "standard_sha256": STANDARD_HASH,
            "origin": "LLM",
            "subject": subject.strip(),
            "applicability": applicability.strip(),
            "required_facts": required_facts,
            "provided_facts": provided_facts,
            "predicate": predicate,
            "evidence_ids": list(evidence_ids),
            "witnesses": witnesses or [],
        }
        prior = self.prior.get(constraint_id)
        if prior is not None:
            if predicate != _parse_sx(prior["predicate"]):
                return {"status": "rejected", "code": "prior-control-predicate-diff"}
            if required_facts != prior["required_facts"] or provided_facts != prior["provided_facts"]:
                return {"status": "rejected", "code": "prior-control-facts-diff"}
        self.accepted = proposal
        self.terminal = "accepted"
        return {"status": "accepted", "proposal": proposal}

    def call(self, name, arguments):
        if name == "read_constraint":
            if arguments:
                raise GateError("read_constraint takes no arguments")
            return {"status": "ok", "result": self.read_constraint()}
        if name == "search_standard":
            return self.search_standard(**arguments)
        if name == "read_span":
            return self.read_span(**arguments)
        if name == "read_rule":
            self._budget()
            rule = arguments.get("rule_number")
            if not isinstance(rule, str) or not re.fullmatch(r"R[0-9]{3,5}", rule):
                raise GateError("invalid rule number")
            start, end = self._rule_span(rule)
            return {"status": "ok", "result": self._span(start, end, "rule")}
        if name == "submit_semantic":
            return self.submit_semantic(**arguments)
        raise GateError(f"unknown tool: {name}")


def _parse_sx(value):
    """Parse the small prior-control S-expression subset for exact controls."""
    tokens = re.findall(r"\(|\)|[^\s()]+", value)
    parse_ops = set(ALLOWED_OPS)
    position = 0

    def parse():
        nonlocal position
        if position >= len(tokens):
            raise GateError("malformed prior predicate")
        token = tokens[position]
        position += 1
        if token == "(":
            if position >= len(tokens):
                raise GateError("malformed prior predicate")
            op = tokens[position]
            if op in parse_ops:
                position += 1
                args = []
                while position < len(tokens) and tokens[position] != ")":
                    args.append(parse())
            else:
                args = [parse()]
                while position < len(tokens) and tokens[position] != ")":
                    args.append(parse())
                if position >= len(tokens):
                    raise GateError("malformed prior predicate")
                position += 1
                return args
            if position >= len(tokens):
                raise GateError("malformed prior predicate")
            position += 1
            return {"op": op, "args": args}
        if token == ")":
            raise GateError("malformed prior predicate")
        if re.fullmatch(r"-?[0-9]+", token):
            return int(token)
        return token

    result = parse()
    if position != len(tokens):
        raise GateError("trailing prior predicate tokens")
    return result


def source_digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
