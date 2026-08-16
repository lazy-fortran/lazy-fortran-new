# L0 current replay — Luna contract review

- Snapshot: `d268f7f`
- Lane: contract and interface
- Verdict: `FAIL`
- Command inspected: `scripts/run_e2e.sh`
- Evidence inspected: `contracts/standardir-v0.sxs`,
  `standard-new/specs/schema-v0.sxs`,
  `standard-new/specs/lexical-facts-v0.sx`,
  `tests/e2e/run-l0.sh`, and the L0 trace.

The component pins are explicit and clean, but the L0 runner consumes
`standard-new`'s lexical-facts source and local schema without declaring or
checking a mapping to the central `contracts/standardir-v0.sxs` contract.
The two schemas differ materially while carrying the same `standardir-v0`
identity. `scripts/check-contracts.sh` validates the central contract in
isolation, not this cross-repository compatibility boundary.

Promotion is blocked until the actual L0 boundary is explicitly declared and
an executable central check consumes it.
