# E0023. First byte buffer and span text slice

## Question

Does `standard-new` provide an owning byte buffer and non-owning span with
fixed-byte behavior, bounds rejection and copy isolation?

## Method

The implementation and test are pinned to `standard-new` commit `f81fd52`.
The complete check is regenerated with:

```text
research/experiments/E0023-do-byte-buffers-and-spans-provide-the-fi/analyse.sh
```

The focused behavioral test uses a fixed input array and a separately declared
expected array. It exercises byte values at the signed `int8` boundaries,
buffer growth, span extraction, suffix slicing, equality, and rejected
out-of-range access. It also copies a buffer, grows the copy past its original
capacity, and checks that the source span remains unchanged.

The expected first byte was changed in a controlled mutation. The focused test
failed with `buffer byte differs from oracle`; the source was then restored
before the accepted run. This is the independent-oracle failure control, not a
repository-state check.

## Result

Accepted. The fixed-byte test, text-policy self-test, normal text-policy scan,
changed-file formatting check and full `fo` pipeline all passed. The run uses
no model calls and has origin `MECHANICAL`.

This closes only the `byte_buffer` and `byte_span` items in ROADMAP.md. The
remaining `byte_builder`, `writer`, `interner` and `utf8_boundary` work, and
the full property/fuzz/malformed-input gate, remain open.

## Boundary

The buffer owns storage and defines deep-copy assignment because a span is a
non-owning view. A span becomes invalid after a buffer operation that
reallocates storage; the API documents that lifetime rule. No parser-symbol
aliases or composite-input resolutions are introduced by this experiment.
