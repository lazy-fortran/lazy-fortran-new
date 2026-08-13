# E0115 protocol

This is the operational companion to the manifest and D0054. It is a file
protocol, not a service.

## Episode inputs

Each episode is one `(model, protocol, reasoning, row)` cell. The harness pins
the repository commits, source hash, local model file, llama.cpp build, sampler
settings, tool schema version and run ID before the first model call. The model receives
the candidate name and the task contract. It does not receive a deterministic
target or citation.

The residue and six-row oracle are separate labels over the same source-backed
task shape. The oracle is never disclosed to the model.

## Tools

The primary transport is an OpenAI-compatible structured tool call. The
harness validates arguments before execution and returns a typed error without
running a malformed request.

```text
search_standard(query, mode, max_results)
read_span(result_id, before_bytes, after_bytes)
read_rule(rule_number)
submit_pointer(name, decision, relation, evidence_ids)
```

`search_standard` searches only the pinned canonical text. `read_span` can
expand only a result returned by the same episode. `read_rule` returns one
numbered rule and its provenance. `submit_pointer` is checked by the
deterministic gate; it is a submission action, not a source lookup.

Every source result has a stable ID, document hash, page, byte start/end and
returned-byte count. The harness clips output before it reaches the model and
records both the unclipped request and returned bytes in the redacted trace.

## Control flow

```text
start episode
  -> model may request evidence
  -> deterministic tool result
  -> model may request more evidence or submit a pointer
  -> gate returns accepted or typed rejection
  -> bounded repair/evidence cycle
  -> terminal row result
```

The budgets are eight evidence calls, three submissions, a predeclared model
class turn cap, 32 KiB of source text and 300 seconds per row. The current caps
are twelve turns for checkpoints up to 4B, sixteen for 9B/26B, and twenty for
dense 27B/31B or sparse 35B-A3B. Reasoning-off runs precede a separately
recorded reasoning-on retry after failure. The runner never silently increases
a budget. It flushes the trajectory after every model/tool event and the row
result after every completed row; resume replays the recorded trajectory
rather than reissuing a successful tool call.

The gate recognizes direct source definitions, the normative assumed rules
R401/R402/R403, and lexical/operator terminals on numbered production
right-hand sides. It does not accept an ordinary syntax name merely because it
appears on a right-hand side. Source spans are UTF-8-safe at byte/page limits.

## Trace

Each episode has one JSONL trajectory. Events are append-only and include:

```text
run, episode, sequence, timestamp, role, tool, validated_arguments,
source_ids, returned_bytes, duration_ms, prompt_tokens, completion_tokens,
total_tokens, finish_reason, gate_status
```

The summary also records setup, model inference, tool and total wall time;
number of calls, submissions and repairs; source bytes; terminal state; and
the independent-oracle result. No API credentials are used by this experiment;
private reasoning is not recorded. A missing metric is `null`, never silently
reconstructed.

## Matrix execution

The runner materializes the complete matrix before execution. It writes one
manifest row for every model/protocol/reasoning/row combination, including
`pending`, `not_applicable`, `model_error`, `timeout` and `abandoned` states.
Execution may be chunked by model or hardware, but the analysis script reads
the materialized matrix and reports missing cells. A model is not dropped when
another model reaches a useful result.

The primary text comparison is:

```text
fixed supplied window | deterministic full retrieval | bounded native tools
```

with `reasoning=off` and `reasoning=on` as separate, predeclared cells. The
visual-first page control is reported separately for eligible image models and
never pooled with text.

## Analysis

The report must contain, for every model and variant:

* residue resolution, abstention, hard-failure and model-error rates;
* six-row exact translation, wrong acceptance and false-negative rates;
* evidence-hit rate, calls, submissions, repairs and source bytes;
* total, setup, inference and tool time, tokens and local model-file/runtime
  metadata;
* paired row-level differences against fixed-window and full-retrieval controls.

Plots show all cells, including zeroes and unavailable cells. A summary ranking
is secondary to the full table. Any excluded or incomplete cell is named before
an aggregate claim.
