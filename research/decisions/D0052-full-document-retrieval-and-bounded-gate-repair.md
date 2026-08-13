# D0052. Full-document retrieval with bounded deterministic gate repair

Date: 2026-08-13
Status: amended by D0053
Amends: D0051
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0112 tested model selection over supplied 384-byte windows. That protocol
isolated source selection, but it could not test whether a model can discover
a definition elsewhere in the complete canonical standard. It also treated a
rejected first response as terminal, although a deterministic correction
message can be cheaper than extending the model's initial prompt.

## Decision

E0113 uses one fixed two-stage protocol for every model. First, deterministic
retrieval scans the complete canonical source for a small generic set of
subject-position definition forms. It supplies the retrieved windows, with
E0110 overlap windows first, and records all retrieval output. Retrieval may
find candidates but cannot promote facts.

Second, the model returns only `name`, `decision`, `relation` and `window`.
The gate checks the selected window against canonical bytes, source hash,
page containment and exact subject position, then derives the target and
provenance citation itself. The model never supplies source text or a target.

Each residue row receives at most three calls: the initial proposal and two
repair attempts. A valid proposal is `accepted`; a valid exact abstention is
also a green terminal result; a malformed, rejected or errored row after the
limit is `hard_failure`. Every call, repair iteration and terminal state is
retained. No model output is promoted automatically into StandardIR.

The comparison includes the available Qwen ladder in nominal-size order,
the Gemma ladder in size order, DeepSeek V4 Flash through its cloud endpoint,
and a one-shot GPT-5.6 Luna Codex CLI control. The protocol and gate are the
same; transport configuration and model provenance are recorded separately.

## Rejected

Asking the model to reproduce target text or citation bytes is rejected:
those are deterministic projections of a selected source span. Searching the
whole source only after a model proposal is rejected because it would conceal
whether the model selected the supplied evidence. Unlimited retries are
rejected because they erase the capability/cost measurement. Treating
abstention as failure is rejected: the residue contains names for which no
source-backed definition is present in the tested relation language.

## Reversal condition

Write a successor if deterministic retrieval requires candidate-specific
branches, if the fixed recognizer grows beyond its compact declarative rule
set, if repair changes the task into an unbounded search procedure, or if the
retrieval-plus-gate protocol systematically accepts a mechanically wrong
definition. Expand the relation language only through a separately recorded
source-backed decision or a fixed erratum.
