#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
RUN=${1:?usage: analyse.sh <run-directory>}
RUN=$(cd "$RUN" && pwd)
GRAMMAR="$RUN/fortran2023.y"
ORACLES="$RUN/grammar-oracles.tsv"
mkdir -p "$RUN/references"
cp "$ROOT/.cache/runs/E0152/R000001/references/lfortran-bison" "$RUN/references/lfortran-bison"
mkdir -p "$RUN/source"
cp "$ROOT/.cache/runs/E0151/R000002-candidate/input/standardir.sx" "$RUN/source/standardir.sx"
cp "$ROOT/.cache/runs/E0151/R000002-candidate/source-projection.tsv" "$RUN/source/source-projection.tsv"
cp "$ROOT/.cache/runs/E0151/R000002-candidate/grammar-oracles.tsv" "$RUN/source/grammar-oracles.tsv"
LFORTRAN="$RUN/references/lfortran-bison"
SOURCE_SX="$RUN/source/standardir.sx"
SOURCE_PROJECTION="$RUN/source/source-projection.tsv"
SOURCE_ORACLES="$RUN/source/grammar-oracles.tsv"

[[ -f "$GRAMMAR" && -f "$ORACLES" && -f "$LFORTRAN" && -f "$SOURCE_SX" && \
    -f "$SOURCE_PROJECTION" && -f "$SOURCE_ORACLES" ]] || {
    echo "missing candidate, oracle, source evidence or pinned LFortran reference" >&2
    exit 1
}

python3 - "$GRAMMAR" "$ORACLES" "$LFORTRAN" "$RUN" <<'PY'
from __future__ import annotations
import hashlib
import json
import re
import sys
from pathlib import Path

grammar, oracles, lfortran, run = map(Path, sys.argv[1:])
g = grammar.read_text(encoding="utf-8")
l = lfortran.read_text(encoding="utf-8")
expected_generated = {
    "grammar.ebnf": "0ceff425b67e546d125394ac8bb3a04253a1c8ea4690a1367c5837eebb7236e0",
    "Fortran2023.g4": "72675a8614329122a5e247ab248675e63e8f38b3ee675974193d24cf8b20b801",
    "fortran2023.y": "ca581902fb9816b1072ffcfa69355663e6b7e763899bed8333b09682d4edbf7e",
    "grammar.js": "86fef515edbbfd5cd9e272e0bc155ecfaa0375f1c34cb9fdbccd02ef97adcebf",
}
for name, expected in expected_generated.items():
    actual = hashlib.sha256((run / name).read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f"generated hash mismatch for {name}: {actual} != {expected}")
expected_oracles = "3348bb3bf3a9e3e29ddb32b8961cd0f33828a87095366bdd6108168c5ff0792b"
actual_oracles = hashlib.sha256(oracles.read_bytes()).hexdigest()
if actual_oracles != expected_oracles:
    raise SystemExit(f"validator report hash mismatch: {actual_oracles} != {expected_oracles}")
expected_lfortran = "112ef0ce5078ccec630a893bc51b92232348c37742b1451c833928a422907936"
actual_lfortran = hashlib.sha256(lfortran.read_bytes()).hexdigest()
if actual_lfortran != expected_lfortran:
    raise SystemExit(f"LFortran hash mismatch: {actual_lfortran} != {expected_lfortran}")
expected_sources = {
    "standardir.sx": "e0816b4b3280e5a7945bf50dfd24036050c1f415daa864166b56741b4cd7b18f",
    "source-projection.tsv": "64035bf921e816a6e64899c699a921c6c3e5425f488cdd48192bfba20782ad1d",
    "grammar-oracles.tsv": expected_oracles,
}
for name, expected in expected_sources.items():
    actual = hashlib.sha256((run / "source" / name).read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f"source evidence hash mismatch for {name}: {actual} != {expected}")

anchors = {
    "R741": ['"PROCEDURE"', "r_proc_x2D_component_x2D_attr_x2D_spec_x2D_list", '"::"', "r_proc_x2D_decl_x2D_list"],
    "R843": ["r_data_x2D_i_x2D_do_x2D_variable", "=", "r_scalar_x2D_int_x2D_constant_x2D_expr", "h_r_R843_3", ")"],
    "R1307": ['"I"', '"B"', '"O"', '"Z"', '"F"', '"EN"', '"ES"', '"EX"', '"G"', '"AT"', '"DT"'],
    "R1315": ['"T" r_n', '"TL" r_n', '"TR" r_n', 'r_n "X"'],
    "R1416": ["r_submodule_x2D_stmt", "h_r_R1416_1", "r_end_x2D_submodule_x2D_stmt"],
    "R1417": ['"SUBMODULE"', "r_parent_x2D_identifier", "r_submodule_x2D_name"],
    "R1418": ["r_ancestor_x2D_module_x2D_name", "h_r_R1418_1", "r_parent_x2D_submodule_x2D_name"],
}
rows = []
for rule, patterns in anchors.items():
    found = all(pattern in g for pattern in patterns)
    rows.append((rule, "PASS" if found else "FAIL", str(len(patterns)), "source-backed Bison anchor"))

