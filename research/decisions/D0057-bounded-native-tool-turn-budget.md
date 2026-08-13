# D0057. Bound native evidence episodes by twelve turns

Date: 2026-08-13
Status: amended by D0058

## Context

The first E0115 Qwen 3.5 2B full-cell attempt showed that a model can keep
requesting tools after the eight evidence-call budget is exhausted. With a
20-turn cap, rows repeatedly consumed time without submitting a pointer or an
abstention. This is a valid model/tool-use failure, but the unproductive tail
would make the 127-row matrix unnecessarily expensive.

## Decision

Set the E0115 maximum to twelve native model turns per row. The budget covers
up to eight evidence calls, three pointer submissions and one final handoff.
Rows that do not terminate within twelve turns remain `hard_failure`; they are
not silently converted into abstentions. The runner flushes every event and
completed row so an interrupted cell remains auditable.

## Rejected

Allowing an unbounded loop was rejected because it makes cost and failure rates
model-dependent in an uncontrolled way. Converting a turn-budget exhaustion
into an abstention was rejected because failure to submit is a protocol failure,
not an explicit model decision to abstain. A four-turn cap was rejected because
it would not allow the declared evidence and submission budgets to be used.

## Reversal condition

Write a successor if local pilot traces show that twelve turns systematically
prevent correct submissions after the declared evidence budget, or if a lower
turn bound gives the same oracle and discovery results with a predeclared
cost/quality comparison.
