# Roadmap

Snapshot: 2026-08-12. Live repository state is reported by
`scripts/status.sh`. Experiment manifests pin the exact commits used by each
result. The lab and `standard-new` checkouts are clean and their current
default-branch CI state is reported separately from those immutable pins.

Live status belongs to each repository. This file records cross-repository
order, the steps in each phase, and the gate that ends it, so that facts are
not copied into several places and left to rot. Any count appearing here names
the command that regenerates it.

A checked box means the thing exists and was observed working, not that someone
intended it. A phase ends when its gate is demonstrated by a named artifact.

## Current position

**Phase 0 complete.** Phase 1 is in progress. `standard-new` extracts UTF-8
bytes and text rectangles for every page of the pinned PDF, writes a
canonical geometric text projection, mechanically projects the complete
numbered syntax span on pages 45--580, and computes profile reachability.
E0013 audits pages 1--688 and reports 522 production starts with no scope
difference. Its gate also reports 1,184 production lines, 522
provenance-bearing StandardIR SX objects, a byte-identical round-trip and 522
normalized production records
(`research/experiments/E0013-complete-core-syntax/check-core-syntax.sh`).
E0014 computes 502 unique R-number rules and a 345-rule closure from 17
declared Core 0 roots, retaining 20 repeated IDs and 249 unresolved names.
its independent graph gate is
`research/experiments/E0014-core0-profile/check-core0-closure.sh`.
The dependency result is syntax reachability, not yet semantic Core 0 support.
D0015 records the required profile-projection boundary. E0015 reports a
graph-level eligibility projection with 313 retained rules, 27 pruned edges,
zero non-closed references and 115 unresolved names requiring adjudication
(`research/experiments/E0015-can-core-0-feature-eligibility-prune-exc/analyse.sh`).
E0016 reports a canonical EBNF projection of all 522 complete-core StandardIR
syntax records with exact ordered provenance agreement and zero model calls
(`research/experiments/E0016-does-standardir-syntax-project-mechanica/analyse.sh`).
E0017 reports a combined ANTLR4 projection of the same 522 records with exact
ordered provenance and lhs agreement and zero model calls
(`research/experiments/E0017-does-standardir-syntax-project-mechanica/analyse.sh`).
E0018 reports a Bison projection of the same 522 records with exact ordered
provenance and lhs agreement, 695 deterministic helper productions and zero
model calls
(`research/experiments/E0018-does-standardir-syntax-project-mechanica/analyse.sh`).
E0019 reports a tree-sitter grammar.js projection of the same 522 records with
exact ordered provenance and lhs agreement and zero model calls
(`research/experiments/E0019-does-standardir-syntax-project-mechanica/analyse.sh`).
E0020 records structural inventories for the house `standard` grammar, kaby76,
LFortran and Flang, retaining source-only and StandardIR-only differences. Its
independent traversal reports zero count difference
(`research/experiments/E0020-how-do-the-deterministic-standardir-synt/analyse.sh`).
E0021 normalizes the 20 repeated lhs records into 502 deterministic exported
definitions. Its target-tool validation retains a failure: 181 unresolved
lexical, name-class or other references remain in the selected projection.
J3/24-007 explicitly says its syntax rules are not a complete parser
description, so D0018 makes composite parser input the next boundary.
(`research/experiments/E0021-are-grouped-syntax-exports-consumable/analyse.sh`).
E0022 inventories all 181 unresolved names, their 472 reference occurrences and
346 referring rules, with independent traversal agreement and comparison-source
evidence retained for adjudication
(`research/experiments/E0022-unresolved-reference-audit/analyse.sh`).
E0023 verifies the first `byte_buffer`/`byte_span` text-representation slice,
including fixed-byte behavior, bounds rejection and deep-copy isolation
(`research/experiments/E0023-do-byte-buffers-and-spans-provide-the-fi/analyse.sh`).
E0024 verifies `byte_builder` appends ASCII boundary bytes, spans and newlines
against an independent fixed-byte oracle
(`research/experiments/E0024-does-the-byte-builder-preserve-source-by/analyse.sh`).
E0025 verifies `writer_t` file, memory, hash and counting backends, including
standard SHA-256 vectors
(`research/experiments/E0025-does-writer-t-preserve-bytes-and-provena/analyse.sh`).
E0026 verifies case-insensitive interning, deterministic IDs and rehash
stability with fixed byte-name witnesses
(`research/experiments/E0026-does-the-interner-resolve-fortran-identi/analyse.sh`).
E0027 verifies UTF-8 scalar decoding, byte-boundary queries and malformed
sequence rejection with fixed vectors
(`research/experiments/E0027-does-the-utf-8-boundary-layer-decode-val/analyse.sh`).
E0028 verifies cross-component byte chunking, span subranges, writer counts,
interner identity and UTF-8 properties
(`research/experiments/E0028-do-the-text-primitives-satisfy-cross-com/analyse.sh`).
E0029 verifies independent SX canonical fixtures, parse/write/parse structure
and malformed-input expectations
(`research/experiments/E0029-does-the-sx-seed-preserve-canonical-tree/analyse.sh`).
E0030 verifies SX validation, writer-backed canonical serialization and a fixed
SHA-256 content hash
(`research/experiments/E0030-does-canonical-sx-hashing-remain-stable-/analyse.sh`).
E0031 verifies a flat `int8` arena SX reader against the recursive seed on
canonical bytes and flat-node structure
(`research/experiments/E0031-does-the-flat-sx-arena-reader-agree-with/analyse.sh`).
E0034 extends that differential to 64 generated nested trees and 10 malformed
inputs, including a controlled diagnostic mutation
(`research/experiments/E0034-does-the-flat-sx-arena-reader-agree-with/analyse.sh`).
E0035 validates the first `.sxs` schema slice over all six declaration forms,
the committed source fixture and four malformed inputs
(`research/experiments/E0035-does-the-v0-sx-schema-parser-validate-al/analyse.sh`).
E0036 validates deterministic Fortran type and enum declaration emission,
stable dependency ordering and cyclic-dependency rejection
(`research/experiments/E0036-does-deterministic-schema-generation-emi/analyse.sh`).
E0037 verifies that the schema driver regenerates the checked-in Fortran source
byte-for-byte and that the generated module passes the normal pipeline
(`research/experiments/E0037-does-the-schema-driver-reproduce-the-che/analyse.sh`).
E0038 verifies the approved schema-value contract over six declaration forms,
nine canonical values, three invalid values and byte-stable regenerated source
(`research/experiments/E0038-does-the-approved-schema-value-contract-/analyse.sh`).
E0039 verifies generated typed readers and writers against fixed SX values and
the independent reference codec
(`research/experiments/E0039-do-generated-schema-readers-and-writers-/analyse.sh`).
E0040 verifies generated validators and structural equality against fixed valid,
invalid and mutation cases, with zero lint warnings
(`research/experiments/E0040-do-generated-validators-and-equality-pre/analyse.sh`).
E0041 compares LFortran, Flang and gfortran on ten generated parser-behavior
fixtures. All three agree on accepted versus rejected input
(`research/experiments/E0041-do-lfortran-flang-and-gfortran-agree-on-/analyse.sh`).
E0042 verifies generated canonical printers and SHA-256 hashes against the
independent schema-value codec over five values
(`research/experiments/E0042-do-generated-schema-printers-and-hashes-/analyse.sh`).
E0032 verifies 64 deterministic generated SX trees and 10 fixed malformed
inputs, including a controlled diagnostic mutation
(`research/experiments/E0032-does-the-sx-seed-survive-a-generated-tre/analyse.sh`).
E0033 audits the complete-core extraction denominator: all 688 indexed pages,
the 536-page selected span, 522 production starts, zero parse/JSON/provenance
failures and zero scope difference, with a controlled count mutation
(`research/experiments/E0033-does-the-complete-core-extraction-report/analyse.sh`).
E0004 and E0005 now report their broad and contiguous extraction gates.
Generated semantic rules do not exist yet. E0041 now records the first parser
behavior comparison across LFortran, Flang and gfortran. Broad adjudication
remains open. E0001 remains running, E0002--E0003 remain draft experiments,
and E0012 remains a later Phase 2 experiment.

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
- [x] `scripts/selftest.sh` with nine gates, including decision-ledger
      validation and its negative control, run in CI
