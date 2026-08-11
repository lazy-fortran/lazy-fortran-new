# From Standards to Compilers

## A specification-generated, AI-assisted Fortran compiler architecture

Status: design proposal.
Meta-repository: `lazy-fortran/lazy-fortran-new`.
First production repository: `lazy-fortran/standard-new`.
Licence: MIT for new Lazy Fortran software and specifications where legally
applicable.

---

## Abstract

Compiler construction is dominated by manually maintained implementation code. A
language standard describes the intended language in several hundred pages;
implementations expand that into hundreds of thousands or millions of lines
covering lexing, parsing, semantic analysis, intermediate representations,
optimization, ABI handling, code generation, diagnostics and testing.

This project proposes to derive the compiler from machine-readable
specifications instead of maintaining it as source. Deterministic generation is
used wherever the specification already determines the implementation. Formal
search and synthesis are used where construction requires bounded choices. Large
language models are used only for residual local tasks that require
interpretation. Every generated artifact is untrusted until checked against
independent constraints, tests, differential oracles, formal properties or
translation validation.

```
normative Fortran standard
          ↓
      StandardIR
          │
          ├──→ mechanical generation or specialization ──┐
          │                                              │
          └──→ residual synthesis ──→ ImplIR ────────────┤
                                                         ▼
                                        verification and benchmarking
                                                         ↓
                                             generated modern Fortran
                                                         ↓
                                                 generated compiler
```

StandardIR is expressive enough that most semantic checks compile directly.
ImplIR is the residual implementation language for the rest, not a layer every
rule passes through (D0007).

The compiler is written in generated modern Fortran and is intended eventually
to compile itself.

Three objectives run in parallel. The scientific one: determine how much
compiler implementation is intelligent work and how much is mechanical
elaboration of an existing specification. The engineering one: build a fast,
simple, reusable modern Fortran frontend and compiler. The methodological one:
establish whether better specifications, better decomposition and small
intermediate languages can substitute for larger coding models.

The proposition under test: once the specification, synthesis, verification and
generation boundaries are drawn in the right places, most of a Fortran
compiler can be derived rather than written. How much is an open number, and
the point of sections 25 and 26 is to produce it rather than to assume it. The
project's own working target is that fewer than one rule in twenty needs a
model, and fewer than one in a hundred needs a person, both measured per
StandardIR rule; those figures are hypotheses, not results.

---

## 1. Motivation

Compiler development is expensive because semantic knowledge is repeatedly
converted into implementation detail by hand. A standard states that an entity
with some attribute shall satisfy some conditions. A conventional project then
writes, separately: parser support, an AST representation, analyzer logic,
diagnostic paths, tests, IR lowering, backend handling and tooling queries. The
same distinction is later rediscovered by static analyzers, formatters,
differentiation tools, translators, language servers and optimizers.

Much of the resulting source represents no new intellectual content. It is
transcription of information that already existed.

Modern coding models change the economics. They make repetitive implementation
much cheaper, which suggests something stronger than using models to write more
compiler code. If code can be generated cheaply, it should stop being the
primary maintained artifact. The durable artifact is the specification the
implementation can be regenerated from.

---

## 2. Evidence from the existing toolchain

The architecture is motivated by specific, documented experience with
`standard`, `fortfront`, `ffc`, `fortad`, `fortsym`, `fortgen`, `fluff`,
`LFortran`, `liric` and the Lazy Fortran GCC fork. `LESSONS.md` records that
evidence at commit level, including the cases where it contradicts the argument.
In summary:

1. **A transcribed specification becomes a software project of its own.** Dead
   tokens, unreachable productions, features attributed to the wrong revision,
   inheritance overrides silently dropping coverage, semantics implemented in
   validators nothing calls, and about 7,000 lines of audit documentation
   eventually deleted for duplicating information available elsewhere.
