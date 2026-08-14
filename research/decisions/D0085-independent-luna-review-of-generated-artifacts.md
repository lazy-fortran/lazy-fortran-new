# D0085. Review generated artifacts with an independent Luna pass

Date: 2026-08-14
Status: accepted

## Context

The deterministic source-validity gate answers whether an artifact agrees with
the pinned source. It does not reveal every usability problem in the review
harness or every representation that is difficult for an independent reader
to understand. A second, independent reading is useful, but it must not become
an alternative source of grammar facts.

## Decision

After a generated artifact has passed its deterministic source and structural
gates, launch one native GPT-5.6 Luna review with the minimal task prompt:

    How well does this represent the Fortran 2023 standard?

Give the reviewer the artifact and its source-backed viewing path, but do not
pre-adjudicate the answer with a leading defect list. Record the review as
LLM evidence in the laboratory run ledger, including the exact artifact
commit, prompt, model identity and result.

Use the review to identify:

* representation defects that the deterministic checks do not cover;
* missing source context or confusing presentation;
* harness problems such as insufficient context or output budget; and
* candidates for new positive or negative deterministic controls.

The review may not rewrite StandardIR, validate a source span, change a
denominator, classify a reference, or promote a fact. A review finding becomes
actionable only through a deterministic witness, a decision record when the
boundary changes, and a new reproducible run.

## Rejected

* Using Luna as the normative grammar extractor. That makes model opinion own
  architecture or source interpretation.
* Feeding the model's critique directly into generated output. The result
  would not have a source-backed provenance chain.
* Running model reviews before the deterministic gate has established what
  artifact is actually being reviewed. That confounds source defects with
  harness or capability defects.

## Reversal condition

Write a successor if repeated independent reviews add no reproducible
controls, or if the minimal prompt systematically hides a necessary class of
context that cannot be supplied without changing the review protocol.
