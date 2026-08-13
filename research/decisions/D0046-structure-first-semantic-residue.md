# D0046. Structure-first semantic residue adjudication

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0104 widened deterministic evidence retrieval from single lines to bounded
windows and sentence continuations. It retained 2,471 source spans for the
127-row residue, but every row remained ambiguous. Widening the same lexical
cue search further would increase retrieval without supplying the missing
document structure.

## Decision

The next M3 slice is a bounded, Fortran-specific document-structure extractor
in `standard-new`. It may identify clause headings, numbered rule blocks,
continuation ownership and explicit cross-reference blocks from the canonical
text and page index. It emits only source-backed structural records with exact
spans, hashes and `MECHANICAL` origin. It does not create aliases, semantic
facts, parser references or StandardIR promotions.

Run that extractor against the pinned E0100/E0104 residue with an independent
traversal and a tampered-source negative control. Measure unique candidates,
ambiguous candidates, no candidates and source-span counts before deciding
whether model assistance is warranted for the remaining residue. Any later
model experiment is separate, explicitly authorized, source-cited and cannot
own wiring or promote facts by itself.

## Rejected

Another generic lexical-window widening is rejected because E0104 measured its
failure mode. A larger model as the immediate next step is rejected because it
would not add a new evidence source or explain why the spans are ambiguous.
Copying comparison grammars or treating recurring suffixes as aliases is
rejected because neither is normative evidence.

## Reversal condition

Write a successor if the structure extractor cannot reduce ambiguity on the
pinned residue without document-specific exception growth, or if its output
does not remain useful as a general provenance-bearing source index for later
clauses and standards.
