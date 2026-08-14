# D0080 — Run the Qwen 3.8 27B replication matrix next

Date: 2026-08-14
Status: accepted

## Context

E0123's Qwen 3.6 35B-A3B model phase completed, but its deterministic
post-run merge, validation and witness gates are still separate work. The
Qwen 3.8 27B server was loaded for the planned successor campaign and has now
been stopped intentionally. The next useful comparison is therefore the
complete, reproducible 27B replication of the protocol families already used,
not another model-selection ladder.

## Decision

Execute E0142 next with the Qwen 3.8 27B logical profile and the separately
managed llama.cpp service bound to
`http://127.0.0.1:8080/v1/chat/completions`. The service must be started with
the intended active configuration before preflight; the experiment harness
does not start, stop, reload or reconfigure it.

Repeat the prior protocol families in this order: E0112 fixed-pointer residue,
E0113 full retrieval and repair, E0114 visual-first solved-oracle control when
image capability is proven, E0115 bounded native tools, E0116 typed predicates,
E0117 required witnesses, and E0123's exact residual retry with its immutable
controls. Reasoning is off first, with at most one fresh thinking-on episode
after failure. Every row, attempt, failure, timing, token count, unavailable
cell and deterministic gate result remains recorded.

The deterministic side owns denominators, source segmentation, provenance,
schema, replay, witness construction, exact row-key merging and promotion.
The model proposes only the bounded local fragment permitted by each existing
protocol. No result is promoted merely because the model produced valid JSON.

## Rejected

- Starting a new model ladder before the complete 27B replication has a
  terminal matrix and comparison report.
- Treating the stopped server as an experiment failure; no E0142 cell has
  started, and the service lifecycle is outside the experiment.
- Rewriting Qwen 3.6 historical manifests or E0123's append-only outputs.
- Allowing the model to change denominators, provenance, fact vocabulary,
  witness rules or compiler wiring.

## Reversal condition

Open a successor decision only after E0142's complete matrix is terminal and
its measured quality, reproducibility, gate behavior and total cost justify a
different model or protocol. A service or transport failure is reported as a
failure cell, not silently repaired by changing the experiment.
