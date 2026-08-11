# Self-hosting and the two intermediate representations

Design note for `lazy-fortran/lazy-fortran-new`.

This defines the two intermediate representations of the specification-generated
architecture and the bootstrap strategy that moves the implementation into
Fortran, and then onto the generated Fortran compiler, as early as practical.

```
Normative standard
       ↓
   StandardIR
       │
       ├──────────────→ direct mechanical generation
       │
       └──────────────→ residual synthesis → ImplIR
                                             ↓
                                          Fortran
```

There are two semantic intermediate representations. **StandardIR** describes
what the language means. **ImplIR** describes a small constructive
implementation algorithm when one is actually necessary. They share a trivial
tree serialization, and that serialization is not itself a third semantic IR.

The change from the earlier sketch is in the second arrow. ImplIR was described
as the path every rule takes. It is not. Most constraints compile mechanically,
and ImplIR is the residual language for what does not. Section 13 gives the reasoning and D0007 records the decision.

---

## 1. Shape of the design

```
              canonical S-expression format
                         │
                 generic SX reader
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
        StandardIR schema      ImplIR schema
              │                     │
              ▼                     ▼
          StandardIR              ImplIR
```

All production tooling around these representations is written in a small
subset of modern Fortran. The S-expression reader starts as a tiny seed. Once
the generated parser machinery exists, the reader is regenerated from its own
grammar and differential-tested against the seed. The seed is a bootstrap
device, not a permanent dependency.

---

## 2. Prior work

Several existing systems independently validate pieces of this architecture.
`literature.md` carries the full references; this section records what each one
contributes and what we deliberately do not take from it.

**ASDL.** The Zephyr Abstract Syntax Description Language was built to describe
compiler IRs concisely and generate data structures and serialization for C,
C++, Java and ML. The lesson is that the maintained artifact can be a small
algebraic schema while the repetitive target-language representation is
generated. We adopt the data model — sum types, product types, lists, optional
and primitive fields — and not the toolchain, for the reasons in section 6.

**WebAssembly.** The specification describes its text format as a rendering of
abstract syntax into S-expressions, with the text grammar kept close to the
abstract syntax. That is the property we want. We are not adopting Lisp
semantics, only the observation that `(add x y)` is already the tree.

**TableGen and MLIR ODS.** LLVM maintains instruction descriptions, register
information, selection patterns and Clang AST definitions declaratively and
generates the implementation from them. MLIR's Operation Definition
Specification does the same for dialect operations. This supports the
direction. It is also a warning: TableGen has grown classes, inheritance,
template arguments, multiclasses, loops and conditionals. That complexity earns
its place in LLVM and would defeat our purpose.

**K, Ott and Spoofax.** K defines language semantics, type systems and analysis
tools as executable rewrite rules. Ott was motivated by the difficulty of
maintaining full-scale semantic definitions and generates proof-assistant
definitions and documentation from one specification. Spoofax separates syntax,
static semantics and transformation into declarative meta-languages and
generates parsers, type checkers and editor services. Together they establish
that much more than syntax can be specification-driven, and that building all
of that machinery at once is its own project.

**Scope graphs and Statix.** Scope graphs split name resolution into
language-specific construction of scopes and a language-independent resolution
calculus. Statix expresses static semantics as declarative constraints over
scope graphs and derives executable type checking from them. Most relevant is
the later work specializing declarative resolution queries into a procedural
intermediate query language: as reported there, query resolution improved by up
to 7.7× and total type-checking time fell by roughly 38 to 48 per cent. That is
the closest published precedent for what section 14 proposes, and it supports
the principle directly: keep the authoritative semantics declarative, and
specialize aggressively when producing the executable compiler.