- [x] Commit-reference checker and optional pre-commit hook (D0017, validates
      active experiment and artifact pins without rewriting them)
- [x] `standard-new` scaffolded: fpm project, `fortpdf` over poppler-glib,
      `pdfinfo`
- [x] `fortpdf` test suite with fixtures of known page count, proven able to
      fail
- [x] Page count agreed by three independent readers: `fortpdf`, an independent
      Go extractor, and a raw `/Type/Page` count
- [x] Text-representation policy with a mechanical gate and its negative
      control (D0011)
- [x] Decision records D0001-D0012, append-only lifecycle, generated index
- [x] CI green on both repositories

**Gate: met.** `scripts/fetch.sh j3-24-007` verifies and fails loudly on a
corrupted hash. `scripts/status.sh` reports every repository in `repos.toml`.
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

- [x] E0001, E0002 and E0003 manifests define their denominator, exclusions,
      independent oracle, pinned commits, toolchain record and analysis command
- [ ] `bootstrap-core` and `core0-v1` are represented as exact StandardIR rule
      selections with computed dependency closure
- [x] A minimal Phase 1 corpus is pinned, including representative clause-5
      pages, hand-checked canonical SX fixtures and malformed SX inputs
      (`research/corpora/phase1-minimal-v0.toml`)
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

