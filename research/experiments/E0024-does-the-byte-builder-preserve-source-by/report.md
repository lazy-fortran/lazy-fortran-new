# E0024. Byte builder append boundary

## Question

Does the byte builder preserve source bytes across ASCII, span and newline
appends?

## Method

The implementation and test are pinned to `standard-new` commit `99c84f4`.
The complete check is regenerated with:

```text
research/experiments/E0024-does-the-byte-builder-preserve-source-by/analyse.sh
```

The focused test supplies a source span containing signed byte values, appends
an ASCII boundary value, a zero byte, the span and a newline, and compares all
resulting bytes with a separately declared expected array. It then checks that
clearing the builder resets its logical size.

The expected first byte was changed in a controlled mutation. The focused test
failed with `builder byte differs from oracle`; the source was restored before
the accepted run. This is the independent-oracle failure control.

## Result

Accepted. The fixed-byte test, text-policy self-test, normal text-policy scan,
changed-file formatting check and full `fo` pipeline all passed. The run uses
no model calls and has origin `MECHANICAL`.

This closes only the `byte_builder` item in ROADMAP.md. Integer formatting,
writer backends, interning, UTF-8 validation and the full property/fuzz gate
remain open.

## Boundary

ASCII input is a boundary operation. UTF-8 source bytes should be appended as
bytes or spans until the later UTF-8 boundary component defines validation.
This slice introduces no StandardIR or parser-symbol resolution.
