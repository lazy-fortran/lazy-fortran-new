# D0078. Scale reusable mechanisms before adding more witnesses

Date: 2026-08-14
Status: accepted

## Context

The bounded `standardir-grammar-v0` producer-to-consumer handoff is now
accepted as E0124. The preceding production waves established useful typed
boundaries and independent gates, but many backend and frontend slices were
single-record or single-query witnesses. Continuing that pattern would grow
the production repositories without testing whether the mechanisms scale to
the generated tables the project ultimately requires.

## Decision

After a bounded handoff is proven, the next production slices must first scale
the reusable mechanism: batch source-backed production, generic grammar fixed
points, normalized target-record tables, generated tables, or equivalent
whole-set operations. A new isolated instruction, token, accessor or query is
not an accepted slice unless it is required by such a mechanism. Scale slices
remain deterministic, source/provenance preserving and independently tested.
They must not add parser or token dispatch, semantic promotion, ISA-specific
dispatch, ABI/MIR wiring or a new cross-repository contract without a separate
decision.

## Rejected

Adding another individual mnemonic, frontend query or accessor would produce
more witness coverage but would not test the batch, fixed-point or table
boundaries needed for generated infrastructure. Freezing production work until
the complete parser or backend exists would discard useful independent
parallelism and is unnecessary.

## Reversal condition

Reverse this decision if a scale slice cannot preserve the same independent
oracle and provenance guarantees as its bounded witness, or if measured
whole-set use shows that the proposed generic mechanism requires more
language- or ISA-specific exceptions than the mechanism it replaces.