required_oracles = {"antlr4": "PASS", "bison": "PASS", "tree-sitter": "PASS", "source-projection": "PASS"}
oracle_rows = {}
for line in oracles.read_text(encoding="utf-8").splitlines():
    fields = line.split("\t")
    if len(fields) >= 2:
        oracle_rows[fields[0]] = fields[1]
for name, expected in required_oracles.items():
    rows.append((name, "PASS" if oracle_rows.get(name) == expected else "FAIL", expected, "independent validator"))

for path in (run / "anchor-check.tsv",):
    path.write_text("id\tstatus\tchecks\tevidence\n" + "\n".join("\t".join(row) for row in rows) + "\n", encoding="utf-8")

feature_rows = [
    ("P001", "selected-start", "%start standardir_start -> r_program", "%start units", "expected_difference", "fortran2023.y:11-14; parser.yy:613-630", "close only with an explicit selected-profile corpus"),
    ("P002", "normative-lineage", "source-lineage plus document/page/byte/hash", "no per-production J3 lineage", "standardir_advantage", "fortran2023.y provenance comments; E0152/R000001/summary.json", "retain lineage through every target normalization"),
    ("P003", "multi-format-projection", "EBNF, ANTLR4, Bison and tree-sitter", "single Bison parser target", "standardir_advantage", "E0152/R000001/summary.json", "keep exact cross-format lineage-set equality"),
    ("P004", "executable-lexer", "absent; separate source-backed lexer contract only", "yylex plus fixed/free-form tokenizer", "reference_advantage", "E0151/R000002-candidate/lexer-contract.jsonl; parser.yy:42-54", "generate a generic lexer ABI/runtime"),
    ("P005", "typed-semantic-values", "absent", "%define api.value.type plus %type declarations", "reference_advantage", "fortran2023.y:1-20; parser.yy:17-18,329-402", "generate typed parser-value wiring from an AST contract"),
    ("P006", "precedence-policy", "absent from generated Bison", "%left/%right/%precedence declarations", "reference_advantage", "fortran2023.y:1-20; parser.yy:599-611", "derive precedence only from source-backed relations"),
    ("P007", "ast-actions", "absent by design in normative syntax export", "semantic/trivia actions in productions", "reference_advantage", "fortran2023.y header; parser.yy:658-673,918-930", "generate actions from a separate AST/wiring contract"),
    ("P008", "conflict-policy", "427 shift/reduce and 2,266 reduce/reduce; no budget", "%expect 238 and %expect-rr 180", "target_specialization_gap", "E0151/R000002-candidate/grammar-oracles.tsv; parser.yy:15-18", "generic role factoring plus a retained conflict witness"),
    ("P009", "parser-role-factoring", "normative roles remain distinct", "parser-oriented categories are hand-factored", "target_specialization_gap", "E0153 comparison-matrix M039; parser.yy:2445-2505", "repair the generic factoring slice and prove preservation"),
    ("P010", "profile-coverage", "selected program root; six declared roots omitted", "units accepts multiple unit forms", "projection_gap", "grammar-oracles.tsv: omitted_declared_root_count; parser.yy:626-650", "define and test the complete production profile"),
    ("P011", "source-expression-identity", "body-bound projection, not expression identity", "not applicable to the reference", "method_gap", "source/source-projection.tsv; D0087/D0088", "emit and mutation-test an expression identity witness"),
    ("P012", "implementation-extensions", "source-restricted normative profile", "implementation forms include union/template families", "standardir_advantage", "source-backed input; parser.yy:362-386,700-760", "keep extensions in explicit non-normative profiles"),
    ("P013", "duplicate-source-occurrences", "identical target bodies retain merged source lineage", "no normative occurrence lineage", "standardir_advantage", "fortran2023.y:4520-4522,5952-5954; source projection", "keep occurrence identity separate from target-body identity"),
]
(run / "feature-audit.tsv").write_text(
    "id\tfeature\tcurrent\treference\tclassification\tevidence\tnext_gate\n"
    + "\n".join("\t".join(row) for row in feature_rows) + "\n", encoding="utf-8"
)

summary = {
    "lfortran_sha256": actual_lfortran,
    "generated_hashes": expected_generated,
    "validator_report_sha256": actual_oracles,
    "source_anchor_rows": len(anchors),
    "source_anchor_failures": sum(status != "PASS" for _, status, *_ in rows[:len(anchors)]),
    "validator_failures": sum(status != "PASS" for _, status, *_ in rows[len(anchors):]),
    "source_evidence_hashes": {name: hashlib.sha256((run / "source" / name).read_bytes()).hexdigest() for name in expected_sources},
    "feature_audit_rows": len(feature_rows),
    "feature_audit_sha256": hashlib.sha256((run / "feature-audit.tsv").read_bytes()).hexdigest(),
    "lfortran_has_lexer": "int yylex(" in l,
    "lfortran_has_typed_values": "%define api.value.type" in l,
    "lfortran_has_precedence": "%left" in l and "%right" in l,
    "lfortran_has_conflict_budget": "%expect" in l and "%expect-rr" in l,
    "generated_has_provenance": "source-lineage=" in g,
    "generated_has_ast_actions": False,
    "equivalence_claim": False,
}
(run / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(json.dumps(summary, indent=2))
if summary["source_anchor_failures"] or summary["validator_failures"]:
    raise SystemExit(1)
PY
