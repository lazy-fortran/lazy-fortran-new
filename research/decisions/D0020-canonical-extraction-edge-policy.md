# D0020. Canonical extraction edge policy

Date: 2026-08-12
Status: accepted

## Context

The canonical PDF projection currently preserves the UTF-8 bytes supplied by
Poppler, orders glyphs by page geometry, inserts spaces from rectangle gaps,
and writes line breaks at geometric line changes. E0033 reran this path over
the 688-page J3/24-007 document. The artifact has no leading UTF-8 BOM, 9,300
non-ASCII bytes, and 687 page separators. No Unicode ligature code point was
observed in the artifact. The current code has no hyphen joining or column
segmentation rule.

D0011 makes source bytes authoritative and reserves normalization for a
derived view. The extraction boundary needs corresponding rules before a
different PDF or a standalone text input exercises these cases.

## Decision

1. At a standalone UTF-8 text-file boundary, recognize one leading BOM as an
   encoding signature rather than normative text. Preserve enough boundary
   provenance that spans in any derived view remain traceable to the original
   byte offsets. Preserve BOM bytes elsewhere. The PDF canonical projection
   has no BOM-specific transformation because the pinned artifact contains
   none.

2. Preserve decoded Unicode scalars and their UTF-8 bytes in the lossless
   projection. Do not expand compatibility ligatures such as `ﬁ` to `fi`.
   A later search or normalization view may expand them with its own provenance
   and tests.

3. Preserve line-ending hyphens and line boundaries in the lossless projection.
   Joining a word across a line is a derived interpretation performed after
   extraction, with an explicit rule and source spans.

4. Use the current page-local geometric order, increasing vertical position
   followed by horizontal position, for pages whose text occupies one reading
   stream. If a selected normative page contains overlapping multi-column
   streams for which that order is not independently established, preserve the
   raw geometry, mark that page's canonical reading order as `ambiguous`, and
   continue extracting other pages. Any profile, rule set or phase gate that
   requires the ambiguous page fails until it is adjudicated. Do not add a
   column heuristic without a corpus and an independent expected reading order.

These rules apply to the lossless canonical projection. They do not constrain
later normalized search text, parser tokenization, or source-to-source output.

## Rejected

**Normalize all Unicode to compatibility form during extraction.** This loses
the distinction between source bytes and a derived search representation.

**Join every line-ending hyphen.** A hyphen may be a normative token, a
punctuation mark, or a line-break artifact. Extraction cannot decide among
those cases from the byte sequence alone.

**Guess column boundaries from x coordinates.** A heuristic can silently
change reading order on tables, sidebars, and indented grammar notation. The
failure should remain visible until an expected order exists.

**Abort the entire document on one ambiguous page.** Raw geometry and other
independent pages remain useful evidence. Ambiguity blocks authoritative use of
that page and anything depending on it, not unrelated extraction work.

**Treat the absence of an edge case in J3/24-007 as proof of generality.** The
current artifact establishes coverage for this document only.

## Reversal condition

Write a successor decision if an independently checked corpus shows that a
leading BOM must remain part of the normative address space, a ligature
expansion is required for normative extraction, a source-controlled hyphenation
rule is available, or a multi-column page can be ordered by a deterministic
rule with an independent oracle. A repeated layout ambiguity is a reason to add
an experiment and oracle, not to add an unmeasured special case.
