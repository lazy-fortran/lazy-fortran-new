# D0058. Generic source-relation gate and adaptive local budgets

Date: 2026-08-13
Status: accepted
Amends: D0054, D0057
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The first complete E0115 Qwen 3.5 2B cell and the partial Qwen 3.5 4B
control exposed two different limits. The old gate accepted only prose-shaped
`X is ...` evidence, although the Fortran source also defines syntax through
numbered productions and the explicit assumed rules R401, R402 and R403. The
model could find such evidence but the gate rejected it. Separately, a byte
clamp at a UTF-8 boundary raised a harness exception.

The fixed twelve-turn budget is also a poor operational fit for a sparse
35B-A3B model and a dense 27B model. Their per-turn quality and speed can be
better than a smaller model even when their parameter count is larger.

## Decision

E0115's deterministic gate accepts only source evidence, but its source
relation language has three generic forms:

1. a direct prose or numbered-production definition with the candidate in
   subject position;
2. an instantiation of the source-defined assumed rules R401 (`xyz-list`),
   R402 (`xyz-name`) or R403 (`scalar-xyz`), selected by candidate shape; and
3. a lexical/operator token occurring on the right-hand side of a numbered
   production.

The gate derives the validated source relation and provenance from the cited
bytes. The model still supplies only evidence IDs, and ordinary right-hand
side nonterminals are not accepted merely because they occur in a source
window. Candidate-shape guidance is generated from the generic relation
profile; no candidate-specific rescue branch is added.

Evidence spans are byte-bounded but UTF-8-safe: a clipped incomplete codepoint
is removed from the exposed inner text while the enclosing page and source
provenance remain validated.

For the convergence run, turn limits are predeclared by model class rather
than parameter count alone:

```text
small <= 4B              12 turns
medium 9B or 26B         16 turns
large dense 27B/31B      20 turns
sparse 35B-A3B           20 turns
```

Reasoning-off runs come first. A failed model/configuration may be repeated
with reasoning on under the same class cap; the run records the mode, turns,
tool calls, total wall time and terminal state. The cap is still finite and
never grows inside an episode.

## Rejected

Accepting any RHS occurrence of an ordinary syntax name is rejected because it
would turn use into definition. Returning a precomputed target or source
classification to the model is rejected because it would remove the evidence
selection task. Candidate-specific exceptions are rejected; a new source form
must be added as a generic relation class with an independent fixture.

Keeping one turn cap for every model is rejected for the convergence run
because it confounds model quality with an arbitrary transport budget. An
unbounded retry loop remains rejected.

## Reversal condition

Write a successor if the generic relation language accepts a negative RHS
control, requires more than the three assumed-rule shapes plus source-defined
lexical/operator handling, or if the adaptive caps make model comparisons
uninterpretable. A source-profile extension must first pass a negative control
and a full denominator replay.
