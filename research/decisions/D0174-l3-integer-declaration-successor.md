# D0174. Bound the L3 integer-declaration successor

Date: 2026-08-18
Status: accepted

## Context

The first L3 source-to-executable slice is promoted only for an empty named
main program. The next useful source increment is a declaration in its
specification part, but the existing frontend-v0 result and downstream MIR
contracts do not represent variable declarations. A larger AST or semantic
change would widen the slice before its source acceptance is independently
verified.

## Decision

Define the successor as one exact free-form source shape:

```fortran
program p
  integer :: x
end program p
```

The central negative neighbour is the malformed declaration:

```fortran
program p
  integer ::
end program p
```

The source-backed evidence set is the pinned J3-24-007 syntax path R501,
R1401, R504, R507, R508, R704, R705 and R801, with the existing StandardIR
provenance replay pinned in `contracts/fixtures/l3-declaration-v0.sx`.
The implementation may preserve the existing frontend-v0 observable and
existing two-instruction MIR/executable path; it must not claim typed symbol,
declaration, or semantic-name support until a later contract exposes those
objects. No model output may promote a semantic fact.

## Rejected

`integer x` is rejected as a negative control because it is valid Fortran
syntax. General declaration parsing, kind selectors, attributes, multiple
entities, initialization, executable statements, and a new AST/MIR declaration
contract are outside this successor.

## Reversal condition

Reverse or split this decision if the exact positive cannot be accepted and the
malformed neighbour rejected without changing downstream contracts, or if
review finds that preserving only the existing frontend-v0 observable makes
the source claim misleading. Record the failing command and source witness.
