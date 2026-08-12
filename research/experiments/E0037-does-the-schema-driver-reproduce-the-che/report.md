# E0037. Schema driver source-tree regeneration

## Question

Does the schema driver reproduce the checked-in Fortran source tree
byte-for-byte?

## Method

The run is pinned to `standard-new` commit `672f44c`. The `sxschema` driver reads
`specs/schema-v0.sxs`, emits a fresh Fortran module, compares it byte-for-byte
with `generated/schema_v0_generated.f90`, checks the generated file with
`fo fmt`, and runs the complete production pipeline.

Regenerate the result with:

```text
research/experiments/E0037-does-the-schema-driver-reproduce-the-che/analyse.sh
```

No model calls were used. The artifact origin is `MECHANICAL`.

## Result

The regeneration matched the checked-in source exactly: 1,117 bytes with the
recorded SHA-256. The generated module entered the normal `fo` source graph;
text policy, generated formatting and the full pipeline passed. Reader, writer,
validator, visitor, hashing, printer and complete wiring generation remain
future slices.
