#!/usr/bin/env python3
"""Fail-closed deterministic oracle for the bounded C759/R736 slice."""
from __future__ import annotations
import copy, hashlib, json, os, re, sys
from pathlib import Path

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
KINDS = {"colon", "component-specification", "other", "unknown"}
PROPERTY = "type-param-value-kind"
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
SPAN = {"byte_start": 242269, "byte_length": 126, "page_start": 93, "page_end": 93}
PAGE_INDEX = {"page": 93, "start": 239957, "length": 2451}
LINES = [{"line": 3854, "text": "40 C759 (R736) Each type-param-value within a component-def-stmt shall be a colon or a component specification"}, {"line": 3855, "text": "41 expression."}]
SOURCE_BYTES = b"40 C759 (R736) Each type-param-value within a component-def-stmt shall be a colon or a component specification\n41 expression.\n"
ROWS = [{"rule": "R736", "lhs": "component-def-stmt", "page": 93, "byte_start": 240100, "byte_length": 81, "occurrence": 86}]
MUTATIONS = [
    ("source-rule", ("source", "rule"), "C758"),
    ("printed-page", ("source", "printed_page"), 80),
    ("ledger-page", ("source", "constraint_span", "ledger_page"), 93),
    ("span-start", ("source", "source_span", "byte_start"), 242270),
    ("span-length", ("source", "source_span", "byte_length"), 125),
    ("canonical-line", ("source", "canonical_lines", 0, "text"), "changed"),
    ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64),
    ("page-index-start", ("source", "page_index", "pages", 0, "start"), 239958),
    ("pdf-hash", ("source", "pdf_sha256"), "0" * 64),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64),
    ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64),
    ("standardir-rule", ("source", "standardir", "rows", 0, "rule"), "R737"),
    ("ledger-text", ("source", "constraint_span", "text"), "changed"),
    ("semantic-item-hash", ("semantic_item", "sha256"), "0" * 64),
    ("contract-version", ("contract", "version"), 1),
]
SOURCE_FIXTURE_SHA256 = "5524a5142e6e2178c9084379bf7261117574b336eb102ed96208a9b0deaa73d8"
EXPECTED_OUTCOMES_SHA256 = "cf841419a2eb2f2e71d833357902c9d679f6b4c414b6527e428d232b9faeef46"
SEMANTIC_ITEM_SHA256 = "464664eb9452260656628512774907730a0eebd05b9f555b165b185b48307ddd"

class ContractError(Exception):
    pass

def require(ok: bool, message: str) -> None:
    if not ok:
        raise ContractError(message)

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def exact_keys(value: dict, expected: set[str], label: str) -> None:
    require(set(value) == expected, f"{label} keys differ")

def set_path(value, path, replacement) -> None:
    for part in path[:-1]:
        value = value[part]
    value[path[-1]] = replacement

def oracle(kind: str) -> str:
    return {"colon": "ACCEPTED", "component-specification": "ACCEPTED", "other": "REJECTED", "unknown": "UNRESOLVED"}[kind]

def validate_standardir(source: dict, path: Path) -> None:
    require(digest(path) == STANDARDIR_SHA256, "StandardIR hash differs")
    expected = {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "sha256": STANDARDIR_SHA256, "source_hash": SOURCE_SHA256, "rows": ROWS}
    require(source["standardir"] == expected, "StandardIR identity differs")
    lines = path.read_text(encoding="utf-8").splitlines()
    matches = [line for line in lines if line.startswith("(syntax R736 ")]
    require(len(matches) == 1, "R736 row count differs")
    line = matches[0]
    for pattern, value, label in [(r"\(lhs ([^)]+)\)", "component-def-stmt", "lhs"), (r"\(page (\d+)\)", "93", "page"), (r"\(byte-start (\d+)\)", "240100", "start"), (r"\(byte-length (\d+)\)", "81", "length"), (r"\(occurrence (\d+)\)", "86", "occurrence")]:
        match = re.search(pattern, line)
        require(match and match.group(1) == value, f"R736 {label} differs")
    require(f"(source-sha256 {SOURCE_SHA256})" in line and "(ref data-component-def-stmt)" in line and "(ref proc-component-def-stmt)" in line, "R736 binding differs")

