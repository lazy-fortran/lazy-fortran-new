# Text representation

Design note for `lazy-fortran/lazy-fortran-new`. The rules are D0011; this is
the reasoning and the detail.

The governing rule:

> Store text as immutable bytes plus spans and IDs. Materialize a Fortran
> `character(:)` only at an external boundary, or where the language semantics
> genuinely require a character value.

`LESSONS.md` §5 is why. In `fortfront` alone: `20edbffb` found token churn at 40
to 45 per cent of instructions and replaced deep string copies with interned
handles; `6e688073` introduced a string builder, fixed two quadratic
concatenation sites and recorded that "219+ additional concatenation sites
remain"; `96dc3314` fixed the same defect class seven months later; and the
same nested-substring bug was fixed three times (`d03f21ce`, `ee5caf7b`,
`3f99a4cb`). None of that was incompetence. It is what happens when one
abstraction is used for five different things.

---

## 1. Five concepts, not one string type

There is no universal `string_t`. Conventional compiler code calls all of these
"strings" and they have nothing in common.

| Thing | Representation |
|---|---|
| Source file text | immutable byte buffer |
| Names, keywords, IR atoms | interned integer IDs |
| Substrings of source | `(buffer_id, start, length)` span |
| Generated textual output | streaming writer or byte builder |
| A Fortran CHARACTER value | dedicated semantic representation |

Keeping these apart is the whole policy. Everything below follows from it.

---

## 2. Source is an immutable byte buffer

Never read a file into `character(:), allocatable` and then slice and
concatenate it. Instead:

```fortran
type :: byte_buffer_t
    integer(int8), allocatable :: data(:)
end type

type :: token_t
    integer :: kind
    integer :: start
    integer :: length
end type
```

`real(dp) :: temperature` exists once in memory. The token for `temperature`
is `start = 12, length = 11`. No allocation, no copy. The same applies to
comments, literal spellings, operator spellings, source locations and
formatting trivia.

---

## 3. Source encoding is not CHARACTER semantics

A source file is bytes representing text. A Fortran expression `"hello"` is a
character literal with language semantics. These are different abstractions and
conflating them is the origin of a large share of the historical bugs.

Tool input is UTF-8, with BOM handling at the file boundary, and the original
bytes stay authoritative for round-tripping. The lexer interprets only enough
encoding to find ASCII punctuation, letters and digits where required, line
endings, quotes and comments. It does not eagerly convert the source into
Unicode scalar arrays or wide characters.

---

## 4. Intern identifiers immediately

Fortran's case-insensitive identity is resolved once, at interning:

```
intern_identifier(source_span) → canonical key → name_id = 1732
```

Downstream carries the integer:

```fortran
type :: symbol_t
    integer :: name_id
    integer :: type_id
    integer :: scope_id
end type
```

Lookup becomes integer hashing rather than repeated character comparison. The
original span is kept separately, so the system holds both the semantic
identity (`name_id`) and the original spelling (span) — which is exactly what
diagnostics and re-emission need.

---

## 5. Keywords and operators are enums after lexing

```fortran
if (token%kind == TK_ALLOCATE) ...
```

not

```fortran
if (token%text == "allocate") ...
```

`+`, `**`, `/=`, `=>`, `::` all get IDs. Obvious, and the discipline has to hold
everywhere or it holds nowhere.

---

## 6. SX, StandardIR and ImplIR atoms

The SX reader uses the same buffer and span infrastructure, and atoms are
interned:

```
"constraint" → atom_id 1
"require"    → atom_id 14
"eq"         → atom_id 27
```

Decoders switch on IDs and enums, never on text.

StandardIR itself should contain almost no unrestricted text. Categories are
enums. Rule identifiers are structured:

```fortran
type :: rule_id_t
    integer :: category
    integer :: number
end type
```

rather than `"C851"` repeated everywhere. Unrestricted text survives only in
provenance document names, diagnostic explanatory text, normative excerpts and
external metadata, and those are spans into artifact buffers.

**Normative prose is never duplicated into StandardIR.** A span identifies it:

```
(source-span
  (document j3-24-007-text)
  (start 184223)
  (length 173))
```

The extracted-text artifact is hashed and pinned like any other (D0002), so the
prose is always retrievable and never stored thousands of times over. Note that
spans point into the *extracted text*, not the PDF, which is what makes them
stable and the extraction reproducible.

---

## 7. ImplIR has no string type

D0012 records the resulting type set. Briefly: names are `name` IDs, diagnostic
codes are enums, builtin operations are enums, and procedure identifiers are
interned after parsing. A model may write `(proc check-C1234 ...)`, and after
parsing `check-C1234` is an ID; the generated algorithm never manipulates its
spelling.

---

## 8. Model prompts and responses

Model APIs are textual, so this lives at the boundary. Build the prompt with a
streaming writer, send UTF-8, store the exact request and response as immutable
artifact bytes, then parse the response into ImplIR immediately. The canonical
ImplIR is the meaningful object; the raw response is research provenance.

**Never build a prompt with repeated `//`.** One reusable builder with
geometric growth:

```fortran
type :: byte_builder_t
    integer(int8), allocatable :: data(:)
    integer :: size
    integer :: capacity
end type
```

with `append_bytes`, `append_span`, `append_ascii`, `append_integer`,
`append_newline`.

---

## 9. Stream rather than accumulate

For large output, do not build one giant result in memory. The emitter exposes
a writer:

```fortran
call w%write_ascii("integer function ")
call w%write_name(proc_name)
```

