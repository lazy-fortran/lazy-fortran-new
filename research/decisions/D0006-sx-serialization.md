# D0006. One canonical S-expression serialization for both IRs

Date: 2026-08-11
Status: accepted

## Context

StandardIR and ImplIR both need a textual form: readable by people, writable by
small models, parseable with almost no machinery, and hashable for provenance.
Giving them separate surface syntaxes would mean two lexers, two parsers, two
canonicalizers and two sets of bugs, in a project whose first phase is about
not maintaining transcriptions by hand.

## Decision

Both IRs serialize to one generic tree format, provisionally SX:

```
document := form*
form     := atom | integer | string | "(" form* ")"
```

Nothing else. No operator precedence, no indentation significance, no
statement terminators, no macros, no reader evaluation, no quotation, no
lists-as-runtime-data. SX serializes trees; it is not Lisp and does not borrow
Lisp semantics.

The writer produces a canonical form with one spelling per operation and
normalized whitespace, integers, string escaping, local names and field order,
so that

```
parse → validate → normalize → canonical serialize → SHA-256
```

gives every object a stable identity for provenance and reproducible builds.

Each IR has a small schema in the same format, covering primitive, record,
sum, list, optional and enum. Fortran types, reader, writer, validator,
visitor, equality, hashing and printer are generated from it.

## Rejected

**ASDL itself.** The closest historical design, and the source of the data
model we adopt. Rejected as a toolchain because we want a self-hostable Fortran
implementation now, because SX parsing is simpler than a second surface syntax,
because we need only a subset of its concepts, and because keeping schemas as
ordinary trees lets one set of storage, hashing and inspection machinery serve
everything.

**TableGen as a language.** Its declarative-records-generate-code direction is
right and its accumulated classes, inheritance, template arguments,
multiclasses, loops and conditionals are exactly what this representation must
not become.

**JSON or TOML.** Both would work and both make trees noisier to write than
`(eq (rank x) 0)`, which matters when a 1.5B model is producing them. JSON also
has no comment syntax, and provenance discussions need comments.

**Separate syntaxes per IR.** Two parsers to maintain, for no benefit.

## Reversal condition

If the canonical form turns out not to be what models produce most reliably,
that is measurable in E4 and E3 as a syntax-error rate per representation. A
significantly better serialization for model output would justify revisiting,
though it would have to beat SX on human readability and hashability too.
