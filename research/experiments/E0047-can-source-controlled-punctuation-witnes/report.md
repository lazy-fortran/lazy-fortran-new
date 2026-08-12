# E0047. Source-controlled punctuation boundary repair

## Question

Can source-controlled punctuation witnesses repair references whose comma or
colon was absorbed into the StandardIR reference name without changing the
source text?

## Method

The analysis command consumes the pinned StandardIR SX, canonical text and the
fixed document errata file:

```text
research/experiments/E0047-can-source-controlled-punctuation-witnes/analyse.sh
```

The errata entries are LLM-originated proposals accepted under D0025. They
record the original reference spelling, the repaired reference, the punctuation
token, the source rule and an exact canonical-text excerpt.
The generic repair operation changes `(ref name,)` into `(ref name) (token ,)`
and the corresponding colon form. It writes a derived parser input and keeps
the authoritative source hash unchanged.

## Result

The command matched all seven canonical source excerpts and repaired seven
references in the 522 syntax records. Six repairs insert a comma token and one
inserts a colon token. The repaired input and generated grammar have stable
hashes recorded in the run artifact. The independent boundary difference is 0,
and the mutated punctuation witness produced the expected validation failure.

## Boundary

This slice repairs an extraction boundary. It does not resolve R401 list
expansions, R403 scalar constraints, or the remaining semantic name classes.
