# E0026. Case-insensitive interner identity

## Question

Does the interner resolve Fortran identity once across case variants and table
growth?

## Method

The implementation and test are pinned to `standard-new` commit `649efcf`.
The complete check is regenerated with:

```text
research/experiments/E0026-does-the-interner-resolve-fortran-identi/analyse.sh
```

The focused test supplies fixed byte arrays for `Foo`, `fOo`, `Bar` and `Baz`.
It checks that case variants share an ID, distinct names receive distinct IDs,
the canonical key is lower-case ASCII, an empty span is rejected, and the
identity remains stable after a forced four-slot-table rehash.

The expected first canonical byte was changed in a controlled mutation. The
focused test failed with `interned key differs from oracle`; the fixture was
restored before the accepted run. This is the independent-oracle failure
control.

## Result

Accepted. The focused test, text-policy self-test, normal text-policy scan,
changed-file formatting check and full `fo` pipeline all passed. The run uses
no model calls and has origin `MECHANICAL`.

This closes the `interner` item in ROADMAP.md. Unicode normalization and the
UTF-8 boundary remain separate open work.

## Boundary

The component performs only ASCII A–Z folding, which is the Fortran identity
rule needed by this text layer. It does not classify lexical names, normalize
Unicode, or adjudicate StandardIR role names.
