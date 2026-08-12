# E0059: Generated top-level program-unit operation

Status: accepted

## Question

Can one local top-level parser operation classify real Fortran program units
with source-linked rule references while compiler-wide wiring remains
generated?

## Result

Yes, for the bounded top-level operation. The corpus contains five real source
files from the pinned `fortfront` oracle checkout. GNU Fortran accepts all five
with `-std=f2018 -fsyntax-only`. The manifest declares eight top-level units:
programs, modules, and one submodule.

The generated Fortran operation classified all eight units. Each result carries
the corresponding StandardIR rule and a page, byte span, and source-document
hash from the E0058 diagnostic table. The generated source and test program
compile with `-ffree-line-length-none -Wall -Wextra -Werror`. The runtime test
reports eight source-linked units. A controlled mutation changes the first
source from a program unit to a module and the operation observes that change.

| Metric | Value |
|---|---:|
| Corpus files | 5 |
| Expected top-level units | 8 |
| Classified units | 8 |
| Source-linked units | 8 |
| Unit mismatches | 0 |
| GNU Fortran accepted files | 5 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Negative control | observed failure |

The result validates one local constructive operation. It does not validate
statement parsing, expression parsing, semantic constraints, or a complete
Fortran frontend. The next local holes are the statement-level operations that
the same generated dispatch and diagnostic structures will call.

## Reproduction

```text
research/experiments/E0059-can-generated-top-level-operation-parse-real-/analyse.sh
```

The corpus manifest records source identities and expected unit sequences.
Source files remain in the external oracle checkout. Generated source and run
payloads remain in the ignored cache. The gate summary is
`artifacts/runs/E0059/R000001-summary.toml`.

## Boundary

The local operation may interpret source lines and maintain its small parsing
state. It may not add modules, dispatch conventions, registration, or source
provenance policy. Those remain generated from StandardIR and the accepted
architecture. No model calls were made.
