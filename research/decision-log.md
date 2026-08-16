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

## 2026-08-16 — L0 replay boundary classification correction

The current L0 replay passed its local deterministic, negative, mutation and
independent-oracle checks. The contract review correctly found that the
runner's component-local generator fixture was not mapped to the central
`standardir-v0` contract. D0022 and D0027 show that such a mapping would be
the wrong repair: the local schema is not complete StandardIR and lexical
facts are a separate projection. L0 is therefore explicitly classified as a
component-local generator slice. The earlier review remains immutable; a new
integration review must verify this narrower, accurate boundary before L0 is
promoted. No GPT-Sol consultation is triggered.

## 2026-08-16 — L0 promoted after boundary and review reconciliation

The corrected L0 runner declares the component-local generator boundary,
rejects a false central StandardIR claim, clears ignored component build
state, pins the exact `fo` executable, records the toolchain and boundary in
the trace, and compares the generated trace with the committed trace. The
local verifier passed and all four independent Luna lanes passed against the
reconciled candidate. The v2 reports remain immutable historical evidence;
the v3 reports are the active evidence. L0 is promoted and L1 is the next
replay gate. No L2 work has started.

## 2026-08-16 — L1 promoted after oracle and attribution repair

The first L1 review found two concrete evidence defects: the independent
oracle did not inspect the malformed neighbor, and the runner trusted
component revisions from the fixture manifest without comparing them with the
actual checkout `HEAD`s. The runner now hashes and structurally checks the
malformed fixture in the independent oracle, verifies both actual checkout
revisions before tracing, cleans ignored component build trees, pins `fo`, and
requires byte-identical committed trace output. The corrected replay and all
four independent Luna lanes passed. The v1 reports remain immutable failure
evidence; the v2 reports are active. L1 is promoted and L2 is now the open
active task.

## 2026-08-16 — first L2 execution boundary

The initial boundary was accepted as [D0121](decisions/D0121-first-executable-rv64-slice.md)
and then narrowed by [D0122](decisions/D0122-narrow-l2-boundary.md) after the
independent L2 reviews found that serialized TargetIR/emission values were not
actually crossed. The active slice is the smallest real path from a pinned
`frontend-v0` witness through canonical `mir-v0` SX to bounded RV64 Linux
emission and a QEMU runtime oracle. It deliberately does not claim source
parsing, StandardIR conversion, serialized TargetIR/emission interchange,
general instruction selection, a complete ABI, or full Fortran compilation.
