# D0008. Bootstrap Core, a profile smaller than Core 0

Date: 2026-08-11
Status: accepted

## Context

The meta-tools — SX reader, schema generator, StandardIR engine, ImplIR
checker, the generators — are ordinary Fortran programs. If they are written in
whatever Fortran is convenient, the generated compiler cannot compile them
until it supports most of the language, and self-hosting is pushed to the end
of the project. If they are written in a restricted profile from the start,
they become the first real corpus the generated compiler must handle.

## Decision

The meta-tools use **Bootstrap Core** from day one, a profile smaller than the
user-facing Core 0.

Permitted: free form, `implicit none`, modules, derived types without
inheritance, integer and logical and simple character, allocatable arrays,
procedures with `intent`, `if`, `select case`, `do`, stream and file I/O,
`ISO_FORTRAN_ENV`.

Avoided where practical: polymorphism, parameterized derived types, coarrays,
elaborate generic machinery, procedure pointers, advanced character semantics,
defined assignment, finalization.

Source and SX processing use a compact byte arena with `start`/`length` offsets
rather than one Fortran string per token. This is faster, and it reduces how
much character semantics the first self-hosting compiler must implement.
`LESSONS.md` §5 records what character handling costs when it is not planned
for: the same quadratic concatenation defect class fixed twice seven months
apart, and the same nested-substring bug fixed three times.

Bootstrap Core is a StandardIR profile like any other, defined as a rule-ID
selection with dependency closure, so it can be checked mechanically rather
than by discipline.

## Rejected

**Write the tools in full modern Fortran.** More comfortable, and it defers
self-hosting until the compiler is nearly complete, which is when a
sufficiency problem is most expensive to discover.

**Make Bootstrap Core and Core 0 the same.** Simpler to explain. Core 0 is
sized for users writing scientific Fortran; the meta-tools need less, and every
feature in the bootstrap profile is a feature the compiler must support before
the first self-host milestone.

**Enforce the profile only by review.** `LESSONS.md` §3 is the record of what
happens to a convention that is written down and not checked: `ffc`'s own
guidance forbids production include fragments while 58 per cent of its source
is include fragments.

## Reversal condition

If a meta-tool genuinely cannot be written without a feature outside Bootstrap
Core, the profile grows and the growth is recorded, because the size of the
profile needed to implement the toolchain is itself the E10 result. Growth is a
measurement, not a violation. Quietly using a feature without recording it is
the violation.
