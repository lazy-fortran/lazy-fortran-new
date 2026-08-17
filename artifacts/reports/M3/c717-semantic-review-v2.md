# C717 focused semantic review v2

Verdict: PASS
Origin: LLM
Packet: durable-pin E0189 replay `R000480`, `.cache/runs/E0189/R000004`.

First fatal issue: none.

Evidence:

- D0140, the typed fixture, validator and committed trace agree on
  `known-violation-before-unknown` and all nine state combinations.
- The independent table check reports one ACCEPTED, five REJECTED and three
  UNRESOLVED outcomes; all eight source, identity and precedence mutations
  reject.
- The result and trace are byte-identical at SHA-256
  `f4b52f8f48f8069c0001d8db617589968b695c416b4ba4cb4c9318b2e38bbd00`.
- The source binding matches C717/R706, canonical lines 3263--3264, page 80
  and the pinned StandardIR hashes. The oracle remains independent of model
  output and does not evaluate expressions or processor capabilities.

Required correction: none.
