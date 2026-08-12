# Design

How the pieces fit together. `WHITEPAPER.md` argues why. This describes what.

---

## 1. Repository hierarchy

```
lazy-fortran-new          laboratory: research, wiring, papers, decisions
│
├── standard-new          normative document → StandardIR → derived artifacts
├── fortfront-new         StandardIR → lexer, parser, AST, semantics, emitter
├── ffc-new               typed frontend output → MIR → optimization → driver
└── fortback-new          target description → encoder, object writer, ISel
```

The split between `ffc-new` and `fortback-new` is deliberate. The middle end is
ISA-independent. The backend is entirely ISA-specific and is generated from a
different class of specification. Keeping them apart also makes the backend
useful on its own, and stops target details leaking into optimization the way
`LESSONS.md` §4 documents.

Production repositories carry no research history. This one carries no
production code. `AGENTS.md` states the boundary and its consequences.

Nothing in the existing repositories constrains any interface here. There is no
compatibility requirement in either direction.

---

## 2. The pipeline

```
J3/24-007 (pinned, never vendored)
    │  poppler via ISO_C_BINDING, layout-aware
    ▼
canonical text + glyph geometry ──── differential oracle: independent extractor
    │  R-numbered production parser (mechanical)
    ▼
StandardIR syntax ─────────────────── comparison: standard .g4, kaby76, LFortran, Flang
    │  prose formalization (mechanical → small model → larger)
    ▼
StandardIR constraints and semantics
    │  profile selection + dependency closure
    ▼
Core 0 rule set
    │  interpret, else specialize, else synthesize
    ├──────────────────────────────────┐
    ▼                                  ▼
specialized Fortran                  ImplIR
    │                                  │  mechanical emission
    └──────────────┬───────────────────┘
                   ▼
generated modern Fortran ─────────── benchmark candidates, select fastest verified
    │
    ▼
frontend → MIR → backend (RISC-V, AArch64, then x86-64)
```

Every arrow produces artifacts with an origin label and provenance back to the
document. Every box has at least one independent check.

The project distinguishes authorship of this laboratory from derivation of
compiler artifacts. A frontier model may help the user and the project author
choose the architecture, write schemas, or review a design. That dialogue does
not make the compiler output model-generated. The origin of an artifact records
the derivation step that produced it. Structural source generation and wiring
are `MECHANICAL`. A model or solver may produce a small local `ImplIR` hole
when the deterministic paths cannot close it.

The governing invariant is:

> A small piece may be synthesized, but composition is deterministic. The LLM
> never owns the architecture.

### Two kinds of generation

**Local generation** produces one typed constructive fragment for a named
unresolved rule. The fragment has an input contract, an output contract, rule
provenance, and an independent verification obligation. It does not choose a
module, a caller, a pass order, or a registration mechanism.

**Structural generation** consumes StandardIR metadata, AST and MIR schemas,
runtime and ABI specifications, target descriptions, and accepted local
fragments. It emits the source tree, module boundaries, `USE` dependencies,
procedure declarations, dispatch, rule ordering, fact dependencies,
registration and generated APIs. The same inputs and generator revision produce
the same canonical source tree.

The first structural implementation may use generic engines and generated rule
tables. A later specializer may fuse rules, remove table lookups, and emit
direct calls. These are two implementations of the same generated composition,
not two sources of architectural truth.

---

## 3. StandardIR

Answers *what the language means*. Declarative, small, and provenance-carrying.
Not implementation code.

Every entry cites `document`, `clause`, `rule`, `page`, `source_hash`. An entry
that cannot cite the document is not a formalization of it.

Four record categories, and a fifth only when a real clause forces one:

**Syntax**: a production, in a normalized form of the standard's own notation.

```
syntax R501 program
    repeat program_unit min=1
end
```

**Constraint**: a numbered restriction that the grammar cannot express.

```
constraint C851
    on dummy_argument
    when has_attribute(value)
    require not has_attribute(pointer)
end
```

**Semantic effect**: what a construct does, as preconditions and effects.

```
semantic allocation
    on allocation_stmt
    require not allocated(object)
    effect
        allocate(object, requested_shape)
    end
end
```

**Definition**: a named set or table the standard establishes.

```
definition numeric_type
    integer
    real
    complex
end
```

A **profile** is not a second grammar. It is a set of rule IDs plus a computed
dependency closure, so Core 0, Core 1 and full F2023 are selections over one
corpus rather than parallel artifacts that can drift apart.

StandardIR also carries the information needed to schedule generated work. A
semantic rule may declare its subject, the facts it requires, the facts it
provides, and the source construct to which it applies. A phase label can be a
derived presentation detail. The dependency graph is authoritative:

```
parse node → scope creation → name resolution → type resolution → rank facts
                                                               ↓
                                                     applicable constraints
```

