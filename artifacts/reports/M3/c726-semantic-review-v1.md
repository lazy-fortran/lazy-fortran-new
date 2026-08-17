# C726 focused semantic review v1

Verdict: `NEEDS FIX`

The packet's declared source span `217828:422` ends at byte `218250`, which is
the start of canonical line 3461. The fixture cites line 3461 but the span
therefore excludes its text. The contract must use a span ending through the
content of that line and the validator must assert the cited-line coverage.

Evidence inspected:

- `tests/e2e/validate_m3_c726.py`
- `tests/fixtures/m3-c726-source-backed-v0.json`
- `artifacts/traces/m3-c726-source-backed-v0.json`
- `.cache/runs/E0194/R000002/result.json`
- the pinned canonical text and page index

The 21-state truth table, mutation controls and non-claims were otherwise
within the declared bounded scope. This review does not cover full C726,
parsing, context inference or semantic-fact promotion.
