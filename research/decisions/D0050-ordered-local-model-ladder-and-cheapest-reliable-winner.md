# D0050. Ordered local-model ladder and cheapest reliable winner

Date: 2026-08-13
Status: accepted
Amends: D0049
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The Qwen3.5-2B pilot did not establish model capability: its first prompt
inventory omitted the exact source spans found by E0110, so the deterministic
overlap was not observable to the model. The model runner also initially
aborted on malformed output instead of preserving the denominator. A larger
experiment must repair both defects without weakening the validator.

The active-parameter count and measured latency are not the same as total
parameter count. A sparse Qwen3.6-35B-A3B model can therefore be cheaper per
token than a dense 9B model, while a smaller dense model may still be the
cheapest reliable choice in practice.

## Decision

Run E0112 against the same 127-row denominator. Add the exact E0110 source
windows to the prompt inventory for overlap, keep the E0110 validator and
source hash unchanged, and record model errors and rejected proposals rather
than aborting or dropping rows.

Try candidates in this fixed order:

1. Qwen3.5-4B;
2. Qwen3.5-9B;
3. Qwen3.6-35B-A3B;
4. Qwen3.6-27B;
5. Gemma 4 E2B;
6. Gemma 4 E4B;
7. Gemma 4 26B-A4B;
8. Gemma 4 31B.

For the smaller candidates, Q4_K_M is followed by Q6_K and Q8_0 controls if
the preceding configuration fails. Thinking is off first and is enabled only
after the same non-thinking configuration fails. Each candidate configuration
gets two attempts. A configuration is reliable only if both attempts preserve
the denominator, have zero runner errors and strict rejections, reproduce all
E0110 accepted keys without disagreement, accept at least one additional
validated row, and produce identical accepted-key sets.

Keep the reliable configuration with the lowest measured wall time per prompt;
active parameters and quantization break ties. This retains the sparse-model
cost advantage without assuming that nominal model size predicts actual cost.
No configuration is promoted to StandardIR automatically.

## Rejected

Treating the first 2B pilot as a capability result is rejected because its
windows did not contain the deterministic overlap evidence. Accepting model
claims based on exact-looking but noncanonical citation text is rejected.
Selecting by total parameter count alone is rejected because sparse MoE active
cost differs from storage size. Turning thinking on for every candidate is
rejected because it changes the cost comparison before non-thinking failure is
observed.

## Reversal condition

Write a successor if the overlap windows systematically bias the task, if two
identical attempts are not a sufficient repeatability test, or if measured
wall time is not a useful proxy for the cost decision on the target runtime.
