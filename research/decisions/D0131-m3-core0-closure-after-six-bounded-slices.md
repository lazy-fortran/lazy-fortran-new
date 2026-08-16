# D0131. Six bounded slices do not close full M3/Core 0

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The C1106, C702, C601, C603, C721 and C725 bounded contracts now pass their
central replays and focused independent reviews. The authoritative M3
definition in `ROADMAP.md` additionally requires a complete 287-row Core 0
semantic ledger and a behavioral witness gate for any promoted subset.

## Decision

Keep M3/Core 0 `OPEN`. The E0181 deterministic closure audit reproduces the
retained E0123 merge, validation and witness gates but reports 4 hard failures,
2 unresolved rows, 94 disputed witness rows, 69 unwitnessed rows and zero
semantic promotions. These counts are a precise remaining evidence gap, not a
reason to reinterpret model self-consistency as an oracle.

The next executable slice is C718 over the already represented R709 shape:
`scalar-int-constant-name` shall denote a named constant of type integer. Its
bounded oracle must carry only typed named-constant and type states, retain
normative provenance, and produce `ACCEPTED`, `REJECTED` or `UNRESOLVED` with
independent positive, negative and unknown witnesses. It must not perform
general name resolution, type checking, model inference or compiler wiring.

## Rejected

* Promoting the six bounded contracts as the complete Core 0 semantic ledger.
* Restarting E0172 or any broad model comparison after its runtime identity
  failure.
* Treating the 117 self-consistent model witness rows as independent semantic
  facts; D0069 explicitly rejects that promotion path.

## Reversal condition

Write a successor if the C718 property cannot be bound to R709 without
general name/type analysis, or if E0181's retained counts are contradicted by
a clean replay of the declared deterministic command.

## Evidence

* `ROADMAP.md` M3 closure definition and the six bounded contract sections.
* `artifacts/reports/M3/m3-core0-closure-audit-v1.md`.
* `research/runs/2026-08.jsonl#R000032`.
* `.cache/runs/E0181/R000001/analysis/report.json`.
* `research/decisions/D0069-model-witnesses-before-independent-promotion.md`.