2. **Semantic knowledge gets reconstructed by every consumer.** One frontend
   query module grew to 9,960 lines and 95 public exports, one query at a time,
   named after the consumers that asked. The downstream consumer wrote the
   required contract into its own roadmap because the frontend did not have one.
3. **Rank, type and representation combinatorics defeat conventions.** Explicit
   rank-one-to-four ladders across reductions, arrays, components and sections;
   13% of one repository's insertions; 58% of its source in include fragments
   its own standards document forbids.
4. **Declaring the representation lattice is not enough.** See §2.4 below. This
   is the correction that most changes the design.
5. **Text handling and accidental quadratic behaviour dominate real cost.**
   Repeated quadratic concatenation, whole-arena scans, token copies and linear
   lookups, with fixes producing order-of-magnitude speedups, and the same
   defect class recurring seven months after a partial fix.
6. **Tests are evidence and evidence can be forged.** Programs that could not
   fail, benchmarks reporting infinite throughput, always-true shipped API
   stubs, and a gate documented as blocking that a merge flag walked past.
7. **Self-reported status rots in both directions.** Optimistically and
   pessimistically, within months.

### 2.4 Declaring the representation lattice is not enough

An earlier version of this argument said that physical representations must be
separately specified and mechanically related to semantic types. That is
correct and insufficient, and the evidence for the insufficiency is decisive.

`lfortran/src/libasr/ASR.asdl` already does exactly what the weaker claim
recommends. It declares nine array physical types and two string physical types,
and it declares explicit `ArrayPhysicalCast` and `StringPhysicalCast` nodes so
that every transition between representations is visible in the IR rather than
inferred. It is a deliberate, well-formed design by people who understood the
problem.

It still produced 394 descriptor commits, 52 cast commits and repeated internal
compiler errors over nine years. The cost is legible in the commit shape:
introducing one new representation takes three commits (declare it, handle it
in the frontend, handle it at the backend), because every consumer must be
taught about it by hand.

The correct requirement is therefore not that representations be declared. It is
that **the lowering between them be generated**. The measure is concrete: adding
a representation must be one specification change with no consumer edits. Any
architecture that cannot meet that test has reproduced the problem with better
documentation.

---

## 3. Thesis

The information required to construct most of a compiler already exists in the
language specification, so most of the implementation should not be written by
hand.

Every implementation problem falls into one of four categories.

**Constructive.** The specification determines the implementation. Use
deterministic generation: lexer tables, AST declarations, visitors, serializers,
encodings, simple semantic predicates.

**Searchable.** The behaviour is determined but several implementations satisfy
it. Use enumeration, SMT, CEGIS, synthesis or autotuning.

**Local reasoning.** The specification determines the behaviour but expressing
the implementation needs a modest reasoning step. Use the smallest capable model.

**Ambiguous.** The normative source has no unambiguous machine interpretation
yet. Use independent formalizations, stronger models, counterexample generation
and external compiler comparison, and permit the system to mark the feature
unresolved rather than guess.

---

## 4. Repository architecture

`lazy-fortran-new` is the laboratory: architecture, wiring, experiments, runs,
decisions, historical analysis and papers. It contains no compiler code.

`standard-new` converts normative language specifications into StandardIR and
derived artifacts, and contains nothing about how those techniques were
developed.

`fortfront-new` is the frontend: source to lexer to parser to AST to semantic
analysis to a typed semantic representation, plus standard-Fortran emission and
frontend queries. No compatibility with the current FortFront API is assumed.

`ffc-new` is the driver and middle end: typed frontend output to MIR,
optimization, and the command-line compiler.

`fortback-new` is the backend: machine-readable target descriptions to generated
encoders, object writers and instruction selection. It is a separate repository
because it is ISA-specific where `ffc-new` is not, and because a generated
backend is useful outside this compiler.

The existing repositories are oracles, corpora and historical evidence. They are
not architectural constraints.

### 4.1 No inherited constraints, and no blindfold

