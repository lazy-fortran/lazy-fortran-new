# Roadmap

Snapshot: 2026-08-11. Baseline: initial commit of this repository.

Live status belongs to each repository. This file records cross-repository order
and the gate that ends each phase, so that facts are not copied into several
places and left to rot. Any count appearing here names the command that
regenerates it.

## Current position

Phase 0, in progress. No extraction pipeline exists. `standard-new` is scaffolded
but implements nothing beyond a PDF page-count smoke test.

## Phase gates

A phase ends when its gate is demonstrated by a named artifact, not when the work
feels finished.

### Phase 0. Laboratory

Establish this repository and the wiring. Record the architecture and the
historical evidence. Scaffold `standard-new`.

**Gate.** `scripts/fetch.sh j3-24-007` verifies the pinned document and fails
loudly against a corrupted hash; `scripts/status.sh` reports every repository in
`repos.toml`; `standard-new` builds under `fo` and reports the page count of a
PDF, cross-checked against an independent extractor.

### Phase 1. `standard-new`: document to StandardIR

The first scientific result, and the reason this phase comes before any compiler
work.

1. Pin J3/24-007 by URL and hash; fetch and verify.
2. Layout-aware extraction through `poppler` from Fortran; canonical text plus
   glyph geometry.
3. Differential check of the text layer against an independent extractor.
4. Mechanical extraction of R-numbered productions; parse the standard's own
   grammar notation.
5. Round-trip: production → StandardIR → normalized production, compared
   structurally.
6. Define minimal StandardIR; generate a syntax grammar from it.
7. Three-way comparison against the `standard` `.g4` corpus, the kaby76 corpus,
   LFortran and Flang; adjudicate every disagreement against the document and
   record the verdict.
8. Formalize the first semantic constraints; compare mechanical, small-model and
   large-model formalization on the same clauses.
9. Generate test families mechanically; build the rule dependency graph.

**Gate.** E1 and E2 report, from run records rather than by hand: the fraction
of syntax extracted with zero model calls, the fraction of semantics formalized
mechanically, the minimum model size per remaining rule, and the three-way
disagreement rate with adjudications.

### Phase 2. `fortfront-new`: generated frontend

Generate lexer, parser and AST schema from StandardIR. Generate semantic checks.
Introduce ImplIR v0 and run the first small-model synthesis experiments. Expose
the semantic contract of `DESIGN.md` §5 by construction. Emit standard Fortran.
Benchmark parsing against FortFront, LFortran and Flang.

**Gate.** The contract-completeness check passes (every StandardIR semantic
rule's implementation reads only facts the contract exposes), and parsing
throughput is measured against at least two established frontends on a pinned
corpus.

### Phase 3. Modern Fortran Core 0

Define Core 0 as a rule-ID selection with dependency closure. Implement enough
rules to handle programs, modules, procedures, arrays, allocatables and control
flow. Generate the rule-coverage report.

**Gate.** Core 0 accepts and correctly analyses a pinned corpus of small
programs, with coverage generated from run records and skipped cases reported
separately from passed ones.

### Phase 4. `ffc-new`: MIR and driver

One MIR. Correct lowering, generated rank and type specialization, simple
optimizations, and performance search over representations.

**Gate.** Generated programs run correctly on a pinned corpus, with rank
specialization generated rather than written, demonstrated by adding a rank and
observing that no consumer needed an edit.

### Phase 5. `fortback-new`: generated backend

Target descriptions for RISC-V and AArch64 from their official machine-readable
specifications. Generated instruction tables, encoder, decoder and object
writer. Synthesized instruction selection. Translation validation against Sail
where available.

**Gate.** A generated program compiles to native code on both ISAs and passes
differential execution against LLVM output; E11 reports the cost difference
between the two ISAs.

### Phase 6. Self-hosting

Expand Core 0 until the compiler can be written entirely within it. Build A with
gfortran, B with A, C with B; require convergence.

**Gate.** B and C are bit-identical.

### Phase 7. x86-64

The hardest target, deliberately last: encodings from Intel XED data files,
semantics from no authoritative source, translation validation impractical. E11
gains its third data point.

### Phase 8. Broader Fortran

Core 1, Core 2, broad F2023, then F2028 as it stabilizes. Legacy remains a
separate optional profile.

### Phase 9. Downstream tools

FortAD, static analysis, formatter, language server, source-to-source extensions
and automatic modernization, all on the same frontend. The goal is that no
downstream tool ever implements Fortran semantics again.

## Ordering constraints

- Phase 2 does not start before E1 and E2 report. The measurement is the point
  of Phase 1, and building the frontend first would consume the evidence.
- Phase 5 does not start before Phase 4 has a stable MIR, or the target
  description will be shaped by a moving interface.
- Phase 6 gates on Core 0 being sufficient, which is discovered during Phases 3
  to 5 and may force Core 0 to grow. That growth is a result worth recording
  (E10), not a scheduling failure.
- x86-64 is not brought forward for convenience. If native development hardware
  becomes a real obstacle, that is a decision record, not a quiet reordering.

## Deliberately deferred

Coarrays, parameterized derived types, full polymorphic object orientation,
fixed form, and every legacy storage feature listed in `WHITEPAPER.md` §15.
GPU targets. Anything requiring a service, a database or a dashboard.
