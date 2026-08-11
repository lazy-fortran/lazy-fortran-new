# Roadmap

Snapshot: 2026-08-12. Baseline: `lazy-fortran-new` at `176f16d`, CI green;
`standard-new` at `7abd7b1`, with layout, canonical-text, production-line and
StandardIR extraction, CI green.

Live status belongs to each repository. This file records cross-repository
order, the steps in each phase, and the gate that ends it, so that facts are
not copied into several places and left to rot. Any count appearing here names
the command that regenerates it.

A checked box means the thing exists and was observed working, not that someone
intended it. A phase ends when its gate is demonstrated by a named artifact.

## Current position

**Phase 0 complete.** Phase 1 is in progress. `standard-new` now extracts
UTF-8 bytes and text rectangles for every page of the pinned PDF, writes a
canonical geometric text projection, and mechanically projects the
R-numbered syntax span on pages 67--580. The E0004 check scripts report 494
production starts and 1,048 production lines in JSONL, followed by 494
provenance-bearing StandardIR SX objects and a byte-identical round-trip
(`research/experiments/E0004-broad-syntax-extraction/check-productions.sh` and
`check-standardir.sh`). The reverse normalizer reconstructs 494 normalized
production records from SX, checked by
`research/experiments/E0004-broad-syntax-extraction/check-normalized.sh`.
The generated grammar and semantic rules do not exist yet. E0001 and E0004
are running, while E0002--E0003 remain draft experiments. E0012 remains a
later Phase 2 experiment.

---

## Phase 0. Laboratory

- [x] Meta-repository created, public, MIT
- [x] `AGENTS.md` with `CLAUDE.md` symlinked, house-style deltas only
- [x] `WHITEPAPER.md`, `DESIGN.md`, `LESSONS.md`, `RESEARCH.md`, `README.md`
- [x] `docs/`: literature, provenance, glossary, self-hosting,
      text-representation
- [x] Historical evidence mined at commit level, with counter-evidence, all 84
      cited hashes verified resolvable
- [x] `repos.toml` and the bootstrap/status/update/fetch/experiment/index
      scripts
- [x] J3/24-007 pinned by URL and SHA-256, never vendored (D0002)
- [x] Fetch verifier proven able to fail on a corrupted hash, and to accept a
      matching one
- [x] `scripts/selftest.sh` with eight gates, run in CI
- [x] `standard-new` scaffolded: fpm project, `fortpdf` over poppler-glib,
      `pdfinfo`
- [x] `fortpdf` test suite with fixtures of known page count, proven able to
      fail
- [x] Page count agreed by three independent readers: `fortpdf`, an independent
      Go extractor, and a raw `/Type/Page` count
- [x] Text-representation policy with a mechanical gate and its negative
      control (D0011)
- [x] Decision records D0001–D0012, append-only lifecycle, generated index
- [x] CI green on both repositories

**Gate: met.** `scripts/fetch.sh j3-24-007` verifies and fails loudly on a
corrupted hash; `scripts/status.sh` reports every repository in `repos.toml`;
`standard-new` builds and reports a page count cross-checked against an
independent extractor.

---

## Phase 1. `standard-new`: document to StandardIR

The first scientific result, and the reason this phase precedes any compiler
work. Ordering follows `docs/self-hosting.md` §19: the seed and the schema
machinery come before extraction, because extraction output must land in
canonical form.

### Startup contract and thin slice

These prerequisites freeze what Phase 1 will measure and provide one small
path through the whole proposed boundary. They must be completed before broad
extraction or semantic formalization.

- [ ] E0001, E0002 and E0003 manifests define their denominator, exclusions,
      independent oracle, pinned commits, toolchain record and analysis command
- [ ] `bootstrap-core` and `core0-v1` are represented as exact StandardIR rule
      selections with computed dependency closure
- [ ] A minimal Phase 1 corpus is pinned, including representative clause-5
      pages, hand-checked canonical SX fixtures and malformed SX inputs
- [ ] One vertical slice works: PDF page → canonical text → one production
      with a continuation line → StandardIR → SX → generated Fortran → seed and
      independent validation
