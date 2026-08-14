# D0070 — Track the latest verified upstream llama.cpp main

Date: 2026-08-14
Status: accepted
Supersedes: D0068

## Context

The E0117 service was pinned to upstream `650913862`, but upstream `master`
has advanced to `885c5bbe8e04dc78db25beb911a2715312ad7b54`. The semantic
harness depends on current server behavior and the user requires future local
runs to use the latest upstream main, while earlier runs must remain
reproducible.

## Decision

Build the clean upstream `master` checkout at
`885c5bbe8e04dc78db25beb911a2715312ad7b54` with CUDA enabled for the local
SM120 GPUs. Install it beside earlier versioned builds, smoke-test the server,
and record the exact commit, build and service settings in every run. Keep
`650913862` and all earlier installations for historical replay; changing the
runtime does not rewrite an existing run record.

Future semantic runs use the newest successfully built upstream `master`
binary available before their manifest is pinned. A newer upstream commit
requires the same build and smoke-test procedure before it becomes current.

## Rejected

- Continuing to call `650913862` current after upstream `master` advanced.
- Replacing the old installation in place and losing rollback/replay ability.
- Treating a newer binary's successful build as semantic evidence without the
  existing schema, provenance and behavioral gates.

## Reversal condition

Write a successor if this build fails its server smoke test, regresses the
E0117 fixture or tool/timing protocol, or a later upstream main passes the same
checks and supersedes it.
