# Glossary

Terms as this project uses them. Where a word is already overloaded in compiler
work, the entry says which sense is meant.

**Adjudication**: deciding, against the pinned normative document, which of
several disagreeing formalizations is right. Produces one of three verdicts:
ours wrong, theirs wrong, or the document is ambiguous. The verdict is
recorded. The third case is a result about the standard.

**Architecture generator**: the deterministic generator that composes the
complete compiler source tree from StandardIR, schemas, runtime and ABI
specifications, target descriptions, profile metadata and accepted local
fragments. It owns modules, `USE` dependencies, declarations, dispatch,
registration, fact scheduling, generated APIs and source grouping.

**Behavioural comparison**: running an oracle compiler and comparing its
observable output. The only permitted use of GPL-licensed compilers here. See
`docs/provenance.md`.

**Bootstrap Core**: the restricted Fortran profile the meta-tools are written
in, smaller than the user-facing Core 0, so the generated compiler can compile
them early. See D0008.

**Core 0**, the initial Modern Fortran profile. A strict subset of standard
Fortran, so every Core 0 program is a valid standard program. Defined as a set of
StandardIR rule IDs with dependency closure, not as a separate grammar. Its
sizing criterion is that it must eventually suffice to implement the compiler
itself.

**Differential oracle**: an independent implementation used to detect
disagreement, not to define correctness. gfortran, Flang, LFortran, FortFront
and FFC are oracles. None is normative; StandardIR is.

**Generated export**: a non-authoritative projection of StandardIR syntax into
EBNF or BNF, ANTLR4, Bison, tree-sitter or a specialized parser-generator
input. It carries rule provenance and is used for interoperability and
comparison, not as a maintained semantic source.

**ffc-new**, the driver and middle end: typed frontend output to MIR to
optimization, plus the command line. ISA-independent.

**Fixpoint**: the criterion for a self-bootstrapping change: for the compiler,
that stages two and three produce identical canonical source; for a
meta-language change, that the new tool regenerates an equivalent version of
itself. See D0010.

**fortback-new**, the backend: machine-readable target description to generated
encoder, decoder, object writer and instruction selection. ISA-specific.

**fortfront-new**, the generated frontend: lexer, parser, AST, semantic
analysis, typed semantic result, standard-Fortran emitter.

**fortpdf**: the `ISO_C_BINDING` module in `standard-new` that reaches
`poppler` for layout-aware PDF extraction. First code in the project.

**ImplIR**: the tiny procedural language that expresses how a rule is
implemented locally, used only for the residue that cannot be specialized
mechanically from StandardIR (D0007). Its defining constraint is that its
complete grammar and semantics fit in a prompt. An ImplIR fragment is a typed
local hole. It cannot choose its module, callers, ordering or compiler-wide
dispatch. Audience: generators, synthesis systems and small models, not
people. See `DESIGN.md` §4.

**Local hole**: a named, typed constructive task with input facts, output
facts, diagnostics, provenance and an independent verification obligation. A
mechanical template, solver or model may fill it. The structural generator
composes the accepted result.

**Laboratory**: this repository. Holds research, wiring, evidence and papers,
and no compiler code.

**Negative control**: a test whose purpose is to prove that a gate can fail. A
gate never observed failing is not evidence. Imported from `fortfront`'s
`check-duplication-gate`.

**Oracle**: see *differential oracle*. Note that in this project the existing
Lazy Fortran repositories are oracles and historical evidence, never
architectural constraints.

**Origin label**: the mechanism by which an artifact was derived:
`MECHANICAL`, `SEARCH`, `SMT`, `LLM`, `LLM_REPAIR`, `HUMAN`, `IMPORTED`,
`DIFFERENTIAL`. Attached to every generated artifact. It describes the artifact
derivation step, not whether a frontier model helped a person write the
surrounding research or generator design. Without it the project cannot answer
the question it exists to ask.

**Physical representation**: how a value is laid out and passed: descriptor,
pointer to descriptor, fixed-size array, assumed rank, character descriptor and
so on. Distinct from the semantic type. The project's requirement is that the
*lowering between* representations is generated, not merely that the
representations are declared. See `LESSONS.md` §4.

**Production repository**: `standard-new`, `fortfront-new`, `ffc-new`,
`fortback-new`. Deliberately boring: code, specifications, generated output and
tests. No research history.

**Profile**: a selection of StandardIR rule IDs plus dependency closure. Core
0, Core 1 and full F2023 are profiles over one corpus, never parallel artifacts.
Reachability closure and feature eligibility are separate projections. E0014
and D0015 record that distinction.

**Provenance**: for a StandardIR entry: document, clause, rule number, page and
source hash. An entry that cannot cite the document is not a formalization of
it. Distinct from *origin label*, which records how the artifact was produced
rather than what it came from.

**Resolution state**: of a StandardIR rule: `resolved`, `unresolved`, or
`disputed` with the disagreeing formalizations attached. Declining to support an
unresolved feature is a supported outcome, not a defect.

**Run**: one attempt at anything measurable, recorded as a single JSONL line.
Append-only. Corrections are new runs. Failures are kept, because deleting them
destroys the denominator.

**Seed**: the hand-written SX reader in Bootstrap Fortran that the bootstrap
starts from. Later regenerated from a StandardIR description of SX and kept as
the differential oracle for its replacement. See D0009.

**Specialization**: compiling a declarative StandardIR rule into procedural
code, the middle path between interpreting the rule and synthesizing ImplIR for
it. It can also fuse a generated rule table and remove generic dispatch. The
Statix work on specializing scope-resolution queries is the precedent.

**Structural generation**: see *architecture generator*. Composition of
language-specific source is deterministic for fixed inputs and generator
revision. It is distinct from local generation, which fills a typed hole.

**StandardIR**: the declarative representation of what the language means,
derived from the normative document with provenance per entry. Its semantic
rules record applicability and fact dependencies so generated wiring can
schedule them. Not implementation code. See `DESIGN.md` §3.

**Strict rate**: a pass rate whose denominator includes skipped cases. Reported
alongside, never instead of, the evaluated rate. `ffc`'s gfortran-dg row reads
32.4% evaluated and 19.8% strict, and the difference is the whole reason for the
convention.

**SX**: the canonical S-expression serialization shared by StandardIR and
ImplIR. A tree format, not Lisp: no precedence, no macros, no reader
evaluation, no quotation. See D0006.

**Translation validation**: proving that one particular compilation preserved
semantics, rather than proving the compiler always does. Achievable against an
executable ISA model such as Sail; the reason RISC-V comes first.

**Trusted base**: what is never generated and is accepted as given: hardware
and the ISA specification's own correctness, the OS and C library, the bootstrap
compiler, bound C libraries, and the verification tools. Stated explicitly so
the project's claim is not mistaken for a stronger one. See `WHITEPAPER.md` §19.

**Wiring generator**: the structural generator's composition role. It derives
the module graph, procedure declarations, dispatch, registration, fact order,
public APIs and generated source layout from schemas and specifications. A
model-generated local fragment never owns this wiring.
