# E0025. Multi-backend writer and SHA-256 boundary

## Question

Does `writer_t` preserve bytes and provenance hashes across file, memory, hash
and counting backends?

## Method

The implementation and test are pinned to `standard-new` commit `ee61cfe`.
The complete check is regenerated with:

```text
research/experiments/E0025-does-writer-t-preserve-bytes-and-provena/analyse.sh
```

The focused test writes a fixed byte sequence through the memory, file,
counting and hash backends. Memory and file output are compared with separate
fixed byte arrays; the counting backend is checked against the exact length;
the hash backend is checked against the published SHA-256 vectors for empty
input and `abc`.

The first byte of the `abc` digest was changed in a controlled mutation. The
focused test failed with `SHA-256 abc vector differs`; the fixture was restored
before the accepted run. This is the independent-oracle failure control.

## Result

Accepted. The focused test, text-policy self-test, normal text-policy scan,
changed-file formatting check and full `fo` pipeline all passed. The run uses
no model calls and has origin `MECHANICAL`.

This closes the `writer_t` item in ROADMAP.md. The interner, UTF-8 boundary,
property/fuzz coverage and malformed-input corpus remain open.

## Boundary

The hash backend is a pure-Fortran SHA-256 implementation and returns digest
bytes, so the writer remains byte-oriented. File output requires the caller to
provide an opened unformatted stream unit; the writer does not take ownership
of or close that unit.
