# D0068 — Use the clean upstream llama.cpp main runtime for local semantic runs

Date: 2026-08-14
Status: accepted

## Context

The local Qwen semantic service had been running an older local llama.cpp
build. E0116's recovery protocol depends on current named-tool handling,
request-level thinking control and timing telemetry. The development checkout
also contains unrelated uncommitted compatibility work, so it is not a safe
runtime source.

## Decision

Build llama.cpp from the clean upstream `master` commit
`65091386227039bfb81ee3426537656e3b4a3f83` (build 10427) with CUDA enabled,
install it in a versioned user-local directory, and point the Qwen systemd
profile at that directory. Keep the previous installation intact for
rollback. Record the exact upstream commit and service settings in every run
that uses the service.

The E0116 service uses a bounded reasoning budget of 4096. Requests disable
thinking by default; the harness may start one fresh thinking-on episode after
a failed no-thinking attempt.

## Rejected

- Running the dirty compatibility checkout as the experiment runtime.
- Replacing the old installation in place without a rollback path.
- Treating a successful binary build as evidence that semantic proposals are
  correct; the existing schema, provenance and witness gates remain required.

## Reversal condition

Amend this decision if the pinned upstream build fails the E0116 fixture or
service smoke test, regresses the independently witnessed result, or prevents
reproducible tool-call and timing telemetry compared with a later pinned
upstream build.