def validate_binding(document: dict, root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(document, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture")
    require(digest(root / "tests/fixtures/m3-c759-source-backed-v0.json") == SOURCE_FIXTURE_SHA256, "source fixture hash differs")
    require(document["schema_version"] == "m3-c759-source-backed-v0" and document["origin"] == "LLM" and document["property"] == PROPERTY, "fixture identity differs")
    require(document["contract"] == {"schema": "contracts/m3-c759-type-param-value-v0.sxs", "fixture": "contracts/fixtures/m3-c759-type-param-value-v0.sx", "version": 0}, "contract identity differs")
    source = document["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C759" and source["standard_rule"] == "R736" and source["printed_page"] == 79, "source identity differs")
    require(source["canonical_lines"] == LINES and source["source_span"] == SPAN, "source coordinates differ")
    require(source["canonical_text_sha256"] == SOURCE_SHA256 and digest(canonical) == SOURCE_SHA256, "canonical source hash differs")
    require(canonical.read_bytes()[242269:242395] == SOURCE_BYTES, "source bytes differ")
    raw_lines = canonical.read_bytes().split(b"\n"); offsets, offset = [], 0
    for line in raw_lines:
        offsets.append(offset); offset += len(line) + 1
    for item in LINES:
        actual = raw_lines[item["line"] - 1].decode("utf-8")
        expected_offset = 242269 if item["line"] == 3854 else 242380
        require(actual == item["text"] and offsets[item["line"] - 1] == expected_offset, f"canonical line {item['line']} differs")
    require(source["page_index"]["sha256"] == PAGE_INDEX_SHA256 and digest(page_index) == PAGE_INDEX_SHA256 and source["page_index"]["pages"] == [PAGE_INDEX], "page-index identity differs")
    require("page 93 start 239957 length 2451" in page_index.read_text(encoding="utf-8").splitlines(), "page-index record absent")
    require(source["constraint_span"] == {"rule": "R736", "canonical_line": 3854, "ledger_page": 92, "pdf_sha256": PDF_SHA256, "text": LINES[0]["text"]}, "constraint ledger coordinates differ")
    ledger = Path(os.environ.get("C759_CONSTRAINT_SPANS", str(root / ".cache/runs/E0081/R000001/constraint-spans.tsv")))
    row = "C759\tR736\t3854\t92\t" + PDF_SHA256 + "\tMECHANICAL\t" + LINES[0]["text"]
    require(row in ledger.read_text(encoding="utf-8").splitlines(), "constraint ledger row absent")
    validate_standardir(source, standardir)
    require(source["pdf_sha256"] == PDF_SHA256 and digest(pdf) == PDF_SHA256, "normative PDF hash differs")
    require(document["semantic_item"] == {"path": "tests/fixtures/m3-c759-semantic-items.sx", "sha256": SEMANTIC_ITEM_SHA256, "id": "S-C759", "subject": PROPERTY, "document": "J3-24-007", "clause": "7", "rule": "C759", "page": 79, "source_hash": SOURCE_SHA256, "origin": "llm", "resolution": "disputed"}, "semantic item differs")
    require(digest(semantic) == SEMANTIC_ITEM_SHA256, "semantic item hash differs")
    require(document["mutation_controls"] == [name for name, _, _ in MUTATIONS], "mutation inventory differs")

def validate_expected(document: dict, path: Path, ids: list[str]) -> dict[str, str]:
    exact_keys(document, {"schema_version", "origin", "property", "source_rule", "outcomes"}, "expected outcomes")
    require(digest(path) == EXPECTED_OUTCOMES_SHA256 and document["schema_version"] == "m3-c759-expected-outcomes-v0" and document["origin"] == "MECHANICAL" and document["property"] == PROPERTY and document["source_rule"] == "C759", "expected identity differs")
    require(set(document["outcomes"]) == set(ids) and all(value in OUTCOMES for value in document["outcomes"].values()), "expected outcomes differ")
    return document["outcomes"]

def validate_cases(document: dict, expected: dict[str, str]) -> dict[str, int]:
    require(len(document["cases"]) == 4, "case count differs")
    require(len({case.get("id") for case in document["cases"]}) == 4 and {case["id"] for case in document["cases"]} == set(expected), "case IDs differ")
    counts = {outcome: 0 for outcome in OUTCOMES}
    for case in document["cases"]:
        exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case['id']}")
        candidate = case["candidate"]
        exact_keys(candidate, {"id", "property", "source", "span", "fact", "expected"}, f"case {case['id']} candidate")
        require(candidate["id"] == case["id"] and candidate["property"] == PROPERTY, f"case {case['id']} identity differs")
        require(candidate["source"] == {"document": "J3-24-007", "clause": "7", "rule": "C759", "page": 79, "source_hash": SOURCE_SHA256}, f"case {case['id']} source differs")
        require(candidate["span"] == SPAN and set(candidate["fact"]) == {"value_kind"} and candidate["fact"]["value_kind"] in KINDS, f"case {case['id']} fact differs")
        require(case["expected"] == expected[case["id"]] == candidate["expected"] == oracle(candidate["fact"]["value_kind"]), f"case {case['id']} expected outcome differs")
        require(case["kind"] == {"ACCEPTED": "positive", "REJECTED": "negative", "UNRESOLVED": "unresolved"}[case["expected"]], f"case {case['id']} kind differs")
        counts[case["expected"]] += 1
    require(counts == {"ACCEPTED": 2, "REJECTED": 1, "UNRESOLVED": 1}, "outcome counts differ")
    return counts

def self_test(root: Path) -> None:
    original = json.loads((root / "tests/fixtures/m3-c759-source-backed-v0.json").read_text(encoding="utf-8"))
    evidence = Path(os.environ.get("C759_EVIDENCE_ROOT", "/home/ert/code/lazy-fortran-new"))
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original); set_path(mutated, path, replacement)
        try:
            validate_binding(mutated, root, evidence / ".cache/j3-24-007.pdf", evidence / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", evidence / ".cache/runs/E0001/R000003/j3-24-007.pages.index", evidence / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c759-semantic-items.sx")
        except (ContractError, KeyError):
            continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C759 self-test PASS: {len(MUTATIONS)} mutation controls rejected")

