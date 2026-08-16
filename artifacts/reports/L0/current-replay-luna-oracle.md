# L0 current replay — Luna oracle review

- Snapshot: `d268f7f`
- Lane: oracle independence
- Verdict: `PASS`
- Command inspected: `scripts/run_e2e.sh`
- Evidence inspected: `tests/e2e/oracle_l0.py`,
  `tests/fixtures/l0-lexical-slice.toml`, the reviewed golden, and the L0
  trace.

The Python oracle does not import the SX implementation under test. It fixes
the five expected lexical facts, source document hash, output hash, generated
schema surface, and mutation behavior independently. The malformed input is
also required to be rejected with the expected diagnostic. The oracle is
adequate for the narrow fixture and does not establish a broader conformance
claim.
