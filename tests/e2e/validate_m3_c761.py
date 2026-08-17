#!/usr/bin/env python3
"""Fail-closed deterministic oracle for the bounded C761/R741 slice."""
from __future__ import annotations
import copy, hashlib, json, os, re, sys
from pathlib import Path

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
PRESENCE = {"absent", "present", "unknown"}
PROPERTY = "pointer-presence"
SOURCE = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PAGE_HASH = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
IR_HASH = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PDF_HASH = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
SEMANTIC_HASH = "125d83e3a56b58b284e27f8bc75f78d1366f01e9867dc948ed183a55633d969d"
FIXTURE_HASH = "f3fb4391cf7b23cd9186ce3cc3153e2e59f47d1aeac5854c0283391a294a4873"
EXPECTED_HASH = "d48f448dbb9370028502a6cd10d99e2961acdaaad9bd31165d127d0eec407d8f"
SPAN = {"byte_start": 242981, "byte_length": 74, "page_start": 93, "page_end": 93}
PAGE = {"page": 93, "start": 239957, "length": 2451}
LINE = {"line": 3871, "text": "9 C761 (R741) POINTER shall appear in each proc-component-attr-spec-list."}
SOURCE_BYTES = b"9 C761 (R741) POINTER shall appear in each proc-component-attr-spec-list.\n"
ROWS = [
    {"rule": "R741", "lhs": "proc-component-def-stmt", "page": 94, "byte_start": 242577, "byte_length": 118, "occurrence": 91},
    {"rule": "R742", "lhs": "proc-component-attr-spec", "page": 94, "byte_start": 242765, "byte_length": 96, "occurrence": 92},
]
MUTATIONS = [
    ("source-rule", ("source", "rule"), "C760"), ("printed-page", ("source", "printed_page"), 80),
    ("pdf-page", ("source", "pdf_page"), 95), ("ledger-page", ("source", "ledger_page"), 94),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64),
    ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64),
    ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64),
    ("standardir-ref", ("source", "standardir", "rows", 1, "rule"), "R743"),
    ("contract-version", ("contract", "version"), 1),
    ("fixture-case", ("cases", 0, "candidate", "fact", "pointer_presence"), "absent"),
    ("semantic-item-hash", ("semantic_item", "sha256"), "0" * 64),
]

class ContractError(Exception): pass
def require(ok, message):
    if not ok: raise ContractError(message)
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def exact(value, expected, label): require(value == expected, f"{label} differs")
def set_path(value, path, replacement):
    for part in path[:-1]: value = value[part]
    value[path[-1]] = replacement

def oracle(fact):
    return {"present": "ACCEPTED", "absent": "REJECTED", "unknown": "UNRESOLVED"}[fact["pointer_presence"]]

def validate_standardir(source, path):
    require(digest(path) == IR_HASH, "StandardIR hash differs")
    exact(source["standardir"], {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "rows": ROWS, "sha256": IR_HASH, "source_hash": SOURCE}, "StandardIR identity")
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    for row in ROWS:
        matches = [line for line in lines if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matches) == 1, f"{row['rule']} row count differs")
        line = matches[0]
        for pattern, expected, label in [(r"\(lhs ([^)]+)\)", row["lhs"], "lhs"), (r"\(page (\d+)\)", str(row["page"]), "page"), (r"\(byte-start (\d+)\)", str(row["byte_start"]), "start"), (r"\(byte-length (\d+)\)", str(row["byte_length"]), "length"), (r"\(occurrence (\d+)\)", str(row["occurrence"]), "occurrence")]:
            match = re.search(pattern, line); require(match and match.group(1) == expected, f"{row['rule']} {label} differs")
        require(f"(source-sha256 {SOURCE})" in line, f"{row['rule']} source hash differs")
    require("(ref proc-component-attr-spec-list)" in lines[91] and "(token POINTER)" in lines[92], "R741/R742 POINTER binding differs")

