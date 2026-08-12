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

The command produced 182 typed records. The records contain 49 aliases, 25
lexical classes, 1 metanotation witness, 107 unresolved records, and 0
semantic-role or disputed records. All 182 rows carry the pinned J3/24-007
source hash.

The independent alias and lexical closure differences are both 0. The
combined projection contains 49 alias records, 21 newly projected lexical
records, and 116 syntax witnesses. The two Unicode cases remain unresolved.
The controlled `entity-name` mutation observed the expected validation
failure. The generated ANTLR4 projection remains partial because the R401,
R403, semantic and other unresolved classes are outside this slice.

## Boundary

This experiment composes accepted resolution families. It does not choose the
representation for R401 list expansions or R403 scalar constraints. That
choice is tracked by D0024.
