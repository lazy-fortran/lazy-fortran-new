# Decision log

The immutable decision ledger under `research/decisions/` is authoritative.
This file is the short operational log for recurring delivery failures and
rejected approaches; it must link to the immutable decision when one exists.

## 2026-08-16 — control plane and delivery contract

Accepted by [D0120](decisions/D0120-delivery-contracts-before-frontier.md).
`lazy-fortran-new` owns all cross-repository Goal Mode state. The next target
is one centrally verified L0 slice, not another unconsumed provenance or
correspondence layer.

## Recurring failure modes

- An audit can be internally consistent and still not prove compiler behavior.
- Component-local green tests do not prove a central contract path.
- A trace without an independent consumer is evidence of execution, not
  correctness.
- A generated artifact must be regenerated and checked, never hand-edited.