The first complete document layout dump is `R000001`. Regenerate it with
`(cd ../standard-new && fo exec pdfextract ../lazy-fortran-new/.cache/j3-24-007.pdf ../lazy-fortran-new/.cache/runs/E0001/R000001/j3-24-007.layout)`.
The geometry probe is `R000002`. Regenerate it with
`research/experiments/E0001-standard-to-grammar/probe-layout.sh`.
The canonical text is `R000003`. Regenerate it with
`(cd ../standard-new && fo exec pdfcanonical ../lazy-fortran-new/.cache/j3-24-007.pdf ../lazy-fortran-new/.cache/runs/E0001/R000003/j3-24-007.canonical.txt ../lazy-fortran-new/.cache/runs/E0001/R000003/j3-24-007.pages.index)`.
The version-2 layout dump is `R000004`. Regenerate it with the `R000001`
command, changing the run directory to `R000004`.
The first production-line slice is `R000005`. Regenerate and check it with
`research/experiments/E0001-standard-to-grammar/check-productions.sh`.
The first StandardIR SX slice is `R000006`. Regenerate and check it with
`research/experiments/E0001-standard-to-grammar/check-standardir.sh`.
The SX round-trip is `R000007`. Regenerate and check it with
`research/experiments/E0001-standard-to-grammar/check-sx-roundtrip.sh`.
The broad syntax-line corpus is `E0004/R000002`. Regenerate and check it with
`research/experiments/E0004-broad-syntax-extraction/check-productions.sh`.
The broad StandardIR projection and its SX round-trip are `E0004/R000003` and
`E0004/R000004`. Regenerate and check them with
`research/experiments/E0004-broad-syntax-extraction/check-standardir.sh`.
The normalized production projection is `E0004/R000005`. Regenerate and check
it with `research/experiments/E0004-broad-syntax-extraction/check-normalized.sh`.
The contiguous core-syntax corpus is `E0005/R000001` through `R000004`.
regenerate and check all four projections with
`research/experiments/E0005-core-syntax-extraction/check-core-syntax.sh`.
The complete core-syntax scope audit and corpus are `E0013/R000017` through
`R000021`, with the scope artifact at `E0013/R000000`. Regenerate and check
them with
`research/experiments/E0013-complete-core-syntax/check-core-syntax.sh`.
The raw text has missing inter-word spaces where rectangle gaps carry the
separation, so the canonicalizer preserves the Poppler bytes and derives a
normalized view rather than overwriting the source extraction.

### 1.1 The `text/` package (D0011)

- [x] `byte_buffer`, `byte_span` (E0023, regenerate with
      `research/experiments/E0023-do-byte-buffers-and-spans-provide-the-fi/analyse.sh`)
- [x] `byte_builder` with geometric growth (E0024, regenerate with
      `research/experiments/E0024-does-the-byte-builder-preserve-source-by/analyse.sh`)
- [x] `writer_t` with file, memory, hash and counting backends (E0025, regenerate with
      `research/experiments/E0025-does-writer-t-preserve-bytes-and-provena/analyse.sh`)
- [x] `interner` with case-insensitive Fortran identity resolved once (E0026,
      regenerate with
      `research/experiments/E0026-does-the-interner-resolve-fortran-identi/analyse.sh`)
- [x] `utf8_boundary` (E0027, regenerate with
      `research/experiments/E0027-does-the-utf-8-boundary-layer-decode-val/analyse.sh`)
