# E0036. Deterministic schema type declaration emission

## Question

Does deterministic schema generation emit stable Fortran type declarations?

## Method

The run is pinned to `standard-new` commit `0c716e5`. The generator validates a
v0 schema, orders non-primitive declarations by their type dependencies, and
emits Fortran enum constants, record types, sum tags, list containers and
optional containers. The test checks ten fixed generated-source lines and a
fixed cyclic-dependency diagnostic.

Regenerate the result with:

```text
research/experiments/E0036-does-deterministic-schema-generation-emi/analyse.sh
```

The focused test was also run with Fortran runtime bounds and backtrace checks.
Changing the expected enum value made the focused test fail; the expected value
was then restored. No model calls were used. The artifact origin is
`MECHANICAL`.

## Result

All six declaration forms emitted the expected structural source lines, and a
cycle was rejected with the expected diagnostic. Text policy, formatting,
runtime checks and the full `fo` pipeline passed. Readers, writers, validators,
visitors, hashing, printer generation and complete wiring remain future slices.
