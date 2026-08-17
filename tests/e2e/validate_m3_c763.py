#!/usr/bin/env python3
"""Fail-closed deterministic oracle for supplied C763/R741 facts."""
from __future__ import annotations
import copy, hashlib, json, os, re, sys
from pathlib import Path

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
PASSES = {"present", "absent", "unknown"}
RELATIONS = {"matching", "nonmatching", "unknown"}
PROPERTY = "pass-argument-name"
SOURCE = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PAGE_HASH = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
IR_HASH = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PDF_HASH = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
EXPECTED_HASH = "6872a5b1899e4f388c5ba37b0e9dbc27111ee77a6b34554972cce0bd8cfe8e7d"
SPAN = {"byte_start": 243182, "byte_length": 139, "page_start": 94, "page_end": 94}
PAGE = {"page": 94, "start": 242409, "length": 2660}
LINES = [
    {"line": 3874, "text": "12 C763 (R741) If PASS (arg-name) appears, the interface of the procedure pointer component shall have a dummy"},
    {"line": 3875, "text": "13 argument named arg-name."},
]
SOURCE_BYTES = (LINES[0]["text"] + "\n" + LINES[1]["text"] + "\n").encode()
ROWS = [
    {"rule": "R741", "lhs": "proc-component-def-stmt", "page": 94, "byte_start": 242577, "byte_length": 118, "occurrence": 91},
    {"rule": "R742", "lhs": "proc-component-attr-spec", "page": 94, "byte_start": 242765, "byte_length": 96, "occurrence": 92},
    {"rule": "R603", "lhs": "name", "page": 68, "byte_start": 175756, "byte_length": 53, "occurrence": 31},
    {"rule": "R1534", "lhs": "dummy-arg-name", "page": 354, "byte_start": 1007549, "byte_length": 31, "occurrence": 509},
]
MUTATIONS = [
    ("source-document", ("source", "document"), "J3-24-008"),
    ("source-clause", ("source", "clause"), "8"),
    ("source-rule", ("source", "rule"), "C762"),
    ("source-standard-rule", ("source", "standard_rule"), "R742"),
    ("source-span", ("source", "source_span", "byte_start"), 243183),
    ("printed-page", ("source", "printed_page"), 80),
    ("pdf-page", ("source", "pdf_page"), 95),
    ("ledger-page", ("source", "ledger_page"), 95),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64),
    ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64),
    ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64),
    ("standardir-ref", ("source", "standardir", "rows", 1, "rule"), "R743"),
    ("contract-version", ("contract", "version"), 1),
    ("fixture-case", ("cases", 4, "candidate", "fact", "dummy_name_relation"), "matching"),
    ("semantic-item-hash", ("semantic_item", "sha256"), "0" * 64),
]

class ContractError(Exception):
    pass

def require(ok, message):
    if not ok:
        raise ContractError(message)

def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def set_path(value, path, replacement):
    for part in path[:-1]:
        value = value[part]
    value[path[-1]] = replacement

def oracle(fact):
    present, relation = fact["pass_argument_state"], fact["dummy_name_relation"]
    if present == "absent":
        return "ACCEPTED"
    if present == "present" and relation == "matching":
        return "ACCEPTED"
    if present == "present" and relation == "nonmatching":
        return "REJECTED"
    return "UNRESOLVED"

def validate_standardir(source, path):
    require(digest(path) == IR_HASH, "StandardIR hash differs")
    expected = {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "rows": ROWS, "sha256": IR_HASH, "source_hash": SOURCE}
    require(source["standardir"] == expected, "StandardIR identity differs")
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    for row in ROWS:
        matches = [line for line in lines if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matches) == 1, f"{row['rule']} row count differs")
        line = matches[0]
        for pattern, wanted, label in [(r"\(lhs ([^)]+)\)", row["lhs"], "lhs"), (r"\(page (\d+)\)", str(row["page"]), "page"), (r"\(byte-start (\d+)\)", str(row["byte_start"]), "start"), (r"\(byte-length (\d+)\)", str(row["byte_length"]), "length"), (r"\(occurrence (\d+)\)", str(row["occurrence"]), "occurrence")]:
            match = re.search(pattern, line)
            require(match and match.group(1) == wanted, f"{row['rule']} {label} differs")
        require(f"(source-sha256 {SOURCE})" in line, f"{row['rule']} source hash differs")
    require("(ref proc-component-attr-spec-list)" in lines[91] and "(token PASS)" in lines[92] and "(ref arg-name)" in lines[92], "R741/R742 binding differs")
    require("(lhs name)" in lines[31] and "(lhs dummy-arg-name)" in lines[509], "name witnesses differ")

