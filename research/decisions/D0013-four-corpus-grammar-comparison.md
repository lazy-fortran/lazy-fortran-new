# D0013. Four-corpus grammar comparison denominator

Date: 2026-08-11
Status: accepted
Amends: D0005

## Context

D0005 calls the grammar comparison three-way while naming four external
comparison sources: the `standard` `.g4` corpus, kaby76, LFortran and Flang.
The roadmap and E0001 need a denominator that can be computed per source. The
old wording leaves it unclear whether the generated grammar is compared with
three sources, whether one source is omitted, or whether the term describes a
classification rather than a corpus count.

## Decision

E0001 compares the generated grammar with four pinned external corpora. It
reports one disagreement rate per corpus. Each disagreement is adjudicated
against J3/24-007 and classified as ours wrong, theirs wrong, or document
ambiguous. The generated grammar is the subject under evaluation and is not
counted as an external corpus.

## Rejected

**Keep the three-way wording.** It leaves the comparison denominator ambiguous
and makes the roadmap gate impossible to audit from the run records.

**Drop one comparison source.** The four sources provide independent evidence
with different maintenance histories and should remain available for
adjudication.

## Reversal condition

If one source cannot be normalized to the common comparison form without
changing the question E0001 asks, a successor decision will define a narrower
comparison set and report the excluded source separately.
