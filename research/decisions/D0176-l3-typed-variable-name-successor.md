# D0176. Bound the typed variable-name successor

Date: 2026-08-18
Status: accepted

## Context

E0235 promoted one typed AST v1 declaration, but its exact producer witness
uses the variable name `x`. The next smallest useful check is to preserve a
different source name through the same generated v1 record without adding a
new schema, declaration form or semantic layer.

## Decision

Add one additive source fixture with the exact free-form shape:

```fortran
program p
  integer :: y
end program p
```

Reuse the v1 `program-unit` schema and the existing malformed neighbour
`integer ::`. The expected typed record has one integer variable declaration
named `y`, with declaration span bytes 10 through 24 and source-hash label
`l3-raw-program-variable-name-v1`. Reuse the D0174 normative syntax path
R501, R1401, R504, R507, R508, R704, R705 and R801 and its pinned J3-24-007 /
StandardIR provenance. This tests source-name preservation only; it does not
infer symbol identity, scope, type semantics, implicit typing or MIR facts.

The central contract must pin the exact positive and negative bytes, the
typed expected fields, the v1 schema and a source-backed witness before the
producer implementation starts. No model output may promote a semantic fact.

## Rejected

General identifier parsing, multiple entities, attributes, kind selectors,
symbol tables, semantic analysis, MIR lowering and a new AST schema revision
are outside this successor. Changing the old frontend-v0 observable is also
rejected.

## Reversal condition

Reverse or split this decision if the same v1 record cannot preserve `y`
without widening the source form, changing frontend-v0, or adding semantic
inference; retain the failing source and oracle evidence.
