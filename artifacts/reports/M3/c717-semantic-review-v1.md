# C717 focused semantic review v1

Verdict: PASS
Origin: LLM
Packet: corrected E0189 replay `R000478`, `.cache/runs/E0189/R000003`.

First fatal issue: none.

Evidence:

- `D0140` defines `known-violation-before-unknown` and the complete 3x3
  state table.
- `tests/fixtures/m3-c717-source-backed-v0.json` contains all nine typed
  combinations and the expected one ACCEPTED, five REJECTED and three
  UNRESOLVED outcomes.
- `tests/e2e/validate_m3_c717.py` computes the outcomes independently,
  checks the precedence policy and rejects all eight mutation controls.
- The frozen result equals the committed trace at SHA-256
  `f4b52f8f48f8069c0001d8db617589968b695c416b4ba4cb4c9318b2e38bbd00` and
  binds C717/R706 to canonical lines 3263--3264, page 80 and the pinned
  StandardIR source.

Required correction: none for the semantic scope. The reproducibility lane
must still close the central-revision durability finding.
