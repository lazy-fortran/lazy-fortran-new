# D0184. Select the next source-derived main-program-name boundary

Date: 2026-08-18
Status: accepted

## Context

The bounded source-derived variable-name slice is promoted only for the fixed
`program p` / `integer :: name` AST v1 shape. The existing schema also exposes
`program-root.name` and `program-declaration.name`, while the producer still
uses the literal root name `p`. The next useful boundary is the source-derived
main-program name and its matching `END PROGRAM` spelling, not another
variable-name fixture.

## Decision

Open one contract-selection task over the existing AST v1 fields. Its compact
family is:

```fortran
program main
  integer :: x
end program main
```

with one changed-name control using `unit` consistently and one negative
neighbour with a mismatched end name. The expected root and program-declaration
names must be derived from the source; the contract must preserve the existing
integer variable record and reject the mismatched end. The source evidence is
the pinned J3-24-007 document hash ending `9979f9e`, rules R501, R1401, R1402,
R1403, R601, R603, R704, R705 and R801, and the existing `frontend-ast-v1`
schema. No producer change starts in this contract task.

## Rejected

More exact variable-name cases, multiple declarations, attributes, kind
selectors, case folding, symbol resolution, general parser work, semantic
analysis and a new schema revision are outside this boundary.

## Reversal condition

Reverse or split this choice if the existing root/declaration fields cannot
express the source-derived relation, if R1402/R1403 do not bind as recorded, or
if an independent oracle cannot distinguish the changed-name and mismatched
end controls.
