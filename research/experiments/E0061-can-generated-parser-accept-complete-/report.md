# E0061: Complete-source parser operation

Status: accepted

## Question

Can one generated local parser operation classify every meaningful line in
five pinned modern Fortran sources, including keyword-like identifiers, and
attach StandardIR source records without changing generated wiring?

## Result

Yes, for the declared corpus. The operation classified all 72 nonblank,
non-comment lines in five pinned source files. It attached a StandardIR rule,
page, byte span, and document hash to every classified line.

The corpus includes program, module, submodule, procedure, interface,
declaration, control-flow, call, print, and assignment statements. The source
also uses `submodule` as an ordinary variable name. The operation classifies
`submodule (...)` as a submodule statement and `submodule = 7` as an
assignment.

GNU Fortran accepts all five source files. The generated Fortran module and
test program compile with `-ffree-line-length-none -Wall -Wextra -Werror` and
pass at runtime. A controlled unsupported-line mutation is rejected.

| Metric | Value |
|---|---:|
| Corpus files | 5 |
| Expected meaningful lines | 72 |
| Classified meaningful lines | 72 |
| Source-linked lines | 72 |
| Line mismatches | 0 |
| GNU Fortran accepted | 5 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Unsupported mutation rejected | 1 |

This validates a complete-source operation over the declared files. It does
not establish general expression parsing, continuation handling, nesting
validation, or semantic checking. The local classifier remains a typed
implementation hole. Rule identity, source provenance, registration, and
compiler-wide dispatch remain generated facts.

## Reproduction

`research/experiments/E0061-can-generated-parser-accept-complete-/analyse.sh`

The corpus manifest records source identities, meaningful source lines and
expected statement families. Source files remain in the external oracle
checkout. Generated payloads remain in the ignored cache. The gate summary is
`artifacts/runs/E0061/R000001-summary.toml`.

## Boundary

The next experiment should add continuation and nested-construct witnesses,
then measure parser acceptance on a broader corpus. The architecture remains
generator-owned. No model calls were made.
