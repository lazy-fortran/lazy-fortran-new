# D0135. Eleventh M3 slice uses C738 abstract requirement

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The tenth bounded M3 slice, C719, is promoted, but full M3/Core 0 remains open
under the E0181 ledger gate. The retained audit still has four hard failures
and two unresolved rows. C738 is an unpromoted hard-failure row whose
normative constraint is a small implication over existing StandardIR syntax
shapes: R726 represents a derived-type definition, R728 its `ABSTRACT`
attribute, R746 the type-bound procedure part, and R752 the `DEFERRED`
binding attribute.

## Decision

Define the eleventh bounded M3 delivery slice as the C738 abstract-requirement
oracle. The typed candidate carries only deferred-binding state and abstract
attribute state:

```text
deferred binding contains/inherits + ABSTRACT present → ACCEPTED
deferred binding absent + ABSTRACT absent/present → ACCEPTED
deferred binding contains/inherits + ABSTRACT absent → REJECTED
unknown deferred-binding or ABSTRACT state → UNRESOLVED
```

The source binding is J3-24-007 C738 at canonical-text lines 3623--3624,
printed page 87, with the R726 constraint occurrence and the existing
StandardIR rows R726, R728, R746 and R752 pinned by exact metadata and source
hashes. Candidate facts are human-authored; no model output can promote a
semantic fact.

Only this implication is evaluated. The oracle does not parse type
definitions, resolve parent types, infer whether a binding is deferred,
perform inheritance analysis, validate extensibility, diagnose source or wire
compiler semantics.

## Rejected

* Restarting E0172 or another broad model experiment.
* Treating the failed E0123 C738 proposal as accepted semantic evidence; it is
  retained only as residual selection evidence.
* Inferring deferred-binding or abstract states from source text in this
  slice; those are typed candidate inputs and remain outside the oracle.

## Reversal condition

Write a successor if C738 cannot bind to the two canonical source lines and
the pinned R726/R728/R746/R752 StandardIR shapes without type-definition or
inheritance analysis, or if a clean replay contradicts the source identity or
independent oracle outcomes.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` lines 3623--3624.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R726, R728,
  R746 and R752.
* `.cache/runs/E0181/R000001/analysis/merged/selected-rows.jsonl` C738@1,
  retained as historical hard-failure evidence.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
* `research/decisions/D0134-tenth-m3-c719-kind-param-nonnegative-oracle.md`.