**Menhir, CompCert, CakeML.** Menhir can generate a parser together with a
proof that it is correct and complete with respect to its grammar, a mechanism
used in CompCert. CompCert composes semantic-preservation proofs across passes,
with its theorem starting from the AST after preprocessing, parsing, type
checking and elaboration — a reminder that parsing is a separate boundary for
any end-to-end claim. CakeML is a verified compiler that bootstraps itself.
Work on bootstrapping the Spoofax meta-languages develops the fixpoint
compilation approach for systems whose compilers depend on their own DSLs and
generators, which is section 19.

---

## 3. One textual representation

StandardIR and ImplIR do not get separate lexers and parsers. Both use one
generic tree format, provisionally **SX**:

```
document := form*

form :=
    atom
  | integer
  | string
  | "(" form* ")"
```

So

```
(require
    (eq
        (rank x)
        0))
```

is

```
REQUIRE
└── EQ
    ├── RANK
    │   └── x
    └── 0
```

There is no operator precedence, no indentation significance, no statement
terminator, no implicit grouping, no macros, no reader evaluation, no
quotation, and no lists-as-runtime-data semantics. SX serializes trees and does
nothing else.

---

## 4. Canonical form

The writer removes textual freedom. `(eq (rank x) 0)` is canonical, and
`(rank(x) == 0)`, `(equal (rank x) 0)` and `(= (rank x) 0)` are not accepted
alongside it. One operation, one spelling.

Canonicalization normalizes whitespace, integer representation, string
escaping, local variable names where appropriate, and field order where the
schema defines one. Therefore

```
parse → validate → normalize → canonical serialize → SHA-256
```

gives every StandardIR and ImplIR object a stable identity, which serves both
provenance and build reproducibility.

---

## 5. The IR schemas

SX knows nothing about either IR. Each IR has a **schema**, which is not a
third semantic representation but the equivalent of a set of derived-type
definitions. The schema language needs only: primitive, record, sum, list,
optional, enum.

```
(schema standardir
  (record source-ref
    (document string)
    (clause string)
    (rule string))
  (sum item
    syntax
    constraint
    relation
    rule
    definition))
```

From it we generate Fortran types plus reader, writer, validator, visitor,
equality, canonical hashing and debug printer. None of those is maintained by
hand.

---

## 6. Why not ASDL itself

ASDL is the closest historical design, and we take its data model rather than
its toolchain. Four reasons: we want a self-hostable Fortran implementation
immediately; SX parsing is simpler than adopting another surface syntax; we
need only a small subset of ASDL's concepts; and representing the schemas as
ordinary trees lets one set of storage, hashing and inspection machinery handle
everything. ASDL idea, SX serialization, Fortran generator.

---

## 7. StandardIR

StandardIR is the authoritative formal representation of the language
specification. Its question is what programs are valid and what they mean.

It must not contain implementation strategy: not which hash table is used, not
how symbols are represented in memory, not how many semantic passes exist, not
which parser algorithm is selected, not which backend data structure is
fastest.

Five semantic forms initially — `syntax`, `definition`, `relation`, `rule`,
`constraint` — plus provenance on every object. That is enough to start Core 0
without designing a universal semantics framework first.

### Syntax

```
(syntax R501
  (lhs program)
  (rhs
    (repeat
      (ref program-unit)
      1
      unbounded))
  (source J3-24-007 R501))
```

The vocabulary is `(ref X)`, `(token X)`, `(literal X)`, `(seq ...)`,
`(alt ...)`, `(optional X)`, `(repeat X min max)`. Alternative parser
implementations are generated from it.

### Definitions

Finite domains and tables:

```
(definition intrinsic-category
    integer
    real
    complex
    logical
    character)

(definition attribute-conflict
    (pair value pointer)
    (pair allocatable pointer))
```

Many otherwise hand-written compiler tables come straight from these.

### Relations

Relations keep StandardIR declarative. A declaration says what kind of fact may
be established, not how to establish it:

```
(relation type-of      (expr type))
(relation resolves-to  (reference symbol))
(relation compatible   (type type))
```

### Rules

Rules derive relations:

