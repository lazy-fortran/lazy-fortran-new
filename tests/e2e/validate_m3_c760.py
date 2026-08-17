#!/usr/bin/env python3
"""Independent, fail-closed oracle for C760/R741."""
from __future__ import annotations
import copy, hashlib, json, os, re, sys
from pathlib import Path

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
COUNT = {"zero", "one", "duplicate", "unknown"}
PROPERTY = "procedure-attribute-occurrence"
SOURCE_HASH = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_HASH = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_HASH = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_HASH = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
CONSTRAINT_SPANS_HASH = "d91018ffc4b777131f5e7cea6206cb41e27909d5a3cb91f869c568c84c1bdc44"
SPAN = {"byte_start": 242862, "byte_length": 119, "page_start": 93, "page_end": 93}
PAGE = {"page": 93, "start": 239957, "length": 2451}
LINES = [{"line": 3869, "text": "7 C760 (R741) The same proc-component-attr-spec shall not appear more than once in a given proc-component-"}, {"line": 3870, "text": "8 def-stmt."}]
SOURCE_BYTES = b"7 C760 (R741) The same proc-component-attr-spec shall not appear more than once in a given proc-component-\n8 def-stmt.\n"
ROWS = [{"rule": "R741", "lhs": "proc-component-def-stmt", "page": 94, "byte_start": 242577, "byte_length": 118, "occurrence": 91}]
MUTATIONS = [
    ("source-rule", ("source", "rule"), "C759"), ("source-span", ("source", "source_span", "byte_start"), 242863),
    ("printed-page", ("source", "printed_page"), 94), ("pdf-hash", ("source", "pdf_sha256"), "0" * 64),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64), ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64),
    ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64), ("standardir-ref", ("source", "standardir", "rows", 0, "rule"), "R740"),
    ("semantic-item-hash", ("semantic_item", "source_hash"), "0" * 64), ("contract-version", ("contract", "version"), 1),
]
class ContractError(Exception): pass
def require(ok, msg):
    if not ok: raise ContractError(msg)
