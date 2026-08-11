# D0010. Fixpoint criteria for the compiler and the meta-languages

Date: 2026-08-11
Status: accepted

## Context

Two things in this project bootstrap themselves, and both can break in ways
that ordinary tests do not detect.

The compiler compiles its own source. A compiler can be subtly wrong in a way
that reproduces itself, and staged builds are the standard detector.

The meta-languages are worse. StandardIR and ImplIR are processed by tools that
are themselves generated from StandardIR and ImplIR descriptions. A change to
either language can produce a version its own implementation cannot process,
and the failure appears one generation later. Work on bootstrapping the Spoofax
meta-languages develops fixpoint compilation precisely for this situation.

## Decision

**Compiler.** gfortran builds compiler-0; compiler-0 builds compiler-1;
compiler-1 builds compiler-2, where 1 and 2 come from identical generated
source and configuration. The first fixed-point criterion is that the canonical
generated compiler source is identical. Object and binary identity under
reproducible build conditions is the later, stronger criterion.

**Meta-language.** On any incompatible change to StandardIR or ImplIR: the old
tool builds new tool A, A builds new tool B, and B must regenerate an
equivalent B before the new language version is declared stable.

**Milestone order.** The meta-tools are compiled by the new compiler *before*
the compiler compiles itself. That is the first practical self-host milestone
and it answers the question that matters earliest: is Bootstrap Core sufficient
for nontrivial compiler infrastructure? Waiting for full self-hosting would
defer that answer by months.

## Rejected

**Stage-2/stage-3 equality as a trust claim.** It establishes reproducibility of
the bootstrap and does not address trusting trust. Diverse double compilation
is the actual answer and is named as future work in `docs/self-hosting.md` §21,
not planned.

**Self-host the whole compiler first.** The conventional order, and it makes the
first evidence about profile sufficiency arrive as late as possible.

**Version the meta-languages and support old versions.** Compatibility shims
for a language whose entire point is to stay small. Regenerate instead.

## Reversal condition

If canonical source identity is reached but object identity proves unreachable
for reasons outside the compiler — nondeterministic linking, timestamps, path
embedding — then the stronger criterion is about the build environment rather
than the compiler, and it should be restated as a reproducible-build
requirement instead of quietly dropped.
