# D0064 — Repair malformed native tool calls inside the episode budget

Status: amended by D0065
Date: 2026-08-14
Amends: D0063

## Context

The complete E0116 pass retained several hard failures caused only by
unterminated or otherwise malformed JSON in a model-produced native tool call.
The deterministic dispatcher correctly rejected the call, but the runner
ended the episode instead of giving the model the already-declared repair
budget. This conflated a recoverable protocol error with a model inability to
formalize the rule.

## Decision

When a native tool call has malformed JSON or an invalid tool-call envelope,
record the model error, return a precise repair instruction as the next user
message, and continue within the existing turn cap. HTTP/model transport
errors remain terminal for that episode. Every malformed call stays in the
append-only trajectory and counts toward the model-call and error metrics.

## Rejected

- Silently repair or truncate model-produced JSON in the deterministic gate.
- Drop the malformed call from the trajectory.
- Retry outside the episode turn budget.
- Treat a repaired episode as equivalent to one with no protocol errors.

## Reversal condition

Reverse this repair behavior if malformed-call feedback causes repeated loops
that consume the entire budget without increasing terminal acceptance, or if a
repair changes the declared tool name or arguments without a new model call.