The graph generator topologically schedules facts and checks. It can emit one
procedure per rule, a generated rule table, or fused procedures. The choice is a
performance option and never changes the StandardIR record.

### Generated syntax projections

The syntax objects have one canonical structural form. Export formats are
derived views for interoperability and comparison:

```
StandardIR syntax
        ↓
canonical grammar projection
        ├── EBNF or BNF documentation
        ├── ANTLR4 .g4
        ├── Bison .y
        ├── tree-sitter grammar where useful
        └── the specialized parser-generator input
```

Every exported production carries its StandardIR rule number, source document,
source hash and generator revision. The exports describe syntax. Constraints,
relations and semantic effects remain separate StandardIR inputs to the
semantic engine.

The raw syntax projections are not assumed to be complete parser grammars. J3/24-007
explicitly limits its syntax rules, and E0021 records the resulting validator
failure for unresolved lexical and name classes. The specialized parser input is
therefore a composite projection of syntax, lexical/token definitions,
constraints, prose restrictions, profile closure and reference-resolution
states. It is the composite input, not an isolated export, that must be accepted
by a target parser generator (D0018).

The four comparison corpora remain comparison sources. The old `standard`
`.g4` corpus and kaby76 can be compared structurally where their formats allow
it. LFortran and Flang are compared through permitted grammar artifacts where
they expose them, and through parser behavior. gfortran is a GPL behavioral
oracle only. Its source is not read or imported into an export. A comparison
adapter records whether each result is structural or behavioral. The export
suite is therefore the common representation for independent parser
implementations without pretending that every oracle has the same internal
parser format.

Each rule also carries a resolution state: `resolved`, `unresolved`, or
`disputed` with the disagreeing formalizations attached. An unresolved rule
means the compiler declines to claim support for the feature. That is a
supported outcome, not a failure to be papered over.

---

## 4. ImplIR

Answers *how the compiler locally implements this rule*. Constructive, tiny, and
aimed at generators and small models rather than at people.

**Residual, not mandatory.** Most StandardIR constraints compile straight to a
checker, and specialization covers more. ImplIR handles what neither reaches.
The fraction of rules that need it is a headline metric and should fall over
time. See `docs/self-hosting.md` and D0007.

Types: `bool`, `int`, `status`, `node`, `symbol`, `type`, `scope`, `name`,
`list<T>`, `optional<T>`. No `string` and no `value` (D0011, D0012).

Statements: `let`, `set`, `if`/`else`, `for ... in`, `return`.

Expressions: canonical names only, one spelling each: `not`, `and`, `or`, `eq`,
`ne`, `lt`, `le`, `gt`, `ge`, `add`, `sub`, `mul`, `list_size`, `list_get`.

Builtins, v0: `sym_lookup`, `sym_exists`, `sym_type`, `sym_rank`, `sym_kind`,
`sym_is_allocatable`, `sym_is_pointer`, `sym_is_parameter`, `type_equal`,
`type_is_numeric`, `node_kind`, `node_child`, `node_symbol`, `node_type`,
`diag`. MIR construction primitives arrive with `ffc-new`.

The constraint that gives ImplIR its value is that it stays small enough for its
whole grammar and semantics to fit in a prompt. Every addition is measured
against that. If ImplIR needs a page of documentation, the hypothesis it was
built to test has already been abandoned.

An accepted ImplIR fragment is a local implementation artifact. The structural
generator decides where it is emitted, which facts it receives, which checks
precede it, and which callers use it. A fragment cannot introduce a new
compiler-wide module or dispatch convention.

Emitters: Fortran is the product. C and Rust emitters exist as controls for E8,
so the same algorithm can be compared across languages without measuring model
familiarity with those languages.

---

## 5. The frontend semantic contract

The single largest departure from the existing toolchain. The frontend exposes
resolved semantic facts by construction, generated from StandardIR, rather than
accumulating queries as consumers discover they need them.

Per entity and per reference, at minimum: resolved symbol, resolved procedure
and the generic candidate chosen, actual-to-dummy mapping, type, kind, rank,
shape, bounds, intent, optionality, allocatable, pointer, target, dynamic type,
SELECT TYPE and SELECT RANK narrowing in each arm, allocation source and mold,
ownership and lifetime, component path, procedure-pointer target, source range,
and the StandardIR rule that justifies each of these.

The design rule: **no consumer may need to answer a semantic question by
inspecting source text or re-deriving a fact.** `LESSONS.md` §2 is the record of
what the alternative costs: a 9,960-line query module grown one request at a
time, and a downstream tool running on source-text heuristics until the facts
arrived.

Completeness is testable rather than aspirational: for each StandardIR semantic
rule, the contract must expose the facts that rule's implementation reads. A
rule whose implementation needs a fact the contract does not expose is a gap in
the contract, detected mechanically.

---