- [x] Property tests plus fixed byte-level fixtures, and each one observed
      failing against a broken variant (E0023-E0028, regenerate with the
      experiment commands recorded in `research/index.md`)

### 1.2 SX seed reader and writer (D0006, D0009)

- [x] Seed reader in Bootstrap Core over the arena node type (parallel oracle
      slice, E0031 and E0034, regenerate with
      `research/experiments/E0034-does-the-flat-sx-arena-reader-agree-with/analyse.sh`)
- [x] Canonical writer: one spelling per operation, normalized fields
- [x] Round-trip properties: `parse(write(t)) = t`, `write(parse(c)) = c`
      (E0029, regenerate with
      `research/experiments/E0029-does-the-sx-seed-preserve-canonical-tree/analyse.sh`)
- [x] Independent canonical SX fixtures and malformed-input expectations
      (E0029, regenerate with
      `research/experiments/E0029-does-the-sx-seed-preserve-canonical-tree/analyse.sh`)
- [x] Fuzzed trees and a malformed-input corpus (E0032, regenerate with
      `research/experiments/E0032-does-the-sx-seed-survive-a-generated-tre/analyse.sh`)
- [x] Content hashing: parse → validate → normalize → serialize → SHA-256
      (E0030, regenerate with
      `research/experiments/E0030-does-canonical-sx-hashing-remain-stable-/analyse.sh`)

### 1.3 Schema language and generator (D0016)

The first place the project generates rather than writes, so the first real
evidence for the thesis.

- [x] `.sxs` schema language parser and validator: primitive, record, sum,
      list, optional, enum (E0035, regenerate with
      `research/experiments/E0035-does-the-v0-sx-schema-parser-validate-al/analyse.sh`)
- [x] First deterministic Fortran type and enum declaration emitter, including
      stable dependency ordering and cycle rejection (E0036, regenerate with
      `research/experiments/E0036-does-deterministic-schema-generation-emi/analyse.sh`)
- [x] Schema driver regenerates the checked-in type layer byte-for-byte and the
      generated module enters the normal build (E0037, regenerate with
      `research/experiments/E0037-does-the-schema-driver-reproduce-the-che/analyse.sh`)
- [x] Generator emitting Fortran types, reader, writer, validator, equality,
      hashing and printer (E0036, E0039, E0040, E0042)
- [ ] Generated visitor with a specified callback and traversal contract
- [x] Generated typed readers and writers agree with fixed SX values and the
      reference codec (E0039, regenerate with
      `research/experiments/E0039-do-generated-schema-readers-and-writers-/analyse.sh`)
- [x] Generated validators and structural equality agree with fixed semantic
      cases and the full pipeline has zero lint warnings (E0040, regenerate
      with
      `research/experiments/E0040-do-generated-validators-and-equality-pre/analyse.sh`)
- [x] Generated canonical printers and SHA-256 hashes agree with the reference
      codec (E0042, regenerate with
      `research/experiments/E0042-do-generated-schema-printers-and-hashes-/analyse.sh`)
- [x] Canonical schema-value encoding for generated APIs (D0021, E0038)
- [ ] StandardIR schema (D0022 amended by D0023, `schema-v0.sxs` is only a
      generator fixture)
- [ ] Initial recursive StandardIR backend uses packed arena IDs and child
      ranges. Hot-path layouts remain generated and benchmark-selected (D0023)
- [ ] ImplIR schema, eight types and two constructors (D0012)
- [ ] Generated code compiles clean and round-trips
- [ ] Generated readers and writers agree with the seed and the fixed SX
      fixtures, not only with each other
- [ ] Origin label `MECHANICAL` recorded for every generated artifact
- [ ] Architecture metadata records applicability, required facts, provided
      facts, runtime and ABI contracts, and generated source grouping
- [ ] Deterministic wiring generator emits modules, `USE` dependencies,
      declarations, dispatch, registration and generated APIs
- [ ] Fixed inputs and generator revision produce a byte-stable source tree

### 1.4 Extraction to canonical text

- [x] Layout-aware extraction from 24-007 into a canonical UTF-8 artifact
- [x] Artifact hashed and pinned. Spans reference it, and prose is never duplicated
      into StandardIR (D0011 §6)
- [x] Differential check of the text layer against an independent extractor,
      with disagreements recorded rather than smoothed over
