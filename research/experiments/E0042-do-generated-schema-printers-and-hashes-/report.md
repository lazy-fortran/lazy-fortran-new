# E0042. Generated schema printer and hash differential

## Question

Do generated schema printers and hashes preserve canonical bytes?

## Method

The run is pinned to `standard-new` commit `c6cd889` and the laboratory setup
at commit `b7dc5fd`. The generator emits canonical printer and SHA-256 APIs for
the v0 schema. The printer wrappers use the generated canonical writer. The
initial hash implementation serializes through a scratch stream and hashes the
result with the existing writer SHA-256 backend.

Regenerate the result with:

```text
research/experiments/E0042-do-generated-schema-printers-and-hashes-/analyse.sh
```

The focused test compares five generated printer cases and five generated hash
cases over primitive, record, sum, list and optional values. Printer bytes are
compared with the independent generic `schema_value` codec. Reference hashes
are computed by hashing those independent canonical bytes with the writer
backend. No model calls were used. The artifact origin is `MECHANICAL`.

## Result

All checks passed. The generated printers and hashes agreed with the reference
codec. The generated source matched 56,058 bytes with SHA-256
`de12d73f2a301d2f4de8a2f282f350d827ff61b3137d4a844f8e7e0ca4c2f042`.

The full `fo` pipeline passed with zero lint warnings. The scratch-stream hash
path is correct and provides a later optimization target for a writer-native
generated emitter. Visitor traversal and complete architecture wiring remain
open.
