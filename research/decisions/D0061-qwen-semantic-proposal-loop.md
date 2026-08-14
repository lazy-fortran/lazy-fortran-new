# D0061 — Use Qwen as a bounded semantic-fragment proposer

Status: accepted
Date: 2026-08-14

## Context

E0115 closed source-backed name/evidence acquisition, but its pointer-only
protocol did not formalize constraint bodies. M3 therefore needs a protocol
that can process the complete Core 0 constraint denominator without moving
source lookup, schema ownership or compiler wiring into the model.

## Decision

Run one local Qwen 3.6 35B-A3B checkpoint as a bounded semantic-fragment
proposer. Each episode receives one source-backed constraint and may use bounded
source tools. It may submit only a typed JSON predicate, subject,
applicability, fact names and optional witness labels.

The deterministic gate owns the constraint denominator, source spans, document
and canonical hashes, rule associations, predicate constructor allowlist,
fact-name syntax, prior accepted-control comparisons, replay and mutation
checks. Every row has a terminal record. Failed proposals are repaired within
the declared turn budget; after that the row remains unresolved. No model
output changes parser productions, StandardIR wiring or production source.

Accepted proposals are evidence for the semantic ledger, not automatically
promoted rules. Promotion requires a later independent behavioral witness gate.
The first complete run processes all constraint occurrences; a repeated
cross-reference is classified deterministically as `reference-only` rather
than treated as a second rule body.

## Rejected

- Run the full Qwen/Gemma matrix before establishing the semantic protocol.
- Let Qwen invent source locations, hashes, citations or dependency wiring.
- Accept free-form prose or arbitrary executable code as a semantic rule.
- Drop a failed row or treat model abstention as semantic success.
- Add a mechanical branch for each failed constraint instead of extending a
  repeated generic schema or source pattern.

## Reversal condition

Reverse this protocol if the fixed predicate schema cannot represent recurring
standard constraint forms with less implementation than corresponding rule
text, or if the source/schema/replay gates accept materially unsupported
predicates. Extend the schema only through a new decision record and a
negative-controlled experiment.