## 6. AST and MIR, and nothing between

Two representations. The AST carries source-level semantics and provenance, and
must support diagnostics, formatting, refactoring, analysis, source-to-source
transformation and language-server queries. MIR is one typed executable
representation: constants, locals, load, store, integer, real and logical
operations, calls, returns, branches, loops, array addressing, allocation and
deallocation.

Operations are added when a requirement justifies them, and the justification is
recorded. The failure mode being avoided is a tower of representations each
added to make one pass convenient.

Libraries: `libfront`, `libmiddle`, `libback`, `libemit`. A static analyzer, a
language server, a formatter, a source-to-source translator and a native
compiler are then compositions of the same components rather than separate
implementations of Fortran semantics.

---

## 7. Physical representations

The lesson from `LESSONS.md` §4, stated as a design rule.

Semantic types and physical representations are specified separately, as
LFortran already does. The addition is that **the lowering between them is
generated**. The acceptance test is concrete and should be checked whenever a
representation is added:

> Adding a physical representation is one specification change, with no edits to
> any consumer.

If adding a representation requires touching the frontend and then the backend,
the architecture has reproduced the problem it was built to avoid, and the
generated lowering is not actually generated.

---

## 8. Backend

`fortback-new` treats an instruction set as a specification to be consumed, not
transcribed. Sources, in descending order of quality:

| ISA | Encodings | Semantics | Oracles |
|---|---|---|---|
| RISC-V | `riscv-opcodes`, machine-readable | Sail model, official and executable | Spike, QEMU, Sail |
| AArch64 | ARM Machine Readable Architecture XML | ASL, official | QEMU, hardware |
| x86-64 | Intel XED data files, Zydis tables | none authoritative | hardware, LLVM |

Order of work: RISC-V and AArch64 together, x86-64 last. This inverts the usual
priority because the cost of a generated backend tracks specification quality
rather than market share, and doing two at once demonstrates that the target
description generalizes rather than fitting one architecture. E11 measures the
difference.

Generated from the target description: instruction tables, encoder, decoder,
register and latency metadata, and the object writer. Synthesized and verified:
instruction selection patterns. Validated per compilation where the semantics
permit: symbolic equivalence between MIR and emitted machine code, which is
achievable against Sail and not against anything available for x86-64.

LLVM stays available as a differential oracle and performance baseline, off the
production path. `liric` is prior art demonstrating that a native backend of this
class is tractable. Being hand-written, it is also the thing this repository
exists to avoid depending on.

---

## 9. Correctness and performance are separate

The specification determines correctness. The generator searches for speed.
Candidate axes: parser strategy, symbol-table representation, AST layout as
array-of-structures or structure-of-arrays, arena strategy, modular versus fused
semantic evaluation. All candidates implement the same semantics and are
verified identically, and selection is by benchmark on real corpora.

Pass fusion falls out of this. The specification stays modular, one constraint
per rule, while generation is free to discover that the checks execute in one
traversal. Modular specification need not imply fragmented execution.

---

## 10. Verification layers

No single mechanism is trusted.

1. **Structural**. generated artifacts parse and typecheck.
2. **Constraint**. implementations satisfy the StandardIR rules they claim.
3. **Mechanical tests**. per rule: minimal valid witness, minimal invalid
   neighbour, boundaries, each alternative, dependency combinations.
4. **Mutation**. the suite must distinguish a correct implementation from a
   nearly correct one, or it is incomplete regardless of size.
5. **Differential**. gfortran, Flang, LFortran, FortFront and FFC over accept
   and reject decisions, diagnostics, runtime behaviour and round-trips.
   Differences produce minimized reproducers. None of them is normative.
6. **Translation validation**. symbolic equivalence between MIR and machine
   code, where the ISA has a formal model.
7. **Negative controls**. every gate has a test proving the gate can fail.

`LESSONS.md` §6 is the argument for layer 7 and it is not hypothetical.

---

## 11. The trusted base

Never generated, trusted as given: hardware and the correctness of the ISA
specification itself, the operating system and C library, the bootstrap compiler,
C libraries bound through `ISO_C_BINDING`, principally `poppler`, and the
verification tools including any solver.

The claim the architecture supports is narrower than "verified compiler" and
worth stating precisely: **no layer is a hand-written transcription of a
specification that exists elsewhere in machine-readable form.**

---

## 12. Implementation language

Fortran, everywhere it is conceivable. C libraries are reached through
`ISO_C_BINDING`. The escape hatch is quantitative rather than aesthetic: a
component may be someone else's C library when writing it would require on the
order of a hundred thousand lines. PDF rendering qualifies. PDF text extraction
does not, once `poppler` is bound. That is why `standard-new` starts with
`fortpdf` rather than a Python script.

The build driver is `fo` throughout, per `~/code/prompts/rules/fortran.md`.
