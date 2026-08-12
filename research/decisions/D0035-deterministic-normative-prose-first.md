# D0035. Deterministic normative-prose resolution precedes model escalation

Date: 2026-08-12
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0022 retains 181 unresolved reference names after the complete-core syntax
extraction. E0043--E0046 prove only source-controlled slices: aliases,
lexical facts, assumed expansions and fixed errata. The canonical document
text contains regular definitional forms such as syntax-class definitions,
metanotation declarations and explicit name-role sentences. Those forms are
the next measurable boundary between syntax extraction and semantic prose.

## Decision

Run a deterministic normative-prose recognizer over the pinned canonical text
and the complete E0022 unresolved-name denominator before escalating any
residue to a model. The recognizer may emit candidate source spans classified
as `alias`, `lexical-class`, `metavariable` or `semantic-role`; it emits
`unresolved` when no accepted pattern is found and retains multiple competing
candidate kinds as ambiguous evidence. Every candidate carries the document
hash, canonical line and derived page. A candidate is evidence, not an
accepted StandardIR fact, until a later source-controlled adjudication records
the relation and its reversal condition.

Use exact, named textual patterns rather than suffix heuristics. In
particular, do not infer that every `*-name` term is `name` merely because the
spelling is common. Keep the 181-name denominator intact, use no model calls
in this experiment, and escalate only the residue measured by this pass.

This is autonomous under D0028: one authoritative source, a small mechanical
recognizer, deterministic provenance and a direct path to later specialized
generation are the simplest choice consistent with the evidence.

## Rejected

Sending all unresolved names to a model first is rejected because it would
hide the mechanical fraction and make regular normative conventions
unmeasurable. Promoting comparison-grammar aliases into StandardIR is rejected
by the provenance gate. Inferring relations from spelling alone is rejected
because it creates parser semantics without a normative source span.

## Reversal condition

Write a successor if the deterministic patterns produce repeated false
positives against independently checked source witnesses, fail to preserve
source location or document identity, or if a broader independently annotated
normative corpus shows that the pattern family cannot recover a useful
fraction without source-specific branches. A low mechanical fraction alone is
not a failure; it is the measured boundary for model escalation.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.
-->