- [ ] The slice records source, artifact hashes, origin labels and the tool and
      oracle versions needed to reproduce it

**Startup gate.** The slice passes against fixed expected bytes and structured
results, and its run record reports extraction completeness, parse failures,
provenance coverage and independent-oracle agreement. A round-trip that only
compares two implementations of the same behavior is insufficient.

### 1.0 Extraction risk probe

Runs first and in parallel with 1.1, because it can invalidate the shape of the
whole phase.

- [x] Extend `fortpdf` with `poppler_page_get_text_layout`: glyphs plus
      rectangles
- [x] Dump glyphs and geometry for the clause-5 syntax pages of 24-007
- [x] Determine whether `R501` and its right-hand side, including continuation
      lines, are reconstructable from geometry alone
- [x] Exercise at least one additional production shape and one held-out page
      layout before declaring the geometry probe positive
- [x] Record the finding as a run, whichever way it goes
- [ ] If negative: decision record naming the fallback (OCR, alternative
      library, J3 sources) before any further extraction work

The first complete document layout dump is `R000001`; regenerate it with
`(cd ../standard-new && fo exec pdfextract ../lazy-fortran-new/.cache/j3-24-007.pdf ../lazy-fortran-new/.cache/runs/E0001/R000001/j3-24-007.layout)`.
The geometry probe is `R000002`; regenerate it with
`research/experiments/E0001-standard-to-grammar/probe-layout.sh`.
The canonical text is `R000003`; regenerate it with
`(cd ../standard-new && fo exec pdfcanonical ../lazy-fortran-new/.cache/j3-24-007.pdf ../lazy-fortran-new/.cache/runs/E0001/R000003/j3-24-007.canonical.txt ../lazy-fortran-new/.cache/runs/E0001/R000003/j3-24-007.pages.index)`.
The version-2 layout dump is `R000004`; regenerate it with the `R000001`
command, changing the run directory to `R000004`.
The first production-line slice is `R000005`; regenerate and check it with
`research/experiments/E0001-standard-to-grammar/check-productions.sh`.
The first StandardIR SX slice is `R000006`; regenerate and check it with
`research/experiments/E0001-standard-to-grammar/check-standardir.sh`.
The SX round-trip is `R000007`; regenerate and check it with
`research/experiments/E0001-standard-to-grammar/check-sx-roundtrip.sh`.
The broad syntax-line corpus is `E0004/R000002`; regenerate and check it with
`research/experiments/E0004-broad-syntax-extraction/check-productions.sh`.
The broad StandardIR projection and its SX round-trip are `E0004/R000003` and
`E0004/R000004`; regenerate and check them with
`research/experiments/E0004-broad-syntax-extraction/check-standardir.sh`.
The normalized production projection is `E0004/R000005`; regenerate and check
it with `research/experiments/E0004-broad-syntax-extraction/check-normalized.sh`.
The raw text has missing inter-word spaces where rectangle gaps carry the
separation, so the canonicalizer preserves the Poppler bytes and derives a
normalized view rather than overwriting the source extraction.

### 1.1 The `text/` package (D0011)

- [ ] `byte_buffer`, `byte_span`
- [ ] `byte_builder` with geometric growth
- [ ] `writer_t` with file, memory, hash and counting backends
- [ ] `interner` with case-insensitive Fortran identity resolved once
- [ ] `utf8_boundary`
- [ ] Property tests plus fixed byte-level fixtures, and each one observed
      failing against a broken variant

### 1.2 SX seed reader and writer (D0006, D0009)

- [ ] Seed reader in Bootstrap Core over the arena node type
- [x] Canonical writer: one spelling per operation, normalized fields
- [ ] Round-trip properties: `parse(write(t)) = t`, `write(parse(c)) = c`
- [ ] Independent canonical SX fixtures and malformed-input expectations
- [ ] Fuzzed trees and a malformed-input corpus
- [ ] Content hashing: parse → validate → normalize → serialize → SHA-256

