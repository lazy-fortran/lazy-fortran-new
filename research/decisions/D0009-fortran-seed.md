# D0009. A tiny Fortran SX reader as the bootstrap seed

Date: 2026-08-11
Status: accepted
Amends: D0003

## Context

Every bootstrap starts somewhere, and the seed is the part of the system that
cannot be derived from anything else. The question is not how to avoid a seed
but which one leaves the smallest thing to trust.

Something must parse SX before any generated parser exists.

## Decision

A hand-written SX reader in Bootstrap Fortran is the seed. It recognizes
parentheses, atoms, integers, quoted strings and whitespace, and nothing else,
and produces nodes in an arena rather than recursive heap objects. A few
hundred lines is the expectation, though simplicity matters more than a line
count.

It is property-tested rather than example-tested: `parse(write(tree)) = tree`
and `write(parse(canonical_text)) = canonical_text`, plus fuzzed trees and a
malformed-input corpus.

Once grammars can be described in StandardIR and parsers generated, SX is
described in StandardIR, `sx_reader_generated.f90` is generated, and both
readers run over the whole corpus with identical canonical trees required.
The generated reader then becomes the default and the seed remains as an
oracle and a bootstrap artifact.

## Rejected

**JSON.** Moves the seed into a JSON implementation, which is larger than the
reader it replaces and brings a dependency that never goes away.

**Python.** Moves the seed into CPython. It also violates D0003 and creates
exactly the situation D0003 was written to prevent, where a scaffold becomes
the authoritative implementation and a rewrite is deferred indefinitely.

**ANTLR.** Moves the seed into the ANTLR runtime and a Java toolchain, to parse
a grammar with four productions.

**No seed, generate from the start.** Circular. The generator needs to read its
own input.

## Consequences

The trusted base gains one hand-written component, and it is a component whose
behaviour can be read in an afternoon. That is the intended trade: not zero
seed code, but the smallest seed from which everything else regenerates.

The seed is never deleted after regeneration. It is the differential oracle for
its own replacement.

## Reversal condition

If the generated reader and the seed disagree on the corpus and the seed turns
out to be the wrong one, that is an ordinary bug. If they disagree repeatedly
in ways that trace to SX being underspecified, the format needs a written
grammar with the ambiguities resolved, which is a change to D0006 rather than
to this decision.
