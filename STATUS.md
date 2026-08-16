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

The result must have an independent oracle. This is an open delivery target,
not a claim that the complete standard or compiler is implemented. L2 is now
promoted; M1-M2 is the next open delivery target.

## Component pins

These are the clean component revisions currently pinned by the control plane.
Verify the table
with `scripts/check_pins.sh` after changing a component pin.

| Component | Repository | Commit | Purpose | Local verification |
|---|---|---|---|---|
| standard-new | lazy-fortran/standard-new | `03719c6ebea7dcfc3e88d2a0997ea8935209d235` | normative source → StandardIR | clean main; full `fo` recorded in lane evidence |
| fortfront-new | lazy-fortran/fortfront-new | `fc828b237c7c7d3962ccdcff6faf629266aaf8de` | frontend | clean main; L1 consumer verified |
| ffc-new | lazy-fortran/ffc-new | `5a82330dc2eff870792c0de8cd7cea8d13e7a8fb` | compiler driver and middle end | clean main; MIR-v0 CLI bridge |
| fortback-new | lazy-fortran/fortback-new | `181715ac2fa04b0682db24564126dee882cac345` | backend | clean main; bounded RV64 Linux executable bridge and CLI boundary test |

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
- M1-M2: `OPEN`; no promotion evidence exists yet. The next task is the
  central source-backed grammar gate selected by `D0123`.

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

ID: T-M1M2-source-backed-fixture — define the first central source-backed
StandardIR grammar gate.

Boundary decision: `research/decisions/D0123-m1m2-central-source-gate.md`.

Expected observable: a pinned, retrieved source artifact and a deterministic
StandardIR grammar projection with source identity, lexical, four-format and
parser-generator checks plus positive, negative and mutation controls.

Oracle: the normative source artifact, independent projection validators and
the source-to-target witness required by `docs/oracle-policy.md`.

## Current blocker

The L2 boundary is promoted. M1-M2 has no central source-backed fixture,
retrieval manifest or executable verifier yet; historical cached replays are
not current clean-checkout evidence. The next task is to establish that gate
without vendoring external source material.

## Next executable task

Implement the central source-backed M1-M2 gate as
`T-M1M2-source-backed-fixture`; do not begin parser-conflict reduction or
semantic/model work before its source, projection and clean-checkout verifier
are defined.

## Last verified central command

```text
Current L0 replay and four-lane review: PASS.
Current L1 replay and four-lane review: PASS.
Current L2: corrected central execution gate `R000441` `PASS`; focused
promotion review `R000444` `PASS`; L2 is promoted and M1-M2 is now open.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
