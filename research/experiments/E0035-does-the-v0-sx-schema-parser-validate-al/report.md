# E0035. V0 SX schema parser and validator

## Question

Does the v0 SX schema parser validate all declared schema forms?

## Method

The run is pinned to `standard-new` commit `6b435b3`. The parser consumes SX
and produces a typed schema for primitive, record, sum, list, optional and enum
declarations. The test checks an inline fixture and the committed
`specs/schema-v0.sxs` source fixture, then checks four malformed schemas for
duplicate declarations, malformed record members and unknown references.

Regenerate the result with:

```text
research/experiments/E0035-does-the-v0-sx-schema-parser-validate-al/analyse.sh
```

The focused test was also run with Fortran runtime bounds and backtrace checks.
Changing the expected declaration count from 7 to 8 made the focused test fail;
the expected value was then restored. No model calls were used. The artifact
origin is `MECHANICAL`.

## Result

The six declaration forms, the source fixture, and all four malformed cases
passed. Text policy, formatting, runtime checks and the full `fo` pipeline
passed. The result establishes the schema parser/validator boundary; source
tree generation, generated APIs, and deterministic wiring remain future work.
