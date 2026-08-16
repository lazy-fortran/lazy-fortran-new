# Lazy Fortran delivery status

## Active milestone

M1-M2 — source-valid StandardIR and sane generated grammars

## Central goal

Progress through the cross-repository delivery path from normative source to
an executable compiler observable:

```text
normative source fact
→ standard-new artifact
→ frontend contract
→ StandardIR
→ downstream contract
→ deterministic observable
```

The result must have an independent oracle. This remains a bounded delivery
target, not a claim that the complete standard or compiler is implemented. L2
is promoted; the M1-M2 central gate has passed and its final promotion metadata
review is in progress.

## Component pins

These are the clean component revisions currently pinned by the control plane.
Verify the table
with `scripts/check_pins.sh` after changing a component pin.

| Component | Repository | Commit | Purpose | Local verification |
|---|---|---|---|---|
| standard-new | lazy-fortran/standard-new | `03719c6ebea7dcfc3e88d2a0997ea8935209d235` | normative source → StandardIR | clean main; full `fo` recorded in lane evidence |
| fortfront-new | lazy-fortran/fortfront-new | `73cf2af7a1ee7c13bae302868dc1595aa4ed0a79` | frontend | clean main; registered L2 frontend trace |
| ffc-new | lazy-fortran/ffc-new | `bcaadcb58c24af613204aa398541c0d2e35abf91` | compiler driver and middle end | clean main; registered L2 MIR trace |
| fortback-new | lazy-fortran/fortback-new | `c578904a8d18e9d5410934f5489a21d5dadfad05` | backend | clean main; registered L2 executable trace |

## Historical milestone evidence

L0 was recorded as passed by `R000437`. The pinned
`standard-new/specs/lexical-facts-v0.sx` source regenerated a deterministic
canonical SX output and generated schema artifact. The reviewed golden and
independent oracle passed; the malformed neighbor produced `unclosed SX list`;
the source-hash mutation was rejected by the oracle. See
`artifacts/traces/l0-lexical-slice-v0.json`.

L1 was recorded as passed by `R000438`. The pinned `standard-new`
canonicalized the two-rule StandardIR grammar fixture and the pinned
`fortfront-new` grammar frontier accepted `PROGRAM` and rejected `BAD`; the
malformed StandardIR neighbor and independent oracle passed. See
`artifacts/traces/l1-frontend-slice-v0.json`. This remains historical evidence,
not current promotion evidence.

## Current verification state

- L0: `PASS`. The corrected component-local boundary replay, independent
  oracle, clean-build/toolchain checks, deterministic outputs, committed trace
  comparison, and all four independent Luna reviews pass. The v2 reports are
  retained historical evidence; the v3 reports are the active review evidence.
- L1: `PASS`. The corrected replay and all four independent Luna reviews pass;
  v1 reports retain the two repaired review failures and v2 reports are the
  active evidence.
- L2: `PASS`; the corrected bounded central execution gate is `PASS` in
  `R000441`. The first fresh review wave is retained as `R000442`; three lanes
  passed and the oracle lane found that recorded tool/runtime pins were not
  consumed as the evidence authority. The runner and oracle now consume those
  pins and the runtime expectation. The next review wave, `R000443`, found
  stale state wording, an unvalidated runtime-oracle identity, and an
  incomplete reproducibility trace. Those corrections are committed in
  the current clean checkout; its central gate passes and three valid focused
  Luna scopes pass in `R000444`. The promotion reports are retained under
  `artifacts/reports/L2/replay-v4-luna-*.md`.
- M1-M2: `OPEN` pending final metadata review. The central source-backed gate
  passes in `R000450`; its fixture, regression corpus, trace, exact environment
  record and failed review history are retained under `artifacts/` and
  `research/runs/2026-08.jsonl`. `R000452` found stale control-plane wording;
  no source, grammar or oracle defect remains open.

The L0 runner currently consumes `standard-new/specs/lexical-facts-v0.sx`
and the component's `specs/schema-v0.sxs` generator fixture. It is now
explicitly classified as a component-local generator boundary, not as a
consumer of central `contracts/standardir-v0.sxs`; the accepted D0022
decision says that local schema is not the complete StandardIR contract. The
recorded L1 run predates the commit containing its final central inputs; the
current replay supersedes it for promotion purposes. L2's active claim is
limited to the pinned `frontend-v0` witness → canonical `mir-v0` SX → bounded
RV64 Linux ELF → QEMU exit status and independent code-word checks. It does
not claim source parsing, StandardIR conversion, or serialized TargetIR and
emission contract interchange.

## Active fixture

ID: T-M1M2-source-backed-fixture — central source-backed StandardIR grammar
gate; the verifier passes in `R000450` and final promotion metadata is pending.

Boundary decision: `research/decisions/D0123-m1m2-central-source-gate.md`.

Expected observable: a pinned, retrieved source artifact and a deterministic
StandardIR grammar projection with source identity, lexical, four-format and
parser-generator checks plus positive, negative and mutation controls.

Oracle: the normative source artifact, independent projection validators and
the source-to-target witness required by `docs/oracle-policy.md`.

## Current blocker

The L2 boundary is promoted. The M1-M2 source-backed fixture, retrieval
manifest and executable clean-checkout verifier pass in `R000450`. The current
blocker is reconciliation of the authoritative promotion metadata after the
`R000452` integration review; M3 remains blocked until this milestone closes.

## Next executable task

Reconcile the M1-M2 promotion metadata and rerun the focused integration
review. Do not begin parser-conflict reduction or semantic/model work before
the bounded M1-M2 gate is promoted.

## Last verified central command

```text
Current L0 replay and four-lane review: PASS.
Current L1 replay and four-lane review: PASS.
Current L2: corrected central execution gate `R000441` `PASS`; focused
promotion review `R000444` `PASS`; L2 is promoted. M1-M2 central replay
`R000450` is `PASS`; final metadata review `R000452` is the open correction.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