**Nothing is inherited.** No API contract, module boundary, naming scheme, data
structure, file layout, error convention, build arrangement or test harness from
`standard`, `fortfront`, `ffc`, `fortad`, `fluff` or any other existing
repository constrains this work. There is no compatibility requirement in either
direction. Where an old design was shaped by a constraint that no longer applies
or by a mistake, the new design is free to differ completely, and usually
should. `LESSONS.md` exists precisely so that the differences are deliberate
rather than accidental.

**And nothing is deliberately unlearned.** The goal is to demonstrate that a
specification-generated compiler can work, not to prove it was built in
isolation. Knowledge from the existing toolchain is welcome, and the good parts
should be taken directly: the negative-control gate, the accept/reject corpus
baseline, the hash-pinned corpora with a tested verifier, reporting strict and
evaluated rates separately, bounded claims with named refusals. `LESSONS.md`
lists these under "what to import rather than reinvent" and they should be
imported on day one, not rediscovered.

Any model used here was trained on Fortran compilers, on LFortran, on gfortran,
and quite possibly on these repositories. Information isolation is therefore
not available, and the project does not claim it. What it claims is narrower
and checkable: that each artifact's origin is recorded, and that the grammar
was derived from the document rather than copied from another grammar.

The one real restriction is narrow and specific: the
extraction pipeline is written without copying productions out of an existing
grammar, so that the generated grammar can be said to come from the document.
That is a rule about *derivation of one artifact*, not a rule about what anyone
is allowed to know. Reading those grammars to understand the problem, to
adjudicate a disagreement, or to decide what to build is expected. The separate
restriction on GPL sources is legal rather than scientific and is described in
§14.

---

## 5. Starting from the normative standard

The upstream artifact is the standards document, not a hand-maintained grammar.
The target is **J3/24-007**, the Fortran 2023 final working draft, which is
freely available and technically near-identical to ISO/IEC 1539-1:2023.

```
standard PDF → layout-aware extraction → canonical text → StandardIR
```

The document is pinned by URL and SHA-256 and never vendored. Extraction is
layout-aware because the grammar productions are typographically structured, and
uses `poppler` through `ISO_C_BINDING` from Fortran. An independent extractor
is the differential oracle for the text layer itself, so the first stage of
the pipeline is checked the same way as every later one.

---

## 6. Syntax extraction

Modern Fortran standards contain numbered grammar productions in a regular
notation. Reinterpreting them does not require a model. It requires a parser for
the standard's own notation.

```
PDF → text and layout → recognize R-numbered production → parse notation
    → StandardIR syntax object
```

Where possible this round-trips: a production is extracted, converted to
StandardIR, pretty-printed back into normalized notation, and compared
structurally against the original.

The existing grammars (the old `standard` corpus, the kaby76 reference
grammars, LFortran, Flang) are independent comparisons, not sources and not oracles. They
may be wrong, which is why there are several of them. Productions are not copied
from any of them, so that the generated grammar can be said to derive from the document. Every disagreement is then adjudicated against the pinned
document and recorded with a verdict: our error, theirs, or genuine ambiguity in
the standard. The classification produces a number that does not otherwise
exist: for each hand-maintained grammar, disagreements resolved against it
divided by rules compared. E1 defines the adjudication procedure and reports
the counts, including the ambiguity bucket, which is a finding about the
document rather than about any implementation.


One comparison this project deliberately does **not** make is effort. Comparing
the cost of building this pipeline in 2026 against the cost of hand-maintaining
a grammar in 2025 is confounded by the change in model capability on both sides
and is not defensible. The defensible claim is about defect classes: a grammar
derived in one pass from one pinned document cannot contain a token that no rule
references, because there is no hand to write one. That claim is independent of
who or what did the work, and the defect list it eliminates is documented in
`LESSONS.md`.

---

## 7. Semantics beyond grammar