```
(rule add-type
  (vars (x expr) (y expr) (tx type) (ty type) (t type))
  (premise (type-of x tx))
  (premise (type-of y ty))
  (premise (common-numeric-type tx ty t))
  (derive  (type-of (add x y) t)))
```

A generic engine can execute this. A specializer can turn it into direct
Fortran.

### Constraints

```
(constraint C1234
  (vars (x symbol))
  (require (exists x))
  (require (eq (rank x) 0))
  (diagnostic ERR_NONSCALAR)
  (source J3-24-007 C1234))
```

This compiles directly into a semantic checker. No model, and no ImplIR.

---

## 8. Name resolution

Scope-graph operations should be a generic part of the semantic engine rather
than Fortran-specific resolution logic scattered through it. Language-specific
rules construct scopes, declarations, references, import edges and parent
edges; a generic resolver answers `resolve(reference) → declaration`.

Fortran's modules, host association, USE association with renaming and
`only:`, interfaces and generic resolution make it a hard test of whether that
abstraction survives contact with a real language. This is registered as **E12**
with an explicit go/no-go gate rather than adopted as settled design. A recorded
failure is a result; the fallback is a Fortran-specific resolver.

---

## 9. Dynamic semantics

Do not invent effect syntax yet. If dynamic semantics become necessary, express
them relationally:

```
(relation step (state action state))
```

with ordinary rules deriving `step`. Whether the full Fortran runtime semantics
fits this shape is an empirical question that does not need settling before
Core 0.

---

## 10. Provenance is mandatory

```
(source
  (document J3-24-007)
  (page 123)
  (clause 8.5.8)
  (rule C851)
  (span-hash "sha256:..."))
```

so that a StandardIR rule, its generated implementation, its tests and the
compiler diagnostic it produces all remain connected. Provenance is part of the
design rather than documentation added afterwards.

The document identity travels with the record, which is what lets the same
pipeline span revisions. A rule extracted from the F2028 working draft is
distinguishable by its provenance alone:

```
(constraint C1234
  (vars (x symbol))
  (require (eq (rank x) 0))
  (diagnostic ERR_NONSCALAR)
  (source J3-26-007 C1234))
```

Nothing else about the record changes, and a profile can therefore select
across revisions.

---

## 11. Unresolved is a legal state

A rule may carry `status = unresolved`, or competing candidate formalizations.
Dependent compiler functionality does not become supported until one
formalization passes the evidence gate. That is preferable to silently encoding
a guess.

---

## 12. ImplIR

ImplIR answers a different question: given a formally specified local compiler
task, what constructive algorithm should the generated compiler execute?

It is not the compiler's MIR. It is not the language being compiled. It is not
the implementation language of the project. It is the narrow synthesis target
for cases where StandardIR cannot simply be specialized into Fortran.

**Types.** `bool`, `int`, `status`, `node`, `symbol`, `type`, `scope`, `name`,
`list<T>`, `optional<T>`. There is no `string`: names are interned IDs,
diagnostic codes and builtin operations are enums, and a procedure identifier
becomes an ID immediately after parsing. There is no `value` either, because no
builtin produces or consumes one. See D0011 and D0012.

**Statements.** `let`, `set`, `if`, `for`, `return`.

**Expressions.** `not`, `and`, `or`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`,
`sub`, `mul`, `call`, where `call` reaches only declared typed operations.

```
(proc check-C1234
  (args (x symbol))
  (returns status)
  (if (not (sym-exists x))
      (return ERR-UNKNOWN-SYMBOL))
  (if (ne (sym-rank x) 0)
      (return ERR-NONSCALAR))
  (return OK))
