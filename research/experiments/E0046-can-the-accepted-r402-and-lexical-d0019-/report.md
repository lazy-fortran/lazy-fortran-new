# E0046. Combined R402 and lexical D0019 resolution projection

## Question

Can the accepted R402 and lexical D0019 witnesses compose into one
deterministic parser projection while preserving the unresolved expansion
boundary?

## Method

The analysis command reruns the accepted E0044 and E0045 slices, checks their
typed-record hashes, and composes their non-conflicting resolutions:

```text
research/experiments/E0046-can-the-accepted-r402-and-lexical-d0019-/analyse.sh
```

E0044 supplies the R402 aliases. E0045 supplies the selected lexical classes.
Overlapping resolved fields must agree. The combined projection replaces only
unresolved rows and retains source provenance on every record.

## Result

Pending the first run.

## Boundary

This experiment composes accepted resolution families. It does not choose the
representation for R401 list expansions or R403 scalar constraints. That
choice is tracked by D0024.
