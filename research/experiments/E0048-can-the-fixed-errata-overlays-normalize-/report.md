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

Pending the first run.

## Boundary

This experiment supplies the planning model with a complete expansion-family
inventory. It does not decide whether the generated representation should use
a new typed resolution class, an alias extension, or a later semantic/parser
projection.