def validate_contract_files(root):
    schema = (root / "contracts/m3-c763-pass-arg-name-v0.sxs").read_text()
    witness = (root / "contracts/fixtures/m3-c763-pass-arg-name-v0.sx").read_text()
    require(schema.startswith("(schema m3-c763-pass-arg-name-v0"), "schema identity differs")
    require("(enum pass-argument-state present absent unknown)" in schema and "(enum dummy-name-relation matching nonmatching unknown)" in schema, "typed schema differs")
    require("(record pass-argument-name-fact" in schema and "(record semantic-candidate" in schema, "schema records differ")
    require(witness.startswith("(contract-witness") and "(contract m3-c763-pass-arg-name)" in witness and "(version 0)" in witness, "fixture contract identity differs")
    require("(standard-rule R741)" in witness and "(byte-start 243182)" in witness and "(byte-length 139)" in witness, "fixture source correspondence differs")

def validate_binding(doc, root, pdf, canonical, page_index, standardir, semantic):
    validate_contract_files(root)
    require(set(doc) == {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture keys differ")
    require(doc["schema_version"] == "m3-c763-source-backed-v0" and doc["origin"] == "LLM" and doc["property"] == PROPERTY, "fixture identity differs")
    require(doc["contract"] == {"fixture": "contracts/fixtures/m3-c763-pass-arg-name-v0.sx", "schema": "contracts/m3-c763-pass-arg-name-v0.sxs", "version": 0}, "contract identity differs")
    s = doc["source"]
    require(s["document"] == "J3-24-007" and s["clause"] == "7" and s["rule"] == "C763" and s["standard_rule"] == "R741" and s["printed_page"] == 79 and s["pdf_page"] == 94 and s["ledger_page"] == 94, "source identity differs")
    require(s["canonical_lines"] == LINES and s["source_span"] == SPAN and s["canonical_text_sha256"] == SOURCE and digest(canonical) == SOURCE, "source coordinates or hash differ")
    raw = Path(canonical).read_bytes()
    require(raw[SPAN["byte_start"]:SPAN["byte_start"] + SPAN["byte_length"]] == SOURCE_BYTES, "canonical bytes differ")
    offsets, pos = [], 0
    for line in raw.split(b"\n"):
        offsets.append(pos); pos += len(line) + 1
    for item in LINES:
        require(raw.split(b"\n")[item["line"] - 1].decode() == item["text"], f"canonical line {item['line']} differs")
    require(offsets[3873] == 243182 and offsets[3874] == 243293, "canonical offsets differ")
    require(s["page_index"] == {"pages": [PAGE], "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index", "sha256": PAGE_HASH} and digest(page_index) == PAGE_HASH, "page index differs")
    require("page 94 start 242409 length 2660" in Path(page_index).read_text().splitlines(), "page record absent")
    require(s["pdf_sha256"] == PDF_HASH and digest(pdf) == PDF_HASH, "PDF identity differs")
    validate_standardir(s, standardir)
    expected_item = {"clause": "7", "document": "J3-24-007", "id": "S-C763", "origin": "llm", "page": 79, "path": "tests/fixtures/m3-c763-semantic-items.sx", "resolution": "disputed", "rule": "C763", "sha256": digest(semantic), "source_hash": SOURCE, "subject": PROPERTY}
    require(doc["semantic_item"] == expected_item, "semantic item identity differs")

def validate_cases(doc, expected):
    require(len(doc["cases"]) == 9 and len({case["id"] for case in doc["cases"]}) == 9, "candidate set differs")
    counts = {outcome: 0 for outcome in OUTCOMES}
    for case in doc["cases"]:
        require(set(case) == {"id", "kind", "expected", "candidate"}, f"case {case['id']} keys differ")
        candidate = case["candidate"]
        require(set(candidate) == {"id", "property", "source", "span", "fact", "expected"}, f"candidate {case['id']} keys differ")
        require(candidate["id"] == case["id"] and candidate["property"] == PROPERTY, f"candidate {case['id']} identity differs")
        require(candidate["source"] == {"clause": "7", "document": "J3-24-007", "page": 79, "rule": "C763", "source_hash": SOURCE} and candidate["span"] == SPAN, f"candidate {case['id']} source differs")
        fact = candidate["fact"]
        require(set(fact) == {"pass_argument_state", "dummy_name_relation"} and fact["pass_argument_state"] in PASSES and fact["dummy_name_relation"] in RELATIONS, f"candidate {case['id']} fact differs")
        result = oracle(fact)
        require(case["expected"] == expected[case["id"]] == candidate["expected"] == result, f"outcome {case['id']} differs")
        require(case["kind"] == {"ACCEPTED": "positive", "REJECTED": "negative", "UNRESOLVED": "unresolved"}[result], f"candidate {case['id']} kind differs")
        counts[result] += 1
    require(counts == {"ACCEPTED": 4, "REJECTED": 1, "UNRESOLVED": 4}, "outcome counts differ")
    return counts

def self_test(root):
    original = json.loads((root / "tests/fixtures/m3-c763-source-backed-v0.json").read_text())
    evidence = Path(os.environ.get("C763_EVIDENCE_ROOT", "/home/ert/code/lazy-fortran-new"))
    paths = [evidence / ".cache/j3-24-007.pdf", evidence / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", evidence / ".cache/runs/E0001/R000003/j3-24-007.pages.index", evidence / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c763-semantic-items.sx"]
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original); set_path(mutated, path, replacement)
        try:
            validate_binding(mutated, root, *paths)
            if name == "fixture-case":
                validate_cases(mutated, {case["id"]: case["expected"] for case in original["cases"]})
        except (ContractError, KeyError, IndexError):
            continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C763 self-test PASS: {len(MUTATIONS)} mutation controls rejected")

def main():
    root = Path(__file__).resolve().parents[2]
    if sys.argv[1:] == ["--self-test"]:
        self_test(root); return 0
    require(len(sys.argv) == 10, "usage: validator.py fixture expected semantic-canonical standardir canonical page-index pdf golden result")
    fixture, expected, semantic_canonical, standardir, canonical, page_index, pdf, golden, result = map(Path, sys.argv[1:])
    document, table = json.loads(fixture.read_text()), json.loads(expected.read_text())
    require(table == {"origin": "MECHANICAL", "outcomes": table["outcomes"], "property": PROPERTY, "schema_version": "m3-c763-expected-outcomes-v0", "source_rule": "C763"} and digest(expected) == EXPECTED_HASH, "expected table differs")
    validate_binding(document, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c763-semantic-items.sx")
    counts = validate_cases(document, table["outcomes"])
    require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs")
    result.write_text(json.dumps({"candidate_promotion":"BOUNDED_ONLY","full_m3":"OPEN","model_calls":0,"mutation_controls":[{"id":name,"result":"REJECTED"} for name, _, _ in MUTATIONS],"origin":"MECHANICAL","outcome_counts":counts,"page_index":PAGE,"property":PROPERTY,"schema_version":"m3-c763-result-v0","semantic_promotions":0,"source_rule":"C763","source_span":SPAN,"standardir_rules":["R741","R742","R603","R1534"],"state_count":9}, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    print(json.dumps(json.loads(result.read_text()), indent=2, sort_keys=True)); return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ContractError, KeyError, IndexError, json.JSONDecodeError) as error:
        print(f"C763 validation failure: {error}", file=sys.stderr); raise SystemExit(1)
