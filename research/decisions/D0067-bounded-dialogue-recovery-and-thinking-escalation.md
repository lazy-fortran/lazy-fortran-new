# D0067 — Bound dialogue recovery, telemetry and thinking escalation

Date: 2026-08-14
Status: accepted
Amends: D0066

## Context

R000014 repaired the mixed Qwen XML/native tool format and accepted C911,
C913 and C1154, but C782 and C950 still consumed the complete 24-turn budget.
Their trajectories show repeated identical gate-rejected submissions rather
than new semantic attempts. The local llama-server also exposed timing and
finish-reason data that the runner discarded. Finally, the service profile's
reasoning budget was zero, so a thinking-on fallback could not actually run.

## Decision

- Retry only transient model transport failures (HTTP 429/5xx, network and
  invalid-JSON responses) with at most the runner's explicit bounded retry
  count. Count every retry in the trajectory and summary; this is not a job
  monitor or an unattended run retry.
- Canonicalize each submitted proposal and detect repeated identical rejected
  submissions. After the second repetition, return a generic structural repair
  message; after the third, end that episode as a retained hard failure rather
  than spending the remaining turns in a loop.
- Consume a forced `submit_semantic` tool choice for one request only, then
  return to automatic tool choice. Evidence exhaustion and repeated evidence
  calls may force one submission turn but may not create a permanent forced
  loop.
- Reserve a small submit-only finalization phase after the normal turn budget.
  It may accept only through the existing deterministic gate; it may not add
  evidence or rewrite a proposal.
- Record response ID, finish reason, llama.cpp timings, token totals,
  transport retries, loop recoveries, finalization turns and thinking mode.
- Start every row with thinking off. With explicit `--escalate-thinking`, a
  failed or unresolved row receives one fresh thinking-on episode. The two
  attempts remain in the trajectory and the selected terminal result is not
  inferred from the first attempt.
- Configure the local Qwen service with a bounded nonzero reasoning budget so
  the escalation is real while the normal request's `enable_thinking=false`
  path remains unchanged.

## Rejected

- Import OpenCode or Slopqueue as a semantic orchestration framework; their
  control-flow ideas are used as evidence, while the semantic runner remains
  a small deterministic research harness.
- Silently rewrite a rejected predicate, convert a hard failure into success,
  or treat an abstention as semantic acceptance.
- Enable unrestricted reasoning or unlimited transport/turn retries.

## Reversal condition

Amend this decision if bounded transport retries duplicate accepted side
effects, if the proposal fingerprint produces false loop positives on distinct
source-backed proposals, if finalization loses evidence provenance, or if a
thinking-on escalation reduces independently witnessed acceptance without
improving residual convergence.
