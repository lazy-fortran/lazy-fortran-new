# E0068: Lossless complete-source acceptance with retained diagnostics

Status: accepted

## Question

Can a generated complete-source operation accept every meaningful line in the
pinned real-source corpus while retaining an unsupported local residue as a
source-located diagnostic instead of silently skipping it or changing
structural wiring?

## Result

Yes, for the declared corpus and mutation. The operation accepted all 72
meaningful records across five pinned fortfront files. Every accepted record
retained its generated statement kind, physical source line, StandardIR rule,
source page, byte span and document hash.

The negative control changes `c = a + b` on physical line 6 of
`module_parsing_basic.f90` to `event post`. GNU Fortran rejects the mutation.
The generated operation retains the five recognized records before the residue
and appends one `unsupported` record at line 6 with one diagnostic. That
diagnostic uses the generic `program-unit/R502` context source reference. The
context identifies where the local recognizer is operating; it does not claim
that `event post` was parsed as a `program-unit` production.

| Metric | Value |
|---|---:|
| Corpus files | 5 |
| Expected meaningful lines | 72 |
| Accepted records | 72 |
| Source-linked accepted records | 72 |
| Unsupported residue records | 1 |
| Diagnostic records | 1 |
| Diagnostics with provenance | 1 |
| Complete-file mismatches | 0 |
| GNU Fortran accepted files | 5 |
| GNU Fortran mutation rejected | 1 |
| Fortran compile status | 0 |
| Runtime test status | 0 |

No model calls were made. The generated acceptance wrapper preserves the
existing structural operation and turns its first bounded local failure into a
typed residue record. It does not resume parsing after the first unsupported
construct, and it does not claim complete semantic analysis.

## Reproduction

`research/experiments/E0068-can-lossless-complete-source-acceptance-/analyse.sh`

The operation consumes the E0061 generated complete-source module, checks the
pinned corpus and GNU Fortran behavior, compiles the generated wrapper with
`-ffree-line-length-none -Wall -Wextra -Werror`, and executes the independent
record and mutation checks. The gate summary is written to
`artifacts/runs/E0068/R000001-summary.toml`.

Generated Fortran and compiler products remain in the ignored `.cache/runs`
directory. The run record is `R000077` in `research/runs/2026-08.jsonl`.

## Decision consequence

D0034 is confirmed: a whole-file operation can preserve useful accepted
records while retaining an unsupported local hole as a source-located,
provenance-bearing diagnostic. The generated architecture and wiring remain
deterministic; no model is needed for this boundary.

## Boundary

The next useful work is to resume after retained residues and increase the
independently checked supported statement and expression families. A model
should enter only if a compact mechanical recovery rule fails to generalize;
it must not own the parser architecture or wiring.
