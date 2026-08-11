# D0005. Grammars as comparisons, and effort not measured

Date: 2026-08-11
Status: amended by D0013

## Context

Three questions arrived together and turn out to have one answer.

What status do the 34 hand-written ANTLR grammars in `lazy-fortran/standard`
have relative to a generated grammar? They cannot be an oracle: their own git
history shows dead tokens, unreachable productions and features attributed to
the wrong revision (`LESSONS.md` §1). They may be wrong in exactly the places
where a disagreement matters.

Should the project compare its cost against the cost of building those grammars
by hand? The comparison is tempting and confounded: model capability changed on
both sides, and the `.g4` work was itself partly model-assisted. A 2026 pipeline
versus 2025 hand-maintenance measures the calendar, not the method.

How strictly should the extraction pipeline avoid existing grammars? A strong
reading of clean room would forbid looking at them at all, which is both
impractical and dishonest, since any model in use was trained on Fortran
compilers regardless.

## Decision

**Existing grammars are one of several independent comparisons.** The `.g4`
corpus, the kaby76 corpus, LFortran and Flang are compared against the generated
grammar. None is authoritative. Every disagreement is adjudicated against the
pinned J3/24-007 text and recorded with a verdict: ours wrong, theirs wrong, or
the document is ambiguous. The classification is a result, a measured
error rate for hand-maintained grammars, obtained without having assumed any of
them was correct.

**Productions are not copied.** StandardIR entries are derived from the
document. The rule governs how one artifact is produced, not what anyone may know or
read. Studying those grammars to understand the problem,
or consulting them to adjudicate, is expected and is recorded in
`docs/provenance.md`.

**Effort is not a published claim.** In its place, three measurements that are
independent of who or what did the work:

1. Defect-class elimination. A grammar derived in one pass from one pinned
   document cannot contain a token no rule references, because there is no hand
   to write one. `LESSONS.md` §1 supplies the eliminated defect list.
2. The fraction of the document convertible with zero model calls, and the
   minimum model size for the remainder, per rule.
3. The three-way disagreement rate with adjudications.

## Rejected

**Treat the `.g4` corpus as an oracle.** Its history says otherwise.

**Seed StandardIR from the `.g4` productions.** Fastest route to a working
parser and destroys the derivation claim, which is the point of Phase 1.

**Strict clean room with no adjudication record.** Cheaper in bookkeeping and
throws away the disagreement dataset, which is the most interesting output.

**Publish an effort comparison.** Not defensible.

## Reversal condition

If adjudication shows the generated grammar losing consistently, with a verdict
of "ours wrong" in more than a quarter of disagreements after the pipeline
stabilizes, then extraction is not working and the claim in point 1
is empty regardless of how the defect classes look.
