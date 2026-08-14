# D0059. Deterministic-first semantic residuals with bounded local proposals

Date: 2026-08-14
Status: accepted

## Context

E0115 established two different facts. The deterministic source-relation
closure covered all 127 remaining name candidates with generic routes. The
bounded local-model protocol then measured whether a model could navigate the
same source and submit valid evidence; Qwen 3.6 35B-A3B reached 127/127 after
bounded retries and 6/6 exact solved-row oracle translations. The model was not
needed to make the current name residue mechanically decidable.

The next residue is semantic prose such as C702, where the source identifies a
conditional relation between a syntax occurrence, declaration attributes and
facts established by earlier semantic phases. A deterministic extractor can
locate and normalize some of this structure, but a compact generic parser may
not uniquely recover the typed predicate and its fact dependencies.

## Decision

StandardIR semantic recovery uses this order:

```text
deterministic extraction and normalization
    -> unique typed relation: accept as MECHANICAL
    -> ambiguity or missing typed predicate:
       bounded local LLM proposes only a small typed relation
    -> deterministic schema/provenance/behavior gate
    -> accept as LLM or LLM_REPAIR, otherwise retain unresolved
```

The LLM may select bounded source evidence or propose a local typed predicate.
It may not invent source facts, choose compiler-wide architecture, create
callers or dispatch, or bypass the deterministic gate. All local models in a
declared comparison campaign receive the same source, tools, budgets and
oracle; reasoning and bounded retries are separate recorded cells. Failed
rows remain in the denominator.

Campaign plots are generated from ignored run artifacts. Their data, command,
model/runtime pins and plot filenames are recorded in git; PNG handoffs are
uploaded to slopbox after each completed campaign. This does not make slopbox
part of the research system.

## Rejected

- Sending every semantic clause to an LLM: it would obscure the mechanical
  fraction and make source provenance harder to audit.
- Adding a candidate-specific parser branch for each difficult clause: it would
  turn the residue into an expanding exception list.
- Letting an LLM emit Fortran modules or compiler wiring: local synthesis is
  allowed only below the generated StandardIR/ImplIR interfaces.

## Reversal condition

Reverse this decision if a generic deterministic semantic normalizer resolves
the full declared Core 0 residue with the same source and behavioral gates, or
if repeated local-model campaigns show no useful improvement over deterministic
residual handling. Conversely, expand the bounded proposal stage only if its
typed predicates pass independent source and behavioral validation without
candidate-specific rescue code.
