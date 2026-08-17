# C763 bounded source-backed replay, corrected gate

Replay status: `PASS-BOUNDED-ONLY`.

## Correction

The first focused review found that the initial validator checked only selected
schema/witness substrings and did not require the fixture mutation inventory.
The corrected validator now checks the complete schema and contract-witness
field lists and requires the fixture's declared mutation controls to equal the
15 controls exercised by self-test. The first replay remains in the append-only
ledger as R000636; this corrected replay is R000637.

## Contract

The implementation classifies the complete 3-by-3 product of supplied
`pass_argument_state` (`present`, `absent`, `unknown`) and
`dummy_name_relation` (`matching`, `nonmatching`, `unknown`). It returns
`ACCEPTED` when PASS(arg-name) is absent or the supplied name matches,
`REJECTED` when PASS(arg-name) is present and the name is nonmatching, and
`UNRESOLVED` otherwise. It does not parse Fortran or infer interfaces, scopes
or names.

The independent expected-outcome table is
`tests/fixtures/m3-c763-expected-outcomes-v0.json`; the validator's decision
procedure is separate. The checked-in candidate fixture is labelled `LLM`
intake, while the result and trace are `MECHANICAL`.

## Source binding

The replay checks J3-24-007 C763/R741 at canonical lines 3874--3875, byte span
`243182:139`, printed page 79, PDF page 94, ledger page 94 and page-index
record `94:242409:2660`. It checks StandardIR R741@91, R742@92, R603@31 and
R1534@509. The canonical, page-index, StandardIR and PDF hashes are pinned in
the experiment manifest and validator.

## Gate

The exact reproducibility command is:

```text
M3_C763_EXPECTED_CENTRAL_COMMIT=7d93cd1e46105a62ea759071c10c7c083d7ed551 C763_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new tests/e2e/run-m3-c763.sh --fresh
```

R000637 passes with 9 states: 4 `ACCEPTED`, 1 `REJECTED` and 4
`UNRESOLVED`. All 15 declared mutation controls are rejected, including the
source/provenance/schema/fixture inventory checks. The committed trace matches
the fresh result, the final central and standard-new checkouts are clean,
model calls are 0 and semantic promotions are 0. This closes only the bounded
oracle leaf; full M3 remains open.

Evidence:

* result and trace SHA-256:
  `110fadb92abcf50a28fb0248c8d1636009bbf0f36b833fc3a1efc760d7fe8223`
* run environment SHA-256:
  `5aaaabdec5f10d6b2436e9174759900011cd92672f15a1a8470a25790c5cdc9e`
* corrected validator SHA-256:
  `de90ca0d373dccaec7da851e4001fa6143d344d142909998473fa8da15e84d65`
* run: `research/runs/2026-08.jsonl#R000637`
