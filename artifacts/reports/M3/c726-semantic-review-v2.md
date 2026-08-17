# C726 focused semantic review v2

Verdict: `NEEDS FIX`

The corrected R000502 oracle packet covers the complete source span
`217828:518`, including canonical line 3461, and its 21-state relation,
mutations and non-claims remain within the bounded contract. The packet's
reproduction command, however, expects central commit `78a65ca...` while the
current pushed control-plane revision is `71bd564...`. A fresh replay at the
current immutable revision is required before promotion.

Evidence inspected:

- `tests/e2e/run-m3-c726.sh`
- `tests/e2e/validate_m3_c726.py`
- `tests/fixtures/m3-c726-source-backed-v0.json`
- `artifacts/traces/m3-c726-source-backed-v0.json`
- `.cache/runs/E0194/R000004/result.json`
- `.cache/runs/E0194/R000004/run-environment.json`
- `git rev-parse HEAD` and `git ls-remote origin refs/heads/main`

This review covers the bounded C726 relation only. It does not cover full
C726, parsing, context inference or semantic-fact promotion.