```

**Builtins carry the domain semantics.** A model does not implement
symbol-table mechanics; it receives typed operations such as
`(sym-exists symbol) -> bool`, `(sym-rank symbol) -> int`,
`(resolve scope name) -> optional<symbol>`, `(node-child node int) -> node`.
Target-language CHARACTER semantics arrive the same way, through `type` plus
`type-is-character`, `char-length-known` and `char-length`, rather than as an
ImplIR type.
The generic infrastructure implements them and ImplIR composes them, so the
model reasons about the rule rather than about data structures.

**No arbitrary memory semantics.** No pointer arithmetic, manual allocation,
casts, exceptions, function pointers, classes, inheritance, operator
overloading, macros, threads or general I/O. Storage is reached through typed
builtins. This is what keeps the legal output space small.

**No recursion initially.** Tree walking and graph traversal belong in the
trusted generic engine, exposed as `(children node)`, `(descendants ...)`,
`(resolve ...)`. If real rules turn out to need recursion, that is a decision
to revisit with evidence.

---

## 13. StandardIR to ImplIR is not mandatory

```
                StandardIR
                /        \
     mechanically         unresolved
     constructive         problem
          │                   │
          ▼                   ▼
       Fortran              ImplIR
                              │
                              ▼
                           Fortran
```

`require rank(x) = 0` should compile mechanically. Calling a model to produce
that checker would be waste. ImplIR exists for the residue.

---

## 14. Specialization sits between interpretation and synthesis

There is a third option between interpreting StandardIR and asking a model:
specialize the declarative semantics into procedural code. The Statix work on
specializing scope-resolution queries into a procedural query language is the
precedent, and it reports substantial speedups from exactly this move.

The performance strategy follows from it:

```
interpret first → verify semantics → profile → specialize → benchmark
```

rather than writing procedural implementations up front.

---

## 15. Text representation

Every component described here holds text as immutable bytes plus spans and
interned IDs, and materializes a Fortran `character` only at a boundary. The SX
reader interns atoms, so decoders switch on IDs; StandardIR references
normative prose by span into a hashed extracted-text artifact rather than
copying it; generated output goes through a streaming writer. D0011 states the
two rules and `docs/text-representation.md` gives the reasoning.

This is also what keeps Bootstrap Core small: because the meta-tools avoid
deferred-length allocatable character, concatenation and substring
manipulation, the compiler does not need to support them before it can compile
its own tools.

---

## 16. One parser for the surface syntax

Only the SX reader parses surface syntax. It produces a generic tree in an
arena rather than recursive heap objects:

```fortran
type :: sx_node_t
    integer :: kind
    integer :: first_child
    integer :: child_count
    integer :: text_start
    integer :: text_end
end type
```

Generated schema-specific decoders then do the meaningful validation.

The seed reader recognizes parentheses, atoms, integers, quoted strings and
whitespace, and nothing else. A few hundred lines is a reasonable expectation,
though simplicity matters more than a line count. It is property-tested:
`parse(write(tree)) = tree` and
`write(parse(canonical_text)) = canonical_text`.

**Why a manual seed is acceptable.** Every bootstrap starts somewhere. JSON
would move the seed into a JSON implementation, Python into CPython, ANTLR into
the ANTLR runtime and a Java toolchain. A tiny Fortran reader is a seed whose
behaviour can be understood in full. The goal is not zero initial code but the
smallest seed from which everything interesting regenerates.

**Regenerate it later.** Once grammars can be described in StandardIR and
parsers generated, describe SX itself in StandardIR, generate
`sx_reader_generated.f90`, and run both readers over the entire corpus
demanding identical canonical trees. When stable, the generated reader becomes
the default and the seed remains an oracle.

---

## 17. What is written in Fortran

All production meta-tooling, from the beginning: SX reader and writer; schema
decoder and generator; StandardIR typed representation, dependency analysis,
validator and reference engine; grammar, parser and test-family generators;
ImplIR typed representation, type checker, normalizer, interpreter and Fortran
emitter; the benchmark harness; the certificate and checking tools.

External programs stay at the boundary: PDF text extraction, model inference,
SMT solving, and initially the system assembler and linker. They do not shape
the internal architecture.

**Do not implement the toolchain in ImplIR.** A parser generator and a
filesystem-facing toolchain would need strings, maps, sets, I/O, collections,
recursion, error handling and filesystem APIs — at which point ImplIR is
another programming language and its value to small models is gone. The
boundary is: generic infrastructure in Fortran, generated local algorithms in
ImplIR.

---

## 18. Bootstrap Core

The meta-tools are written from day one in a restricted Fortran profile, so the
new compiler can compile them early. Call it **Bootstrap Core**; it is smaller
than the user-facing Core 0.

Prefer: free form, `implicit none`, modules, derived types without inheritance,
integer and logical and simple character, allocatable arrays, procedures with
`intent`, `if`, `select case`, `do`, stream and file I/O, `ISO_FORTRAN_ENV`.

Avoid where practical: polymorphism, parameterized derived types, coarrays,
elaborate generic machinery, procedure pointers, advanced character semantics,
defined assignment, finalization.

**Byte buffers internally.** Source and SX processing use a compact byte arena
with `start`/`length` offsets rather than a Fortran string per token:

```fortran
type :: byte_buffer_t
    integer(int8), allocatable :: data(:)