### 1.3 Schema language and generator

The first place the project generates rather than writes, so the first real
evidence for the thesis.

- [ ] `.sxs` schema language: primitive, record, sum, list, optional, enum
- [ ] Generator emitting Fortran types, reader, writer, validator, visitor,
      equality, hashing, printer
- [ ] StandardIR schema
- [ ] ImplIR schema, eight types and two constructors (D0012)
- [ ] Generated code compiles clean and round-trips
- [ ] Generated readers and writers agree with the seed and the fixed SX
      fixtures, not only with each other
- [ ] Origin label `MECHANICAL` recorded for every generated artifact

### 1.4 Extraction to canonical text

- [x] Layout-aware extraction from 24-007 into a canonical UTF-8 artifact
- [x] Artifact hashed and pinned; spans reference it, prose never duplicated
      into StandardIR (D0011 §6)
- [x] Differential check of the text layer against an independent extractor,
      with disagreements recorded rather than smoothed over
- [ ] Completeness, parse failure, provenance failure and skipped-page counts
      are reported against a predeclared page and production denominator
- [ ] BOM, ligature, hyphenation and column-order handling decided and tested

### 1.5 Syntax extraction

- [x] Recognize R-numbered productions in the canonical text
- [x] Parse the standard's own grammar notation
- [x] Emit StandardIR syntax objects with full provenance: document, clause,
      rule, page, span hash
- [x] Count eligible productions before extraction and report extracted,
      rejected, ambiguous and skipped productions separately
- [x] Round-trip: production → StandardIR → normalized production, compared
      structurally
- [ ] Report the fraction extracted with zero model calls (**E1**)

### 1.6 Comparison and adjudication (D0005, D0013)

- [ ] Generate a syntax grammar from StandardIR
- [ ] Compare against four external corpora: the `standard` `.g4` corpus,
      kaby76, LFortran and Flang
- [ ] Adjudicate every disagreement against 24-007
- [ ] Classify each: ours wrong, theirs wrong, document ambiguous
- [ ] Publish the defect rate per comparison corpus, with the denominator and
      the document-ambiguous bucket

### 1.7 Semantic formalization

- [ ] StandardIR constraints, definitions, relations and rules over Core 0
      clauses
- [ ] Mechanical formalization patterns first
- [ ] Small-model then larger-model escalation on the residue, one run record
      per attempt including failures
- [ ] `unresolved` and `disputed` states exercised on real clauses, not just
      supported in principle
- [ ] Acceptance rule enforced: independent formalizations normalize to the
      same form and witnesses agree with at least two oracles
- [ ] Count eligible Core 0 rules before formalization and report resolved,
      unresolved, disputed and skipped rules separately
- [ ] Report the mechanical fraction and the minimum model size per rule
      (**E2**, **E3**)

### 1.8 Tests and dependencies

- [ ] Generate test families per rule: minimal valid witness, minimal invalid
      neighbour, boundaries, each alternative, dependency combinations
- [ ] Mutation testing over the generated checkers
- [ ] Rule dependency graph, and profile closure computed from it

### Phase 1 experiments

- [x] E0001 (E1) manifest written and metrics named **before** extraction starts
- [x] E0002 (E2) manifest likewise
- [x] E0003 (E3) manifest likewise
- [x] E0004 broad syntax extraction manifest, denominator and oracle recorded
- [x] `scripts/index.sh` reports all declared experiments from run records

**Gate.** E0001--E0003 report, from run records rather than by hand: complete
syntax coverage and the fraction extracted with zero model calls, complete
semantic coverage and the fraction formalized mechanically, the minimum model
size per remaining rule, and the four-corpus disagreement rates with
adjudications.

---

## Phase 2. `fortfront-new`: generated frontend

- [ ] Repository created, `AGENTS.md` + symlink, CI, text gate
- [ ] Generate the lexer from the lexical specification
- [ ] Generate at least two parser strategies from StandardIR syntax
- [ ] Benchmark them on a pinned corpus; keep the fastest correct one
- [ ] Generate the AST schema
- [ ] Generate semantic checks by direct specialization where possible (D0007)
- [ ] ImplIR v0: type checker, normalizer, interpreter, Fortran emitter
- [ ] Differential test: ImplIR interpreter against emitted-and-compiled
      Fortran
