# C717 focused semantic review v0

Verdict: NEEDS FIX
Origin: LLM
Packet: E0189 first replay, `.cache/runs/E0189/R000001`, referenced as the
ambiguous `R000077` in the pre-correction control-plane state.

First fatal issue: the oracle returns `UNRESOLVED` before checking known
violations. Therefore `(negative, unknown)` and `(unknown, absent)` do not
implement the stated known-violation rejection rule, and the six-case fixture
does not cover the complete 3x3 state table.

Evidence:

- `tests/e2e/validate_m3_c717.py`, `c717_oracle` and `self_test`
- `tests/fixtures/m3-c717-source-backed-v0.json`, six cases
- `research/decisions/D0139-fourteenth-m3-c717-kind-selector-oracle.md`
- `python3 tests/e2e/validate_m3_c717.py --self-test`

Required correction: define known-violation precedence, enumerate all nine
state combinations, and independently validate the complete table.
