# D0161. Thirty-first M3 slice selects C751 coarray allocatable relation

Date: 2026-08-17
Status: proposed
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Decision needed

Accept the C751 bounded delivery contract only after its implementation has a
complete typed outcome table, source/provenance mutation controls, an
independent expected-outcome oracle, clean replay and focused review. This
record selects the property; it does not promote a semantic fact.

## Context

After C750 promotion, the retained E0181 witness ledger has 141 unpromoted
rows: 82 `disputed` and 59 `unwitnessed`. The deterministic partition selects
C751@1 first. C751 is J3-24-007 clause 7, canonical lines 3840--3841, printed
page 79, and byte span `241193:142`:

```text
26 C751 (R737) If a coarray-spec appears, it shall be a deferred-coshape-spec-list and the component shall have
27 the ALLOCATABLE attribute.
```

The span is contained by canonical page-index record 93. Existing StandardIR
provides R737/R739 for the component context and R809/R810/R811 for coarray
shape alternatives. All records cite the pinned J3-24-007 source hash.

## Decision

Define the thirty-first bounded M3 delivery contract over:

```text
coarray-spec: absent | deferred-coshape-list | explicit-coshape-spec | unknown
allocatable-attribute: absent | present | unknown
```

The fixed context is a data component represented by R737/R739. The
deterministic oracle shall be:

```text
coarray-spec=absent                                      ACCEPTED
coarray-spec=deferred-coshape-list, allocatable=present  ACCEPTED
coarray-spec=deferred-coshape-list, allocatable=absent   REJECTED
coarray-spec=explicit-coshape-spec                       REJECTED
all remaining states                                    UNRESOLVED
```

The implementation must retain the complete 12-state product, positive and
negative neighbours, unresolved states, source/page/rule/identity mutation
controls, and an independently authored expected-outcome table. No model
output can promote a semantic fact.

This selection does not parse component declarations, infer real coarray
shape, resolve names, diagnose arbitrary Fortran, combine C752/C754, or close
full M3.

## Rejected

* Treating the retained model-self-consistency C751 row as semantic evidence.
* Combining C751 with C752, C754 or other coarray constraints.
* Using compiler behavior or a model to decide actual component compliance.
* Treating absence of a coarray-spec as evidence about any unrelated attribute.

## Reversal condition

Write a successor if source/page/StandardIR binding fails, if the typed oracle
cannot distinguish the stated cases without parsing or model output, or if an
independent mutation control is accepted.

## Evidence

* `research/runs/2026-08.jsonl#R000598` records the deterministic post-C750
  selection.
* `artifacts/reports/M3/m3-core0-next-property-selection-v20.md` records the
  exact partition, source span and reusable StandardIR witnesses.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3840--3841, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, records 93, 121 and 122.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R737,
  R739, R809, R810 and R811.
* Pinned witness ledger, canonical text, page-index, StandardIR and normative
  PDF hashes are recorded in E0219 and the selection report.

<!--
This body is immutable once the status is accepted. To change a decision,
write a new record that names this one in Supersedes, Amends or Retracts.
-->