- [ ] First small-model synthesis runs on the residue (**E4**)
- [ ] Record the fraction of rules needing ImplIR, the headline trend metric
- [ ] Expose the semantic contract of `DESIGN.md` §5 by construction
- [ ] Contract-completeness check: every rule's implementation reads only facts
      the contract exposes
- [ ] Standard-Fortran emitter, streaming (D0011 §9)
- [ ] Regenerate the SX parser from a StandardIR description of SX
- [ ] Differential-test generated reader against the seed over the whole corpus
- [ ] **E12**: scope-graph resolution against Fortran modules, host
      association, USE renaming and only-lists, interfaces, generic resolution
- [ ] E12 go/no-go recorded; if no-go, decision record for the Fortran-specific
      resolver
- [ ] Parsing throughput measured against FortFront, LFortran and Flang
      (**E5**, **E6**)

**Gate.** The contract-completeness check passes, parsing throughput is
measured against at least two established frontends on a pinned corpus, and the
generated SX reader agrees with the seed on the whole corpus.

---

## Phase 3. Modern Fortran Core 0

- [ ] Core 0 defined as a rule-ID selection with computed dependency closure
- [ ] Bootstrap Core defined the same way, as a strict subset (D0008)
- [ ] Rules implemented for programs, modules, procedures, arrays,
      allocatables, control flow
