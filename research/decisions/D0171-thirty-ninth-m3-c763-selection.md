# D0171. Select C763 as the next bounded property

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and independent source audit pass. This
accepts only the C763 source occurrence and a bounded conditional-name
contract target; it does not accept a C763 semantic fact or close M3.

## Context

After excluding the promoted bounded contracts through C762 and harvested
C760, the pinned witness ledger retains 133 rows: 77 `disputed` and 56
`unwitnessed`. C763@1 is first. Its normative text is J3-24-007 C763/R741:
`If PASS (arg-name) appears, the interface of the procedure pointer component
shall have a dummy argument named arg-name.`

The source is canonical lines 3874--3875, byte span `243182:139`, printed page
79, PDF page 94 and ledger page 94. The page-index record is page 94, start
242409, length 2660. Existing StandardIR R741, occurrence 91, represents the
procedure component definition; R742, occurrence 92, represents the attribute
choice including `PASS (arg-name)`. R603@31 and R1534@509 provide the existing
name and dummy-argument-name representation witnesses without requiring parser
or name-resolution work.

## Decision

Select C763 as the next bounded source-backed slice. The implementation
contract may type a supplied `pass_argument_state` as `present`, `absent` or
`unknown`, and a supplied `dummy_name_relation` as `matching`, `nonmatching` or
`unknown`. The deterministic oracle may return `ACCEPTED` when PASS(arg-name)
is absent or the supplied dummy name matches; `REJECTED` when PASS(arg-name) is
present and the supplied name is nonmatching; and `UNRESOLVED` otherwise. It
must keep the implication and name relation explicit, must not parse Fortran,
infer interfaces or scopes, call a model, or promote a semantic fact.

## Rejected

* Treating Luna fixture material as source authority or an expected-outcome
  oracle.
* Starting procedure-interface parsing, name resolution, general semantic
  analysis, E0172 or full M3 work.
* Treating an absent or unresolved name representation as proof of a mismatch;
  such states remain typed and are handled by the three-outcome oracle.

## Reversal condition

Write a successor if the residual ordering, source coordinates, R741/R742
binding or finite conditional-name target cannot be independently reproduced,
or if the bounded implementation requires information not represented by the
pinned StandardIR shapes.

## Evidence

* `research/experiments/E0230-which-residual-source-occurrence-should-/manifest.yaml`
  records the pinned partition, source artifacts and gate.
* `artifacts/reports/M3/m3-core0-next-property-selection-v27.md` records the
  deterministic partition and source audit.
* `research/runs/2026-08.jsonl#R000635` records this selection.
