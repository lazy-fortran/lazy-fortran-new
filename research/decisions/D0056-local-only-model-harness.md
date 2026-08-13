# D0056. Use local models for future residue harnesses

Date: 2026-08-13
Status: accepted

## Context

E0113 compared local Qwen and Gemma checkpoints with DeepSeek V4 Flash through
an official cloud API and a GPT-5.6 Luna Codex control. Neither remote control
resolved the residue reliably: DeepSeek accepted five rows, all overlapping
the solved oracle, and Luna accepted two. Their additional cost does not buy a
clearer next experiment. The local ladder already supplies the relevant model
family and size comparisons, and its runtime is pinned by D0055.

## Decision

From E0115 onward, the model harness uses only locally hosted Qwen and Gemma
checkpoints through the pinned llama.cpp runtime. Model inference runs with
network access disabled and no API credentials. Every declared local model
remains in the denominator; missing checkpoints and local runtime failures are
recorded as explicit failed cells. DeepSeek and Luna remain immutable historical
controls in E0113 and earlier experiments, but are excluded from future model
matrices.

## Rejected

Continuing the DeepSeek API was rejected because its E0113 result did not
improve on the strongest local controls and incurs recurring cost. Continuing
Luna in every cell was rejected for the same reason and because a remote
Codex execution is not comparable to the local llama.cpp resource profile.
Deleting the historical runs was rejected because it would destroy the
comparison denominator and provenance.

## Reversal condition

Write a successor only if a predeclared local-only comparison shows that a
remote model is necessary to answer a specific research question that local
models cannot answer, and records a bounded cost ceiling and explicit funding
or approval for that experiment.
