# D0063 — Replay controls and retry only terminal residuals

Status: amended by D0064
Date: 2026-08-14
Amends: D0062

## Context

The first complete E0116 run processed all 287 occurrences, but all 21
previously accepted controls became unresolved because the model did not know
the canonical nested predicate representation. This is a calibration failure,
not evidence against Qwen's semantic ability. The run also left terminal
unresolved and hard-failure rows that can be retried without repeating already
accepted work.

## Decision

For every known accepted control, the deterministic harness presents the
canonical predicate and fact lists in the system prompt and requires exact
reproduction through the normal source-evidence tool path. The model still
makes the tool call and the gate still compares the submitted JSON; the control
is not silently copied into the result.

Run one bounded adaptive retry over only the prior run's `unresolved` and
`hard_failure` row keys, with the same source/schema gate and a larger declared
turn budget. Merge retry rows by row key only after replay validation; accepted
rows from the first complete pass are not re-run. Keep both attempts and report
the selected terminal result plus the retry delta.

## Rejected

- Count a control that never reproduced its canonical predicate as a model
  failure.
- Re-run the full denominator after every harness correction.
- Retry accepted rows opportunistically or overwrite the first trajectory.
- Treat a larger turn budget as a substitute for the independent witness gate.

## Reversal condition

Reverse this retry policy if control replay causes the model to copy unrelated
predicates, if selected-row merging can accept a row absent from either
validated attempt, or if one bounded retry materially changes the denominator
without an independently recorded reason.
