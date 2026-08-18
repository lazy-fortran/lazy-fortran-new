# D0188. Canonicalize the DOUBLE PRECISION AST-v1 atom

Date: 2026-08-18
Status: accepted
Amends: D0187

## Context

The isolated D0187 producer recognizes the exact source line, preserves the
existing REAL and integer controls, and passes its component gate. Its output
cannot pass the existing AST-v1 validator when `variable.type-spec` is the
two-word value `double precision`: the schema's `name` primitive serializes
atoms and rejects spaces. This is an implementation-boundary failure, not a
source or parser failure. D0187's reversal condition is therefore met.

## Decision

Keep the exact source spelling in the pinned Fortran fixture and source
evidence, but represent the multi-word standard term as the canonical SX atom
`double-precision` in the existing AST-v1 `variable.type-spec` field. The
contract oracle must check both facts: the input bytes contain exactly
`double precision`, and the accepted AST contains exactly
`double-precision`. The REAL control remains `real`; the malformed
`double precision ::` neighbour remains rejected. No schema revision, quoting
rule, general intrinsic-type parser, or semantic promotion is introduced.

This is a representation normalization at the existing serialization boundary;
it does not claim that the AST-v1 field is a complete type representation.

## Rejected

Changing the AST-v1 schema to add a string primitive would widen the interface
for one source spelling and require a separate schema migration slice. Keeping
the invalid two-word atom would make the producer/replay contract impossible to
verify. Emitting an arbitrary abbreviation would lose the source-term
correspondence.

## Reversal condition

Write a successor if an independent replay cannot simultaneously prove the
exact source spelling and canonical `double-precision` output, or if a later
accepted AST-v1 contract establishes a different canonical encoding for
multi-word source terms.