def digest(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def keys(d, expected, label): require(set(d) == expected, f"{label} keys differ")
def oracle(c):
    return {"zero": "ACCEPTED", "one": "ACCEPTED", "duplicate": "REJECTED", "unknown": "UNRESOLVED"}[c["occurrence_count"]]
def set_path(v, path, replacement):
    for part in path[:-1]: v = v[part]
    v[path[-1]] = replacement
def validate_standardir(source, path):
    require(digest(path) == STANDARDIR_HASH, "StandardIR hash differs")
    expected = {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "sha256": STANDARDIR_HASH, "source_hash": SOURCE_HASH, "rows": ROWS}
    require(source["standardir"] == expected, "StandardIR fixture identity differs")
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    matches = [x for x in lines if x.startswith("(syntax R741 ")]
    require(len(matches) == 1, "expected one R741 row")
    line = matches[0]
    for pattern, value, label in [(r"\(lhs ([^)]+)\)", "proc-component-def-stmt", "lhs"), (r"\(page (\d+)\)", "94", "page"), (r"\(byte-start (\d+)\)", "242577", "byte-start"), (r"\(byte-length (\d+)\)", "118", "byte-length"), (r"\(occurrence (\d+)\)", "91", "occurrence")]:
        m = re.search(pattern, line); require(m and m.group(1) == value, f"R741 {label} differs")
    require(f"(source-sha256 {SOURCE_HASH})" in line and "(ref proc-component-attr-spec-list)" in line, "R741 binding differs")
def validate_constraint_span(path):
    require(digest(path) == CONSTRAINT_SPANS_HASH, "constraint span hash differs")
    rows = Path(path).read_text(encoding="utf-8").splitlines()
    matches = [x for x in rows if x.startswith("C760\tR741\t3869\t93\t")]
    require(len(matches) == 1 and matches[0].endswith("\tMECHANICAL\t7 C760 (R741) The same proc-component-attr-spec shall not appear more than once in a given proc-component-"), "constraint span differs")
def validate_binding(doc, root, pdf, canonical, page_index, standardir, semantic):
    keys(doc, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture")
    require(doc["origin"] == "LLM" and doc["schema_version"] == "m3-c760-source-backed-v0" and doc["property"] == PROPERTY, "fixture identity differs")
    require(doc["contract"] == {"schema": "contracts/m3-c760-proc-component-attr-uniqueness-v0.sxs", "fixture": "contracts/fixtures/m3-c760-proc-component-attr-uniqueness-v0.sx", "version": 0}, "contract identity differs")
    s = doc["source"]
    require(s["document"] == "J3-24-007" and s["clause"] == "7.5.4.1" and s["rule"] == "C760" and s["standard_rule"] == "R741" and s["printed_page"] == 93, "source identity differs")
    require(s["canonical_lines"] == LINES and s["source_span"] == SPAN, "source coordinates differ")
    require(s["canonical_text_sha256"] == SOURCE_HASH and digest(canonical) == SOURCE_HASH, "canonical source hash differs")
    raw = Path(canonical).read_bytes(); require(raw[SPAN["byte_start"]:SPAN["byte_start"] + SPAN["byte_length"]] == SOURCE_BYTES, "source bytes differ")
    raw_lines = raw.split(b"\n"); offsets = []; pos = 0
    for line in raw_lines:
        offsets.append(pos); pos += len(line) + 1
    for expected in LINES:
        actual = raw_lines[expected["line"] - 1].decode("utf-8")
        require(actual == expected["text"] and offsets[expected["line"] - 1] == (242862 if expected["line"] == 3869 else 242969), f"canonical line {expected['line']} differs")
    require(SPAN["byte_start"] + SPAN["byte_length"] == 242981, "source span end differs")
    require(s["page_index"]["sha256"] == PAGE_HASH and digest(page_index) == PAGE_HASH and s["page_index"]["pages"] == [PAGE], "page index differs")
    require(f"page 93 start 239957 length 2451" in Path(page_index).read_text(encoding="utf-8").splitlines(), "page record absent")
    span_path = Path(os.environ.get("C760_CONSTRAINT_SPANS", str(root / ".cache/runs/E0081/R000001/constraint-spans.tsv")))
    validate_constraint_span(span_path)
    validate_standardir(s, standardir)
    require(s["pdf_sha256"] == PDF_HASH and digest(pdf) == PDF_HASH, "normative PDF hash differs")
    item = {"path": "tests/fixtures/m3-c760-semantic-items.sx", "sha256": doc["semantic_item"]["sha256"], "id": "S-C760", "subject": PROPERTY, "document": "J3-24-007", "clause": "7.5.4.1", "rule": "C760", "page": 93, "source_hash": SOURCE_HASH, "origin": "llm", "resolution": "disputed"}
    require(doc["semantic_item"] == item and digest(semantic) == item["sha256"], "semantic item differs")
    require(doc["mutation_controls"] == [x[0] for x in MUTATIONS], "mutation inventory differs")
def validate_cases(doc, expected):
    require(len(doc["cases"]) == 4, "case count differs"); ids = [c.get("id") for c in doc["cases"]]; require(set(ids) == set(expected) and len(ids) == len(set(ids)), "case IDs differ")
    counts = {x: 0 for x in OUTCOMES}
    for case in doc["cases"]:
        keys(case, {"id", "kind", "expected", "candidate"}, f"case {case['id']}"); c = case["candidate"]; keys(c, {"fact", "source_rule", "occurrence_count"}, f"case {case['id']} candidate")
        require(c["fact"] == PROPERTY and c["source_rule"] == "C760" and c["occurrence_count"] in COUNT, "case candidate differs")
        result = oracle(c); require(case["expected"] == expected[case["id"]] == result, f"case {case['id']} oracle disagrees")
        require(case["kind"] == {"ACCEPTED": "positive", "REJECTED": "negative", "UNRESOLVED": "unresolved"}[result], f"case {case['id']} kind differs"); counts[result] += 1
    return counts
def self_test(root):
    p = root / "tests/fixtures/m3-c760-source-backed-v0.json"; original = json.loads(p.read_text())
    evidence = Path(os.environ.get("C760_EVIDENCE_ROOT", str(root)))
    if not (evidence / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt").exists():
        evidence = Path("/home/ert/code/lazy-fortran-new")
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original); set_path(mutated, path, replacement)
        try: validate_binding(mutated, root, evidence/".cache/j3-24-007.pdf", evidence/".cache/runs/E0001/R000003/j3-24-007.canonical.txt", evidence/".cache/runs/E0001/R000003/j3-24-007.pages.index", evidence/".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root/"tests/fixtures/m3-c760-semantic-items.sx")
        except ContractError: continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C760 self-test PASS: {len(MUTATIONS)} mutation controls rejected")
def main():
    root = Path(__file__).resolve().parents[2]
    if sys.argv[1:] == ["--self-test"]: self_test(root); return 0
    require(len(sys.argv) == 10, "usage: validator.py fixture expected semantic-canonical standardir canonical page-index pdf golden result")
    fixture, expected, semantic_canonical, standardir, canonical, page_index, pdf, golden, result = map(Path, sys.argv[1:])
    f = json.loads(fixture.read_text()); e = json.loads(expected.read_text()); validate_binding(f, root, pdf, canonical, page_index, standardir, root/"tests/fixtures/m3-c760-semantic-items.sx")
    keys(e, {"schema_version", "origin", "property", "source_rule", "outcomes"}, "expected outcomes"); require(digest(expected) == EXPECTED_HASH and e["origin"] == "LLM" and e["property"] == PROPERTY and e["source_rule"] == "C760", "expected identity differs")
    require(set(e["outcomes"]) == {c["id"] for c in f["cases"]} and all(x in OUTCOMES for x in e["outcomes"].values()), "expected outcomes differ")
    counts = validate_cases(f, e["outcomes"]); require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs from golden")
    output = {"schema_version": "m3-c760-result-v0", "origin": "MECHANICAL", "property": PROPERTY, "source_rule": "C760", "source_span": SPAN, "page_index": PAGE, "standardir_rules": ["R741"], "state_count": 4, "outcome_counts": counts, "mutation_controls": [{"id": n, "result": "REJECTED"} for n, _, _ in MUTATIONS], "model_calls": 0, "semantic_promotions": 0, "candidate_promotion": "BOUNDED_ONLY", "full_m3": "OPEN"}
    Path(result).write_text(json.dumps(output, sort_keys=True, separators=(",", ":")) + "\n"); print(json.dumps(output, indent=2, sort_keys=True)); return 0
EXPECTED_HASH = "4a61c75309a8f42b0dc5662939af7c97105783da3ec62e1d1af68c3961a37f9b"
if __name__ == "__main__":
    try: raise SystemExit(main())
    except (ContractError, KeyError, IndexError, json.JSONDecodeError) as e: print(f"C760 validation failure: {e}", file=sys.stderr); raise SystemExit(1)
