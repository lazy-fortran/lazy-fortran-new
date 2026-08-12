# E0038. Approved schema-value contract

## Question

Does the approved schema-value contract survive deterministic validation and
canonical writing?

## Method

The run is pinned to `standard-new` commit `bb8756a` and the laboratory setup
at commit `84e9cb8`. The schema parser accepts explicit payload types on sum
variants. The type emitter gives payload variants deterministic storage. The
reference codec validates and writes records with named fields, sums, lists,
optionals, enums and primitive values.

Regenerate the result with:

```text
research/experiments/E0038-does-the-approved-schema-value-contract-/analyse.sh
```

The gate checks nine canonical values and three invalid values. It also
regenerates the checked-in Fortran module and compares it byte-for-byte with
the generated artifact. No model calls were used. The artifact origin is
`MECHANICAL`.

## Result

All checks passed. The six declaration forms remained available, the explicit
sum payload and payload-less variant were retained, and all nine canonical
values matched their fixed expected bytes. The three invalid values produced
the expected rejection diagnostics. The regenerated module matched 1,266
bytes with SHA-256
`ffb96ecb70c082874cb2fc0b9a1a226d80711829736baaa8c0e2824dd6337b2f`.

This establishes the value contract and a generic reference codec. Specialized
generated readers and writers, validators, visitors, equality, hashing and
printers remain the next generator slice.