A grammar describes syntactic possibility. It does not describe name resolution,
scope, type compatibility, rank constraints, generic resolution, argument
association, initialization, allocation, finalization, procedure
characteristics, dynamic type, storage association or runtime behaviour. All
normative meaning must therefore be expressible in StandardIR, or the
formalization is incomplete in exactly the places that make compilers hard.

---

## 8. StandardIR

StandardIR answers "what does the language mean". It is declarative, it is not
implementation code, and every entry carries provenance: document, clause, rule
number, page, source hash.

Keep the language small. Four record categories suffice to begin:

```
syntax R501 program
    repeat program_unit min=1
end

constraint C851
    on dummy_argument
    when has_attribute(value)
    require not has_attribute(pointer)
end

semantic allocation
    on allocation_stmt
    require not allocated(object)
    effect
        allocate(object, requested_shape)
    end
end

definition numeric_type
    integer
    real
    complex
end
```

A fifth category is added only when a real clause demonstrates it is necessary.

---

## 9. Prose to StandardIR

This is where model capability first becomes necessary. A normative
paragraph may say that if some condition applies, an entity shall possess some
property unless a further condition holds. Formalization proceeds
hierarchically: mechanical translation patterns first, then the smallest model,
escalating only on failure. Output is not accepted merely because it parses.

---

## 10. Verifying the formalization

A formal system can prove conformance to a formal specification. It cannot
prove that an automatically produced formalization is the uniquely
correct reading of an English sentence, because the English has no formal
semantics to compare against.

What can be proved is that **the compiler conforms to StandardIR**. The bridge
from prose to StandardIR carries no proof and is validated by independent
evidence instead: extract the exact paragraph and its referenced definitions, run
independent formalizations, normalize and compare them, synthesize distinguishing
examples where they differ, query existing compiler behaviour, generate positive
and negative witnesses, review adversarially with a second model, and mark the
rule unresolved rather than guess.

The acceptance rule is mechanical rather than editorial. A rule becomes
`resolved` when the independent formalizations normalize to the same form and
the generated witnesses agree with at least two oracles. Everything else stays
`unresolved`, and the compiler reports the feature as unsupported rather than
guessing at it.

---

## 11. ImplIR

ImplIR answers "how does the compiler locally implement this rule". Unlike
StandardIR it is constructive and procedural, and it is deliberately tiny. Its
audience is deterministic generators, synthesis systems, small models and
mechanical verifiers, not human programmers.

**It is residual.** A constraint such as `require rank(x) = 0` fully determines
its own checker and compiles mechanically; routing it through synthesis would
buy nothing and would make the model-generated fraction 100 per cent by
construction, destroying the measurement. Three paths exist and are tried in
order: interpret the declarative rule, specialize it into procedural Fortran,
or synthesize ImplIR. `docs/self-hosting.md` gives the design and D0007 the
decision.

### The case for a tiny DSL

A model may have seen billions of tokens of Python and little Fortran. A new DSL
that appears nowhere in training data can still be easier to generate, because
its legal output space is dramatically smaller and its complete grammar and
semantics fit in the prompt. Instead of choosing among language idioms,
container libraries, allocation strategies, error conventions and module
structures, the model chooses among roughly thirty canonical compiler
operations.

The hypothesis, stated so it can fail: **better intermediate representations
trade against model scale.**

### ImplIR v0

Types: `bool`, `int`, `status`, `node`, `symbol`, `type`, `scope`, `value`,
`block`, `list<T>`, `optional<T>`.

Statements: `let`, `set`, `if`/`else`, `for ... in`, `return`. Additions wait for a real requirement.

Expressions use canonical names with no synonyms: `not`, `and`, `or`, `eq`,
`ne`, `lt`, `le`, `gt`, `ge`, `add`, `sub`, `mul`, `list_size`, `list_get`.