end type
```

Two benefits: it is likely faster, and it reduces how much Fortran character
semantics the first self-hosting compiler must support. `LESSONS.md` §5 is the
evidence that character handling is where compiler implementations bleed.

---

## 19. Bootstrap sequence

Stage 0 is gfortran building the meta-tools, which already use only Bootstrap
Core. No Python implementation is allowed to become the authoritative version
and then need rewriting.

Then the generated frontend, from the StandardIR Core subset: generated lexer,
parser and semantic checks. At that stage the frontend may handle only
Bootstrap Core, which is sufficient — and the first real corpus for it is its
own meta-tools.

**Compile the meta-tools before the whole compiler.** As soon as `ffc-new` can
emit runnable code, compile the SX reader, the StandardIR engine, the ImplIR
checker and the generators. That is the first practical self-host milestone and
it tells us whether Bootstrap Core is sufficient for nontrivial compiler
infrastructure. Only then require the compiler to compile itself.

Then conventional staged bootstrapping: gfortran builds compiler-0, compiler-0
builds compiler-1, compiler-1 builds compiler-2, where 1 and 2 come from
identical generated source and configuration. The first fixed-point criterion
is that the canonical generated compiler source is identical; object and binary
identity under reproducible build conditions comes later.

**Meta-language fixpoint.** When StandardIR or ImplIR changes incompatibly, the
old tool builds new tool A, A builds new tool B, and B must regenerate an
equivalent B before the new version is stable. This is what prevents a DSL
change that its own implementation cannot process.

**Order.**

1. SX reader and writer in Bootstrap Fortran
2. StandardIR schema → generated Fortran types
3. ImplIR schema → generated Fortran types
4. StandardIR syntax → generated Fortran parser
5. StandardIR constraints → generated semantic checker
6. Compiler handles enough Bootstrap Core to compile the SX and IR tools
7. Compiler compiles the parser and semantic generators
8. Compiler compiles itself
9. Generated SX parser replaces the seed by default
10. Native backend removes the LLVM dependency

---

## 20. Verification

**SX layer.** Round-trip properties, differential seed against generated
parsing, mutation testing, fuzzed trees, a malformed-tree corpus, canonical
serialization equality.

**StandardIR.** Layered: SX syntax valid, schema valid, references resolve,
semantic terms well typed, relations and rules well formed, dependency graph
valid, generated witnesses pass. The validator is generated from the schema
wherever possible.

**ImplIR.** Acceptance requires SX valid, schema valid, fully typed, all
variables defined, all paths valid, effects permitted, return type valid,
contract satisfied, tests pass, mutation gate passes. Output failing any layer
is rejected, and no model output is part of the trusted base.

**Emitter.** A small Fortran interpreter for ImplIR gives reference execution
independent of the emitter, so generated Fortran can be differentially tested
against interpreted ImplIR over generated inputs. Keeping ImplIR small helps
the emitter's own verification as much as it helps the model.

---

## 21. Correctness boundary, and what is not planned

The eventual chain:

```
normative PDF
   ↓ automatic formalization, evidence checked
