# D0011. Text is bytes, spans and IDs, not Fortran character values

Date: 2026-08-11
Status: accepted

## Context

`LESSONS.md` §5 records what happens when one abstraction serves five different
purposes. In `fortfront`: token churn at 40 to 45 per cent of instructions
(`20edbffb`); a string builder introduced with two sites fixed and "219+
additional concatenation sites remain" recorded in the same message
(`6e688073`); the same quadratic defect class fixed again seven months later
(`96dc3314`); the same nested-substring bug fixed three times (`d03f21ce`,
`ee5caf7b`, `3f99a4cb`). LFortran and `fluff` show the same pattern.

The common cause is that source text, identifiers, source slices, generated
output and Fortran CHARACTER values are all called strings and all represented
the same way, despite having no shared semantics.

There is a second reason, specific to this project. If the implementation
leans on deferred-length allocatable character, concatenation and substring
manipulation, then Bootstrap Core must support all of it before the compiler
can compile its own tools, and self-hosting moves to the end of the schedule.

## Decision

Two rules, in force across every repository in the program.

> **Text Representation Rule.** Compiler and meta-tool internals shall not use
> allocatable or repeatedly constructed Fortran `character` values as their
> general text representation. Immutable UTF-8 byte buffers, source spans,
> interned IDs and streaming writers are the default representations. Fortran
> `character` objects are used at system boundaries, and when implementing the
> semantic behaviour of target-language CHARACTER entities.

> **No Concatenation Rule.** Repeated `character(:)` concatenation is forbidden
> in performance-relevant or unbounded code. Generated text is produced through
> a builder or a streaming writer.

Five representations, kept distinct: immutable byte buffer for source text;
interned integer IDs for names, keywords and IR atoms; `(buffer, start,
length)` spans for source slices; a streaming writer or byte builder for
generated output; and a dedicated semantic representation for target-language
CHARACTER values.

Consequences recorded here because they are the parts most likely to be
forgotten:

- Host character types never model target character types. `character(len=10)`
  in a compiled program is a `char_type_t` data structure in the compiler, not
  a host `character(len=10)`.
- Diagnostics are structured — code, location, typed arguments — and rendered
  only at the presentation layer. **Tests assert code, location and arguments,
  never English sentences.**
- Normative prose is referenced by span into a hashed extracted-text artifact,
  never copied into StandardIR objects.
- Exactly one low-level text package exists: byte buffer, span, builder,
  writer, interner, UTF-8 boundary. It does not grow into a string library.

**The No Concatenation Rule is enforced mechanically, from the first commit
that has Fortran to check.** `standard-new/scripts/check_text_policy.sh` fails
the build on accumulator-style concatenation in `src/`, and it carries a
negative control proving it can fail. A rule that is only written down loses:
`ffc/CLAUDE.md` forbids production include fragments while 58 per cent of
`ffc/src` by line count is include fragments (`LESSONS.md` §3).

`docs/text-representation.md` carries the full policy and the reasoning.

## Rejected

**One universal `string_t`.** The convenient choice, and it is the specific
thing that produced the defects above. It makes a source slice, an interned
name and a target character value interchangeable at the type level when they
are not interchangeable at all.

**Fortran `character(:)` internally with discipline about concatenation.**
Halfway. It leaves per-token allocation in place, keeps case-insensitive
comparison on the hot path, and still requires Bootstrap Core to support
deferred-length character early.

**A general string library.** Would solve the ergonomics and reintroduce the
single-abstraction problem behind a nicer interface.

**Convert source to Unicode scalars or wide characters on load.** Loses the
original bytes, which are authoritative for round-tripping and
source-to-source work, and buys nothing the lexer needs.

## Reversal condition

If profiling shows the span-and-ID machinery is itself the bottleneck, or if a
meta-tool genuinely cannot be written without general string manipulation, then
the rule is costing more than it saves and should be narrowed to the hot paths
rather than applied everywhere. Either finding needs a measurement, not an
impression: the historical evidence runs strongly the other way.

If the mechanical gate produces so many false positives that people route
around it, the gate is wrong and gets fixed. Deleting it is not the remedy.
