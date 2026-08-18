# D0186. Select the next bounded intrinsic type-spec boundary

Date: 2026-08-18
Status: accepted

## Context

The source-derived program-root-name leaf is promoted only for the fixed typed
AST v1 shape containing one `integer :: x` declaration. The existing schema
already carries the declaration's `variable.type-spec` as a name atom, and the
current producer hard-codes the integer spelling. The next useful boundary is
one source-derived intrinsic type-spec alternative, not another identifier
case or a general declaration parser.

## Decision

Open one bounded contract for the no-kind-selector `REAL` alternative in the
same named main-program envelope:

```fortran
program main
  real :: x
end program main
```

The contract will retain the existing `program-root`,
`program-declaration`, and `variable-declaration` AST v1 records, with
`variable.type-spec = real` and `variable.name = x`. The existing integer
source is the changed-type regression control. A malformed `real ::` source is
the negative neighbour. No new schema revision is needed. The implementation
must preserve the promoted integer behavior and the existing frontend-v0 and
MIR-v0 observables.

The exact source evidence is J3-24-007, PDF SHA-256
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`, canonical
text SHA-256
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, and
StandardIR SHA-256
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`:

- R501, R1401, R1402, R1403 and C1401 for the retained main-program envelope;
- R601 and R603 for the source name;
- R702 and R703 at canonical lines 3135 and 3140 for type-spec context;
- R704 at canonical lines 3255--3260 for the REAL alternative;
- R801 for the type-declaration statement at page 117.

## Rejected

Kind selectors, `DOUBLE PRECISION`, `COMPLEX`, `CHARACTER`, `LOGICAL`,
attributes, multiple declarations, expressions, assignments, general
intrinsic-type parsing, semantic type checking, and full M3 promotion remain
outside this boundary. Another exact variable-name ladder is also rejected.

## Reversal condition

Write a successor if the pinned R704 occurrence does not contain the REAL
alternative, if the existing AST v1 type-spec field cannot represent `real`,
or if an independent oracle cannot distinguish the changed-type control from
the malformed declaration.
