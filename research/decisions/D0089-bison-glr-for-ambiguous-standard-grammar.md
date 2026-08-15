# D0089. Emit Bison grammars in generic GLR mode

Date: 2026-08-15
Status: accepted
Amends: D0030

## Context

The E0147 source-backed replay retains all 1,066 exportable alternatives and
all four projections pass their structural/source witnesses. Bison accepts the
generated grammar, but its LALR(1) mode reports hundreds of shift/reduce and
thousands of reduce/reduce conflicts. A probe shows that choosing one
`program` start removes only the conflicts introduced by the broad start
wrapper; the remaining conflicts are properties of the context-sensitive
Fortran grammar as seen by an LALR parser. They must not be repaired by
changing StandardIR or by adding named target exceptions.

## Decision

The Bison projection emits `%glr-parser` as a deterministic target policy.
This lets Bison retain multiple parses for grammar ambiguity while preserving
the source-derived productions. The validator continues to run with all
Bison warnings enabled and records shift/reduce, reduce/reduce and useless-rule
diagnostics. GLR does not make the grammar conflict-free and does not close
E0147 by itself; source projection, root disposition, lexical connectivity and
Luna review remain independent gates.

The specialized direct parser remains the production parser target under D0029.
Bison is an export and differential oracle, not the semantic authority.

## Rejected

Suppressing conflict warnings, adding `%expect` counts, deleting ambiguous
alternatives, or hand-editing the generated `.y` file is rejected. Choosing a
single arbitrary LALR reduction would lose information from the normative
grammar. Asking an LLM to adjudicate parser conflicts is rejected because the
choice is a generic target strategy, not a missing StandardIR fact.

## Reversal condition

Write a successor if an independent behavior comparison shows that GLR still
loses a source-derived alternative, or if a compact generic Bison projection
with a stronger parser strategy is demonstrated without weakening provenance.