Builtins cover symbol, type and node queries plus diagnostics: `sym_lookup`,
`sym_exists`, `sym_type`, `sym_rank`, `sym_kind`, `sym_is_allocatable`,
`sym_is_pointer`, `sym_is_parameter`, `type_equal`, `type_is_numeric`,
`node_kind`, `node_child`, `node_symbol`, `node_type`, `diag`.

A complete synthesis task then looks like this. Rule: the referenced entity
shall exist and shall be scalar. Expected output:

```
proc check_C1234(x: symbol) -> status
    if not(sym_exists(x))
        return ERR_UNKNOWN_SYMBOL
    end
    if ne(sym_rank(x), 0)
        return ERR_NONSCALAR
    end
    return 0
end
```

which lowers mechanically to Fortran. The model never reasons about Fortran
implementation mechanics.

### Generating ImplIR mechanically

Wherever possible, we should, and that is the intended maturation path. A new
rule family is first solved by a model. The repeated pattern becomes evident,
and the model is replaced by a deterministic generator. The model is a mechanism for
discovering missing abstractions. If the architecture works, model use per
rule declines over time as patterns are absorbed into generators, and E3 tracks
that trajectory directly.

---

## 12. Generation hierarchy

Deterministic generation; then symbolic search, SMT or CEGIS; then the smallest
model, escalating through model scales; then human intervention only if
unavoidable. Stop at the cheapest accepted solution and record which
level produced the artifact.

---

## 13. Testing, and who tests the tests

A model-generated corpus is not trustworthy because it is large. The same model
can misunderstand the specification and reproduce the misunderstanding in the
implementation and the tests alike.

```
                     StandardIR
                 /       |        \
     implementation   properties   tests
                \        |         /
                  verification + mutation
```

Mechanically, per rule: a minimal valid witness, a minimal invalid neighbour,
boundary cases, each alternative, and dependency combinations. Models add
adversarial cases, cross-feature cases and metamorphic properties. Mutation
testing then asks whether the suite distinguishes a correct implementation from
a nearly correct one: given `rank(x) == 0`, produce mutants with the condition
removed, with `== 1`, with `<= 1`, with `>= 0`. A suite that cannot separate
them is incomplete, whatever its size.

`LESSONS.md` §6 records what the alternative produced: 21 test programs
totalling 9,246 lines that could not fail, three of which used a
non-empty-output check as their verdict.

---

## 14. Differential oracles

The existing compilers are valuable precisely because they disagree with each
other.
gfortran, LLVM Flang, LFortran, FortFront and FFC serve as independent oracles
over accept and reject decisions, diagnostics, runtime behaviour, source
round-trips and ABI behaviour. Differences produce automatically minimized
reproducers. No existing compiler is normative; StandardIR is.

One boundary is legal rather than technical. gfortran is GPL. It is used as a
behavioural oracle only (run the binary, compare the output), and its source is
not read while authoring the corresponding component. Permissively licensed
sources may be read, with each instance logged. Hash-pinning solves
redistribution. It does not solve contamination.

---

## 15. Modern Fortran Core

The compiler does not initially target all historical Fortran, and does not
target a toy language. Core 0 is a strict subset of standard Fortran, so every
Core program is a valid standard program. It comprises free form, `implicit none`,
modules, procedures, intent, optional and keyword arguments, generic interfaces,
the intrinsic numeric and logical types, basic character handling, derived
types, arrays including assumed shape and allocatable, the common control
constructs, `do concurrent`, `ISO_C_BINDING`, basic I/O and OpenMP syntax.

Initially excluded: fixed form, implicit typing, `COMMON`, `EQUIVALENCE`,
`BLOCK DATA`, assigned and arithmetic control transfer, alternate returns,
statement functions, Hollerith, `ENTRY`, legacy storage association, complex
legacy `FORMAT` behaviour, parameterized derived types, coarrays, and full
polymorphic object orientation.

The governing criterion: **Core 0 must eventually suffice to implement the
generated compiler itself.**

Profiles are not second grammars. A profile is a set of StandardIR rule IDs plus
a computed dependency closure.

---

