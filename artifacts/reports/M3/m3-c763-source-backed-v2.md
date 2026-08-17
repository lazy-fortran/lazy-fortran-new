# C763 bounded source-backed replay, pin-corrected

Replay status: `PASS-BOUNDED-ONLY`.

This replay supersedes R000637 after the focused review found that the E0231
repository pin still named `be7872b...` while the corrected validator replay
used `7d93cd1...`. The manifest now pins both `repos.lazy-fortran-new` and
`implementation_commit` to the resolving `7d93cd1...` revision.

The validator retains the earlier hardening: complete schema and
contract-witness field equality, exact fixture mutation inventory, an
independent decision procedure, and the 15 declared mutation controls.

The implementation classifies the complete 3-by-3 product of supplied
`pass_argument_state` (`present`, `absent`, `unknown`) and
`dummy_name_relation` (`matching`, `nonmatching`, `unknown`). It returns
`ACCEPTED` when PASS(arg-name) is absent or the supplied name matches,
`REJECTED` when PASS(arg-name) is present and the name is nonmatching, and
`UNRESOLVED` otherwise. It does not parse Fortran or infer interfaces, scopes
or names. The candidate fixture is labelled `LLM` intake; result, expected
outcomes and trace are `MECHANICAL`.

The source binding remains J3-24-007 C763/R741, canonical lines 3874--3875,
byte span `243182:139`, printed page 79, PDF/ledger page 94, page-index
`94:242409:2660`, and StandardIR R741@91, R742@92, R603@31 and R1534@509.

Exact command:

```text
M3_C763_EXPECTED_CENTRAL_COMMIT=00f3a0c117f5e02d4610505cff408519151a64df C763_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new tests/e2e/run-m3-c763.sh --fresh
```

R000639 passes with 9 states: 4 `ACCEPTED`, 1 `REJECTED` and 4
`UNRESOLVED`; all 15 mutation controls reject; trace comparison, contract
registry, clean central and standard-new state pass; model calls and semantic
promotions are 0. This is bounded-oracle evidence only; full M3 remains open.

Evidence:

* result and trace SHA-256:
  `110fadb92abcf50a28fb0248c8d1636009bbf0f36b833fc3a1efc760d7fe8223`
* run environment SHA-256:
  `48d645b492f279c0cf0934ae368499fc183f4ac7a486b311efbd01e8abc62b3d`
* validator SHA-256:
  `de90ca0d373dccaec7da851e4001fa6143d344d142909998473fa8da15e84d65`
* run: `research/runs/2026-08.jsonl#R000639`