- [ ] Rule-coverage report generated from run records
- [ ] Accept/reject corpus baseline committed, so no change silently narrows
      the language (imported from `fortfront`'s rejection gate)
- [ ] Skipped cases reported separately from passed ones, both rates published

**Gate.** Core 0 accepts and correctly analyses a pinned corpus of small
programs, with coverage generated rather than typed.

---

## Phase 4. `ffc-new`: MIR and driver

- [ ] Repository created, `AGENTS.md` + symlink, CI, text gate
- [ ] One MIR, operations added only with a recorded justification
- [ ] Lowering from the typed frontend representation
- [ ] Rank and type specialization generated from specification
- [ ] **Acceptance test for the generated-lowering claim**: add a rank, observe
      that no consumer needed an edit (`LESSONS.md` §4)
- [ ] Simple optimizations
- [ ] Performance search over representations: symbol table, AST layout, arena
      strategy (**E9**)
- [ ] Command-line driver
- [ ] LLVM path as differential oracle and performance baseline only
- [ ] **First self-host milestone**: the new compiler compiles the meta-tools —
      SX reader, StandardIR engine, ImplIR checker, generators (D0010)
- [ ] Bootstrap Core sufficiency reported; growth recorded as an E10 result,
      not treated as a failure

**Gate.** Generated programs run correctly on a pinned corpus, with rank
specialization generated rather than written and demonstrated by the
add-a-rank test.

---

## Phase 5. `fortback-new`: generated backend

- [ ] Repository created, `AGENTS.md` + symlink, CI, text gate
- [ ] Target description language, derived from the ISA specifications rather
      than transcribed
- [ ] RISC-V: `riscv-opcodes` pinned by hash; generated instruction tables,
      encoder, decoder
- [ ] AArch64: ARM Machine Readable Architecture pinned; the same generated
      from it
- [ ] Object writers: ELF, then Mach-O
- [ ] Instruction selection synthesized, not written (**E11**)
- [ ] Translation validation against the Sail model where the semantics permit
- [ ] Behavioural oracles wired: Spike, QEMU, hardware where available
- [ ] Differential execution against LLVM output on a pinned corpus
- [ ] E11 reports the cost difference between two well-specified ISAs

**Gate.** A generated program compiles to native code on both ISAs and passes
differential execution against LLVM output.

---

## Phase 6. Self-hosting

- [ ] Core 0 expanded until the compiler is expressible entirely within it
- [ ] gfortran builds compiler-0
- [ ] compiler-0 builds compiler-1
- [ ] compiler-1 builds compiler-2, from identical generated source and
      configuration
- [ ] Canonical generated compiler source from stages 1 and 2 compared
- [ ] Object and binary identity attempted under reproducible build conditions
- [ ] **E10**: the smallest Fortran profile sufficient to implement its own
      compiler, reported
- [ ] Meta-language fixpoint procedure exercised on a real breaking change to
      StandardIR or ImplIR (D0010)

**Gate.** The canonical generated compiler source from stages 1 and 2 is
identical. Stage equality establishes reproducibility, not trusting trust;
diverse double compilation is named as future work in `docs/self-hosting.md`
§21 and is not planned.

---

## Phase 7. x86-64

Deliberately last: no official machine-readable encoding specification, no
authoritative semantics, translation validation impractical.

- [ ] Intel XED data files and Zydis tables pinned by hash
- [ ] Encodings generated from them; disagreements between the two adjudicated
- [ ] uops.info pinned for latency and throughput cost modelling
- [ ] Instruction selection synthesized
- [ ] Differential execution against LLVM and against hardware
- [ ] E11 gains its third data point, and the specification-quality hypothesis
      is confirmed or refuted

---

## Phase 8. Broader Fortran

- [ ] Core 1 profile
- [ ] Core 2 profile
- [ ] Broad F2023 coverage
- [ ] Second document: J3/26-007 extracted through the same pipeline, measuring
      the diff cost between revisions
- [ ] Legacy features as a separate optional profile, never in Core

---

## Phase 9. Downstream tools

- [ ] FortAD on the generated frontend, consuming facts rather than
      reconstructing them (`LESSONS.md` §2)
- [ ] Static analysis
- [ ] Formatter, using the lossless-edit mode (D0011 §10)
- [ ] Language server
- [ ] Source-to-source extensions and automatic modernization
- [ ] Lazy Fortran extensions as layered specifications over ISO StandardIR

**Gate.** No downstream tool implements Fortran semantics independently.

---

## Continuous, not a phase

These run alongside everything and have no completion box, but they can be
neglected, so they are listed.

- [ ] `docs/literature.md`: verify the ~30 citations recorded from memory;
      three are checked. **Read Lämmel & Verhoef before E1's related work** —
      E1 automates the loop that paper describes semi-automatically, and the
      framing of the first result depends on getting that relationship right
- [ ] Prose passes: `LESSONS.md`, `DESIGN.md`, `README.md`, `AGENTS.md` and the
      two new design notes have not had an adversarial pass; only
      `WHITEPAPER.md` has
- [ ] `docs/provenance.md` consultation log kept current as permissive sources
      are read
- [ ] Every new gate ships with a negative control
- [ ] Every published number names the command that regenerates it

---

## Ordering constraints

- Phase 1.0 runs before 1.4 and can invalidate the phase. Nothing downstream of
  extraction is built until the probe answers.
- Phases 1.1 to 1.3 are independent of the standard and can proceed in parallel
  with the probe.
- Phase 2 does not start before E0001--E0003 report. The measurement is the
  point of Phase 1, and building the frontend first consumes the evidence.
- Phase 5 does not start before Phase 4 has a stable MIR, or the target
  description is shaped by a moving interface.
- Phase 6 gates on Core 0 sufficiency, discovered during Phases 3 to 5, and may
  force Core 0 to grow. That growth is the E10 result, not a scheduling
  failure.
- x86-64 is not brought forward for convenience. If native development hardware
  becomes a real obstacle, that is a decision record, not a quiet reordering.
- A repository is created when its phase starts, not before. No `fortgen-new`
  on speculation (`docs/self-hosting.md` §22).

## Deliberately deferred

Coarrays, parameterized derived types, full polymorphic object orientation,
fixed form, and every legacy storage feature listed in `WHITEPAPER.md` §15.
GPU targets. Certified parsing and diverse double compilation, named as future
work in `docs/self-hosting.md` §21. Anything requiring a service, a database or
a dashboard.