StandardIR
   ↓ formal semantics
source language
   ↓ parsing
AST
   ↓ semantic checking
typed program
   ↓ transformations
MIR
   ↓ backend
machine code
```

CompCert shows how semantic-preservation theorems compose across passes once
the languages have formal semantics. Our added difficulty is pushing the formal
boundary upstream toward the standard itself.

Two stronger guarantees are **named as future work and are not planned**, with
no phase gate and no roadmap entry. Certified parsing in the Menhir sense would
introduce a proof assistant into a project whose thesis is that everything is
Fortran. Diverse double compilation, which is the actual answer to trusting
trust rather than stage-2/stage-3 equality, would eventually mean independent
bootstrap paths through gfortran, Flang and ifx. Both are recorded here so that
the trusted-base statement in `WHITEPAPER.md` §19 is not mistaken for a claim
that these problems are solved.

---

## 22. Where the components live

`standard-new`: SX seed reader and writer, IR schema generator, the StandardIR
schema, the StandardIR engine, and the PDF-to-StandardIR machinery.

`fortfront-new`: the ImplIR schema, checker, interpreter and emitter; parser
generation; semantic specialization; the generated frontend.

When `ffc-new` starts using ImplIR independently, assess whether the shared
implementation should be extracted. Do not create a `fortgen-new` because it
might one day be useful. Extract on actual duplication.

Provisional file extensions: `.sir` for StandardIR, `.iir` for ImplIR, `.sxs`
for schemas. The suffixes do not matter; the separation does.

---

## 23. The split, and the trend

StandardIR answers *what is true*: declarative, relational, provenanced,
stable, human-reviewable, independent of implementation strategy. ImplIR
answers *what should this generated procedure do*: constructive, typed,
restricted, canonical, easy for small models to produce and easy to verify.

If StandardIR starts discussing hash-table probing, it is wrong. If ImplIR
starts becoming the formal definition of Fortran semantics, it is wrong.

Early on there will be many residual ImplIR synthesis tasks. As generic
engines, specializers and mechanical generators improve, there should be fewer.
The fraction of rules requiring ImplIR, plotted against project maturity, is
therefore one of the more interesting measurements the project can produce, and
it should decrease. It is tracked as a headline metric rather than left to
impression.

---

## 24. Decisions adopted

1. Both IRs use one canonical S-expression serialization (D0006).
2. That syntax is a tree representation, not Lisp (D0006).
3. StandardIR is declarative and relational.
4. StandardIR initially contains syntax, definitions, relations, rules and
   constraints.
5. Name resolution starts by testing scope-graph-style generic resolution, as
   E12, with a go/no-go gate.
6. Most simple StandardIR constraints compile directly (D0007).
7. ImplIR is a residual typed implementation language (D0007).
8. ImplIR is deliberately too weak to implement the toolchain (D0007).
9. Production meta-tools are written in Bootstrap Core (D0008, D0009).
10. A tiny Fortran SX reader is the seed (D0009).
11. Typed IR readers and writers are generated from the schemas.
12. Once parser generation exists, generate the SX parser and
    differential-test it against the seed.
13. The IR and meta-tools are the first substantial programs compiled by the
    new compiler (D0010).
14. Then the compiler compiles itself (D0010).
15. Fixpoint regeneration is required for the compiler and for breaking
    meta-language changes (D0010).

The bootstrap is deliberately short:

```
tiny Fortran seed
      ↓
StandardIR machinery
      ↓
generated Fortran frontend
      ↓
minimal compiler
      ↓
compile the IR machinery
      ↓
compile the compiler
      ↓
self-host
```

The objective this protects is that the architecture becomes simpler as it
becomes more capable, instead of accumulating layers.
