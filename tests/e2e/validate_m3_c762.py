#!/usr/bin/env python3
"""Fail-closed deterministic oracle for the supplied-state C762/R741 property."""
from __future__ import annotations
import copy, hashlib, json, os, re, subprocess, sys
from pathlib import Path

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
TRIGGERS = {"not-triggered", "triggered", "unknown"}
NOPASS = {"present", "absent", "unknown"}
PROPERTY = "conditional-nopass"
SOURCE = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PAGE_HASH = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
IR_HASH = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
PDF_HASH = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
SEMANTIC_HASH = "c2a3b1287b2f6669c4aa51d943f635af088b45a2a18604e2261eb83a6a1cc472"
FIXTURE_HASH = "f48fd16f6de365ee85190104becde42cd68f7750592bff0aa30e95821ddb7381"
EXPECTED_HASH = "db8bddc1ea7be70cccad61c7829c9c9af723132288ebeb6991d55673c4d752eb"
SPAN = {"byte_start": 243055, "byte_length": 127, "page_start": 93, "page_end": 93}
PAGE = {"page": 93, "start": 239957, "length": 2451}
LINES = [{"line": 3872, "text": "10 C762 (R741) If the procedure pointer component has an implicit interface or has no arguments, NOPASS shall"}, {"line": 3873, "text": "11 be specified."}]
SOURCE_BYTES = b"10 C762 (R741) If the procedure pointer component has an implicit interface or has no arguments, NOPASS shall\n11 be specified.\n"
ROWS = [{"rule": "R741", "lhs": "proc-component-def-stmt", "page": 94, "byte_start": 242577, "byte_length": 118, "occurrence": 91}, {"rule": "R742", "lhs": "proc-component-attr-spec", "page": 94, "byte_start": 242765, "byte_length": 96, "occurrence": 92}]
MUTATIONS = [("source-rule", ("source", "rule"), "C761"), ("source-span", ("source", "source_span", "byte_start"), 243056), ("printed-page", ("source", "printed_page"), 80), ("pdf-page", ("source", "pdf_page"), 95), ("ledger-page", ("source", "ledger_page"), 94), ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64), ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64), ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64), ("standardir-ref", ("source", "standardir", "rows", 1, "rule"), "R743"), ("contract-version", ("contract", "version"), 1), ("fixture-case", ("cases", 0, "candidate", "fact", "trigger_state"), "triggered"), ("semantic-item-hash", ("semantic_item", "sha256"), "0" * 64)]

class ContractError(Exception): pass
def require(ok, message):
    if not ok: raise ContractError(message)
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def set_path(value, path, replacement):
    for part in path[:-1]: value = value[part]
    value[path[-1]] = replacement
def oracle(fact):
    trigger, nopass = fact["trigger_state"], fact["nopass_state"]
    if trigger == "unknown" or (trigger == "triggered" and nopass == "unknown"): return "UNRESOLVED"
    if trigger == "not-triggered" or nopass == "present": return "ACCEPTED"
    return "REJECTED"

def validate_standardir(source, path):
    require(digest(path) == IR_HASH, "StandardIR hash differs")
    exact = {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "rows": ROWS, "sha256": IR_HASH, "source_hash": SOURCE}
    require(source["standardir"] == exact, "StandardIR identity differs")
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    for row in ROWS:
        matches = [line for line in lines if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matches) == 1, f"{row['rule']} row count differs")
        line = matches[0]
        for pattern, expected, label in [(r"\(lhs ([^)]+)\)", row["lhs"], "lhs"), (r"\(page (\d+)\)", str(row["page"]), "page"), (r"\(byte-start (\d+)\)", str(row["byte_start"]), "start"), (r"\(byte-length (\d+)\)", str(row["byte_length"]), "length"), (r"\(occurrence (\d+)\)", str(row["occurrence"]), "occurrence")]:
            m = re.search(pattern, line); require(m and m.group(1) == expected, f"{row['rule']} {label} differs")
        require(f"(source-sha256 {SOURCE})" in line, f"{row['rule']} source hash differs")
    require("(ref proc-component-attr-spec-list)" in lines[91] and "(token POINTER)" in lines[92], "R741/R742 binding differs")

