# Decision log

The immutable decision ledger under `research/decisions/` is authoritative.
This file is the short operational log for recurring delivery failures and
rejected approaches; it must link to the immutable decision when one exists.

## 2026-08-16 — control plane and delivery contract

Accepted by [D0120](decisions/D0120-delivery-contracts-before-frontier.md).
`lazy-fortran-new` owns all cross-repository Goal Mode state. The next target
is one centrally verified L0 slice, not another unconsumed provenance or
correspondence layer.

## 2026-08-16 — L0 delivered

`R000437` was recorded as passed. The central runner consumes the
pinned `standard-new` lexical specification and schema, checks deterministic
roundtrip and generated-schema hashes, verifies a reviewed golden with an
independent Python oracle, rejects an unbalanced negative fixture with its
expected diagnostic, and rejects a source-hash mutation. At the time of that
record L1 was the next active milestone; its later historical result is
`R000438`.

## 2026-08-16 — control-plane replay audit

The historical delivery records `R000437` and `R000438` are preserved. The
current control-plane status is not promoted from those records alone:
`scripts/run_e2e.sh` and `tests/e2e/run-l1.sh` verify clean sibling component
pins but do not establish a clean central checkout before execution, and the
recorded L1 run predates the commit that contains its final central inputs.
Therefore current L0/L1 verification is `NEEDS REPLAY`; L2 is not started.
The next active task is the clean L0 replay, followed by the clean L1 replay.
No provenance or correspondence maintenance is allowed to displace those
verifiers.

## Recurring failure modes

- An audit can be internally consistent and still not prove compiler behavior.
- Component-local green tests do not prove a central contract path.
- A trace without an independent consumer is evidence of execution, not
  correctness.
- A generated artifact must be regenerated and checked, never hand-edited.

## 2026-08-16 — L0 replay contract boundary failure

The current L0 replay passed its local deterministic, negative, mutation and
independent-oracle checks. The four independent Luna reviews then found three
PASS results and one contract/interface FAIL: the runner consumes
`standard-new`'s lexical-facts source and local schema without checking a
mapping to the central `contracts/standardir-v0.sxs` contract. The schemas
differ materially while sharing the same identity. The replay and reviews are
retained; L0 is not promoted, L1 remains blocked, and the next task is the
smallest executable boundary repair. No GPT-Sol consultation is triggered by
this single failure.
