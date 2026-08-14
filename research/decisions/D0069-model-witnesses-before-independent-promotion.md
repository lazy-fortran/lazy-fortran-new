# D0069 — Require concrete model witnesses before independent semantic promotion

Date: 2026-08-14
Status: accepted
Amends: D0061

## Context

E0116 produced source/schema-accepted proposals but no concrete test cases.
Consequently the independent witness stage could exercise only one previously
known exception form and left 285 accepted proposals unwitnessed. A predicate
without a concrete assignment and expected outcome is difficult to test and
cannot be promoted merely because it passed the structural gate.

## Decision

The next semantic protocol requires each accepted primary proposal to include
one to eight labelled fact maps with Boolean expected outcomes. A deterministic
evaluator checks the submitted predicate against those maps and records
`self-consistent`, `disputed` or `unwitnessed` separately from schema
acceptance. These cases are candidate test material, not semantic truth: no
StandardIR promotion follows from model self-consistency.

The requirement is an optional protocol mode in the reusable E0116 harness so
the earlier run remains reproducible. The existing source, schema, provenance
and independent-witness gates remain authoritative.

## Rejected

- Treating a model's expected Boolean as an independent oracle.
- Inferring a witness environment from fact names without recording it.
- Promoting every predicate that is structurally valid but has no executable
  behavioral check.

## Reversal condition

Amend this decision if concrete witness maps consistently add no testable
coverage, if the evaluator cannot remain generic without becoming larger than
the semantic rule surface, or if an independently generated witness protocol
supersedes model-supplied cases.
