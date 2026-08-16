# Lazy Fortran delivery status

## Active milestone

L2 — first compiled execution slice

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
not a claim that the complete standard or compiler is implemented. L2 is not
complete until its own end-to-end execution gate passes.

## Component pins

These are the clean component revisions currently pinned by the control plane.
Verify the table
with `scripts/check_pins.sh` after changing a component pin.

| Component | Repository | Commit | Purpose | Local verification |
|---|---|---|---|---|
| standard-new | lazy-fortran/standard-new | `03719c6ebea7dcfc3e88d2a0997ea8935209d235` | normative source → StandardIR | clean main; full `fo` recorded in lane evidence |
| fortfront-new | lazy-fortran/fortfront-new | `fc828b237c7c7d3962ccdcff6faf629266aaf8de` | frontend | clean main; L1 consumer verified |
| ffc-new | lazy-fortran/ffc-new | `32538492ba10de8d6c8745b71da372ebd5b6db36` | compiler driver and middle end | clean main; central L0 use not wired |
| fortback-new | lazy-fortran/fortback-new | `a149015b8592b6c4c96b513171c1002f7654545b` | backend | clean main; central L0 use not wired |

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
- L2: `OPEN` and not yet implemented. It is the active dependency-ready task.

The L0 runner currently consumes `standard-new/specs/lexical-facts-v0.sx`
and the component's `specs/schema-v0.sxs` generator fixture. It is now
explicitly classified as a component-local generator boundary, not as a
consumer of central `contracts/standardir-v0.sxs`; the accepted D0022
decision says that local schema is not the complete StandardIR contract. The
recorded L1 run predates the commit containing its final central inputs; the
current replay supersedes it for promotion purposes. No L2 execution claim is
made yet.

## Active fixture

ID: T-L2-vertical-slice — deliver the first frontend-to-executable path.

Candidate family: to be created under `tests/fixtures/` after the component
interfaces are fixed.

Boundary decision: `research/decisions/D0121-first-executable-rv64-slice.md`.

Expected observable: a runnable artifact and independently verified runtime
result, with the complete source-to-frontend-to-MIR-to-backend trace.

Oracle: an independent runtime/result oracle plus the component and contract
oracles required by `docs/oracle-policy.md`.

## Current blocker

No L2 central runner or executable fixture exists yet. This is an open
implementation task, not a blocker in the terminal mission.

## Next executable task

Define the smallest runnable target and implement its cross-repository runner;
do not add a second source feature family while this first execution slice is
incomplete.

## Last verified central command

```text
Current L0 replay and four-lane review: PASS.
Current L1 replay and four-lane review: PASS.
Current L2: `OPEN`; no execution runner has passed.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
