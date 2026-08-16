# Lazy Fortran delivery status

## Active milestone

L0 — first normative-source-to-observable compiler slice

## Central goal

A minimal source fixture must traverse the declared pipeline:

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

These are the clean component revisions at the start of L0. Verify the table
with `scripts/check_pins.sh` after changing a component pin.

| Component | Repository | Commit | Purpose | Local verification |
|---|---|---|---|---|
| standard-new | lazy-fortran/standard-new | `03719c6ebea7dcfc3e88d2a0997ea8935209d235` | normative source → StandardIR | clean main; full `fo` recorded in lane evidence |
| fortfront-new | lazy-fortran/fortfront-new | `41908855f26b28f95619faf96d33cb1d27f80273` | frontend | clean main; central L0 use not wired |
| ffc-new | lazy-fortran/ffc-new | `32538492ba10de8d6c8745b71da372ebd5b6db36` | compiler driver and middle end | clean main; central L0 use not wired |
| fortback-new | lazy-fortran/fortback-new | `a149015b8592b6c4c96b513171c1002f7654545b` | backend | clean main; central L0 use not wired |

## Active fixture

ID: OPEN — choose the smallest existing fixture before implementation.

Candidate family: `contracts/fixtures/lexical-layout-v2.sx`.

Expected observable: OPEN — must be fixed before implementation and recorded
with its oracle.

Oracle: OPEN — normative, reviewed golden, differential or metamorphic.

## Current blocker

No central runner yet binds one source fixture, the pinned `standard-new`
artifact, the declared contracts, stage traces and an independent oracle.

## Next executable task

Choose the smallest existing fixture and implement the central L0 runner. It
must fail closed until the fixture, expected observable and oracle are named.

## Last verified central command

```text
NOT RUN — the L0 runner is not wired yet.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
