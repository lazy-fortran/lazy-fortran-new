# E0048. Fixed errata normalization and R401/R403 inventory

## Question

Can the fixed errata overlays normalize the remaining punctuation boundary and
enumerate every R401/R403 expansion-family term without selecting its parser
representation?

## Method

The analysis command consumes the pinned StandardIR SX, canonical text,
unresolved audit, the seven-entry D0025 overlay, and its R1123 extension:

```text
research/experiments/E0048-can-the-fixed-errata-overlays-normalize-/analyse.sh
```

It creates a derived audit view by applying the eight source repairs. It then
extracts first-use StandardIR provenance and inventories terms ending in
`-list` as R401 candidates and terms beginning with `scalar-` as R403
candidates. The output retains every term as `unresolved` and records that
the representation choice is deferred to D0024.

## Result

The command applied all eight accepted D0025 source repairs and reduced the
181-name audit to 178 names in the derived view. The expansion inventory has
100 records: 80 R401 suffix-list terms and 20 R403 scalar-prefix terms. Every
record has an independent StandardIR source witness, no selected term has an
explicit StandardIR definition, and the independent set comparison differs by
zero. The family mutation produced the expected validation failure.

The records remain `unresolved`; parser representation is explicitly deferred
to D0024. The run made no model calls. Its summary and inventory hashes are
recorded in `artifacts/runs/E0048/R000001-summary.toml`.

## Boundary

This experiment supplies the planning model with a complete expansion-family
inventory. It does not decide whether the generated representation should use
a new typed resolution class, an alias extension, or a later semantic/parser
projection. The eight-entry overlay is a derived input policy; it does not
alter the authoritative PDF or StandardIR.
