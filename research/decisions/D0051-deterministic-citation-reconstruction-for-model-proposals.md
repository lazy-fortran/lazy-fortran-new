# D0051. Deterministic citation reconstruction for model proposals

Date: 2026-08-13
Status: amended by D0052
Amends: D0050
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The Qwen3.5-4B non-thinking audit shows that the model does produce local
proposals, but many fail because it copies a 384-byte window, invents a name,
or emits a citation span that is not byte-identical. The Qwen3.5-4B thinking
run spends its bounded output budget in reasoning and returns no parseable
answer. Counting these as semantic failures would mix model reasoning with a
mechanical byte-serialization task.

## Decision

For E0112, the model returns only a strict-schema local proposal: the exact
candidate name, relation, target and a 1-based index selecting one supplied
source window. The deterministic validator checks that window against the
canonical bytes, finds exactly one subject-position definition of the returned
relation, reconstructs the exact source span and emits the provenance-bearing
citation. The validator remains the independent acceptance gate; no semantic
fact is promoted.

The raw-citation E0111 pilot remains retained as evidence of the original
serialization bottleneck. E0112's model errors measure transport, schema or
empty-content failures; pointer-mode validator rejections measure incorrect
semantic/evidence selections.

## Rejected

Letting the model return arbitrary citation text is rejected because exact
source-byte identity is deterministic and needlessly expensive in model
tokens. Letting the validator search the whole standard after a model proposal
is rejected because that would hide whether the model selected the supplied
evidence. Accepting a model proposal without a unique subject-position match
is rejected because it would weaken D0048.

## Reversal condition

Write a successor if pointer mode accepts proposals that raw citation mode
would reject for a substantive source-selection reason, if a model can exploit
window indices without seeing the defining text, or if deterministic citation
reconstruction makes the comparison no longer measure the intended local
semantic capability.