def validate_contract_files(root):
    schema = (root / "contracts/m3-c762-conditional-nopass-v0.sxs").read_text()
    witness = (root / "contracts/fixtures/m3-c762-conditional-nopass-v0.sx").read_text()
    require(schema.startswith("(schema m3-c762-conditional-nopass-v0") and "(record conditional-nopass-fact" in schema and "(record semantic-candidate" in schema, "schema correspondence differs")
    require(witness.startswith("(contract-witness") and "(contract m3-c762-conditional-nopass)" in witness and "(version 0)" in witness, "fixture correspondence differs")

def validate_binding(doc, root, pdf, canonical, page_index, standardir, semantic):
    require(digest(root / "tests/fixtures/m3-c762-source-backed-v0.json") == FIXTURE_HASH, "source fixture hash differs")
    validate_contract_files(root)
    require(set(doc) == {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture keys differ")
    require(doc["schema_version"] == "m3-c762-source-backed-v0" and doc["origin"] == "LLM" and doc["property"] == PROPERTY, "fixture identity differs")
    require(doc["contract"] == {"fixture": "contracts/fixtures/m3-c762-conditional-nopass-v0.sx", "schema": "contracts/m3-c762-conditional-nopass-v0.sxs", "version": 0}, "contract identity differs")
    s = doc["source"]
    require(s["document"] == "J3-24-007" and s["clause"] == "7" and s["rule"] == "C762" and s["standard_rule"] == "R741" and s["printed_page"] == 79 and s["pdf_page"] == 94 and s["ledger_page"] == 93, "source identity differs")
    require(s["canonical_lines"] == LINES and s["source_span"] == SPAN and s["canonical_text_sha256"] == SOURCE and digest(canonical) == SOURCE, "source coordinates or hash differ")
    raw = Path(canonical).read_bytes(); require(raw[SPAN["byte_start"]:SPAN["byte_start"] + SPAN["byte_length"]] == SOURCE_BYTES, "canonical bytes differ")
    lines = raw.split(b"\n"); offsets = []; pos = 0
    for line in lines: offsets.append(pos); pos += len(line) + 1
    for item in LINES: require(lines[item["line"] - 1].decode() == item["text"], f"canonical line {item['line']} differs")
    require(offsets[3871] == 243055 and offsets[3872] == 243165, "canonical offsets differ")
    require(s["page_index"] == {"pages": [PAGE], "path": ".cache/runs/E0001/R000003/j3-24-007.pages.index", "sha256": PAGE_HASH} and digest(page_index) == PAGE_HASH, "page index differs")
    require("page 93 start 239957 length 2451" in Path(page_index).read_text().splitlines(), "page record absent")
    require(s["pdf_sha256"] == PDF_HASH and digest(pdf) == PDF_HASH, "PDF identity differs")
    validate_standardir(s, standardir)
    item = {"clause": "7", "document": "J3-24-007", "id": "S-C762", "origin": "llm", "page": 79, "path": "tests/fixtures/m3-c762-semantic-items.sx", "resolution": "disputed", "rule": "C762", "sha256": SEMANTIC_HASH, "source_hash": SOURCE, "subject": PROPERTY}
    require(doc["semantic_item"] == item and digest(semantic) == SEMANTIC_HASH, "semantic item differs")
    require(doc["mutation_controls"] == [name for name, _, _ in MUTATIONS], "mutation inventory differs")

def validate_cases(doc, expected):
    require(len(doc["cases"]) == 9 and len({c["id"] for c in doc["cases"]}) == 9, "candidate set differs")
    counts = {outcome: 0 for outcome in OUTCOMES}
    for case in doc["cases"]:
        require(set(case) == {"id", "kind", "expected", "candidate"}, f"case {case['id']} keys differ")
        c = case["candidate"]; require(set(c) == {"id", "property", "source", "span", "fact", "expected"}, f"candidate {case['id']} keys differ")
        require(c["id"] == case["id"] and c["property"] == PROPERTY and c["source"] == {"clause": "7", "document": "J3-24-007", "page": 79, "rule": "C762", "source_hash": SOURCE} and c["span"] == SPAN, f"candidate {case['id']} identity differs")
        require(set(c["fact"]) == {"trigger_state", "nopass_state"} and c["fact"]["trigger_state"] in TRIGGERS and c["fact"]["nopass_state"] in NOPASS, f"candidate {case['id']} fact differs")
        result = oracle(c["fact"]); require(case["expected"] == expected[case["id"]] == c["expected"] == result, f"outcome {case['id']} differs")
        require(case["kind"] == {"ACCEPTED": "positive", "REJECTED": "negative", "UNRESOLVED": "unresolved"}[result], f"candidate {case['id']} kind differs"); counts[result] += 1
    require(counts == {"ACCEPTED": 4, "REJECTED": 1, "UNRESOLVED": 4}, "outcome counts differ"); return counts

def self_test(root):
    original = json.loads((root / "tests/fixtures/m3-c762-source-backed-v0.json").read_text())
    evidence = Path(os.environ.get("C762_EVIDENCE_ROOT", "/home/ert/code/lazy-fortran-new"))
    paths = [evidence / ".cache/j3-24-007.pdf", evidence / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", evidence / ".cache/runs/E0001/R000003/j3-24-007.pages.index", evidence / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c762-semantic-items.sx"]
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original); set_path(mutated, path, replacement)
        try: validate_binding(mutated, root, *paths)
        except (ContractError, KeyError, IndexError): continue
        if name == "fixture-case":
            try: validate_cases(mutated, {case["id"]: case["expected"] for case in original["cases"]})
            except (ContractError, KeyError, IndexError): continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C762 self-test PASS: {len(MUTATIONS)} mutation controls rejected")

def main():
    root = Path(__file__).resolve().parents[2]
    if sys.argv[1:] == ["--self-test"]: self_test(root); return 0
    require(len(sys.argv) == 10, "usage: validator.py fixture expected semantic-canonical standardir canonical page-index pdf golden result")
    fixture, expected, semantic_canonical, standardir, canonical, page_index, pdf, golden, result = map(Path, sys.argv[1:])
    f = json.loads(fixture.read_text()); e = json.loads(expected.read_text())
    require(digest(expected) == EXPECTED_HASH and e["origin"] == "MECHANICAL" and e["property"] == PROPERTY and e["source_rule"] == "C762", "expected table differs")
    validate_binding(f, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c762-semantic-items.sx")
    counts = validate_cases(f, e["outcomes"]); require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs")
    result.write_text(json.dumps({"candidate_promotion":"BOUNDED_ONLY","full_m3":"OPEN","model_calls":0,"mutation_controls":[{"id":n,"result":"REJECTED"} for n,_,_ in MUTATIONS],"origin":"MECHANICAL","outcome_counts":counts,"page_index":PAGE,"property":PROPERTY,"schema_version":"m3-c762-result-v0","semantic_promotions":0,"source_rule":"C762","source_span":SPAN,"standardir_rules":["R741","R742"],"state_count":9}, sort_keys=True, separators=(",", ":")) + "\n")
    print(json.dumps(json.loads(result.read_text()), indent=2, sort_keys=True)); return 0

if __name__ == "__main__":
    try: raise SystemExit(main())
    except (ContractError, KeyError, IndexError, json.JSONDecodeError) as error: print(f"C762 validation failure: {error}", file=sys.stderr); raise SystemExit(1)
