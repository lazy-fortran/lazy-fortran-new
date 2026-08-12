# E0060: Generated statement operation

Status: accepted

## Question

Can one local statement parser operation classify declared real-source
witnesses and attach StandardIR rule references while generated wiring and
diagnostic policy remain unchanged?

## Result

Yes, for the declared witness set. The operation searched five pinned real
Fortran files for ten source witnesses covering `use`, declarations,
assignments, `call`, `print`, and `do concurrent`. It classified all ten
witnesses and attached a page, byte span, and source-document hash from the
generated diagnostic table for every result.

The generated Fortran module and test program compile with
`-ffree-line-length-none -Wall -Wextra -Werror` and pass at runtime. Replacing
`do concurrent` with `print` in a controlled source mutation changes the
statement-family witness.

| Metric | Value |
|---|---:|
| Corpus files | 5 |
| Expected witnesses | 10 |
| Classified witnesses | 10 |
| Source-linked witnesses | 10 |
| Witness mismatches | 0 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Negative control | observed failure |

This validates a bounded local operation. It does not establish general
statement parsing, expression parsing, nesting, or semantic checking. The
operation is intentionally a typed local hole. Rule identity, source
provenance, registration, and compiler-wide dispatch remain generated facts.

## Reproduction

`research/experiments/E0060-can-generated-statement-operation-match-real-/analyse.sh`

The corpus manifest records the source identities and witness needles. Source
files remain in the external oracle checkout. Generated payloads remain in the
ignored cache. The gate summary is
`artifacts/runs/E0060/R000001-summary.toml`.

## Boundary

The next operation should cover a larger statement family and then measure
acceptance on complete source files. The architecture stays generator-owned.
No model calls were made.
