# D0055. Pin llama.cpp runtime and conservative Gemma 4 configuration

Date: 2026-08-13
Status: accepted

## Context

The first Gemma 4 E4B local preflight used the installed llama.cpp wrapper at
commit `19e92c3`, with ordinary layer splitting and flash attention. The
server aborted during model loading with
`GGML_ASSERT(n_inputs < GGML_SCHED_MAX_SPLIT_INPUTS)`. This is a runtime
failure, not evidence that the model cannot perform the task. The current
official release on 2026-08-13 is `b10405`, commit
`e79e4bf660e19f2ad851e06c6913f7a8c5852621`; it builds successfully for the
machine's CUDA 13.3 / SM120 target.

## Decision

Use the pinned `b10405` build as the local experiment runtime and record the
commit in every run. For Gemma 4, use the conservative single-GPU control
configuration `--split-mode none --main-gpu 0 --flash-attn off --parallel 1`
until a newer tested configuration is shown stable. Keep layer splitting and
flash attention configurable in the serving scripts rather than hard-coded.
Retain the old-runtime preflight as a toolchain-control failure, separate from
model-quality results.

## Rejected

Treating the loader assertion as a model error was rejected because the new
runtime loads the same checkpoint. Leaving the runtime unpinned was rejected
because it makes model comparisons non-reproducible. Requiring the
conservative configuration for every model was rejected because it would
confound ordinary model cells with a Gemma-specific workaround.

## Reversal condition

Write a successor when a newer official build and configuration passes the
same Gemma 4 load and inference preflight, with no scheduler assertion or
quality regression, and the exact build/configuration is recorded in the run
ledger.
