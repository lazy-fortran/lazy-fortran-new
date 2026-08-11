# D0003. Fortran everywhere, C libraries through ISO_C_BINDING

Date: 2026-08-11
Status: accepted

## Context

The compiler is to be written in generated modern Fortran. The tooling around
it (PDF extraction, StandardIR handling, generators, analysis) could
reasonably be written in anything, and Python would reach the first E1 numbers
fastest. The pull toward a Python scaffold is strong and, once present, such
scaffolds stay.

There is also existing house tooling: `~/code/sloppy/helpy/pkg/pdf` is about
3,900 lines of Go over pdfcpu and a local `pdf` fork, and it works well,
including layout-aware extraction with per-glyph coordinates.

## Decision

Fortran everywhere it is conceivable. External functionality is reached through
`ISO_C_BINDING` to established C libraries rather than reimplemented. The
escape hatch is quantitative rather than aesthetic: a component may be someone
else's C library when writing it would require on the order of a hundred
thousand lines.

PDF rendering qualifies for the escape hatch; PDF text extraction does not, once
`poppler` is bound. `standard-new` therefore starts with `fortpdf`, an
`ISO_C_BINDING` module over `poppler-glib`, whose `poppler_page_get_text_layout`
returns per-character rectangles.

The Go stack becomes a differential oracle for the text-extraction layer rather
than part of the pipeline, the same oracle principle the rest of the program
uses, applied at stage one.

## Rejected

**Python for tooling, Fortran for the compiler.** Fastest to a first result and
adds a bootstrap dependency that can never be removed. It also undercuts the
project's own thesis: a program arguing that Fortran is a good implementation
language should not route around it for its own tools.

**Go for extraction, since it already exists and works.** Same objection, plus a
second toolchain.

**Python now, migrate later.** Requires a written rule about what may never stay
Python. Such rules are not obeyed.

## Consequences

Slower start. `fortpdf` must exist before any extraction happens. In exchange
the generators become artifacts that the compiler can eventually compile, which
is a self-hosting milestone rather than an obstacle.

`poppler-glib` is a C API, so binding is direct. mupdf would also work but is
not installed locally. The binding is expected to be a few hundred lines.

## Reversal condition

If a required capability has no C library with a bindable interface and would
take a hundred thousand lines to write, the escape hatch applies and
the component is documented as permanently external. Record which one and why.
