# C729 semantic/source review v0

Status: `PASS` for the semantic/source scope; paired review did not authorize promotion.
Origin: `LLM`
Functional snapshot: `24798c2c18e6e3d751e571d7be2afc23d4fa2c9b`
Control-plane snapshot: `7ed9ca9a64b43bc562bb1b234aade268f6aebaa1`
Replay: `tests/e2e/run-m3-c729.sh .cache/runs/E0184/R000001`

The candidate binds C729 to canonical-text line 3466 and page 84, with the
R722, R703 and R801 StandardIR metadata and source hashes checked by the
validator. The typed comma/context oracle computes `ACCEPTED`, `REJECTED` or
`UNRESOLVED` before comparing expected labels. Its four cases and five
source/provenance mutation controls are bounded and fail closed. The slice
does not parse statements, analyze declarations, resolve names, type-check,
consume model output or promote a semantic fact.

This scope passed. The reproducibility scope found a control-plane metadata
defect in the same review wave; the retained review therefore did not
authorize promotion.