## 16. Frontend

One reusable frontend, exposed as a library rather than only as part of an
executable: canonicalization, lexer, parser, AST, semantic analysis, typed
semantic result.

The lexer is generated from the lexical specification. Generated does not imply
a slow generic runtime: direct-coded DFA, table-driven DFA and specialized
scanners are all candidates and are benchmarked. The source stays in one
immutable buffer. A token is a kind and two offsets, and names are interned once and
case is normalized once.

The parser structure is generated from StandardIR syntax. Predictive recursive
descent, LALR, specialized direct parsing, Pratt expression parsing and hybrids
are candidates. Generate several, benchmark them against real corpora, keep the
fastest correct one. The grammar does not change.

The frontend exposes the following by construction, so that no consumer
reconstructs any of it: resolved symbols and
procedures, generic candidates, actual-to-dummy mappings, type, kind, rank,
shape, bounds, intent, optionality, allocatable and pointer and target
attributes, dynamic type, SELECT TYPE and SELECT RANK narrowing, allocation
source and mold, ownership and lifetime, component paths, procedure-pointer
targets, source ranges and rule provenance. `LESSONS.md` §2 is the record of
what happens otherwise.

---

## 17. AST and MIR only

Two representations, not a tower. The AST holds source-level semantics and
provenance, sufficient for diagnostics, formatting, refactoring, analysis,
source-to-source transformation and language-server features. MIR is one typed
executable representation: constants, locals, load, store, arithmetic and
logical operations, calls, returns, branches, loops, array addressing,
allocation. Operations are added when a requirement justifies them.

The generated compiler exposes `libfront`, `libmiddle`, `libback` and `libemit`,
which yields a static analyzer, a language server, a formatter, a
source-to-source translator and a native compiler from the same components.
Lazy Fortran extensions become layered specifications over ISO StandardIR, each
specifying syntax, meaning and lowering, so an extension can lower automatically
to standard Fortran.

---

## 18. Backend

The original plan for this project was to lower MIR to LLVM IR and treat a
native backend as distant future work. Two facts change that.

First, `liric` already exists: a from-scratch C11 compiler and JIT of about
50,000 lines with its own LLVM IR parser, bitcode decoder, instruction selection
for x86-64, AArch64 and RISC-V, and ELF and Mach-O writers, reporting an order
of magnitude speedup against LLVM on its own corpus. It establishes that one
person can write a working native backend for the IR a Fortran compiler emits.
It does not establish that such a backend can be generated, which is the open
question.

Second, `liric` is hand-written. Under this project's own thesis that makes it
the weakest link in the chain: every other layer would be generated from a
specification and checked against oracles, while code generation rested on
50,000 lines of C that someone maintains by hand. Its own roadmap reports its
producer, nightly and compatibility evidence as red, and 78% of its commits come
from a single month.

`fortback-new` therefore applies the same method one layer down. A backend is
the same shape of problem as a frontend. In both cases the normative artifact
is a finite table of forms with an associated semantics, machine-readable in
principle, so the implementation is a function of that table rather than an
interpretation of it. Where the two differ is in how good the table is, which
is the subject of E11.

**Instruction sets have official machine-readable specifications**, and their
quality varies enormously:

- **RISC-V.** `riscv-opcodes` gives every encoding in machine-readable form and
  the Sail model is the official formal semantics, executable. BSD licensed.
  Spike and QEMU are additional behavioural oracles, and Sail makes translation
  validation of generated machine code achievable.
- **AArch64.** ARM publishes the Machine Readable Architecture: every A64
  encoding plus per-instruction semantics in ASL, official and complete.
- **x86-64.** No official machine-readable encoding specification. The SDM is a
  PDF (the same extraction problem as 24-007, one layer down), and the
  practical sources are Intel XED's data files, Zydis tables, and uops.info for
  latency and throughput.