- [x] Completeness, parse failure, provenance failure and skipped-page counts
      are reported against a predeclared page and production denominator
      (E0033, regenerate with
      `research/experiments/E0033-does-the-complete-core-extraction-report/analyse.sh`)
- [x] BOM, ligature, hyphenation and column-order handling decided (D0020)
- [ ] Edge fixtures exercise the D0020 policy on standalone text and ambiguous
      page layouts

### 1.5 Syntax extraction

- [x] Recognize R-numbered productions in the canonical text
- [x] Parse the standard's own grammar notation
- [x] Emit StandardIR syntax objects with full provenance: document, clause,
      rule, page, span hash
- [x] Count eligible productions before extraction and report extracted,
      rejected, ambiguous and skipped productions separately
- [x] Round-trip: production → StandardIR → normalized production, compared
      structurally
- [x] Report the fraction extracted with zero model calls (**E1**): 522/522
      production starts (100%). Regenerate and verify with
      `research/experiments/E0013-complete-core-syntax/check-core-syntax.sh`

### 1.6 Comparison and adjudication (D0005, D0013)

- [x] Generate canonical EBNF from StandardIR, with rule and provenance
      annotations (E0016, regenerate with
      `research/experiments/E0016-does-standardir-syntax-project-mechanica/analyse.sh`)
- [x] Generate ANTLR4 `.g4` from StandardIR (E0017, regenerate with
      `research/experiments/E0017-does-standardir-syntax-project-mechanica/analyse.sh`)
- [x] Generate Bison `.y` from StandardIR (E0018, regenerate with
      `research/experiments/E0018-does-standardir-syntax-project-mechanica/analyse.sh`)
- [x] Generate tree-sitter grammar.js from StandardIR (E0019, regenerate with
      `research/experiments/E0019-does-standardir-syntax-project-mechanica/analyse.sh`)
- [x] Normalize repeated StandardIR lhs records into one deterministic target
      definition with provenance-bearing alternatives (standard-new `7344c65`, validate with
      `research/experiments/E0021-are-grouped-syntax-exports-consumable/analyse.sh`)
- [x] Record that raw syntax exports are partial projections and that parser
      validation applies to a composite input (D0018, E0021)
- [ ] Define the composite parser-generator input: syntax, lexical/token
      definitions, constraints, prose restrictions, profile closure and
      resolution states (typed resolution policy accepted in D0019)
- [x] Choose the typed representation for R401/R403 assumed syntax expansions
      ([D0024](research/decisions/D0024-assumed-syntax-expansions.md)): use
      typed `assumed-expansion` records
- [x] Compose the accepted R402 and lexical D0019 resolution slices (E0046,
      regenerate with
      `research/experiments/E0046-can-the-accepted-r402-and-lexical-d0019-/analyse.sh`)
- [x] Apply the accepted fixed errata overlay to the seven punctuation
      boundaries (E0047, regenerate with
      `research/experiments/E0047-can-source-controlled-punctuation-witnes/analyse.sh`)
- [x] Inventory the complete R401/R403 assumed-expansion boundary after the
      fixed errata overlay (E0048, regenerate with
      `research/experiments/E0048-can-the-fixed-errata-overlays-normalize-/analyse.sh`)
- [x] Compose the accepted resolutions and fixed errata into one candidate
      partial input, retaining the R402/R403 overlap as a verification failure
      (E0049, regenerate with
      `research/experiments/E0049-can-accepted-resolutions-and-fixed-errat/analyse.sh`)
- [x] Compare the pending D0024/D0026 representations without selecting one
      (E0050, regenerate with
      `research/experiments/E0050-can-deterministic-candidate-representati/analyse.sh`)
- [x] Validate the E0049 partial candidate independently in ANTLR4, Bison and
      tree-sitter, retaining the common rejection and distinct failure
      mechanisms (E0051, regenerate with
      `research/experiments/E0051-do-antlr4-bison-and-tree-sitter-independ/analyse.sh`)
- [x] Preserve erratum reference-plus-punctuation groups inside optional
      expressions and rerun all target validators (E0052, regenerate with
      `research/experiments/E0052-can-grouped-erratum-composition-preserve/analyse.sh`)
- [x] Decide how accepted D0019 lexical-class records enter the generated
      lexer and parser exports (D0027): use a target-independent lexical-fact
      schema with specialized exporters
- [x] Decide how R402 aliases and R403 scalar facts compose (D0026): retain
      both in one compositional fact set and lower them deterministically
