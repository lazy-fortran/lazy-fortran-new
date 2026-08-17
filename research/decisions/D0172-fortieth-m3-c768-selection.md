# D0172. Select C768 as the next bounded property

Date: 2026-08-18
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and independent source audit pass. This
accepts only the C768 source occurrence and a bounded component-initialization
attribute contract target; it does not accept a C768 semantic fact or close
M3.

## Context

After excluding the promoted bounded contracts through C763 and harvested
C760, the pinned witness ledger retains 132 rows: 76 `disputed` and 56
`unwitnessed`. C768@1 is first. Its normative text is J3-24-007 C768/R737:
`If => appears in component-initialization, POINTER shall appear in the
component-attr-spec-list. If = appears in component-initialization, neither
POINTER nor ALLOCATABLE shall appear in the component-attr-spec-list.`

The source is canonical lines 3977--3979, byte span `249918:239`, printed page
82, PDF page 96 and ledger page 96. The page-index record is page 96, start
247480, length 3187. Existing StandardIR R737@87 represents the data-component
definition, R738@88 the component attribute alternatives, R739@89 the
component declaration and R743@93 the initialization operators.

## Decision

Select C768 as the next bounded source-backed slice. The implementation
contract may type a supplied `initialization_operator` as `equals`,
`pointer-assign` or `unknown`, and supplied POINTER and ALLOCATABLE attribute
states as `present`, `absent` or `unknown`. The deterministic oracle may return
`ACCEPTED` for `pointer-assign` with POINTER present, and for `equals` with
both POINTER and ALLOCATABLE absent; it may return `REJECTED` when a known
operator violates its required attribute relation, and `UNRESOLVED` whenever
the supplied states do not determine the property. It must not parse Fortran,
infer declarations or names, call a model or promote a semantic fact.

## Rejected

* Treating Luna harvest material as source authority or an expected-outcome
  oracle.
* Starting general component-declaration parsing, type checking, name
  resolution, E0172 or full M3 semantic work.
* Treating unknown POINTER, ALLOCATABLE or initialization-operator states as
  absent or present.

## Reversal condition

Write a successor if the residual ordering, source coordinates, R737/R738/R739/
R743 binding or finite initialization-attribute target cannot be independently
reproduced, or if a bounded implementation requires information not
represented by the pinned StandardIR shapes.

## Evidence

* `research/experiments/E0232-which-residual-source-occurrence-should-/manifest.yaml`
  records the pinned partition, source artifacts and gate.
* `artifacts/reports/M3/m3-core0-next-property-selection-v28.md` records the
  deterministic partition and source audit.
* `research/runs/2026-08.jsonl#R000644` records this selection.
