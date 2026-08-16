# E0176 — C702 semantic-oracle vertical slice

This is the second bounded M3 delivery contract. It checks one source-backed
property: a colon `type-param-value` is permitted only in the declaration of
an entity with the `POINTER` or `ALLOCATABLE` attribute. The property is
J3/24-007 C702 and is bound to the already represented StandardIR rows R701,
R832 and R856.

The candidate is a typed colon value plus a known pointer, known allocatable,
known neither-attribute or unknown attribute context. The deterministic oracle
returns `ACCEPTED`, `REJECTED` or `UNRESOLVED`. It does not evaluate C701,
declaration typing, allocation semantics or name resolution. Model output is
not an input and cannot promote a fact.

Run the complete gate with:

```text
tests/e2e/run-m3-c702.sh .cache/runs/E0176/R000012
```

The command canonicalizes the pinned semantic-items SX through `standard-new`,
checks the normative PDF, canonical text and StandardIR rows, evaluates the
four fixed witnesses, runs three source mutations that must fail closed, and
compares the result with the committed trace. The run-directory argument must
name a fresh directory below `.cache/runs/E0176/`.

This is not general type checking, arbitrary Fortran parsing, semantic
analysis, compiler IR or a model experiment. A later M3 slice needs its own
accepted contract and verifier.