- [x] Record the default decision policy: prefer simple, source-preserving,
      compile-time-specialized designs and self-accept decisions when those
      principles determine the choice (D0028)
- [x] Partition the remaining target-tool failures into source-provenance
      buckets without resolving them (E0053, regenerate with
      `research/experiments/E0053-can-the-remaining-target-failures-be-par/analyse.sh`)
- [x] Compare deterministic D0027 lexical projection candidates without
      selecting one (E0054, regenerate with
      `research/experiments/E0054-can-deterministic-lexical-projection-can/analyse.sh`)
- [x] Generate the accepted specialized parser-generator input under D0024,
      D0026 and D0027 (E0055, regenerate with
      `research/experiments/E0055-can-accepted-projection-decisions-produc/analyse.sh`)
- [x] Apply D0024, D0026 and D0027 to one composite input and measure the
      remaining target-export boundary (E0055, regenerate with
      `research/experiments/E0055-can-accepted-projection-decisions-produc/analyse.sh`)
- [x] Normalize the compact target-export structural failures mechanically:
      left recursion and nullable wrappers, retaining target warnings and the
      remaining tree-sitter boundary (E0056, regenerate with
      `research/experiments/E0056-can-deterministic-target-normalizers-rem/analyse.sh`)
- [x] Select the specialized direct parser as the production target and keep
      tree-sitter as a generated export and differential oracle ([D0029](research/decisions/D0029-specialized-direct-parser-production-target.md), based on E0056's 13 conflict groups and next unresolved group
      `r_int_x2D_literal_x2D_constant` versus `r_kind_x2D_param`)
- [x] Decide the ANTLR4 and Bison warning policy: retain their target
      diagnostics as derived evidence and require zero fatal errors and zero
      unresolved names, rather than making warning-free secondary exports gate
      the direct parser ([D0030](research/decisions/D0030-generated-export-warning-policy.md),
      E0056 recorded 18 and 206 warnings, respectively)
- [x] Emit deterministic direct-parser dispatch wiring from the accepted
      composite input, with one provenance-bearing row per syntax record and
      one generated procedure per unique left-hand side (E0057, regenerate
      with `research/experiments/E0057-can-accepted-composite-standardir-emit-a/analyse.sh`)
- [x] Generate and execute the source-linked diagnostic lookup for every
      accepted composite record. Retain page, byte span, source hash, known
      lookup, unknown rejection and mutation evidence (E0058, regenerate with
      `research/experiments/E0058-can-accepted-composite-records-generate-/analyse.sh`)
- [x] Fill the first local top-level parser operation and validate its
      program, module and submodule witnesses against five pinned real-source
      files with source-linked diagnostics (E0059, regenerate with
      `research/experiments/E0059-can-generated-top-level-operation-parse-real-/analyse.sh`)
- [x] Fill a bounded statement-level local parser operation and validate ten
      declared witnesses across five pinned real-source files with
      source-linked diagnostics (E0060, regenerate with
      `research/experiments/E0060-can-generated-statement-operation-match-real-/analyse.sh`)
- [x] Classify every meaningful line in the five pinned real-source files,
      including the `submodule` keyword-like identifier case, with generated
      source-linked diagnostics (E0061, regenerate with
      `research/experiments/E0061-can-generated-parser-accept-complete-/analyse.sh`)
- [x] Assemble logical statements and validate nested construct closure over
      continuation and named-construct witnesses (E0062, regenerate with
      `research/experiments/E0062-can-generated-parser-handle-constructs-/analyse.sh`)
- [x] Compose E0062 logical records into a source-linked typed AST forest with
      deterministic parent and child links (E0063, regenerate with
      `research/experiments/E0063-can-generated-ast-records-preserve-/analyse.sh`)
- [x] Add expression-shaped AST children and source-linked kind/rule queries
      (E0064, regenerate with
      `research/experiments/E0064-can-generated-ast-expressions-be-queried-/analyse.sh`)
- [x] Compose recursive token-level expression subtrees and source-linked
      witness queries (E0065, regenerate with
      `research/experiments/E0065-can-generated-expression-subtrees-preserve-/analyse.sh`)
- [x] Compose precedence-shaped expression subtrees with generated binary,
      unary and array-constructor nodes, preserving source links (E0066,
      regenerate with
      `research/experiments/E0066-can-generated-precedence-trees-preserve-/analyse.sh`)