**RISC-V and AArch64 come first, x86-64 last**, on the assumption that the cost
of a generated backend tracks the quality of the ISA specification rather than
market share. Doing two at once tests whether the target description
generalizes. E11 reports the cost across all three, and would refute the
ordering if x86-64 turned out no more expensive.

LLVM remains available as a differential oracle and performance baseline. It is
not on the production path.

---

## 19. The trusted base

The following are never generated, and are trusted as given:

- the hardware, and the ISA specification's own correctness;
- the operating system and the C library;
- the bootstrap compiler used to build the first generated compiler;
- the C libraries bound through `ISO_C_BINDING`, principally `poppler` at the
  top of the pipeline;
- the verification tools themselves, including any solver.

What the architecture claims is narrower: **no layer is a hand-written
transcription of a specification that exists elsewhere in machine-readable
form.**

---

## 20. Optimization at the highest semantic level

Perform a transformation before the information it needs has been destroyed.
`matmul(A, x)` carries meaning that disappears once it becomes scalar pointer
arithmetic. `R(y, p) = 0` carries information useful for implicit
differentiation that disappears if only the numerical iteration solving it is
visible. Symbolic transformation and array algebra belong high; differentiation
belongs at the highest semantic level where it is possible; loop fusion belongs
in MIR; vectorization lower; instruction selection and peephole work at the
machine level. This mirrors the experience of source-level versus late IR-level
automatic differentiation.

---

## 21. Performance as a search objective

Correctness and performance are separated. The specification determines
correctness. The generator searches for speed. Parser strategy, symbol-table
representation, AST layout as array-of-structures or structure-of-arrays, and
modular versus fused semantic evaluation are all candidate axes producing the
same semantics. Benchmark real workloads and select.

Pass fusion follows from this. Human-maintained compilers have many separate
passes because that makes them tractable to maintain. Generated code has no such
constraint. The specification stays modular, one constraint per rule, while
generation discovers that the checks can execute in a single traversal.
The resulting hypothesis is measurable, and E6 measures it: generated fused
checking should bring parsing-plus-checking throughput close to parsing alone
on the pinned corpus, where a conventional pass-per-rule structure does not.

---

## 22. Fortran as the implementation language

The generated implementation language is modern Fortran, for practical and
scientific reasons alike. Compiler workloads are full of structures Fortran
handles well: large arrays, integer identifiers, arenas, graphs, tables,
bitsets, dense passes, immutable buffers, parallel analysis. Generated code need
not be aesthetically hand-written, because boilerplate is irrelevant when it is
generated.

Implementation is in Fortran, with C libraries reached through `ISO_C_BINDING`.
A component may remain someone else's C library only when writing it would
require on the order of a hundred thousand lines. PDF rendering qualifies; PDF text extraction
does not, once `poppler` is bound.

ImplIR additionally supports experimental deterministic emitters to C and Rust,
so the same algorithm can be compared across implementation languages without
measuring model familiarity. Fortran is the project; C and Rust are controls.

---

## 23. Self-hosting

Build the generated compiler with gfortran to get
compiler A; compile the compiler's own source with A to get B; with B to get C;
require convergence. The compiler is written within Modern Fortran Core, so
self-hosting simultaneously demonstrates the compiler's viability, modern
Fortran's general-purpose viability, and the sufficiency of the chosen profile.

---

## 24. Research method

All research process data lives in `lazy-fortran-new`, never in the production
repositories. The infrastructure is git, Markdown, JSON, JSONL and TOML, and
nothing else until pain proves otherwise.

Three properties of the record matter for the claims above, and `RESEARCH.md`
specifies the formats that enforce them. Runs are append-only, so a reported
rate cannot be improved after the fact. Failed runs are kept, so the
denominator is real. Every artifact carries one of eight origin labels, which
is what turns "mostly generated" from an impression into a count.

---

## 25. Experiments

- **E1.** How much of the syntax of a real standard can be extracted without a
  model?
