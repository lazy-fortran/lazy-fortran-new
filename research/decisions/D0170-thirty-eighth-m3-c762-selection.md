# D0170. Select C762 as the next bounded property

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and independent source audit pass. This
accepts only the C762 source occurrence and a bounded conditional NOPASS
contract target; it does not accept a C762 semantic fact or close M3.

## Context

After excluding the promoted bounded contracts through C761 and harvested C760,
the pinned witness ledger retains 134 rows: 78 `disputed` and 56
`unwitnessed`. C762@1 is first. Its normative text is J3-24-007 C762/R741:
`If the procedure pointer component has an implicit interface or has no
arguments, NOPASS shall be specified.`

The source is canonical lines 3872--3873, byte span `243055:127`, printed page
79 and ledger page 93. The page-index record is page 93, start 239957, length
2451. Existing StandardIR R741, occurrence 91, represents the procedure
component definition and R742, occurrence 92, represents the attribute choice
including `NOPASS`.

## Decision

Select C762 as the next bounded source-backed slice. The implementation
contract may type supplied trigger state as `triggered`, `not-triggered` or
`unknown`, and NOPASS state as `present`, `absent` or `unknown`. It may return
`ACCEPTED` when the trigger is absent or NOPASS is present, `REJECTED` when the
trigger is present and NOPASS is absent, and `UNRESOLVED` whenever the supplied
states do not determine the property. It must keep all states explicit; it
must not parse Fortran, infer interfaces/arguments or use model output.

## Rejected

* Treating the Luna harvest packet as source authority or a promoted fact.
* Starting procedure-interface parsing, argument analysis, name resolution,
  E0172 or full M3 semantic work.
* Treating absent representation of interface or arguments as a fact rather
  than preserving `UNRESOLVED`.

## Reversal condition

Write a successor if the residual ordering, source coordinates, R741/R742
binding or finite conditional-NOPASS target cannot be independently reproduced,
or if a bounded implementation requires information not represented by the
pinned StandardIR shapes.

## Evidence

* `research/experiments/E0229-which-residual-source-occurrence-should-/manifest.yaml`
  records the pinned partition, metrics and gate.
* `artifacts/reports/M3/m3-core0-next-property-selection-v26.md` records the
  deterministic partition and source audit.
* `research/runs/2026-08.jsonl#R000632` records this selection.
