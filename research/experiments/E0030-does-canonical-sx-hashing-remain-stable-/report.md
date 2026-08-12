# E0030. Canonical SX content hashing

## Question

Does canonical SX hashing remain stable after validation and writer
serialization?

## Method

The implementation and test are pinned to `standard-new` commit `f221edf`.
The complete check is regenerated with:

```text
research/experiments/E0030-does-canonical-sx-hashing-remain-stable-/analyse.sh
```

The focused test parses a noncanonical SX form, validates the resulting tree,
serializes it through the writer-backed canonical path, checks the exact output
byte count, and compares the digest with an independently computed SHA-256
vector. It also supplies an invalid node and expects validation rejection.

The first digest byte was changed in a controlled mutation. The focused test
failed with `SX content hash differs from oracle`; the fixture was restored
before the accepted run. This is the independent-oracle failure control.

## Result

Accepted. The focused hashing test, text-policy self-test, normal text-policy
scan, changed-file formatting check and full `fo` pipeline all passed. The run
uses no model calls and has origin `MECHANICAL`.

This closes the SX content-hashing item in ROADMAP.md. The seed remains
recursive rather than an arena-based Bootstrap-Core reader.