def main() -> int:
    root = Path(__file__).resolve().parents[2]
    if sys.argv[1:] == ["--self-test"]:
        self_test(root); return 0
    if len(sys.argv) != 10:
        raise ContractError("usage: validator.py fixture expected semantic-canonical standardir canonical page-index pdf golden result")
    fixture_path, expected_path, semantic_canonical, standardir, canonical, page_index, pdf, golden, result_path = map(Path, sys.argv[1:])
    fixture = json.loads(fixture_path.read_text(encoding="utf-8")); expected = validate_expected(json.loads(expected_path.read_text(encoding="utf-8")), expected_path, [case["id"] for case in fixture["cases"]])
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c759-semantic-items.sx")
    counts = validate_cases(fixture, expected)
    require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs")
    result = {"schema_version": "m3-c759-result-v0", "origin": "MECHANICAL", "property": PROPERTY, "source_rule": "C759", "source_span": SPAN, "page_index": PAGE_INDEX, "standardir_rules": ["R736"], "state_count": 4, "outcome_counts": counts, "mutation_controls": [{"id": name, "result": "REJECTED"} for name, _, _ in MUTATIONS], "model_calls": 0, "semantic_promotions": 0, "candidate_promotion": "BOUNDED_ONLY", "full_m3": "OPEN"}
    result_path.write_text(json.dumps(result, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8"); print(json.dumps(result, indent=2, sort_keys=True)); return 0

if __name__ == "__main__":
    try: raise SystemExit(main())
    except (ContractError, KeyError, IndexError, json.JSONDecodeError) as error:
        print(f"C759 validation failure: {error}", file=sys.stderr); raise SystemExit(1)
