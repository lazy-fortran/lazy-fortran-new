#!/usr/bin/env python3
"""Fail-closed deterministic oracle for the bounded C757/R737 slice."""
from __future__ import annotations
import copy, hashlib, json, os, re, sys
from pathlib import Path

OUTCOMES = {"ACCEPTED", "REJECTED", "UNRESOLVED"}
PRESENCE = {"absent", "present", "unknown"}
PROPERTY = "contiguous-pointer-component-array"
SOURCE_SHA256 = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PDF_SHA256 = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
PAGE_INDEX_SHA256 = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
STANDARDIR_SHA256 = "106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2"
CONSTRAINT_LINE = "C757\tR737\t3851\t92\t7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2\tMECHANICAL\t37 C757 (R737) If the CONTIGUOUS attribute is specified, the component shall be an array with the POINTER"
SOURCE_SPAN = {"byte_start": 242052, "byte_length": 120, "page_start": 93, "page_end": 93}
PAGE_INDEX = {"page": 93, "start": 239957, "length": 2451}
CANONICAL_LINES = [
    {"line": 3851, "text": "37 C757 (R737) If the CONTIGUOUS attribute is specified, the component shall be an array with the POINTER"},
    {"line": 3852, "text": "38 attribute."},
]
SOURCE_BYTES = b"37 C757 (R737) If the CONTIGUOUS attribute is specified, the component shall be an array with the POINTER\n38 attribute.\n"
ROWS = [
    {"rule": "R737", "lhs": "data-component-def-stmt", "page": 93, "byte_start": 240182, "byte_length": 115, "occurrence": 87},
    {"rule": "R738", "lhs": "component-attr-spec", "page": 93, "byte_start": 240298, "byte_length": 179, "occurrence": 88},
    {"rule": "R739", "lhs": "component-decl", "page": 93, "byte_start": 240478, "byte_length": 157, "occurrence": 89},
]
MUTATIONS = [
    ("source-rule", ("source", "rule"), "C756"),
    ("printed-page", ("source", "printed_page"), 80),
    ("ledger-page", ("source", "constraint_span", "ledger_page"), 93),
    ("span-start", ("source", "source_span", "byte_start"), 242053),
    ("span-length", ("source", "source_span", "byte_length"), 121),
    ("canonical-line", ("source", "canonical_lines", 0, "text"), "changed"),
    ("page-index-hash", ("source", "page_index", "sha256"), "0" * 64),
    ("page-index-start", ("source", "page_index", "pages", 0, "start"), 239958),
    ("pdf-hash", ("source", "pdf_sha256"), "0" * 64),
    ("canonical-hash", ("source", "canonical_text_sha256"), "0" * 64),
    ("standardir-hash", ("source", "standardir", "sha256"), "0" * 64),
    ("standardir-rule", ("source", "standardir", "rows", 0, "rule"), "R738"),
    ("ledger-text", ("source", "constraint_span", "text"), "changed"),
    ("semantic-item-hash", ("semantic_item", "source_hash"), "0" * 64),
    ("contract-version", ("contract", "version"), 1),
]
SOURCE_FIXTURE_SHA256 = "9466c1c48aad8412ae6861aa13faeda20cb1485755bb4348a9418395d14ce0fb"
EXPECTED_OUTCOMES_SHA256 = "2169a7c06cf0966a4136a3dbfe2e387f038e4080cf3f42208194715fc92d073a"
SEMANTIC_ITEM_SHA256 = "551eaf2b0488954f59bde152cdf9e59c72bd43a58375ab68e4ddd5f72fafd0ca"

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

def oracle(candidate: dict[str, str]) -> str:
    contiguous = candidate["contiguous_attribute"]
    pointer = candidate["pointer_attribute"]
    array = candidate["component_array"]
    if contiguous == "absent":
        return "ACCEPTED"
    if contiguous == "present":
        if "absent" in (pointer, array):
            return "REJECTED"
        if pointer == "present" and array == "present":
            return "ACCEPTED"
        return "UNRESOLVED"
    if pointer == "present" and array == "present":
        return "ACCEPTED"
    return "UNRESOLVED"

def validate_standardir(source: dict, path: Path) -> None:
    require(digest(path) == STANDARDIR_SHA256, "StandardIR hash differs")
    expected = {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "sha256": STANDARDIR_SHA256, "source_hash": SOURCE_SHA256, "rows": ROWS}
    require(source["standardir"] == expected, "StandardIR identity differs")
    lines = path.read_text(encoding="utf-8").splitlines()
    fragments = {"R737": ["(lhs data-component-def-stmt)", "(ref component-decl-list)"], "R738": ["(lhs component-attr-spec)", "(token CONTIGUOUS)", "(token POINTER)", "(ref component-array-spec)"], "R739": ["(lhs component-decl)", "(ref component-array-spec)"]}
    for row in ROWS:
        matches = [line for line in lines if line.startswith(f"(syntax {row['rule']} ")]
        require(len(matches) == 1, f"{row['rule']} row count differs")
        line = matches[0]
        for pattern, value, label in [(r"\(lhs ([^)]+)\)", row["lhs"], "lhs"), (r"\(page (\d+)\)", str(row["page"]), "page"), (r"\(byte-start (\d+)\)", str(row["byte_start"]), "start"), (r"\(byte-length (\d+)\)", str(row["byte_length"]), "length"), (r"\(occurrence (\d+)\)", str(row["occurrence"]), "occurrence")]:
            match = re.search(pattern, line)
            require(match and match.group(1) == value, f"{row['rule']} {label} differs")
        require(f"(source-sha256 {SOURCE_SHA256})" in line, f"{row['rule']} source hash differs")
        for fragment in fragments[row["rule"]]:
            require(fragment in line, f"{row['rule']} binding differs")