- [x] Enlarge the E0066 expression corpus with broader literal and operator
      families, including function references, and validate deterministic
      source-linked coverage over nine witnesses in six files (E0067,
      regenerate with
      `research/experiments/E0067-can-generated-expression-coverage-/analyse.sh`)
- [x] Validate parser acceptance over complete real-source files using the
      generated local operations, retaining unsupported constructs and
      source-linked diagnostics (E0068, regenerate with
      `research/experiments/E0068-can-lossless-complete-source-acceptance-/analyse.sh`)
- [x] Measure exact normative-prose evidence over the E0022 unresolved-name
      denominator before model escalation: 9 candidate spans across 7 names,
      174 names retained unresolved (D0035, E0069, regenerate with
      `research/experiments/E0069-can-deterministic-normative-prose-patter/analyse.sh`)
- [x] Extend the deterministic prose recognizer to bounded sentence and table
      structure with fixed source witnesses: 42 candidate spans across 30
      names, 151 names retained unresolved (E0070, regenerate with
      `research/experiments/E0070-can-bounded-sentence-and-table-structure/analyse.sh`)
- [x] Adjudicate all 42 E0070 source-linked candidates into 37 typed,
      source-supported relations and 5 retained false-positive/residue records
      with independent source checks (E0071, regenerate with
      `research/experiments/E0071-can-source-controlled-adjudication-separ/analyse.sh`)
- [ ] Compose the E0071 accepted relations with the existing D0019 records
      into a partial parser input while retaining all rejected and unresolved
      names
- [ ] Resume after retained residues and enlarge supported complete-source
      statement and expression families under independent corpus checks
- [x] Compare the generated syntax against the `standard` `.g4` corpus and
      kaby76 structurally where the formats permit (E0020, regenerate with
      `research/experiments/E0020-how-do-the-deterministic-standardir-synt/analyse.sh`)
- [x] Compare permitted grammar artifacts and parser behavior against LFortran
      and Flang (E0041, regenerate with
      `research/experiments/E0041-do-lfortran-flang-and-gfortran-agree-on-/analyse.sh`)
- [x] Compare parser behavior against gfortran as a GPL behavioral oracle only
      (E0041)
- [x] Record structural comparison adapters for the house grammar, kaby76,
      LFortran and Flang, labeling them separately from behavioral results
      (E0020)
- [ ] Adjudicate every disagreement against 24-007
- [ ] Classify each: ours wrong, theirs wrong, document ambiguous
- [ ] Publish the defect rate per comparison corpus, with the denominator and
      the document-ambiguous bucket

### 1.7 Semantic formalization

- [ ] StandardIR constraints, definitions, relations and rules over Core 0
      clauses
- [ ] Every rule records its subject, applicability, required facts and
      provided facts
- [ ] Fact dependency graph and topological rule scheduling are generated,
      rather than maintained as a pass list
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
- [x] Rule dependency graph, and the E0014 syntax profile closure computed
      from it. Feature eligibility remains a separate projection (D0015)

### Phase 1 experiments

- [x] E0001 (E1) manifest written and metrics named **before** extraction starts
- [x] E0002 (E2) manifest likewise
- [x] E0003 (E3) manifest likewise
- [x] E0004 broad syntax extraction manifest, denominator and oracle recorded
- [x] E0005 contiguous core syntax extraction manifest, denominator and oracle recorded
- [x] E0013 complete core syntax extraction, scope audit, denominator and oracle recorded
- [x] E0014 Core 0 roots, dependency closure, duplicate policy and independent
      graph oracle recorded
- [x] E0015 explicit feature exclusions, graph projection and unresolved-name
      classification recorded
- [x] E0016 canonical EBNF projection, provenance and independent structural
      oracle recorded
- [x] E0017 ANTLR4 projection, provenance and independent structural oracle
      recorded
- [x] E0018 Bison projection, provenance, helper lowering and independent
      structural oracle recorded
- [x] E0019 tree-sitter projection, provenance and independent structural
      oracle recorded
- [x] E0034 flat SX arena-reader corpus differential recorded
- [x] E0035 v0 SX schema parser differential recorded
- [x] E0036 deterministic schema type-emission differential recorded
- [x] E0037 generated schema source-tree regeneration recorded
- [x] E0038 approved schema-value contract and reference codec recorded
- [x] E0039 generated schema reader and writer differential recorded
- [x] E0040 generated schema validation and equality differential recorded
- [x] E0041 LFortran, Flang and gfortran parser behavior differential recorded
- [x] E0042 generated schema printer and hash differential recorded
- [x] E0069 deterministic normative-prose evidence inventory and escalation
      boundary recorded
