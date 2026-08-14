# D0066 — Repair the bounded Qwen tool dialogue generically

Date: 2026-08-14
Status: amended by D0067
Amends: D0065

## Context

The first residual replay after D0065 left five hard failures. One row emitted
the model's declared Qwen XML tool format in message content instead of the
server's native `tool_calls` field. Three rows repeated a gate-rejected
predicate because the runner returned only the tool result, without an
explicit repair instruction. One malformed long tool argument was appended to
the next request and was followed by an HTTP 500.

## Decision

- Adapt exactly one recognized `<tool_call><function=...>` XML call from
  assistant content into the same internal tool-call object used by native
  calls. The raw model message and adapter event remain in the trajectory.
- On malformed native arguments, record the error but do not put the malformed
  assistant message back into the next model context. Send a concise repair
  instruction instead.
- After a rejected semantic submission, return the exact deterministic gate
  message plus a generic instruction to submit a replacement or use
  `relation` when a primitive constructor is insufficient.
- Keep all corrections bounded by the existing episode turn cap; no silent
  predicate repair and no constraint-specific branch is added.

## Rejected

- Treat XML content calls as a new model-specific semantic protocol.
- Repair malformed JSON by truncating or rewriting the model's arguments.
- Repeat a rejected proposal without telling the model why it failed.
- Hide a transport failure by dropping the trajectory or retrying indefinitely.

## Reversal condition

Amend this decision if the XML adapter accepts ambiguous or multiple calls, if
sanitizing malformed history loses required valid context, or if explicit gate
feedback increases repeated invalid submissions rather than reducing them.
