# D0018. Composite parser input, not raw syntax exports

Date: 2026-08-12
Status: accepted

## Context

E0021 regenerated the four deterministic StandardIR syntax projections after
normalizing repeated lhs records. The outputs had no duplicate definitions, but
ANTLR4, Bison and tree-sitter still rejected them because the selected syntax
records contain unresolved lexical classes, name classes and other references.

This is not only an extraction defect. J3/24-007 §4.1.4 paragraph 2, PDF page
31, says that the standard's syntax rules are not a complete and accurate syntax
description and cannot by themselves generate a Fortran parser. The extracted
syntax must therefore not be treated as a complete parser specification.

## Decision

Keep the raw EBNF, ANTLR4, Bison and tree-sitter files as deterministic syntax
projections for documentation, interoperability and structural comparison.
They are not required to pass a target parser-generator validator in isolation.

The authoritative input for a specialized parser generator is a composite
projection containing:

- StandardIR syntax records and their profile closure;
- lexical and token definitions, including the processor-character-set rules;
- constraints and prose restrictions needed to complete or restrict syntax;
- resolution states and provenance for every reference that remains unresolved
  or disputed.

The generator must never invent a placeholder production merely because a name
appears in a `(ref ...)`. A reference is either resolved by the composite input,
retained as an explicit unresolved/disputed record, or excluded by a declared
profile. Target-tool validation applies to the composite parser input, not to a
raw syntax export.

## Rejected

**Add 181 guessed aliases or token rules to the raw exports.** This would make
the validators pass by silently converting prose and incomplete syntax into
implementation claims, exactly the ambiguity the source document warns about.

**Treat E0021 as a failed syntax extraction.** The duplicate-definition defect
was fixed and independently measured as zero. The remaining failure is evidence
that the parser-input boundary has not yet been assembled.

## Reversal condition

If a later source-controlled extraction of the relevant normative clauses proves
that a declared profile's raw syntax projection is complete, resolves every
reference without prose or constraints, and passes independent target-tool
validation, a successor decision may narrow the composite input. Until then,
raw syntax and composite parser input remain separate artifacts.
