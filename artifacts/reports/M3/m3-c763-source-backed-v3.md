# C763 bounded source-backed replay, final pin-aligned evidence

Replay status: `PASS-BOUNDED-ONLY`.

This replay supersedes R000639 after the final focused review found that the
experiment’s separate `implementation_commit` field still named the old
intermediate revision. Both the repository pin and implementation pin now
resolve to `7d93cd1e46105a62ea759071c10c7c083d7ed551`, and the replay below
uses that implementation/evidence revision through the clean central checkout.

The validator checks complete schema and contract-witness field equality,
requires the exact fixture mutation inventory, and keeps its decision
procedure independent of the mechanical expected-outcomes table. The
candidate fixture is labelled `LLM` intake; expected outcomes, result and
trace are `MECHANICAL`.

The implementation classifies the complete 3-by-3 product of supplied
`pass_argument_state` (`present`, `absent`, `unknown`) and
`dummy_name_relation` (`matching`, `nonmatching`, `unknown`). It returns
`ACCEPTED` when PASS(arg-name) is absent or the supplied name matches,
`REJECTED` when PASS(arg-name) is present and the name is nonmatching, and
`UNRESOLVED` otherwise. It does not parse Fortran or infer interfaces, scopes
or names.

Source binding: J3-24-007 C763/R741, canonical lines 3874--3875, byte span
`243182:139`, printed page 79, PDF/ledger page 94, page-index
`94:242409:2660`, StandardIR R741@91, R742@92, R603@31 and R1534@509.

Exact command:

```text
M3_C763_EXPECTED_CENTRAL_COMMIT=5f0f610cb3c3aa24cdae40a880de0e3fd3279962 C763_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new tests/e2e/run-m3-c763.sh --fresh
```

R000640 passes with 9 states: 4 `ACCEPTED`, 1 `REJECTED` and 4
`UNRESOLVED`; all 15 mutation controls reject; registry, trace comparison and
clean central/standard-new state pass; model calls and semantic promotions are
0. This is bounded-oracle evidence only; full M3 remains open.

Evidence:

* result and trace SHA-256:
  `110fadb92abcf50a28fb0248c8d1636009bbf0f36b833fc3a1efc760d7fe8223`
* run environment SHA-256:
  `a485e010c9c94e14e4b8d7f313103cf2bf5e5f068875c989ad070848738e38ca`
* validator SHA-256:
  `de90ca0d373dccaec7da851e4001fa6143d344d142909998473fa8da15e84d65`
* run: `research/runs/2026-08.jsonl#R000640`
