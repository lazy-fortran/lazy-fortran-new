# D0054. Bounded tool-assisted evidence acquisition

Date: 2026-08-13
Status: amended by D0058
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0113 supplies deterministic windows before the model sees a residue row. Its
large abstention count is consistent with a retrieval limitation: the
fixed-form retriever found evidence for only a small part of the residue. It
does not establish that the models cannot find the evidence when allowed to
ask focused, bounded questions.

The next protocol needs an agent loop, but not a general coding agent. The
useful precedent is [mini-SWE-agent v2's native tool-call loop](https://mini-swe-agent.com/latest/advanced/v2_migration/)
and [trajectory format](https://mini-swe-agent.com/latest/usage/output_files/).
Slopqueue adds the relevant operational controls: bounded tool output,
durable per-run traces, checkpoint/resume, explicit timing, and context
compaction that retains an evidence ledger. The experiment must retain those
controls without importing a service, database or repository-editing surface.

## Decision

E0115 uses a deterministic evidence environment with native structured tool
calls. Text parsing of commands is not part of the primary protocol. A model
that cannot use the declared tool interface is a protocol failure; a separate
text-parser control may be run only as an explicitly labelled transport
control.

The primary tool registry has three read-only tools and one submission tool:

1. `search_standard(query, mode, max_results)` searches the pinned canonical
   text and returns bounded source snippets with document hash, page, byte
   span and a stable result ID.
2. `read_span(result_id, before_bytes, after_bytes)` expands one returned
   source span, subject to a byte limit.
3. `read_rule(rule_number)` returns one numbered normative rule with its
   source metadata.
4. `submit_pointer(name, decision, relation, evidence_ids)` submits the
   pointer-only result. The deterministic gate derives target text and the
   citation from the selected evidence; the model never supplies either.

Tool results contain canonical source evidence only. They do not contain a
hidden target, an E0110 label, or a precomputed acceptance decision. Every
call and result is retained in an append-only JSONL trajectory. Each event
records sequence, row, tool, validated arguments, returned bytes, source IDs,
duration, prompt/completion/total tokens where available, finish reason and
gate state. A redacted trajectory, configuration, checkpoint and summary are
the reproducibility package; credentials and model-private reasoning are not
committed.

Each row has fixed budgets: at most eight evidence calls, three submissions,
32 KiB of returned source text, three repair messages, and a declared wall
clock limit. A submission may receive a typed gate rejection and the model may
use remaining evidence calls. A row terminates as `accepted`, `wrong_accepted`,
`abstained_after_budget`, `hard_failure` or `model_error`. Abstention is not a
green result here: it is a false negative for both the unresolved discovery
denominator and the six-row solved-translation oracle.

The comparison is a predeclared factorial matrix. Every eligible text model is
run on every text protocol, with reasoning off and on as separate cells:

* fixed supplied-window control;
* E0113 deterministic full-document retrieval;
* bounded native-tool evidence acquisition.

Every image-capable model is additionally run on the E0114 visual-first page
protocol, with reasoning off and on as separate cells. Non-image models have
explicit `not_applicable` cells rather than silently disappearing. No model is
removed when another model appears reliable. The matrix is executed in waves,
but stopping rules are administrative only and cannot change the denominator.

The fixed row sets are the complete 127-row residue and all six E0110 solved
definitions. The primary measures are resolution rate, exact six-row oracle
accuracy, wrong-accept rate, abstention and hard-failure rate. Secondary
measures are evidence-hit rate, tool calls, submissions, repair count, source
bytes, total/setup/inference/tool wall time, tokens and cloud cost. Reports
show paired row-level comparisons, per-model/per-variant tables, and the full
failure denominator before any aggregate ranking.

This protocol is deliberately a small evidence harness, not a general agent:
no shell, file mutation, web access, unrestricted source dump, delegation or
semantic promotion is exposed to the model.

## Rejected

Giving the model the complete PDF or canonical document by default is rejected:
it removes evidence acquisition as a measurable capability and makes context
cost incomparable. An unrestricted search API is rejected because it permits
an unbounded retrieval loop. Returning the target or citation from a tool is
rejected because it turns translation into lookup. Regex extraction of tool
commands is rejected for the primary run because malformed transport and model
reasoning become confounded. Adaptive escalation from reasoning-off to
reasoning-on is rejected in the comparison matrix; it is useful operationally
but not a clean experiment. Stopping the ladder after the first successful
model is rejected because it prevents model-family and harness comparison.

## Reversal condition

Write a successor if the four-tool surface requires candidate-specific branches,
if its implementation exceeds the compact source-retrieval and gate logic it
supports, if native tool transport is unavailable for the declared model
families, or if tool-assisted accuracy cannot be distinguished from a tool
that leaks the answer. Reduce or replace a tool only with a replayable ablation
showing that it contributes no measurable evidence or quality.
