# D0045. Native Codex subagents for parallel slices

Date: 2026-08-13
Status: accepted
Supersedes: D0043
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

D0043 described production delegation as one-shot shell-launched GPT tasks.
That distinction is no longer the useful boundary: current Codex provides
managed native subagents that can run independent slices in parallel and return
their results to the coordinating thread. The old detached-process instructions
also encouraged manual process tracking and repeated status checks.

## Decision

Use native Codex subagents for explicitly requested parallel production and
research slices. The coordinator gives each subagent one exclusive checkout or
worktree, branch, exact base commit, file scope, accepted contract revisions,
test command and report schema. The coordinator explicitly selects
GPT-5.6 Luna for these subagents. Native Codex owns subagent lifetime, waiting
and result collection; the coordinator integrates only after checking the
reported commit, diff, gates and oracle.

Keep `gpt-delegate.sh` for bounded reproducible `codex exec` experiments that
need a transcript and JSONL event log. It is synchronous, defaults to
GPT-5.6 Luna, and retains the approved bypass of approval and sandbox prompts.
It is not the production delegation mechanism.

## Rejected

Detached shell launches, PID files and self-managed polling are rejected because
they are not the Codex agent lifecycle and can cause goal continuations to
re-enter a task without a reliable completion event. A permanent scheduler or
shared task service remains rejected because the laboratory must stay a
searchable file record.

## Reversal condition

Write a successor if native Codex cannot reliably run a bounded subagent in an
assigned sibling checkout, return a final result to the coordinator, or support
the required model selection and independent-slice isolation. Preserve the
reproducible `codex exec` path for experiments even if production delegation
changes again.
