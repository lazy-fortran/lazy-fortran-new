# D0053. Solved-translation oracle and visual-first controls

Date: 2026-08-13
Status: accepted
Amends: D0052
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The unresolved residue is not enough to measure model translation quality.
The six strict definitions accepted by E0110 are a mechanically solved
control set with exact source spans and relations. A model can be correct on
an unresolved row by abstaining, so discovery and translation quality must be
reported separately.

The PDF itself is also an available input modality. A visual model should be
tested on rendered rule pages before canonical text, OCR, structure indexing
or retrieval is supplied. That is a different experiment, not a replacement
for the source-byte gate.

## Decision

E0113 keeps all 127 residue rows in the denominator and reports two distinct
results: discovery on the 121 rows not accepted by E0110, and exact
translation on all six E0110 strict-definition rows. For the solved rows, the
mechanical E0110 relation and exact source span are the oracle. A valid model
pointer that selects another definition is `wrong-accepted`; abstention and
hard failure are false negatives for the translation control. The primary
translation metric is exact oracle matches divided by six.

Every E0113 run records total wall time, setup time, inference time, per-row
time, per-attempt time, repair count, model calls and terminal state. These
timings include failed calls and are not reconstructed from successful rows.

E0114 is the visual-first control. It renders the six E0110 source pages
directly from the pinned PDF and supplies only the page image plus the
candidate name. Qwen and Gemma VLM-capable checkpoints may return a relation
and target, but no canonical text or precomputed source window. The gate
compares the result to the E0110 oracle after a declared whitespace
normalization. Visual results are never pooled with E0113 text results.

## Rejected

Counting abstention as successful translation is rejected. Reporting only
accepted unresolved rows is rejected because it hides false negatives. Using
OCR or canonical text in the visual-first prompt is rejected because it would
turn the visual control into the text protocol. Treating a visually plausible
target as a fact without comparison to the pinned source is rejected.

## Reversal condition

Write a successor if the six-row oracle is too small after an independently
validated expansion of the mechanical set, if exact target comparison is
shown to measure formatting rather than translation, or if the visual page
rendering cannot preserve the rule text at a declared resolution. Any larger
oracle must be frozen before observing model results.
