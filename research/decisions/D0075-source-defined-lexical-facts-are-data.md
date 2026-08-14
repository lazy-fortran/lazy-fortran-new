# D0075 — Keep source-defined lexical facts as queried data

Date: 2026-08-14
Status: accepted

## Context

The pinned StandardIR lexical projection already carries source terms,
Unicode ranges, target names and provenance. The next production boundary is a
lookup that lets generated consumers classify a scalar without embedding
Fortran-specific letter, digit or token cases. Some normative lexical facts,
such as processor-defined representation characters, do not define a single
portable scalar and cannot be accepted by a scalar lookup alone.

## Decision

Lexical classification shall be driven by caller-supplied, source-backed fact
records. The generic query accepts a scalar/codepoint and returns only a fact
whose declared scalar or range contains it, together with its target/class and
provenance. It must not recognize a target name through a hardcoded branch.

Processor-defined or otherwise non-scalar facts remain explicit non-match or
unsupported results at this boundary. A later target policy may handle them
through a separate, source-linked operation; it may not silently turn them into
a universal wildcard.

The production repositories own the query mechanism and generated consumers.
The laboratory owns the source manifests, experiments, decisions and
cross-repository contract. No lexical payload is copied into a production
repository merely to make a test pass.

## Rejected

- Hardcoding `LETTER`, `DIGIT` or other Fortran token names in the frontend:
  this makes language-specific wiring authoritative and prevents reuse.
- Treating `processor-defined` as any scalar: this invents a portable fact the
  standard does not provide.
- Making the frontend reread the PDF or own lexical provenance: this duplicates
  StandardIR ownership and breaks the production/laboratory boundary.

## Reversal condition

Write a successor if a complete closed lexer profile demonstrates that scalar
lookup cannot represent a required normative lexical distinction without
silently losing source identity, or if an independent target-policy witness
shows that the explicit processor-defined result is insufficient. The
successor must retain the source-backed denominator and identify the missing
representation rather than adding a target-specific branch by convention.
