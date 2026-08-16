# Lazy Fortran delivery status

## Active milestone

L2 — first compiled execution slice

## Central goal

A minimal source fixture must extend the verified L0 path into the frontend:

```text
normative source fact
→ standard-new artifact
→ frontend contract
→ StandardIR
→ downstream contract
→ deterministic observable
```

The result must have an independent oracle. This is an open delivery target,
not a claim that the complete standard or compiler is implemented.

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

## Completed milestones

L0 passed as `R000437` from a clean checkout. The pinned
`standard-new/specs/lexical-facts-v0.sx` source regenerated a deterministic
canonical SX output and generated schema artifact. The reviewed golden and
independent oracle passed; the malformed neighbor produced `unclosed SX list`;
the source-hash mutation was rejected by the oracle. See
`artifacts/traces/l0-lexical-slice-v0.json`.

L1 passed as `R000438` from a clean checkout. The pinned `standard-new`
canonicalized the two-rule StandardIR grammar fixture and the pinned
`fortfront-new` grammar frontier accepted `PROGRAM` and rejected `BAD`; the
malformed StandardIR neighbor and independent oracle passed. See
`artifacts/traces/l1-frontend-slice-v0.json`.

## Active fixture

ID: OPEN — choose the smallest existing fixture before implementation.

Candidate family: smallest existing source-to-MIR or driver fixture that the
pinned `ffc-new` and `fortback-new` revisions can consume.

Expected observable: OPEN — must be fixed before implementation and recorded
with its oracle for L2.

Oracle: OPEN — runtime output, reviewed golden, differential or metamorphic.

## Current blocker

No central L2 runner yet binds the verified frontend artifact to the pinned
driver/backend path and an independently checked executable observable.

## Next executable task

Choose the smallest existing driver/backend-compatible fixture and implement
the central L2 runner. It must fail closed until the fixture, expected runtime
observable and oracle are named.

## Last verified central command

```text
PASS — `scripts/verify_active_milestone.sh` for L1; see `R000438`.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