rather than returning a giant allocatable result. One abstraction, `writer_t`,
with several backends: file, memory, hash, counting. A hash writer computes a
provenance hash without ever materializing the artifact, which is useful
enough on its own to justify the abstraction.

Compiler passes never communicate through generated Fortran text. The pipeline
is typed structures throughout, with an emitter at the very end, unless
source-to-source output is the requested product.

---

## 10. Source-to-source needs two modes

**Semantic re-emission**, where whitespace and comments need not survive:
source → AST → canonical pretty printer.

**Lossless editing**, for refactoring and IDE use: keep the source bytes and
express changes as edits.

```fortran
type :: text_edit_t
    integer :: start
    integer :: end
    integer :: replacement_id
end type
```

Apply edits at the end. Everything not deliberately changed is preserved
exactly, and no semantic node has to carry comments and whitespace through the
pipeline to achieve it.

---

## 11. Diagnostics are structured until the last moment

```fortran
type :: diagnostic_t
    integer :: code
    integer :: source_start
    integer :: source_end
    integer :: arg_first
    integer :: arg_count
end type
```

Only the presentation layer renders "Expected scalar entity, but `a` has rank
2." This gives stable diagnostic identifiers, localization later, structured
JSON or SARIF output for free, and far less allocation.

It also changes what tests assert. **Tests assert diagnostic code, location and
structured arguments, not English sentences.** A test that pins a message
string fails on every wording improvement and passes when the wrong rule fires
with the right words.

---

## 12. Paths, metadata, corpora

Paths are spans or interned UTF-8, converted only by the code that calls the
operating system, so path handling never reaches compiler logic.

Research metadata is I/O: JSONL bytes → parser → typed `run_record_t`, with
string keys discarded in favour of enums; and typed record → streaming JSON
writer on the way out.

Corpora are manifests of file IDs, path IDs, hashes and metadata. Read one
source buffer at a time; never load a corpus as an array of Fortran strings.

---

## 13. Target CHARACTER semantics are a separate system

Eventually the compiler must implement Fortran CHARACTER properly. That cannot
be done with byte spans, and it should be isolated rather than diffused.

**Do not model target character types with host character types.** For
`character(len=10) :: x`, the compiler's representation is a data structure:

```fortran
type :: char_type_t
    integer :: kind
    integer :: length_kind
    integer(int64) :: constant_length
end type
```

not a host `character(len=10)`. Conflating host-language string semantics with
target-language type semantics is a documented source of bugs in existing
implementations.

A character literal keeps its source span, semantic kind and semantic length,
and its value is decoded only when a semantic operation needs it.

The runtime representation — inline storage or data pointer, length, ownership
state for deferred-length allocatables — is a target and runtime specification
question, and the lowering for assignment, padding, truncation, concatenation,
substring, allocation and argument passing is generated from that
specification. Descriptor assumptions are not scattered through codegen;
`LESSONS.md` §4 is the record of what that costs.

UTF-8 is the tool encoding. Default character kind, `ISO_10646` and other
processor kinds are target-language semantics. The two systems do not meet.

---

## 14. Equality, hashing, sorting

Interned names compare as integers. Source slices compare as bytes when needed.
Canonical StandardIR and ImplIR compare as canonical trees, or by content hash
once canonicalized. Never compare rendered text to decide semantic equality.

For deterministic output ordering, sort interned IDs by their canonical byte
key, which the interner retains. Most internal operations need no lexical order
at all.

---

## 15. One small text package

Exactly one low-level package, shared by the whole stack:

```
text/
    byte_buffer
    byte_span
    byte_builder
    writer
    interner
    utf8_boundary
```

That is the complete list. It does not grow into a general string library. If
something needs a facility this package lacks, the first question is whether
the caller should be using spans instead.

`integer(int8)` is unpleasant to print, so `writer_t` owns every conversion
between internal bytes and Fortran I/O, and boundary modules own path and
stream conversion. The ugliness is real and it is confined to those places.

---

## 16. What stays a Fortran character value

Little: small static literals such as message templates, operating-system calls
requiring `character(*)`, command-line arguments, and the final user-visible
text. Each crosses immediately into or out of the byte world —
`get_command_argument` into a temporary, copied once into a buffer, and the
internal logic never sees a Fortran string again.

---

## 17. Why this makes bootstrapping easier

This is the part that pays for itself twice. Because our own implementation
avoids deferred-length allocatable character, heavy concatenation, complex
substring manipulation and large allocatable character arrays, **Bootstrap Core
does not need to support them** (D0008). The compiler can bootstrap on integer
arrays, byte arrays, spans, IDs and arenas, and full CHARACTER support becomes
a target-language feature implemented later, without blocking self-hosting.

The point is not to solve Fortran strings. It is to make host-language strings
nearly irrelevant to the implementation, while implementing target-language
CHARACTER semantics correctly and explicitly, in one place, from a
specification.

---

## 18. End to end

```
STANDARD PDF
   │ binary, pinned by hash, never vendored
   ▼
extraction → UTF-8 text artifact
   │ spans
   ▼
StandardIR
   │ IDs and structured values
   ▼
ImplIR
   │ IDs and structured values
   ▼
generated compiler structures
   │
   ├── diagnostics    → structured, rendered at the edge
   ├── Fortran source → streaming writer
   └── model prompt   → byte builder → UTF-8 API
```

and compilation itself:

```
source bytes → tokens as spans → names as IDs
    → AST in arenas → semantic representation → MIR → backend
```

with target CHARACTER semantics travelling on their own track: literal source
span → semantic CHARACTER object → specified lowering → runtime
representation.
