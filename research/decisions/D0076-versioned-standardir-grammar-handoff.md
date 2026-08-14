# D0076 — Version the normalized StandardIR grammar handoff

Date: 2026-08-14
Status: accepted

## Context

The existing `standardir-v0` contract carries syntax identity, left-hand side,
provenance, origin and resolution, but not the right-hand-side expression.
The production StandardIR parser already distinguishes references, tokens,
sequences, choices, optional groups and repetitions. The frontend grammar
consumer needs that structure to generate a parser; reparsing a notation string
or copying an existing comparison grammar would make the consumer authoritative
for StandardIR syntax.

## Decision

Add a separate `standardir-grammar-v0` contract. It carries one source-backed
syntax alternative as a bounded flat preorder node table. Each node records its
kind, name, repetition minimum, unbounded flag, first child and child count;
`root` is a one-based node index and zero means no child. References, tokens,
sequence, choice, optional and repeat are represented explicitly. The node
table is a structural serialization boundary, not a parser strategy.

The existing `standardir-v0` contract remains unchanged for metadata consumers.
The producer remains `standard-new`; the frontend owns the generic consumer and
later deterministic parser generation. Every rule retains source identity,
origin and resolution, and unresolved or disputed rules remain non-accepted
states rather than becoming parser wiring.

## Rejected

- Extending `standardir-v0` in place: its current consumers would receive a
  breaking record shape without a contract revision.
- Exporting only flat reference/token names: optional, repeated, grouped and
  alternative structure would be lost before parser generation.
- Exporting the raw notation string: the frontend would need a second grammar
  parser and would own StandardIR-specific interpretation.
- Copying ANTLR, Bison, tree-sitter or another comparison grammar: those are
  differential evidence, not the normative source.

## Reversal condition

Write a successor if the bounded node table cannot represent a normative syntax
construct without loss, or if measurements show that its validation and
generation cost is materially worse than a simpler source-backed representation.
The successor must name the lost construct or measured cost and retain the
existing contract's provenance and resolution states.
