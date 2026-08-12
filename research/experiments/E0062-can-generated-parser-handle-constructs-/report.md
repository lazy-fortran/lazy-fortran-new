# E0062: Logical statements and nested constructs

Status: accepted

## Question

Can one generated local parser operation assemble free-form continuation
lines, classify nested constructs and preserve StandardIR source spans over
five pinned modern Fortran sources?

## Result

Yes, for the declared corpus. The operation assembled 75 meaningful physical
lines into 73 logical statements. It recorded two free-form continuation joins
and classified every logical statement with a StandardIR rule, source page,
byte span, and document hash.

The corpus contains a multiline `if` guard, a continued assignment, nested
`do` and `select case` constructs, named constructs, a `block`, and an
`associate` construct. The construct stack reaches depth 2 and closes with
zero errors. GNU Fortran accepts all five source files. The generated Fortran
module and test program compile with `-ffree-line-length-none -Wall -Wextra
-Werror` and pass at runtime. Replacing an `end do` with `end if` is rejected.

| Metric | Value |
|---|---:|
| Corpus files | 5 |
| Meaningful physical lines | 75 |
| Logical statements | 73 |
| Classified logical statements | 73 |
| Source-linked statements | 73 |
| Continuation joins | 2 |
| Nesting errors | 0 |
| Maximum nesting depth | 2 |
| GNU Fortran accepted | 5 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Malformed nesting rejected | 1 |

This validates logical-statement assembly and construct closure for the
declared files. It does not establish general expression parsing, semantic
checking, or complete language coverage. The operation remains a typed local
implementation hole. Rule identity, source provenance, registration, and
compiler-wide dispatch remain generated facts.

## Reproduction

`research/experiments/E0062-can-generated-parser-handle-constructs-/analyse.sh`

The corpus manifest records source identities, physical lines, logical
statement ranges, expected families and nesting depths. Source files remain in
the external oracle checkout. Generated payloads remain in the ignored cache.
The gate summary is `artifacts/runs/E0062/R000001-summary.toml`.

## Boundary

The next experiment should add continuation inside richer expressions and
construct families outside this corpus, then measure acceptance on a broader
source set. The architecture remains generator-owned. No model calls were
made.
