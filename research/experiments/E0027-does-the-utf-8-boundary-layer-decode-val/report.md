# E0027. UTF-8 boundary validation

## Question

Does the UTF-8 boundary layer decode valid scalars and reject malformed byte
sequences?

## Method

The implementation and test are pinned to `standard-new` commit `444b295`.
The complete check is regenerated with:

```text
research/experiments/E0027-does-the-utf-8-boundary-layer-decode-val/analyse.sh
```

The focused test supplies fixed byte vectors for ASCII `A`, U+00A2, U+20AC and
U+1F600, and compares decoded scalar values and widths with independent
expected values. It checks start, interior and end boundaries, then rejects
overlong, surrogate, out-of-range and truncated sequences.

The expected U+00A2 value was changed in a controlled mutation. The focused
test failed with `two-byte codepoint differs from oracle`; the fixture was
restored before the accepted run. This is the independent-oracle failure
control.

## Result

Accepted. The focused test, text-policy self-test, normal text-policy scan,
changed-file formatting check and full `fo` pipeline all passed. The run uses
no model calls and has origin `MECHANICAL`.

This closes the `utf8_boundary` item in ROADMAP.md. Unicode normalization and
language-specific lexical policy remain out of scope.

## Boundary

The component validates UTF-8 byte structure and decodes Unicode scalar values
only. It does not materialize Unicode arrays, normalize text, or decide what a
Fortran identifier or StandardIR symbol means.
