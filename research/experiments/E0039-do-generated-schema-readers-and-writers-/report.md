# E0039. Generated schema reader and writer differential

## Question

Do generated schema readers and writers agree with the reference codec and
fixed SX values?

## Method

The run is pinned to `standard-new` commit `44be898` and the laboratory setup
at commit `6f8c773`. The generator emits typed readers and writers for
primitive values, records, enums, sums, lists and optionals. The generated
module is exposed through a source symlink so the normal production build
compiles the generated source.

Regenerate the result with:

```text
research/experiments/E0039-do-generated-schema-readers-and-writers-/analyse.sh
```

The test covers ten canonical API cases and two malformed reader inputs. Each
generated writer result is compared with fixed expected SX bytes and with the
independent generic `schema_value` codec. Fixed SX trees are read back through
the generated readers, including both sum states and both optional states. No
model calls were used. The artifact origin is `MECHANICAL`.

## Result

All checks passed. The generated APIs agreed with the fixed SX values and the
reference codec. The regenerated source matched 20,294 bytes with SHA-256
`681a1e876f297d63eaef206e016755a2eee12ff4c7756f2b9b7da6914b6f067f`.

This establishes the generated reader and writer boundary. Generated
validators, visitors, equality, hashing, printers and architecture metadata
remain open.
