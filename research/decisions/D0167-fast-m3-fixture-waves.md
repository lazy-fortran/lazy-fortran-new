# D0167. Fast M3 fixture waves

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

M3 progress has been limited by serial coordination rather than by the
bounded oracle code. The first provisional harvest produced a large intake
batch, but workers used inconsistent source coordinates and one batch was
malformed. The controller repaired source envelopes and then implemented one
leaf through repeated review and replay cycles.

The current harvest counts are reproduced by:

```text
jq -c '{packet_count,readiness_counts}' artifacts/staging/m3-harvest-v0.json
```

The C760 replay and review are recorded in
`research/runs/2026-08.jsonl#R000623` and demonstrate that model-authored
semantic packets can remain useful input while deterministic source binding
and the independent oracle retain authority.

## Decision

Use fast, bounded waves for M3 fixture production and implementation.

- Native production and fixture workers use `gpt-5.6-luna` with reasoning
  effort `medium` by default. `low` is not used for semantic fixture
  generation or review. A higher effort requires an exact blocker or an
  explicit task-level reason.
- Freeze the source ledger, StandardIR inputs, contract schema and output
  schema before dispatch. Partition work by disjoint source rows and worktrees.
- A harvest worker returns batch JSONL and a concise batch report. It does not
  edit central metadata, create per-case decision records, commit, push, or
  promote a semantic fact. Each semantic packet is labelled `LLM`.
- The controller performs one batch intake pass. It mechanically validates
  JSON shape and rebinds source envelopes to the pinned source ledger when
  necessary. Mechanical source repair cannot alter semantic fields or promote
  a packet. Malformed packets remain retained failures and are excluded from
  the ready set.
- The harvest-first gate applies to the current batch: implementation starts
  only after that batch has passed structural intake. Later harvest batches may
  overlap implementation once their inputs and worktrees are disjoint.
- The controller selects the strongest ready candidates for implementation in
  parallel. Each selected candidate still receives its own typed contract,
  independent oracle, negative or unresolved neighbours, mutation controls and
  clean replay. Batch intake does not become batch semantic promotion.
- Central metadata is updated once per wave. Candidate packets do not receive
  separate durable decision records until selected for implementation. Focused
  review is reserved for the reusable-artifact or milestone boundary. Ordinary
  worker output receives the smallest verifier and optional micro-review.

The controller remains the only owner of central state, integration and
promotion. The fast lane removes repeated coordination, not the provenance,
oracle, clean-checkout or no-model-promotion rules.

## Rejected

Using `low` reasoning for semantic fixture generation is rejected because the
first harvest spent a worker wave on unusable abstentions and malformed output.

Requiring the entire residual ledger to be implementation-ready before using
any ready candidate is rejected because it serializes independent delivery.

Giving workers central metadata or promotion authority is rejected because it
would make batch intake and semantic promotion race-prone.

Running one reviewer and one documentation cycle for every provisional packet
is rejected. The packet is staging evidence until a selected candidate crosses
its own verifier and the applicable review boundary.

## Reversal condition

Write a successor if medium-depth waves repeatedly produce source-binding
failures that mechanical intake cannot isolate, if parallel implementation
causes integration races despite disjoint scopes and frozen bases, or if the
bounded oracle promotion rate falls below the prior serial process after the
same intake and replay commands are compared.