def validate_contract_files(root):
    schema = (root / "contracts/m3-c761-pointer-presence-v0.sxs").read_text(encoding="utf-8")
    witness = (root / "contracts/fixtures/m3-c761-pointer-presence-v0.sx").read_text(encoding="utf-8")
    require(schema.startswith("(schema m3-c761-pointer-presence-v0") and "(record semantic-candidate" in schema, "schema correspondence differs")
    require(witness.startswith("(contract-witness") and "(contract m3-c761-pointer-presence)" in witness and "(version 0)" in witness, "fixture correspondence differs")

def validate_binding(doc, root, pdf, canonical, page_index, standardir, semantic):
    require(digest(root / "tests/fixtures/m3-c761-source-backed-v0.json") == FIXTURE_HASH, "source fixture hash differs")
    validate_contract_files(root)
    require(set(doc) == {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture keys differ")
    exact(doc["schema_version"], "m3-c761-source-backed-v0", "schema version"); exact(doc["origin"], "LLM", "fixture origin"); exact(doc["property"], PROPERTY, "property")
    exact(doc["contract"], {"fixture": "contracts/fixtures/m3-c761-pointer-presence-v0.sx", "schema": "contracts/m3-c761-pointer-presence-v0.sxs", "version": 0}, "contract")
    s = doc["source"]
    exact(s["document"], "J3-24-007", "document"); exact(s["clause"], "7", "clause"); exact(s["rule"], "C761", "rule"); exact(s["standard_rule"], "R741", "standard rule")
    exact(s["printed_page"], 79, "printed page"); exact(s["pdf_page"], 94, "PDF page"); exact(s["ledger_page"], 93, "ledger page"); exact(s["canonical_lines"], [LINE], "canonical line"); exact(s["source_span"], SPAN, "source span")
    require(s["canonical_text_sha256"] == SOURCE and digest(canonical) == SOURCE, "canonical hash differs")
    raw = Path(canonical).read_bytes(); require(raw[SPAN["byte_start"]:SPAN["byte_start"] + SPAN["byte_length"]] == SOURCE_BYTES, "canonical bytes differ")
    lines = raw.splitlines(); require(lines[3870].decode() == LINE["text"], "canonical line text differs")
    exact(s["page_index"], {"pages": [PAGE], "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index", "sha256": PAGE_HASH}, "page index"); require(digest(page_index) == PAGE_HASH, "page-index hash differs")
    require("page 93 start 239957 length 2451" in Path(page_index).read_text(encoding="utf-8").splitlines(), "page-index record absent")
    exact(s["pdf_sha256"], PDF_HASH, "PDF identity"); require(digest(pdf) == PDF_HASH, "PDF hash differs")
    validate_standardir(s, standardir)
    exact(doc["semantic_item"], {"clause": "7", "document": "J3-24-007", "id": "S-C761", "origin": "llm", "page": 79, "path": "tests/fixtures/m3-c761-semantic-items.sx", "resolution": "disputed", "rule": "C761", "sha256": SEMANTIC_HASH, "source_hash": SOURCE, "subject": PROPERTY}, "semantic item"); require(digest(semantic) == SEMANTIC_HASH, "semantic item hash differs")
    exact(doc["mutation_controls"], [name for name, _, _ in MUTATIONS], "mutation inventory")

def validate_cases(doc, expected):
    require(len(doc["cases"]) == 3 and len({c["id"] for c in doc["cases"]}) == 3, "candidate set differs")
    require(set(expected) == {"pointer-present", "pointer-absent", "pointer-unknown"}, "expected candidate IDs differ")
    counts = {outcome: 0 for outcome in OUTCOMES}
    for case in doc["cases"]:
        require(set(case) == {"id", "kind", "expected", "candidate"}, f"case {case['id']} keys differ")
        c = case["candidate"]; require(set(c) == {"id", "property", "source", "span", "fact", "expected"}, f"candidate {case['id']} keys differ")
        exact(c["id"], case["id"], "candidate ID"); exact(c["property"], PROPERTY, "candidate property"); exact(c["source"], {"clause": "7", "document": "J3-24-007", "page": 79, "rule": "C761", "source_hash": SOURCE}, "candidate source"); exact(c["span"], SPAN, "candidate span")
        require(set(c["fact"]) == {"pointer_presence"} and c["fact"]["pointer_presence"] in PRESENCE, "candidate fact differs")
        require(case["expected"] == expected[case["id"]] == c["expected"] == oracle(c["fact"]), f"outcome {case['id']} differs")
        exact(case["kind"], {"ACCEPTED": "positive", "REJECTED": "negative", "UNRESOLVED": "unresolved"}[case["expected"]], "candidate kind"); counts[case["expected"]] += 1
    exact(counts, {"ACCEPTED": 1, "REJECTED": 1, "UNRESOLVED": 1}, "outcome counts"); return counts

def self_test(root):
    original = json.loads((root / "tests/fixtures/m3-c761-source-backed-v0.json").read_text())
    evidence = Path(os.environ.get("C761_EVIDENCE_ROOT", "/home/ert/code/lazy-fortran-new"))
    paths = [evidence / ".cache/j3-24-007.pdf", evidence / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", evidence / ".cache/runs/E0001/R000003/j3-24-007.pages.index", evidence / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c761-semantic-items.sx"]
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original); set_path(mutated, path, replacement)
        try: validate_binding(mutated, root, *paths)
        except (ContractError, KeyError, IndexError): continue
        if name == "fixture-case":
            try:
                validate_cases(mutated, {"pointer-absent": "REJECTED", "pointer-present": "ACCEPTED", "pointer-unknown": "UNRESOLVED"})
            except (ContractError, KeyError, IndexError): continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C761 self-test PASS: {len(MUTATIONS)} mutation controls rejected")

def main():
    root = Path(__file__).resolve().parents[2]
    if sys.argv[1:] == ["--self-test"]: self_test(root); return 0
    require(len(sys.argv) == 10, "usage: validator.py fixture expected semantic-canonical standardir canonical page-index pdf golden result")
    fixture, expected, semantic_canonical, standardir, canonical, page_index, pdf, golden, result = map(Path, sys.argv[1:])
    f = json.loads(fixture.read_text()); e = json.loads(expected.read_text())
    require(digest(expected) == EXPECTED_HASH and e == {"origin": "MECHANICAL", "outcomes": {"pointer-absent": "REJECTED", "pointer-present": "ACCEPTED", "pointer-unknown": "UNRESOLVED"}, "property": PROPERTY, "schema_version": "m3-c761-expected-outcomes-v0", "source_rule": "C761"}, "expected table differs")
    validate_binding(f, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c761-semantic-items.sx")
    counts = validate_cases(f, e["outcomes"]); require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs")
    output = {"candidate_promotion": "BOUNDED_ONLY", "full_m3": "OPEN", "model_calls": 0, "mutation_controls": [{"id": n, "result": "REJECTED"} for n, _, _ in MUTATIONS], "origin": "MECHANICAL", "outcome_counts": counts, "page_index": PAGE, "property": PROPERTY, "schema_version": "m3-c761-result-v0", "semantic_promotions": 0, "source_rule": "C761", "source_span": SPAN, "standardir_rules": ["R741", "R742"], "state_count": 3}
    result.write_text(json.dumps(output, sort_keys=True, separators=(",", ":")) + "\n"); print(json.dumps(output, indent=2, sort_keys=True)); return 0

if __name__ == "__main__":
    try: raise SystemExit(main())
    except (ContractError, KeyError, IndexError, json.JSONDecodeError) as error:
        print(f"C761 validation failure: {error}", file=sys.stderr); raise SystemExit(1)