- [x] `scripts/index.sh` reports all declared experiments from run records

**Gate.** E0001--E0003 report, from run records rather than by hand: complete
syntax coverage and the fraction extracted with zero model calls, complete
semantic coverage and the fraction formalized mechanically, the minimum model
size per remaining rule, and the comparison-corpus disagreement rates with
adjudications. The comparison report must separate structural grammar
comparisons from behavioral oracle comparisons.

---

## Phase 2. `fortfront-new`: generated frontend

- [ ] Repository created, `AGENTS.md` + symlink, CI, text gate
- [ ] Generate the lexer from the lexical specification
- [ ] Generate canonical grammar exports: EBNF or BNF, ANTLR4, Bison and the
      specialized parser-generator input
- [ ] Generate at least two parser strategies from StandardIR syntax
- [ ] Benchmark them on a pinned corpus. Keep the fastest correct one
- [ ] Generate the AST schema
- [ ] Generate the frontend source tree and wiring from the AST schema and
      architecture metadata
- [ ] Generate semantic checks by direct specialization where possible (D0007)
- [ ] Start with a generated rule table and generic semantic engine, then
      specialize and fuse it without changing the authoritative records
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
- [ ] E12 go/no-go recorded. If no-go, write a decision record for the Fortran-specific
      resolver
- [ ] Parsing throughput measured against FortFront, LFortran and Flang
      (**E5**, **E6**)

**Gate.** The contract-completeness check passes, parsing throughput is
measured against at least two established frontends on a pinned corpus, and the
generated SX reader agrees with the seed on the whole corpus.

---

## Phase 3. Modern Fortran Core 0

- [ ] Core 0 defined as a rule-ID selection with computed dependency closure
- [ ] Feature-eligibility projection closes aggregate syntax alternatives without
      confusing reachability with feature support (D0015)
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
- [ ] MIR node dispatch and lowering wiring generated from the MIR schema
- [ ] Local lowering holes cannot add modules, callers or dispatch conventions
- [ ] Rank and type specialization generated from specification
- [ ] **Acceptance test for the generated-lowering claim**: add a rank, observe
      that no consumer needed an edit (`LESSONS.md` §4)
- [ ] Simple optimizations
- [ ] Performance search over representations: symbol table, AST layout, arena
      strategy (**E9**)
- [ ] Command-line driver
- [ ] LLVM path as differential oracle and performance baseline only
- [ ] **First self-host milestone**: the new compiler compiles the meta-tools:
      SX reader, StandardIR engine, ImplIR checker, generators (D0010)
- [ ] Bootstrap Core sufficiency reported. Growth is recorded as an E10 result,
      not treated as a failure

**Gate.** Generated programs run correctly on a pinned corpus, with rank
specialization generated rather than written and demonstrated by the
add-a-rank test.

---

## Phase 5. `fortback-new`: generated backend

- [ ] Repository created, `AGENTS.md` + symlink, CI, text gate
- [ ] Target description language, derived from the ISA specifications rather
      than transcribed
- [ ] RISC-V: `riscv-opcodes` pinned by hash. Generated instruction tables,
      encoder, decoder
- [ ] AArch64: ARM Machine Readable Architecture pinned. The same generated
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
- [ ] Structural generator emits the complete source tree and wiring without
      model calls
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
identical. Stage equality establishes reproducibility, not trusting trust.
diverse double compilation is named as future work in `docs/self-hosting.md`
§21 and is not planned.

---

## Phase 7. x86-64

Deliberately last: no official machine-readable encoding specification, no
authoritative semantics, translation validation impractical.

- [ ] Intel XED data files and Zydis tables pinned by hash
- [ ] Encodings generated from them. Disagreements between the two adjudicated
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

- [ ] `docs/literature.md`: verify the ~30 citations recorded from memory.
      Three are checked. **Read Lämmel & Verhoef before E1's related work**,
      E1 automates the loop that paper describes semi-automatically, and the
      framing of the first result depends on getting that relationship right
- [ ] Prose passes: `LESSONS.md`, `DESIGN.md`, `README.md`, `AGENTS.md` and the
      two new design notes have not had an adversarial pass. Only
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
