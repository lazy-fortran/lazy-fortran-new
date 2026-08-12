# E0031. Flat SX arena-reader differential

## Question

Does the flat SX arena reader agree with the recursive seed on canonical bytes?

## Method

The implementation and test are pinned to `standard-new` commit `50392e7`.
The complete check is regenerated with:

```text
research/experiments/E0031-does-the-flat-sx-arena-reader-agree-with/analyse.sh
```

The focused test parses the same noncanonical SX form with the flat arena and
recursive seed readers, compares arena output with a separately declared
canonical fixture, compares every output byte across the two implementations,
and checks the flat node count and root kind.

The expected canonical `b` byte was changed to `c` in a controlled mutation.
The focused test failed with `arena output byte differs`; the fixture was
restored before the accepted run. This is the independent-oracle failure
control.

## Result

Accepted. The focused differential test, text-policy self-test, normal
text-policy scan, changed-file formatting check and full `fo` pipeline all
passed. The run uses no model calls and has origin `DIFFERENTIAL`.

This closes the first flat arena-reader slice. It does not yet replace the
recursive seed by default or prove agreement over the complete corpus.
