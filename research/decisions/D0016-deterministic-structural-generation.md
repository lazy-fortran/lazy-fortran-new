# D0016. Deterministic structural generation and local synthesis holes

Date: 2026-08-12
Status: accepted

## Context

The design already separates mechanical StandardIR derivation from residual
ImplIR synthesis, but that wording does not by itself prevent an implementation
from asking a model to create modules, choose callers or maintain pass order.
That would make the architecture part of an opaque generation result. It would
also make the phrase "no LLM" ambiguous. The project needs to distinguish a
model helping a person design the laboratory from a model participating in the
derivation of a compiler artifact.

The syntax projection also needs an explicit status. ANTLR, Bison, tree-sitter
and canonical grammar files are useful comparison and interoperability outputs,
but they must not become a second maintained source of semantics.

## Decision

1. Separate local generation from structural generation. Local generation fills
   one named, typed ImplIR hole. Structural generation composes the compiler.

2. Name the composition component the **wiring generator**. For fixed inputs and
   a fixed generator revision, it deterministically owns the generated source
   tree, module boundaries, `USE` dependencies, declarations, dispatch,
   registration, fact scheduling, public APIs and source grouping.

3. A solver or LLM may propose a local implementation fragment. The accepted
   fragment has a contract, provenance and an independent verification
   obligation. It cannot choose its module, callers, preconditions, ordering,
   registration or compiler-wide dispatch convention.

4. StandardIR metadata records applicability, required facts and provided facts
   for semantic rules. The wiring generator derives a dependency graph and
   topological schedule from those records. A phase name is a derived view
   unless the standard itself requires it.

5. The first executable composition may use generic engines and generated rule
   tables. A later specializer may fuse the same verified composition into direct
   procedures and remove runtime lookup. Neither optimization creates a second
   architectural source of truth.

6. StandardIR syntax generates canonical EBNF or BNF, ANTLR4 `.g4`, Bison `.y`,
   tree-sitter input where useful and specialized parser-generator input. These
   exports carry rule numbers, source provenance, source hashes and generator
   revisions. They are syntax projections for interoperability and comparison,
   not normative semantic sources.

7. The comparison boundary follows the licence boundary. Permitted grammar
   artifacts from the old `standard` corpus, kaby76, LFortran and Flang may be
   normalized and compared where they are exposed. LFortran and Flang behavior
   may also be compared. gfortran is a GPL behavioral oracle only. Its
   implementation source is not read or imported. Comparison adapters label
   each result as structural or behavioral, so an oracle need not expose the
   same parser format for its result to be comparable.

8. A generation gate that says "no LLM" means that no model call participates
   in deriving that artifact. It does not prohibit frontier-model dialogue used
   by a human to develop the meta-architecture, schemas or generator.

## Rejected

**Model-generated wiring.** A model that chooses modules, dispatch or call
order owns architecture implicitly and makes reproducibility and auditing
weaker.

**A separately maintained GrammarIR.** The canonical syntax projection is an
internal view of StandardIR syntax. A second maintained grammar source would
reintroduce drift.

**Semantic actions embedded in ANTLR or Bison exports.** Export formats describe
syntax. Semantic constraints and relations stay in StandardIR and the generated
semantic engine.

**Treating a parser export as compliance.** Syntax acceptance does not establish
constraint or semantic conformance.

## Reversal condition

Write a successor decision if a concrete architecture cannot be expressed by
the wiring generator after the schemas, fact graph, runtime contracts and
profile metadata are specified, or if deterministic composition fails its
fixed-input source-stability gate. Reconsider the export boundary if an
independent parser comparison shows that the syntax projection loses normative
information that cannot be represented in StandardIR. A model may gain a
structural role only after an independent reproducibility and verification
result demonstrates that it does not own architectural choices.
