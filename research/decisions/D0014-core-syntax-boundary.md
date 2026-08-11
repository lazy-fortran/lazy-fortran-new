# D0014. Core syntax boundary includes assumed syntax

Date: 2026-08-12
Status: accepted

## Context

The full pinned PDF scan over pages 1--688 found 522 numbered productions.
The E0005 contiguous span over pages 53--580 found 519. The only productions
outside that span are `R401`, `R402` and `R403`, all on page 45 under
"Assumed syntax rules": `xyz-list`, `xyz-name` and `scalar-xyz`. A core
grammar that omits these definitions cannot claim to have recovered the full
numbered syntax used by the selected document.

The comparison is regenerated with the production extractor over pages 1--688
and over the selected core span, followed by a set difference of the
production-start rule numbers.

## Decision

The mechanical core-syntax corpus starts at page 45 and ends at page 580.
It includes `R401`--`R403` and every other numbered production in that
contiguous span. Page 45 is the prelude to the main syntax section, not an
out-of-scope convention.

## Rejected

**Keep pages 53--580.** This leaves three numbered syntax productions out of
the corpus while giving no machine-readable representation for their names.

**Use pages 1--688 as the core corpus.** This would include introductory,
semantic and annex material that is not part of the selected core syntax
profile and would make the extraction boundary less useful for later rule
selection.

## Reversal condition

If a later dependency-closure analysis demonstrates that `R401`--`R403` are
not grammar definitions but only external notation conventions, or if the
normative source assigns the core profile a different explicit production
boundary, a successor decision will amend this page range and retain the
excluded records as a separately identified corpus.
