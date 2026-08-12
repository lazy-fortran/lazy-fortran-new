# E0041. LFortran, Flang and gfortran parser behavior differential

## Question

Do LFortran, Flang and gfortran agree on the pinned parser-behavior corpus?

## Method

The run uses ten generated Fortran fixtures. Eight are intended-valid forms:
minimal program, module and `USE`, derived type, interface block, array section,
`do concurrent`, `select rank` and a coarray declaration. Two are malformed:
an unclosed program and an invalid expression.

Regenerate the matrix with:

```text
research/experiments/E0041-do-lfortran-flang-and-gfortran-agree-on-/analyse.sh
```

Fixtures and compiler diagnostics are written below
`.cache/runs/E0041/R000001/`, which is gitignored. No source corpus or compiler
output is committed. LFortran runs in AST-emission mode. Flang and gfortran
run in syntax-only mode. gfortran is used only as a behavioral oracle. No GCC
implementation source was read.

## Result

All 30 invocations returned a result. The three compilers accepted the same
eight fixtures and rejected the same two malformed fixtures. Thus all ten
accepted/rejected cases agree. LFortran returned exit code 2 for both malformed
fixtures. Flang and gfortran returned exit code 1. The raw exit-code difference
is recorded separately from parser behavior. Thirty diagnostic files remain in
the ignored run cache.

The summary is 535 bytes with SHA-256
`81ab7e460d5f881957df09e0a7e457cd4e9838eef9e5e4f2591e446231051b87`.
The result establishes a small behavioral comparison corpus. It does not
adjudicate the 181 unresolved StandardIR names or establish full-language
conformance.
