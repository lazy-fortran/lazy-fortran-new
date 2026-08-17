# D0175. Add a typed variable declaration AST boundary

Date: 2026-08-18
Status: accepted

## Context

The promoted L3 declaration slice accepts the exact source spelling
`integer :: x` but deliberately preserves the old frontend-v0 result and
erases the declaration before MIR lowering. The next useful increment is to
make that declaration observable in the typed frontend AST without mixing AST
records into the frontend-v0 result exchange or starting general semantic
analysis.

## Decision

Add `frontend-ast` version 1 as an additive central contract. Its bounded
positive witness is the existing source:

```fortran
program p
  integer :: x
end program p
```

The v1 `program-unit` record carries exactly one existing program declaration
and exactly one `variable-declaration` with `type-spec integer`, `name x`, and
the source span of the declaration line. The existing `frontend-ast-v0` and
`frontend-v0` contracts remain unchanged. The contract is a typed source-span
boundary only: it does not infer symbol tables, implicit typing, kind values,
storage, rank, initialization, or executable semantics.

The production generator must consume the central v1 schema and emit the
typed record mechanically. The independent central oracle must compare the
canonical v1 SX output and exact source span, reject the existing malformed
`integer ::` neighbour, and require zero model calls and zero semantic
promotions.

## Rejected

Extending `frontend-v0` with variable fields is rejected because D0071
separates the result exchange from the typed AST. Adding general declaration
lists, type selectors, attributes, multiple entities, or MIR lowering is
rejected until this one-record AST boundary has an independent replay.

## Reversal condition

Write a successor if the v1 schema cannot be generated without language-specific
special cases, if the source span cannot be reproduced from exact bytes, or if
the independent oracle shows that the added field changes the existing
frontend-v0 result or promotes semantic facts.
