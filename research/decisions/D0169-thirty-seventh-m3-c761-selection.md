# D0169. Select C761 as the next bounded property

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and independent source audit pass. This
accepts only the C761 source occurrence and a bounded pointer-presence
contract target; it does not accept a C761 semantic fact or close M3.

## Context

After excluding the promoted bounded contracts through C759 and the harvested
C760 leaf, the pinned witness ledger retains 135 rows: 79 `disputed` and 56
`unwitnessed`. C761@1 is first. Its normative text is J3-24-007 C761/R741:
`POINTER shall appear in each proc-component-attr-spec-list.`

The source is canonical line 3871, byte span `242981:74`, printed page 79 and
ledger page 93. The page-index record is page 93, start 239957, length 2451.
The existing StandardIR source occurrence is R741, occurrence 91, with lhs
`proc-component-def-stmt`, page 94 and byte span `242577:118`; R742 supplies
the existing `POINTER` attribute alternative.

## Decision

Select C761 as the next bounded source-backed slice. The implementation
contract may type the supplied attribute-list state as `pointer-present`,
`pointer-absent` or `unknown`, returning `ACCEPTED`, `REJECTED` or
`UNRESOLVED` respectively. It must keep the list state as an explicit input;
it must not parse Fortran or infer the state from model output.

## Rejected

* Treating the Luna harvest packet as source authority or as a promoted fact.
* Starting general parsing, attribute-list construction, name resolution,
  E0172 or full M3 semantic work.
* Accepting an unclassified list state instead of preserving `UNRESOLVED`.

## Reversal condition

Write a successor if the residual ordering, source coordinates, R741 binding
or finite pointer-presence target cannot be independently reproduced, or if a
bounded implementation requires information not represented by the pinned
R741/R742 shapes.

## Evidence

* `research/experiments/E0227-which-residual-source-occurrence-should-/manifest.yaml`
  records the pinned partition, metrics and gate.
* `artifacts/reports/M3/m3-core0-next-property-selection-v25.md` records the
  deterministic partition and source audit.
* `research/runs/2026-08.jsonl#R000629` records this selection.
