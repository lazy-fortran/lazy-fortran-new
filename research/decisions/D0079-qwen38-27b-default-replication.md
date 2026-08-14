# D0079 — Use Qwen 3.8 27B as the default local replication model

Date: 2026-08-14
Status: accepted

## Context

The semantic protocol was established with Qwen 3.6 35B-A3B. A Qwen 3.8
27B service is now being prepared on the local llama.cpp server and will use
the existing local endpoint at `127.0.0.1:8080`. The older model's results are
historical evidence and must remain reproducible; changing reported manifests
or silently changing a running service would destroy that distinction.

The semantic work also clarified that model output is only one stage of the
pipeline. Deterministic extraction owns source segmentation, provenance,
cross-references, schema and rejection. The model receives one bounded local
task and may navigate declared source tools. Witness generation, replay,
promotion and compiler wiring remain deterministic.

## Decision

Use the logical profile `qwen38-27b` as the default model for new local
experiments. Use the currently active local llama.cpp endpoint and configuration
without starting, stopping, reloading or reconfiguring the service. The exact
server model ID, model hash, llama.cpp commit/build, quantization, context,
sampler and reasoning settings must be captured by preflight in every run.

Create E0142 as an unstarted replication matrix covering the existing semantic
protocol stack:

- E0112/E0113/E0115 fixed-window, full-retrieval and bounded-native-tool text
  cells over the 127-row residue and six-row solved oracle;
- E0114's visual-first control only if preflight proves that the active model
  accepts images, otherwise an explicit `not_applicable` cell;
- E0116's typed-predicate proposal pass over all 287 constraint occurrences;
- E0117's required-witness replay over the same denominator;
- E0123's exact 53-row residual retry with the 234 predecessor controls.

Every applicable cell runs reasoning off first. A failed cell may receive one
fresh thinking-on episode under the declared finite turn/token/tool budgets.
All rows, attempts, trajectories, failures, timings and unavailable cells are
retained. Qwen 3.6 35B-A3B remains an explicit historical control and is never
replaced in earlier run records.

## Rejected

- Editing reported experiment manifests to make old results appear to use
  Qwen 3.8.
- Restarting or changing the active llama.cpp service as part of wiring.
- Treating a schema-valid model predicate as a semantic fact without an
  independent witness.
- Giving the model the complete corpus by default or allowing it to invent
  fact names, citations, dependencies or compiler wiring.
- Assuming visual capability from the model name alone.

## Reversal condition

Reconsider the default after E0142 if Qwen 3.8 27B cannot complete the bounded
text protocol with reproducible transport, schema and witness behavior, or if
its measured quality/cost is inferior to the retained Qwen 3.6 control. Any
model change remains a new profile and a new run; historical records are not
rewritten.
