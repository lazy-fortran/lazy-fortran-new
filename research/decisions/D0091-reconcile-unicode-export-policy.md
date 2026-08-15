# D0091. Reconcile Unicode source facts with canonical target spellings

Date: 2026-08-15
Status: accepted
Amends: D0042

## Context

D0042 correctly preserved the two exact Unicode scalars found in the PDF, but
its exporter rule also prohibited replacing them with the canonical Fortran
source spellings. E0148 shows that this leaves generated grammars with PDF
typography as target terminals. D0090 establishes the generic provenance-
preserving normalization boundary, but the older prohibition must be made
explicitly obsolete rather than left contradictory.

## Decision

D0042 remains authoritative for source evidence: StandardIR retains U+2013 and
U+2019, their code points, source spans and document provenance as lexical
facts. Its prohibition on canonical target spellings is amended. D0090 is the
target-boundary policy: syntax projections map U+2013 to canonical source `-`
and U+2019 to canonical source `'`, while preserving the original scalars in
typed provenance. The mapping is lexical and positional, not a claim that
every use of `-` is an arithmetic operator.

The source-validity gate must test both sides: source evidence must retain the
PDF scalar, and generated target witnesses must use the canonical source
spelling. Unknown Unicode terminals remain unresolved rather than being
silently normalized.

## Rejected

* Leaving D0042's exporter prohibition in force while claiming that generated
  grammars accept Fortran source spelling.
* Deleting the Unicode source facts after normalization.
* Treating LFortran's tokenizer as normative input rather than corroborating
  evidence.

## Reversal condition

Write a successor if a normative source witness establishes that either scalar
is a required Fortran source spelling, or if independent lexical witnesses
show that the canonical mapping changes a valid or invalid source decision.