- **E2.** How much semantic formalization can be mechanical?
- **E3.** What is the minimum model size per semantic rule?
- **E4.** Does ImplIR reduce required model capability and cost, on the
  residue that cannot be specialized mechanically?
- **E12.** Does language-independent scope-graph resolution handle Fortran's
  modules, host association, USE renaming and generic resolution without
  Fortran-specific escape hatches?
- **E5.** Can generated specialized parsers match or beat established compilers?
- **E6.** Can rule-derived semantic checks outperform conventional pass
  structures?
- **E7.** How effective are mechanical, model-generated and mutation-derived
  tests, measured against each other?
- **E8.** How do generated Fortran, C and Rust versions of the same compiler
  compare?
- **E9.** Can automatically selected representations outperform manually chosen
  ones?
- **E10.** How small a modern Fortran profile suffices to implement its own
  compiler?
- **E11.** How does the cost of a generated backend vary with the quality of the
  ISA specification, across RISC-V, AArch64 and x86-64?

---

## 26. Success metrics

Compiler completeness and implementation origin are tracked together: syntax
rules covered, semantic rules formalized, and of those, how many were
mechanically implemented, search-synthesized, model-generated or left
unresolved; how many are verified and how many are mutation-covered.

Performance: parsing throughput, files per second, peak resident memory,
compiler build time, binary size, generated-program runtime and size.

Economics: model, tokens, attempts, latency, cost, and the minimum model that
succeeded.

Every published figure names the command that regenerates it.

---

## 27. Risks

**Formalization remains ambiguous.** Mitigate with multiple formalizers,
counterexamples, differential oracles and an explicit unresolved state. Never
silently guess.

**StandardIR becomes another programming language.** Keep a few declarative
record forms. Reject convenience features until a clause requires one.

**ImplIR grows into another LLVM.** It exists for tiny implementation
fragments. Machine semantics belong in the target description, not here, and
the toolchain is deliberately not implementable in it: a parser generator would
need strings, maps, sets, I/O, recursion and filesystem access, at which point
it is another programming language and its value to small models is gone.

**Generated code is slow.** Generate multiple candidates and benchmark.
Generated source need not resemble hand-written source.

**Tests agree with an incorrect formalization.** Mutation, independent
interpretations, differential compilers, metamorphic tests and semantic
properties.

**Research infrastructure becomes a project of its own.** Git, Markdown and
JSONL. No platform until the pain is demonstrated.

**The backend is harder than the frontend.** Possible. Starting with the
best-specified ISAs and keeping LLVM as an oracle bounds the damage, and E11
measures the cost rather than assuming it.

---

## 28. What is explicitly not built

No agent framework, workflow server, experiment database service or custom
dashboard. No tower of intermediate representations. No new general-purpose
language. No model runtime inside the compiler. No bespoke theorem prover. No
microservices. Each of these has been proposed at some point in the existing
toolchain and none of them survived contact with the actual work.

---

## 29. The design principle for AI

AI enters this architecture in one place: as an untrusted synthesis mechanism
for the residue that deterministic methods do not yet cover, subject to the
same verification as any other generator. That placement is what makes the
declining-model-use prediction in section 11 falsifiable. A project organized
the other way round, with a model writing the compiler and tests checking it
afterwards, would have no way to tell whether it was improving.

---

## 30. The intended workflow

```
update the normative specification
        ↓
regenerate StandardIR
        ↓
identify new or changed formal rules
        ↓
mechanical implementation where possible
        ↓
tiny-model synthesis for residual gaps
        ↓
independent verification
        ↓
generate optimized Fortran
        ↓
benchmark candidate implementations
        ↓
select the fastest verified variant
        ↓
publish the generated compiler
```

A developer adding a language feature specifies what syntax exists, what it
means, what constraints hold, and how it lowers, without reading the frontend
or the backend.

How much of a compiler that covers is unknown. Section 25 is built to produce
the number, and the number may come out well below what the argument here
assumes.
