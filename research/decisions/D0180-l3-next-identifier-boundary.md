# D0180. Stop the exact-name ladder at the next identifier boundary

Date: 2026-08-18
Status: accepted

## Context

The L3 typed-AST lane now has promoted exact witnesses for `x`, `y`, `z` and
`alpha`, with independent changed-name controls and explicit refusal of a
general identifier claim. Adding more hard-coded names would produce more
bounded leaves but would not establish source-derived identifier handling.

## Decision

The next central task is contract selection for a genuine identifier boundary
over the existing `frontend-ast-v1` shape. Its contract must define a compact
source-name mutation family, execute each selected control through the same
producer, pin expected spans and source bytes, and state exactly what remains
unclaimed. The contract task must not begin a producer implementation. The
default design is to replace exact-name dispatch with a source-derived name
field and retain the existing malformed declaration control, but that design
is not accepted until its independent oracle is written.

This is the next scope decision, not a claim that the current producer already
handles arbitrary identifiers. No model output may promote a semantic or
source-derived fact.

## Rejected

Continuing an unbounded sequence of one-name or multi-name golden fixtures,
general semantic analysis, symbol resolution, MIR, parser conflicts and full
M3 are not the next task.

## Reversal condition

Reverse this decision if a smaller source-backed contract can independently
distinguish source-derived identifier handling with equal or stronger
evidence, or if the existing AST v1 schema is insufficient for the boundary.
