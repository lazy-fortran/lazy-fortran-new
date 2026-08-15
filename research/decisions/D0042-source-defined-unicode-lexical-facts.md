# D0042. Source-defined Unicode lexical facts

Date: 2026-08-13
Status: amended by D0091
Amends: D0027
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

D0027 retained the two non-ASCII lexical records `–` and `’` as unresolved
because their meaning was not to be inferred from a rendered glyph. The
complete D0041 closure rebuild now shows that these are the only two
non-production parser references left after the accepted R401/R402/R403
projection. The pinned, lossless canonical text contains exact source
witnesses: R1010 lists `–` as the second `add-op`, and R724 uses `’` as a
character-literal delimiter. The source hash is
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

## Decision

Promote these two records to accepted source-defined lexical facts. Preserve
their exact Unicode scalars and UTF-8 provenance in StandardIR-derived
lexical data, and emit stable target names `EN_DASH` (U+2013) and
`RIGHT_SINGLE_QUOTE` (U+2019). The source citations are R1010, page 69, and
R724, page 85, respectively. This is a lexical fact projection, not an
ASCII normalization and not a semantic interpretation of a comparison
grammar.

The mechanical closure ledger must classify both references as lexical facts.
The target exporters may use target-specific spellings for the same exact
code points, but may not replace them with `-` or `'`.

## Rejected

Inferring the code points from a comparison grammar is rejected by the
provenance gate. Replacing the symbols with ASCII punctuation is rejected
because it changes the source-defined token set. Leaving exact source-backed
facts unresolved is rejected because it would keep the complete parser
profile artificially open.

## Reversal condition

Write a successor if an independently checked lossless extraction shows that
either scalar was introduced by PDF substitution rather than present in the
source text, or if the normative document gives a different source-defined
character for either cited rule.
