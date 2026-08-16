# Lazy Fortran delivery status

## Active milestone

L0 — normative lexical slice (current replay gate)

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
started while the current L0/L1 replay gate is open.

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

- L0: `NEEDS REPLAY`. `R000437` is retained historical evidence.
- L1: `NEEDS REPLAY`. `R000438` is retained historical evidence.
- L2: `NOT STARTED` and blocked by the L0/L1 replay gate.

The existing L0 and L1 runners check clean sibling component pins but do not
assert a clean central checkout before execution. The recorded L1 run also
predates the commit containing its final central inputs. No replay is claimed
by this audit.

## Active fixture

ID: T-L0-replay-current — replay the existing L0 fixture from the current
clean central checkout.

Candidate family: `tests/fixtures/l0-lexical-slice.toml`, followed only after
its PASS by `tests/fixtures/l1-frontend-slice.toml`.

Expected observable: the existing L0 deterministic StandardIR artifact,
reviewed golden, negative diagnostic and mutation rejection.

Oracle: `tests/e2e/oracle_l0.py` and the existing L0 negative/mutation gates.

## Current blocker

No current replay has established the L0/L1 evidence from this central
checkout, and no central L2 runner binds the frontend artifact to the pinned
driver/backend path.

## Next executable task

Run `scripts/run_e2e.sh` from a clean central checkout. If it passes, promote
only the replay task and make `tests/e2e/run-l1.sh` the next active verifier.
Do not implement L2 in this audit.

## Last verified central command

```text
Historical PASS — `scripts/verify_active_milestone.sh` for L1; see `R000438`.
Current replay: `NEEDS REPLAY`.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
