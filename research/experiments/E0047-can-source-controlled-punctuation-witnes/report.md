# E0047. Source-controlled punctuation boundary repair

## Question

Can source-controlled punctuation witnesses repair references whose comma or
colon was absorbed into the StandardIR reference name without changing the
source text?

## Method

The analysis command consumes the pinned StandardIR SX, canonical text and a
seven-row punctuation seed:

```text
research/experiments/E0047-can-source-controlled-punctuation-witnes/analyse.sh
```

The seed records the original reference spelling, the repaired reference,
the punctuation token, the source rule and an exact canonical-text excerpt.
The generic repair operation changes `(ref name,)` into `(ref name) (token ,)`
and the corresponding colon form. It writes a derived parser input and keeps
the authoritative source hash unchanged.

## Result

The first run is pending.

## Boundary

This slice repairs an extraction boundary. It does not resolve R401 list
expansions, R403 scalar constraints, or the remaining semantic name classes.