def validate_binding(document: dict, root: Path, pdf: Path, canonical: Path, page_index: Path, standardir: Path, semantic: Path) -> None:
    exact_keys(document, {"schema_version", "origin", "property", "contract", "source", "semantic_item", "cases", "mutation_controls"}, "fixture")
    require(digest(root / "tests/fixtures/m3-c757-source-backed-v0.json") == SOURCE_FIXTURE_SHA256, "source fixture hash differs")
    require(document["schema_version"] == "m3-c757-source-backed-v0" and document["origin"] == "LLM" and document["property"] == PROPERTY, "fixture identity differs")
    require(document["contract"] == {"schema": "contracts/m3-c757-contiguous-pointer-v0.sxs", "fixture": "contracts/fixtures/m3-c757-contiguous-pointer-v0.sx", "version": 0}, "contract identity differs")
    source = document["source"]
    require(source["document"] == "J3-24-007" and source["clause"] == "7" and source["rule"] == "C757" and source["standard_rule"] == "R737" and source["printed_page"] == 79, "source identity differs")
    require(source["canonical_lines"] == CANONICAL_LINES and source["source_span"] == SOURCE_SPAN, "source coordinates differ")
    require(source["canonical_text_sha256"] == SOURCE_SHA256 and digest(canonical) == SOURCE_SHA256, "canonical source hash differs")
    require(canonical.read_bytes()[242052:242172] == SOURCE_BYTES, "source bytes differ")
    raw_lines = canonical.read_bytes().split(b"\n")
    offsets, offset = [], 0
    for line in raw_lines:
        offsets.append(offset); offset += len(line) + 1
    for item in CANONICAL_LINES:
        actual = raw_lines[item["line"] - 1].decode("utf-8")
        require(actual == item["text"] and offsets[item["line"] - 1] == (242052 if item["line"] == 3851 else 242158), f"canonical line {item['line']} differs")
    require(source["page_index"]["sha256"] == PAGE_INDEX_SHA256 and digest(page_index) == PAGE_INDEX_SHA256 and source["page_index"]["pages"] == [PAGE_INDEX], "page-index identity differs")
    require(f"page 93 start 239957 length 2451" in page_index.read_text(encoding="utf-8").splitlines(), "page-index record absent")
    require(source["constraint_span"] == {"rule": "R737", "canonical_line": 3851, "ledger_page": 92, "pdf_sha256": PDF_SHA256, "text": CONSTRAINT_LINE.split("\t")[-1]}, "constraint ledger coordinates differ")
    ledger = Path(os.environ.get("C757_CONSTRAINT_SPANS", str(root / ".cache/runs/E0081/R000001/constraint-spans.tsv")))
    require(CONSTRAINT_LINE in ledger.read_text(encoding="utf-8").splitlines(), "constraint ledger row absent")
    validate_standardir(source, standardir)
    require(source["pdf_sha256"] == PDF_SHA256 and digest(pdf) == PDF_SHA256, "normative PDF hash differs")
    require(document["semantic_item"] == {"path": "tests/fixtures/m3-c757-semantic-items.sx", "sha256": SEMANTIC_ITEM_SHA256, "id": "S-C757", "subject": PROPERTY, "document": "J3-24-007", "clause": "7", "rule": "C757", "page": 79, "source_hash": SOURCE_SHA256, "origin": "llm", "resolution": "disputed"}, "semantic item differs")
    require(digest(semantic) == SEMANTIC_ITEM_SHA256, "semantic item hash differs")
    require(document["mutation_controls"] == [name for name, _, _ in MUTATIONS], "mutation inventory differs")

def validate_expected(document: dict, path: Path, ids: list[str]) -> dict[str, str]:
    exact_keys(document, {"schema_version", "origin", "property", "source_rule", "outcomes"}, "expected outcomes")
    require(digest(path) == EXPECTED_OUTCOMES_SHA256 and document["schema_version"] == "m3-c757-expected-outcomes-v0" and document["origin"] == "LLM" and document["property"] == PROPERTY and document["source_rule"] == "C757", "expected identity differs")
    require(set(document["outcomes"]) == set(ids) and all(value in OUTCOMES for value in document["outcomes"].values()), "expected outcomes differ")
    return document["outcomes"]

