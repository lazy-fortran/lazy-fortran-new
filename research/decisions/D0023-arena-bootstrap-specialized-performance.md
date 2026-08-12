# D0023. Arena bootstrap with specialized performance representations

Date: 2026-08-12
Status: accepted
Amends: D0022

## Context

The actual StandardIR schema has recursive syntax expressions and provenance.
The schema must remain authoritative without forcing one Fortran storage layout
onto every consumer. An arena is attractive for bootstrap tooling, canonical
loading, provenance and deterministic IDs, but a generic arena interpreter is
not automatically the fastest semantic implementation.

## Decision

1. StandardIR schemas describe semantic structure and canonical SX values, not
   the target storage layout.
2. The first generated StandardIR backend uses a deterministic arena with
   integer node IDs, packed node storage and explicit child ranges. It is the
   bootstrap, persistence, hashing, provenance and generic traversal backend.
3. Generated compiler hot paths may use packed arrays, structure-of-arrays
   layouts, typed views or directly specialized Fortran procedures derived from
   the same StandardIR. These are derived representations, not additional
   semantic sources.
4. The production compiler does not interpret the StandardIR arena on every
   source-program operation. The wiring generator and specializer turn the
   accepted records into direct generated code and may fuse away generic
   dispatch.
5. The exact hot-path layout remains an empirical choice. It is selected by
   pinned benchmarks measuring correctness, cache-sensitive throughput,
   allocation behavior, memory footprint and generated-source stability.

## Rejected

**One mandatory recursive heap object per syntax node.** It is simple to
express, but risks allocation and pointer-chasing overhead and is a poor
Bootstrap Core default.

**One mandatory arena layout for all compiler stages.** It would optimize the
schema loader at the cost of preventing generated, domain-specific layouts in
the compiler hot paths.

**A generic arena interpreter as the final semantic engine.** It preserves the
declarative data but leaves runtime dispatch and lookup in the critical path.
specialization should remove those costs where measurements justify it.

## Reversal condition

Write a successor decision if the first arena backend cannot meet the
Bootstrap Core, provenance or canonical-serialization gates, or if pinned
benchmarks show that the backend prevents the required generated performance
without a practical derived representation.
