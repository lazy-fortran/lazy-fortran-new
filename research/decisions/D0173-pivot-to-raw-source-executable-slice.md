# D0173. Pivot from residual CXXX intake to a raw-source executable slice

Date: 2026-08-18
Status: accepted

## Context

The bounded M3 oracle method is now demonstrated, but continuing to implement
residual CXXX constraints one at a time is not the shortest path to a usable
compiler. Those constraints are retained evidence material, not a required
implementation queue. L0, L1, L2 and M1-M2 already establish the central
control plane, while L2 begins from a frontend-v0 witness rather than raw
Fortran source.

## Decision

The active delivery path pivots to L3: one raw-source-to-executable Fortran
slice. Its first input is exactly one free-form named main program with no
declarations or executable statements:

```fortran
program p
end program p
```

The positive path is:

```text
raw source file
→ fortfront-new source parser
→ frontend-v0 result
→ ffc-new MIR-v0 lowering
→ existing fortback-new executable emission
→ process exit status 0
```

The central verifier must also reject a near-neighbour with a mismatched end
name, record the source and component hashes, and use an independent oracle.
The slice makes no claim about declarations, expressions, I/O, modules,
procedures, fixed-form source, or general Fortran parsing.

The CXXX residual corpus, including completed bounded oracle slices, remains
retained and may supply source-backed regression cases when the executable
subset requires them. It is no longer the default active frontier. No model
output promotes a semantic fact.

## Rejected

Processing every remaining CXXX row before building a raw-source path was
rejected because those rows are evidence units rather than compiler features
and do not compose into a parser or executable by themselves. A broad parser,
semantic analyser, or I/O implementation was rejected for this slice because
it would expand the boundary before the first source-to-executable observable
exists.

## Reversal condition

Reverse this decision only if the bounded L3 source slice cannot produce a
deterministic accepted executable and a deterministic rejected near-neighbour
after one disjoint implementation wave, or if the pinned component interfaces
cannot express that path without introducing a second control plane. Record
the exact failing stage and evidence before widening the scope.
