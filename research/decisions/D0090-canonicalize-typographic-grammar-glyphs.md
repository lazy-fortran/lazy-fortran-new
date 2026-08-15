# D0090. Canonicalize typographic grammar glyphs at the syntax boundary

Date: 2026-08-15
Status: accepted

## Context

The E0148 comparison of E0147/R000016 with the pinned LFortran Bison source
found that the PDF's typographic en dash and right single quotation mark are
currently emitted as literal target terminals. They are typography in the
standard document, not the ASCII source spellings of Fortran minus and
character-literal delimiters. The source glyph must remain available for
provenance and source-span auditing.

## Decision

The source lexer preserves the exact PDF glyph and its source location. A
generic typed lexical-normalization table then maps U+2013 to canonical source
`-` and U+2019 to canonical source `'` when they occur as grammar terminals.
Every projection consumes the canonical spelling and retains the original
glyph, code point and mapping record in provenance. The mapping is not allowed
to mention a Fortran rule number or a particular output format.

The mapping is accepted only for the declared typographic forms. An unknown
Unicode terminal remains unclassified and blocks the source-valid grammar
gate. The mapping is tested by source witnesses and by target-language
accept/reject witnesses for both the canonical spelling and the unaccepted
typographic code point.

## Rejected

* Emitting U+2013 and U+2019 literally in generated grammars. This describes
  the PDF typography rather than valid Fortran source spelling.
* Replacing the glyph in the canonical source evidence. That would make the
  provenance audit unable to explain what was printed in the standard.
* Adding separate per-rule repairs for R1010, R712, R724, R773, R774, R775 or
  R868. The issue is a generic lexical boundary policy.
* Copying LFortran's tokenizer or grammar into StandardIR. It is evidence for
  source spelling, not normative input.

## Reversal condition

Write a successor if the normative standard explicitly admits the typographic
code points as Fortran source characters, or if an independent lexical oracle
shows that the canonical mapping changes a valid or invalid source decision.
