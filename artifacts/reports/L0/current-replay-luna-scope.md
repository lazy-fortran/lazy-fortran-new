# L0 current replay — Luna scope review

- Snapshot: `d268f7f`
- Lane: milestone truth and scope
- Verdict: `PASS`
- Command inspected: `scripts/run_e2e.sh`
- Evidence inspected: `artifacts/traces/l0-lexical-slice-v0.json`,
  `tests/e2e/oracle_l0.py`, and the L0 fixture manifest.

The replay executes the five-record lexical fixture, deterministic roundtrip
and schema generation, the independent oracle, the malformed negative, and
the source-hash mutation. The evidence supports only the narrow L0 fixture;
it does not claim complete StandardIR or compiler support. This lane is
sufficient for scope, subject to the contract/interface review.
