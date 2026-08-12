# E0040. Generated schema validation and equality differential

## Question

Do generated validators and equality preserve the schema value contract?

## Method

The run is pinned to `standard-new` commit `531e590` and the laboratory setup
at commit `ac4b4f7`. The generator emits validators and structural equality for
primitive values, records, enums, sums, lists and optionals. Validation checks
recursive members, enum domains, required payloads, inactive payloads and
canonical names. Equality treats allocated and unallocated empty lists as the
same schema value.

Regenerate the result with:

```text
research/experiments/E0040-do-generated-validators-and-equality-pre/analyse.sh
```

The semantic test covers seven valid values, five invalid mutations and eight
equality cases. Fixed expected diagnostics and mutation outcomes are the
behavioral oracle. The generated source is also regenerated and compared
byte-for-byte. No model calls were used. The artifact origin is `MECHANICAL`.

## Result

All checks passed. The generated APIs accepted the seven valid values, rejected
the five invalid mutations with the specified diagnostics and matched all eight
equality outcomes. The generated source matched 29,970 bytes with SHA-256
`e49b113697adc2107584f3719c7ed56422d74319e26967a198e47305c66db88e`.

The full `fo` pipeline passed with zero lint warnings. Generated visitors,
hashing, printers, architecture metadata and complete wiring remain open.
