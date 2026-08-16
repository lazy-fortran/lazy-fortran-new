# D0123. Start M1-M2 with a central source-backed grammar gate

Date: 2026-08-16
Status: accepted

## Context

L2 is now promoted by the central verifier and three valid focused Luna
scopes in `R000444`. The next roadmap milestone, M1-M2, has historical
source-validity and grammar-export work, but no central executable verifier or
clean-checkout source artifact contract. The old cached replays are useful
evidence but are not, by themselves, a current central delivery slice.

## Decision

The next central task is to define and implement one source-backed M1-M2 gate
in `lazy-fortran-new`. It will pin the external source artifact without
vendoring it, consume a declared StandardIR grammar input from the pinned
`standard-new`, validate source identity and lexical normalization, generate
EBNF, ANTLR4, Bison and tree-sitter projections, run their independent parser
generator checks, and retain positive, negative and mutation controls. The
gate must have a clean-checkout command and a central trace before M1-M2 can
be promoted.

This is the selected bounded route from the next-frontier exploration. It
keeps the complete-standard claim and parser conflict policy open until the
central source-backed gate has an executable definition of done.

## Rejected

Using an existing `.cache` replay as the milestone evidence is rejected
because its source inputs and toolchain are not established by the current
central clean-checkout contract. A tiny hand-authored grammar fixture is
rejected as insufficient evidence for source validity. Jumping directly to
Bison conflict reduction or semantic/model work is rejected because neither
consumes a newly established central source-backed gate.

## Reversal condition

Revise this boundary if the pinned source cannot be retrieved and verified
under the repository's provenance rules, or if the first central executable
slice demonstrates that a different source-backed projection is the smallest
general gate for the actual M1-M2 definition of done.
