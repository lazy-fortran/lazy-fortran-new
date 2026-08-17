# D0168. Select C759 as the next bounded property

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and independent source audit pass. This
accepts only the selection of the C759 source occurrence and its bounded
contract target; it does not accept a C759 semantic fact or close M3.

## Context

After C757 and the harvested C760 leaf, the pinned witness ledger leaves 136
rows: 79 `disputed` and 57 `unwitnessed`. C759@1 is first. Its source is
J3-24-007 C759/R736, whose rule states that a `type-param-value` in a
`component-def-stmt` is a colon or a component specification expression.

## Decision

Select C759 as the next bounded source-backed slice. A later delivery contract
may use a typed opaque value-kind axis for `colon`, `component-specification`
and `unknown`, with any unclassified value kept as a negative neighbour or
`UNRESOLVED` until its source-backed representation is independently fixed.
The contract must reuse R736 and the existing type-parameter representation
where possible; it must not parse Fortran or infer semantic facts from the
Luna harvest.

## Rejected

* Treating the harvest's three cases as semantic evidence.
* Treating the abstract `component-specification` category as already
  implemented StandardIR without a further source/representation check.
* Starting general parsing, expression semantics, E0172, or full M3 work.

## Reversal condition

Write a successor if the source coordinates, R736 binding, residual ordering or
the finite typed representation cannot be independently reproduced, or if the
next delivery contract requires a different bounded property.

## Evidence

* `research/experiments/E0226-can-a-bounded-source-backed-oracle-class/manifest.yaml`
  records the pinned question, denominator, metrics and gate.
* `artifacts/reports/M3/m3-core0-next-property-selection-v24.md` records the
  partition and source audit.
* `research/runs/2026-08.jsonl#R000625` records the pushed C757 regression
  that is a prerequisite for this selection.
