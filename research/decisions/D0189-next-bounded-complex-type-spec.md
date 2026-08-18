# D0189. Select the next bounded COMPLEX type-spec boundary

Date: 2026-08-18
Status: accepted

## Context

The exact no-kind-selector DOUBLE PRECISION producer/replay leaf is promoted
only for the fixed AST-v1 `program main` shape. The next controller task must
select one adjacent source-backed boundary without broadening the frontend.
Two independent Luna-medium candidate scans proposed LOGICAL and COMPLEX.
The controller selects COMPLEX because it is the immediately following
unpromoted no-kind-selector alternative in the same R704 production; LOGICAL is
retained as a rejected candidate, not silently discarded.

## Decision

Open one bounded contract for this exact source shape:

```fortran
program main
  complex :: x
end program main
```

Reuse the existing AST-v1 `program-root`, `program-declaration` and
`variable-declaration` records, with the canonical atom
`variable.type-spec = complex`. Use the promoted REAL leaf as a changed-type
control and `complex ::` as the malformed negative neighbour. No kind selector,
schema revision, general intrinsic-type parsing, expression support, semantic
analysis or M3 promotion is included.

The exact normative evidence is J3/24-007, PDF SHA-256
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`, canonical
text SHA-256 `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`,
and StandardIR SHA-256
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`:

- R702 and R703 for type-spec context, canonical lines 3135 and 3140;
- R704, canonical line 3258, specifically `or COMPLEX [ kind-selector ]`;
- R801, canonical line 4869, for the type-declaration statement;
- R501/R1401/R1402/R1403/C1401 and R601/R603 for the retained program and
  source-name envelope.

## Rejected

LOGICAL is retained as the alternate candidate from R000730 but is not selected
because it is later in the same R704 alternative list and does not provide a
smaller source/evidence boundary than COMPLEX. CHARACTER is deferred because
its selector grammar is a separate shape. Kind selectors, attributes, multiple
declarations, expressions, assignments, broad grammar closure, semantic type
checking, E0172 and model-generated promotion remain outside the contract.

## Reversal condition

Write a successor if the pinned R704 occurrence does not contain the COMPLEX
alternative, if `complex :: x` cannot reuse the existing AST-v1 atom field with
an independent changed-type and malformed-negative oracle, or if the exact
source/provenance evidence is insufficient.
