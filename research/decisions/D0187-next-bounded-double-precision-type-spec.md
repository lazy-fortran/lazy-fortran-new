# D0187. Select the next bounded DOUBLE PRECISION type-spec boundary

Date: 2026-08-18
Status: amended by D0188

## Context

The bounded REAL type-spec leaf is promoted only for the fixed typed AST v1
shape containing one `real :: x` declaration. The existing schema represents
the declaration type as a name atom, and the pushed producer now distinguishes
REAL from the retained integer control. The next source-backed type alternative
is the adjacent no-kind-selector `DOUBLE PRECISION` occurrence in the same
standard production. This is a small lexical/type-spelling extension, not a
general intrinsic-type implementation.

## Decision

Open one bounded contract for this exact source shape:

```fortran
program main
  double precision :: x
end program main
```

Retain the existing `program-root`, `program-declaration`, and
`variable-declaration` AST v1 records, with `variable.type-spec = double
precision` and `variable.name = x`. The promoted REAL source is the changed-type
control, and the malformed `double precision ::` source is the negative
neighbour. No schema revision is needed. The implementation must preserve the
promoted REAL and integer behavior and the existing frontend-v0/MIR-v0
observables.

The exact source evidence remains J3-24-007, PDF SHA-256
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`, canonical
text SHA-256
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, and
StandardIR SHA-256
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`:

- R501, R1401, R1402, R1403 and C1401 for the retained main-program envelope;
- R601 and R603 for the source name;
- R702 and R703 at canonical lines 3135 and 3140 for type-spec context;
- R704 at canonical lines 3255--3260, specifically the `DOUBLE PRECISION`
  alternative at line 3257;
- R801 for the type-declaration statement at page 117.

## Rejected

Kind selectors, COMPLEX, CHARACTER, LOGICAL, attributes, multiple
declarations, expressions, assignments, general intrinsic-type parsing,
semantic type checking and full M3 promotion remain outside this boundary.

## Reversal condition

Write a successor if the pinned R704 occurrence does not contain the
`DOUBLE PRECISION` alternative, if the existing AST v1 type-spec field cannot
represent the spelling without a schema change, or if an independent oracle
cannot distinguish the changed REAL control from the malformed declaration.