def validate_cases(document: dict, expected: dict[str, str]) -> dict[str, int]:
    require(len(document["cases"]) == 27, "case count differs")
    require(len({case.get("id") for case in document["cases"]}) == 27 and {case["id"] for case in document["cases"]} == set(expected), "case IDs differ")
    counts = {outcome: 0 for outcome in OUTCOMES}
    for case in document["cases"]:
        exact_keys(case, {"id", "kind", "expected", "candidate"}, f"case {case['id']}")
        candidate = case["candidate"]
        exact_keys(candidate, {"id", "property", "source", "span", "fact", "expected"}, f"case {case['id']} candidate")
        require(candidate["id"] == case["id"] and candidate["property"] == PROPERTY, f"case {case['id']} identity differs")
        require(candidate["source"] == {"document": "J3-24-007", "clause": "7", "rule": "C757", "page": 79, "source_hash": SOURCE_SHA256}, f"case {case['id']} source differs")
        require(candidate["span"] == {"byte_start": SOURCE_SPAN["byte_start"], "byte_length": SOURCE_SPAN["byte_length"], "page_start": SOURCE_SPAN["page_start"], "page_end": SOURCE_SPAN["page_end"]}, f"case {case['id']} span differs")
        exact_keys(candidate["fact"], {"contiguous_attribute", "pointer_attribute", "component_array"}, f"case {case['id']} fact")
        require(all(candidate["fact"][key] in PRESENCE for key in ("contiguous_attribute", "pointer_attribute", "component_array")), f"case {case['id']} fields differ")
        require(case["expected"] == expected[case["id"]] and case["expected"] == candidate["expected"] and case["expected"] == oracle(candidate["fact"]), f"case {case['id']} expected outcome differs")
        require(case["kind"] == {"ACCEPTED": "positive", "REJECTED": "negative", "UNRESOLVED": "unresolved"}[case["expected"]], f"case {case['id']} kind differs")
        counts[case["expected"]] += 1
    require(counts == {"ACCEPTED": 11, "REJECTED": 5, "UNRESOLVED": 11}, "outcome counts differ")
    return counts

def self_test(root: Path) -> None:
    original = json.loads((root / "tests/fixtures/m3-c757-source-backed-v0.json").read_text(encoding="utf-8"))
    evidence = Path(os.environ.get("C757_EVIDENCE_ROOT", "/home/ert/code/lazy-fortran-new"))
    for name, path, replacement in MUTATIONS:
        mutated = copy.deepcopy(original); set_path(mutated, path, replacement)
        try:
            validate_binding(mutated, root, evidence / ".cache/j3-24-007.pdf", evidence / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", evidence / ".cache/runs/E0001/R000003/j3-24-007.pages.index", evidence / ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", root / "tests/fixtures/m3-c757-semantic-items.sx")
        except (ContractError, KeyError):
            continue
        raise ContractError(f"mutation {name} was accepted")
    print(f"C757 self-test PASS: {len(MUTATIONS)} mutation controls rejected")

def main() -> int:
    root = Path(__file__).resolve().parents[2]
    if sys.argv[1:] == ["--self-test"]:
        self_test(root); return 0
    if len(sys.argv) != 10:
        raise ContractError("usage: validator.py fixture expected semantic-canonical standardir canonical page-index pdf golden result")
    fixture_path, expected_path, semantic_canonical, standardir, canonical, page_index, pdf, golden, result_path = map(Path, sys.argv[1:])
    fixture = json.loads(fixture_path.read_text(encoding="utf-8")); expected = validate_expected(json.loads(expected_path.read_text(encoding="utf-8")), expected_path, [case["id"] for case in fixture["cases"]])
    validate_binding(fixture, root, pdf, canonical, page_index, standardir, root / "tests/fixtures/m3-c757-semantic-items.sx")
    counts = validate_cases(fixture, expected)
    require(semantic_canonical.read_bytes() == golden.read_bytes(), "semantic canonical output differs")
    result = {"schema_version": "m3-c757-result-v0", "origin": "MECHANICAL", "property": PROPERTY, "source_rule": "C757", "source_span": SOURCE_SPAN, "page_index": PAGE_INDEX, "standardir_rules": [row["rule"] for row in ROWS], "state_count": 27, "outcome_counts": counts, "mutation_controls": [{"id": name, "result": "REJECTED"} for name, _, _ in MUTATIONS], "model_calls": 0, "semantic_promotions": 0, "candidate_promotion": "BOUNDED_ONLY", "full_m3": "OPEN"}
    result_path.write_text(json.dumps(result, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8"); print(json.dumps(result, indent=2, sort_keys=True)); return 0

if __name__ == "__main__":
    try: raise SystemExit(main())
    except (ContractError, KeyError, IndexError, json.JSONDecodeError) as error:
        print(f"C757 validation failure: {error}", file=sys.stderr); raise SystemExit(1)
