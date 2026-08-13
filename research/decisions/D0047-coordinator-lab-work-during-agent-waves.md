# D0047. Coordinator laboratory work during agent waves

Date: 2026-08-13
Status: accepted
Amends: D0045
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The first Wave L production agents completed while the coordinator waited for
their reports. The laboratory still had an independent D0046 measurement ready
to run, so waiting left useful work idle and delayed the evidence needed for
the next semantic decision.

## Decision

Every parallel production wave must include an explicit coordinator-side
laboratory slice whenever a safe independent slice exists. The coordinator
starts that work immediately alongside the native Luna agents. Eligible work
includes experiment analysis, source-pin verification, provenance updates,
decision records and roadmap metadata. It must use disjoint files and inputs,
must not inspect or alter an unverified agent worktree, and must not implement
the agent's production task a second time.

This is active work, not monitoring: native Codex owns agent lifetime and
completion events, while the coordinator advances the laboratory. If no safe
laboratory slice exists, the coordinator records the reason and returns
control rather than manufacturing a task or polling.

## Rejected

Waiting for agent reports before starting laboratory work was rejected because
it serializes independent evidence collection and makes the central roadmap a
passive queue. Detached background jobs and polling remain rejected under
D0045; this decision does not create an orchestration service.

## Reversal condition

Write a successor if coordinator-side parallel laboratory work repeatedly
causes conflicting metadata, invalidates production inputs, or prevents exact
integration and cleanup, despite explicit disjoint scopes and recorded pins.
