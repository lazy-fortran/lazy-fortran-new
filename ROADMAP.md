# Roadmap

Snapshot: 2026-08-14. Live repository state is reported by
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
E0089 records the current semantic successor ledger with 22 resolved and 265
unresolved constraints. E0090--E0097 generate semantic rule rows, classify
nine top-level forms, execute nested implication, not-or and finite-domain
predicates, and emit structured source-linked diagnostics. Wave B is now
integrated: `standard-new` exposes source-backed StandardIR records,
`fortfront-new` consumes caller-supplied syntax witnesses for a bounded
program slice, `ffc-new` owns the target-independent MIR function boundary,
and `fortback-new` imports bounded `riscv-opcodes` and AARCHMRS witnesses. The
first deterministic E0099 name-resolution attempt is explicitly blocked by
missing historical comparison pins; it made no classifications. E0041
records the parser behavior comparison across LFortran, Flang and gfortran.
Broad comparison adjudication, complete semantic coverage and the Phase 2
frontend gate remain open. Regenerate this snapshot's experiment values with
`scripts/index.sh`.

[D0040](research/decisions/D0040-defer-paper-for-broader-result.md) supersedes
D0038. The syntax-only manuscript was retired. The research evidence remains
in the run ledger and ignored cache. The planned paper has Christopher Albert
as sole author and targets *Nature Computational Science* aspirationally after
semantic formalization and generated frontend measurements establish the
broader result. Top programming languages venues remain fallback targets.

[D0041](research/decisions/D0041-fortran-first-adapter-and-mechanical-syntax-closure.md)
sets the immediate order. We finish the Fortran/J3 adapter and mechanically
close the complete syntax reference set before starting new model-assisted
semantic work, generalized multi-standard tooling or the production frontend.
E0055 already demonstrated the D0024/D0026 expansion projection. The next run
must carry that accepted layer into the current E0074-derived integration.
The generic boundary is kept at StandardIR, typed facts, expansion algebra,
provenance, exporters and wiring. PDF layout, R/C notation, wording patterns,
errata and lexical data remain a Fortran-specific adapter for now.

[D0045](research/decisions/D0045-native-codex-subagents-for-parallel-slices.md)
keeps this roadmap as the sole program planning authority. `standard-new`,
`fortfront-new`, `ffc-new` and `fortback-new` remain production-only sibling
repositories. Their specifications, generated source and behavioral tests stay
there, while decisions, experiments, runs, provenance and integration pins stay
in this laboratory. Independent native GPT-5.6 Luna subagents may work on bounded,
non-overlapping slices in those sibling directories and report commits back to
the central agent for metadata updates.

The backend lane is active as a parallel program lane, not a second planning
repository. Its implementation roadmap is maintained here under Phase 5 and
its eventual production work will happen in `../fortback-new`. The backend
does not wait for the frontend to begin TargetIR, ISA ingestion, encoders,
decoders, register/feature metadata, ABI metadata or object writing. MIR-
dependent legalization and instruction selection wait for the MIR contract.

## Parallel lane index and wave gates

The lane details are central and live in `roadmaps/`: StandardIR,
`fortfront-new`, `ffc-new`, `fortback-new`, and integration. Cross-repository
interfaces are central versioned SX schemas in `contracts/`, validated by
`scripts/check-contracts.sh`. Production repositories do not receive local
roadmaps or research ledgers. D0044 defines the contract and branch lifecycle.

```text
standardir-v0 ──→ frontend-v0 ──→ mir-v0 ──→ fortback legalization/ISel
       │                              ▲                 │
       └──────────────→ tools         │                 ▼
targetir-v0 ──────────────────────────┘          emission-v0
```

Wave A can run independent StandardIR closure, backend source provenance and
production scaffolds. Wave B consumes the integrated contract revisions for
StandardIR and TargetIR. Wave C connects the frontend and MIR boundary. Wave D
starts legalization, instruction selection and end-to-end validation only after
their input contracts are integrated. The coordinator merges verified slices
frequently and deletes their clean local and remote task branches after the
merged commit is recorded.

Wave D is complete for its bounded handoffs: the StandardIR production
projection, frontend-v0 SX reader, witness-bounded MIR SX handoff, and
TargetIR-v0 SX handoff are integrated. E0100 independently reproduced the 181
unresolved-name denominator and found 54 mechanically-supported candidates,
46 ambiguous candidates, and 81 names with no candidate, with zero model calls.
E0101 now provides the strict residue package and citation validator, but its
model execution is blocked until the pinned E0100 cache and an explicit local
model runner exist; it made zero calls and adjudicated nothing.

Wave F is complete for four additive production slices: a bounded StandardIR
semantic-item table, canonical typed program-root SX in the frontend, explicit
program-root lowering into the existing MIR witness, and a reloc-free RISC-V
ELF64 object writer. Wave G then added deterministic semantic-table queries, a
standalone typed program-declaration SX boundary, a canonical program-root-SX
to-MIR bridge, and stream-unit ELF64 output. Each slice was independently
tested, merged into the corresponding main branch, pushed, and cleaned up. M3
remains pending: no semantic residue was promoted and no contract was changed
in place. E0101 now has a regenerated 127-row package, and E0102 has exercised
the explicit Luna escalation against it. The next semantic work item is the
120-row abstention residue; no result may be promoted without another exact
source-backed validation gate.

Wave H is complete for three additive vertical slices: a bounded typed
program-unit aggregate, program-declaration SX lowering into the existing MIR
witness, and an end-to-end single-instruction RISC-V-to-ELF witness. E0102
provided the first strict Luna escalation over the 127-row residue: seven
relations passed exact citation validation and 120 rows were abstained; no
relation was promoted into StandardIR. M3 therefore remains pending and the
abstentions remain the next semantic work item.

Wave I is complete for the three production warning-cleanup slices and the
E0103 deterministic audit. Fresh `fo lint` and full `fo` gates are clean in all
four production checkouts. E0103 independently verified all seven accepted
Luna citations, retained six trailing-comma artifacts, matched five names to
StandardIR lhs after explicit normalization, classified two semantic targets,
and promoted nothing. The next semantic step is adjudicating the 120 E0102
abstentions under the same source-backed boundary.

Wave J is complete for the bounded frontend semantic-table consumer, the
program-unit-to-MIR structural bridge, and E0104's multi-line mechanical
search. E0104 retained 2,471 source spans but resolved zero rows uniquely: all
127 residue names became ambiguous. This is the planned escalation boundary,
not a reason to add more ad hoc windows. The attempted E0105 larger-model run
was unauthorized and interrupted before valid output; it is retained as an
abandoned run and contributes no evidence. D0046 selects a deliberately
specified Fortran-document structure extractor as the next M3 slice; no
relation is promoted automatically.

Wave K integrated three dependency-independent production slices: typed
source-linked diagnostic SX in `fortfront-new`, an AArch64 ELF64 witness in
`fortback-new`, and the bounded source-structure index in `standard-new`.
All three passed coordinator-side `fo` gates and retain their existing
frontend/MIR, TargetIR/emission, and StandardIR semantic boundaries. The next
M3 gate is the laboratory measurement of the structure index against the
E0100/E0104 residue; it must not promote semantic facts automatically.

E0106 then measured the structure index against the residue: it emitted 6,707
source-backed records and supplied candidate evidence for 126 of 127 rows
(60 unique, 66 ambiguous, 1 with no structural candidate), without semantic
promotion or model calls. The next production wave may proceed in parallel
with the stricter definition measurement. Its
safe independent lanes are target-side codec/decoder work in `fortback-new`
and a contract-first MIR boundary task in `ffc-new`. No task may modify the
same production files as another task, redefine `mir-v0` inside the backend,
or infer semantic aliases from the structure index.

Wave L integrated the AArch64 ADD/SUB decoder witness in `fortback-new` and
the canonical source-linked StandardIR syntax-item SX boundary in
`fortfront-new`. Both were additive, warning-free, independently checked and
cleaned after merge. The coordinator simultaneously completed E0106 in the
laboratory, as required by D0047.

Wave M then integrated the source-linked frontend diagnostic SX continuation,
the validated `mir-v0` instruction accessor, and a source-backed RISC-V OR
codec slice. Their exact production pins are maintained in
`roadmaps/integration.md`; all three were checked with the full `fo` workflow
and their task branches were removed after merge. These are bounded production
advances only and do not close M3.

Wave N then integrated a provenance-preserving StandardIR semantic-table query,
a typed MIR opcode query, a source-backed RISC-V XOR codec, and a bounded
frontend result-to-program-unit boundary. Each slice passed its independent
behavioral tests and full `fo` gate; the coordinator merged and pushed the
four main branches and removed their task branches. These additive contracts
continue in parallel with E0117 and do not close M3.

Wave O then integrated a provenance-aware StandardIR source query, a typed
frontend program-unit handoff validator, a MIR result-kind query, and a
source-backed RISC-V SLL codec. Each passed the full `fo` gate and its
independent behavioral tests; all task branches were removed after push. The
semantic promotion gate remains unchanged.

Wave P then integrated the generated typed StandardIR consumer callback
contract, the frontend-to-MIR program-unit SX handoff, the MIR frontend-handoff
boundary, and a source-backed AArch64 ADR codec. All four production mains are
clean and pushed after full `fo` verification; none changes the semantic
promotion rule.

Wave Q integrated the typed frontend program-unit query, the MIR handoff
round-trip validation, and paired AArch64 ADRP support. The StandardIR
consumer extension was abandoned before verification, reverted cleanly, and
is retained as run `R000189`; `standard-new` therefore remains at the Wave P
pin. The three accepted slices are pushed and do not change M3's semantic
promotion gate.

Wave R then integrated a source-linked StandardIR semantic sequence consumer,
a frontend diagnostic query, a MIR source-rule query, and a source-backed
RISC-V ORI codec. All four passed their independent tests and full `fo` gates;
their task branches were removed after push. These are production-boundary
advances only and do not promote semantic facts.

Wave S integrated a typed frontend result-span query, a validated MIR block
query, and a source-backed RISC-V ANDI codec. The parallel StandardIR
generated-consumer extension was abandoned after its generator failed on stale
module ordering; it is retained as `R000190` and made no production change.
The three accepted slices are pushed and the semantic promotion rule is
unchanged.

Wave T recovered the generated-module ordering repair in `standard-new` and
integrated a frontend result-header query, a MIR function query, and a
source-backed RISC-V SRA codec. The generator repair is recorded as `R000191`
after coordinator-side full `fo` verification; all four production mains are
now pushed and clean, with no semantic promotion.

Wave U also integrated the delayed validated MIR function-body query in
`ffc-new` at `0beb88c`; its source-preserving and malformed-body tests passed
the full `fo` gate. No other Wave U slice produced a verified change.

Wave V integrated the StandardIR list-element consumer and generated-output
freshness gate, the frontend diagnostic-count query, the MIR function-block
count query, and the source-backed AArch64 LDR literal codec. Each accepted
slice passed its independent tests and the full `fo` gate; all task branches
were deleted after push. The slices remain contract work and do not promote
semantic facts or close M3.

Wave W integrated the indexed frontend diagnostic query, the MIR block
instruction query, and the source-backed RV64 SLLI codec. Each accepted slice
passed its independent tests and the full `fo` gate; all task branches were
deleted after push. These additive boundaries do not redefine a contract,
promote semantic facts, or close M3.

Wave X has integrated the indexed frontend program-declaration query and the
source-backed RV64 SRLI codec. Both passed coordinator-side full `fo` gates;
their task branches were deleted and their production mains are clean and
pushed. The MIR instruction result-type query also passed its coordinator-side
full `fo` gate and was merged and pushed. These additive boundaries do not
redefine a contract, promote semantic facts, or close M3.

Wave Y has integrated the indexed frontend program-declaration-count query and
the source-backed RV64 SRAI codec. Both passed coordinator-side full `fo`
gates; their task branches were deleted and their production mains are clean
and pushed. The M4 generation experiment E0119 is reported separately as
`R000192` for its first AST/wiring slice. These boundaries do not redefine a
contract, promote semantic facts, or close M3/M4.

Wave Z has integrated the source-preserving `frontend-ast-v0` SX handoff into
`ffc-new`. It passed coordinator-side full `fo`, retained source spans and
hashes, and its task branch was deleted after push. The frontend generator
remains in flight; this handoff does not redefine `mir-v0`, promote semantic
facts, or close M3/M4.

Wave AA has integrated the deterministic `frontend-ast-v0` generator and its
checked-in generated Fortran records in `fortfront-new`. The generator,
canonical SX witness, malformed/unsupported schema controls, negative
provenance/span/count cases and full `fo` gate passed; the task branch was
deleted after push. E0119 is reported accepted as `R000192` for this first
AST/wiring slice; the complete M4 lexer, parser, semantic and lowering gates
remain pending.

Wave AB has integrated two disjoint additive boundaries: the generic AArch64
fixed-record validator/matcher in `fortback-new` and the MIR instruction
result-ID query in `ffc-new`. Both passed coordinator-side full `fo` with zero
warnings, their task branches were removed after push, and neither changes a
contract, adds target-specific MIR behavior or closes M3/M4. The exact
production commits are maintained in `roadmaps/integration.md` and recorded as
`R000207` and `R000208`.

Wave AC has integrated generic AARCHMRS variable-bit-range preservation in
`fortback-new`. It passed the full `fo` gate with malformed, overlap and
out-of-range controls; the task branch was removed after push. It adds source
metadata for later generated field extraction, not instruction dispatch or
machine semantics, and is recorded as `R000209`.

Wave AD has integrated two disjoint follow-up slices. `fortfront-new` now has
schema-generated AST preorder traversal with safe optional callbacks, and
`fortback-new` now extracts retained AARCHMRS variable fields by ordinal from
source records. Both passed coordinator-side full `fo` with zero warnings,
negative controls and cleaned local/remote task branches. They are recorded as
`R000210` and `R000211`; neither adds parser semantics, instruction dispatch,
ABI behavior or MIR changes.

Wave AE has integrated the backend continuation at `fortback-new`: generic
source-record-driven insertion now packs a supplied variable field value while
preserving fixed bits and sharing the ordinal/range validation boundary. The
full `fo` gate passed with zero warnings and the task branch was removed; the
slice is recorded as `R000212`. No instruction names, mnemonic dispatch, ABI
behavior or MIR wiring were added. The parallel frontend AST-query slice is
still in flight and is not yet a production pin.

Wave AF has now integrated that frontend continuation at `fortfront-new`.
`generated_ast_kind_count` is emitted from the AST schema and tested over
nested records, empty input, missing and empty kinds and unsupported types. The
full `fo` gate passed with zero warnings and the task branch was removed; it is
recorded as `R000213`. The complete M4 lexer, parser, semantic and lowering
gates remain open.

Wave AG has integrated the first target-independent MIR analysis utility in
`ffc-new`: `mir_function_opcode_count_at` counts validated `mir-v0` opcodes
without importing target details. It passed the full `fo` gate with zero
warnings and malformed/boundary controls, and is recorded as `R000214`. The
MIR contract and frontend/backend ownership boundaries remain unchanged.

Wave AH has integrated the source-backed lexical scalar lookup in
`standard-new` under D0075. It matches ranges and exact scalars, returns source
provenance, and reports processor-defined, invalid, duplicate and overlapping
cases explicitly. Text-policy and full `fo` gates passed with zero warnings;
the slice is recorded as `R000215` and does not add frontend token wiring.

Wave AI has integrated the generic whole-record AArch64 codec in
`fortback-new`. It composes source-record matching with ordinal field
extraction/insertion for encode/decode round trips, while retaining fixed bits
and clearing outputs on failure. Full `fo` passed with zero warnings and the
task branch was removed; the slice is recorded as `R000216`. No mnemonic
dispatch, ABI or MIR wiring was added.

Wave AJ has integrated the frontend lexical-fact classifier in `fortfront-new`
under D0075. It consumes caller-supplied source-backed facts, validates
provenance at lookup time, and exposes explicit scalar, ambiguity,
processor-defined and invalid-input states. Full `fo` passed with zero
warnings; the task branch was removed and the slice is recorded as `R000217`.
It does not yet tokenize source or wire grammar dispatch.

Wave AK has integrated two disjoint lexical/codec continuations. `fortback-new`
`3a1b38e84af54f70ff6baaff231d84deed31a353` now composes the source-record
RISC-V I-format matcher with a generic operand-array whole-record codec;
`fortfront-new` `2bb1bdd1fe0f75164b8de4bfd1c1c6db9d710cca` now iterates UTF-8 scalars by byte span and classifies
source spans using caller-supplied lexical facts. Both passed coordinator-side
full `fo` with zero warnings and explicit malformed-input/output-clearing
controls. The frontend change includes a small coordinator follow-up to make
span no-match, unsupported, ambiguous and invalid-fact statuses distinct from
empty spans. Neither slice adds mnemonic or keyword dispatch, grammar/parser
wiring, ABI, MIR or instruction-selection behavior; they are recorded as
`R000218` and `R000219`.

Wave AL is now complete with the backend normalization continuation at `fortback-new`
`8c4c71e33beb94a4891e3cffe17c29c54b716709`: RISC-V I-format and AArch64
source records normalize into one provenance-bearing generic encoding record
with fixed bits and variable fields. Full `fo` passed with zero warnings and
explicit malformed, unsupported, wrong-target and output-clearing controls;
the slice is `R000220`. The parallel frontend continuation is integrated at
`fortfront-new` `e98bc27d1ad275001df5c040931213b0da34c4c7`: a bounded scanner
coalesces maximal same-fact UTF-8 spans, retains provenance, and reports
unmatched, unsupported, ambiguous, malformed and capacity states explicitly.
It also passed full `fo` with zero warnings and is recorded as `R000221`.
Neither slice adds instruction/keyword dispatch, grammar/parser wiring, ABI,
MIR or instruction selection.

Wave AM has integrated the next frontend/backend pair. `fortfront-new`
`f75e7091798eed10e2aef2ab60dae2ba3698b6ce` now stores caller-supplied,
source-provenanced grammar rules and queries them by LHS in insertion order;
`fortback-new` `5a44f9c5906068433bf616c1687dc2f486fa5abc` now encodes and
decodes normalized TargetIR records without importing ISA source modules.
Both passed coordinator-side full `fo` with zero warnings and explicit
malformed, capacity, provenance, fixed-bit, field-range, unsupported-word and
output-clearing controls. They are recorded as `R000222` and `R000223`.
Neither adds Fortran parser dispatch, ABI, MIR or instruction selection.

Wave AN has extended those two generic consumers without crossing their
language-specific boundaries. `fortfront-new`
`b657fad20cccb2a2166c11d1faf48d8b0d69314f` now matches a caller-supplied
grammar RHS deterministically while preserving rule identity and provenance;
`fortback-new` `e72467d97fbd8978d29c8cc69719e343a687a992` now performs
source-family-independent normalized TargetIR candidate lookup in insertion
order with explicit ambiguity, no-match, malformed, unsupported-word,
invalid-target and capacity states. Both passed coordinator-side full `fo`
with zero warnings and are recorded as `R000224` and `R000225`. Parser state,
frontier/backtracking policy, ISA dispatch, ABI, MIR and instruction selection
remain open rather than being smuggled into these data boundaries.

Wave AO has composed the preceding boundaries once more. `fortfront-new`
`199c383ede97fe78f91a738d16c28e946c15f072` now collects unique or ambiguous
grammar candidates by composing LHS lookup with exact RHS matching, retaining
insertion order, identity and provenance. `fortback-new`
`b533414aae80052308434fc725500cf2d028a1ac` now decodes a word through the
normalized candidate lookup and generic codec only when the candidate is
unique. Both passed coordinator-side full `fo` with zero warnings and are
recorded as `R000226` and `R000227`. Parser state/frontier management and
ambiguity policy, as well as backend instruction selection and MIR connection,
remain open.

D0076 now defines the next cross-repository syntax boundary as
`standardir-grammar-v0`: a source-backed flat preorder node table that retains
reference, token, sequence, choice, optional and repeat structure. The
producer/consumer implementation wave is in progress in `standard-new` and
`fortfront-new`. This contract is an input to deterministic generation; it is
not itself a parser and does not authorize copying grammar payloads into the
frontend.

E0120 is now reported as `R000195`. Its generic sentence-form extractor
reconstructed 23 source-linked constraint records from the pinned normative
text: the eight E0083 baseline rows plus 15 new rows. It retained all 287
constraint occurrences, classified 258 as unsupported and six as no-match,
accepted no ambiguous rows, made zero model calls, and passed four independent
input/predicate mutation controls. The inventory is occurrence-based, so the
two source rows carrying identifier C704 remain distinct. This expands the
independent source oracle but does not validate semantic sufficiency or close
M3; the next gate is to feed the expanded oracle into independently generated
finite cases.

E0121 reports the expanded finite-case replay as `R000196`. The 23-record
E0120 source oracle overlapped 18 accepted E0117 proposals and produced 49
finite cases: 34 exact matches, zero mismatches, zero evaluator errors, and
four explicit `candidate_unavailable` cases where model fact names had no
source-oracle counterpart. The remaining 226 source cases are explicit
`oracle_unavailable` outcomes because their predicates or model rows do not
provide a faithful finite domain. The run made zero model calls, passed 246
mutation controls, invoked no compiler, and promoted no semantic fact. M3
remains open; the next semantic step is to formalize the still-unavailable
predicate families or hand them to the bounded model protocol.

E0122 reports the generic finite-materialization continuation as `R000199`.
The E0120 source oracle produced 93 cases over its 18 rows that overlap an
accepted E0117 proposal: 36 exact matches, zero mismatches, zero evaluator
errors and 57 explicit `candidate_unavailable` outcomes. The five source rows
without an accepted model proposal and the 215 rows without an independent
oracle remain explicit denominator statuses. String-length, count,
existential and containment terms are now handled by generic machinery; no
model-specific aliases or semantic promotions were added.
E0123 is the active bounded semantic retry. It keeps all 287 E0117 row keys,
retries only the 53 unresolved or hard-failure rows with a fresh Qwen 3.6
35B-A3B episode and one thinking-on escalation, and retains the 234 prior
terminal rows as immutable controls. Its manifest records D0070's verified
llama.cpp master service and the one-shot health/version preflight. The run is
not reported until its rows, validator, witness gate and exact merge gate have
all completed.

D0073 fixes the repair boundary for this and later semantic runs: deterministic
processing may repair transport representation, but may not rewrite predicate
operators, invent facts, infer missing nesting or substitute evidence. The
model must receive the rejection and submit a bounded replacement; every
attempt remains retained.
D0074 adds compact, generic constructor-shape examples to successor prompts
after the E0123 predecessor's repeated nesting and fact-versus-literal gate
errors. It does not relax validation or change E0123's pinned prompt.

D0075 fixes the next lexer boundary: source-defined lexical facts remain
source-backed data queried by generic code, while processor-defined facts are
explicit non-match/unsupported results until a separate target policy exists.
The frontend may not hardcode Fortran token names or reread the PDF. The first
production lookup slice is integrated in `standard-new` and recorded as
`R000215`; the active frontend task consumes this boundary without importing
the sibling repository at build time.

The current production pins after the latest bounded integration wave are
`standard-new` `985d684a2c8e5f4394b3473c8bdc3a9de7453ab9`,
`fortfront-new` `199c383ede97fe78f91a738d16c28e946c15f072`, and
`fortback-new` `b533414aae80052308434fc725500cf2d028a1ac`; these are clean
`main` branches with coordinator-side full `fo` verification. The FFC pin
is `555eb09bfb17329517176f967a3d1fda36c3159e`.

The same integration wave added bounded program, module and subroutine
source-witness forms to `fortfront-new`: exact program, module, subroutine and
function headers and
`end`/`end <kind>`/`end <kind> NAME` forms, source spans, name matching and
malformed-input rejection are tested. The StandardIR slice also exposes a
generic ordinal query for duplicate semantic identifiers, preserving insertion
order and provenance. These are witness and API boundaries, not semantic
promotions or general-language implementations.
D0072 records the corresponding backend boundary: the existing RISC-V codec
cases are bootstrap witnesses, and further instruction coverage now waits for
generic source-record-to-TargetIR normalization and generated codec output.
The decision is recorded in
`research/decisions/D0072-targetir-generated-backend-boundary.md`.
The first implementation step is now integrated: a generic source-record-
driven RV64I I-format codec helper with no new mnemonic dispatch.
The second is integrated as a generic AArch64 fixed-record validator/matcher
over imported ADD, SUB and NOP records, with no mnemonic dispatch, ABI or MIR
behavior.

## Numbered milestones

These milestones are the externally meaningful stops in the roadmap. A
milestone is complete only when its gate is demonstrated by an experiment or
an independently checked artifact.

### M0. Laboratory and provenance foundation (complete)

The laboratory repository, source pins, decision and run ledgers, provenance
gate, reproducible scripts, and comparison boundaries exist and pass their
repository checks.

### M1. Normative syntax extraction (complete)

The pinned J3/24-007 PDF yields the complete numbered syntax span as
provenance-bearing StandardIR. The canonical SX round-trip and the EBNF,
ANTLR4, Bison, tree-sitter, and direct-parser projections are reproducible.
The remaining reference closure is deliberately carried forward as the next
milestone's input.

### M2. Closed syntax and sane selected generated grammars (complete)

The complete selected Fortran syntax profile reaches a closed, source-backed
reference state. Every referenced name is accounted for as an explicit
production, an R401/R402/R403 assumed expansion, a lexical fact, a fixed
erratum/token operation, or a source-backed semantic-only fact. The selected
parser profile has zero unresolved, disputed, or unclassified parser names.
An explicitly unsupported profile feature is a separate exclusion decision,
not a hidden resolution.

The selected production parser inputs—EBNF, ANTLR4, Bison and the specialized
direct-parser input—are structurally sane. They retain provenance, contain no
unresolved symbols, and pass their target validators without fatal errors.
Target warnings remain reported as evidence under D0030. The direct parser has
no dispatch collisions, and its generated source compiles. Tree-sitter remains
a separately reported derived differential export under D0029: its target
conflict does not block this milestone or the production parser.

### M3. Source-backed Core 0 semantics (pending)

Core 0 constraints, definitions, relations, and fact dependencies have a
measured resolution state. D0046's structure-first extractor and E0106's
independent residue measurement are complete. D0048 defines the strict
source-form acceptance boundary. E0110 is the final bounded mechanical pass:
liberal discovery through three declarative normalization operations, strict
acceptance, and zero candidate-specific branches. E0111 is retained as a
2B pilot; D0050 corrects its missing overlap windows. E0112 now runs the
predeclared Qwen/Gemma ladder against the same 127 rows, using deterministic
citation reconstruction from a model-selected evidence window. It has Q6/Q8
controls for smaller models, thinking only after non-thinking failure,
two-attempt repeatability, and no automatic promotions. E0113 replaces that
terminal comparison with full-document deterministic retrieval, a three-call
bounded gate/repair protocol, explicit total/setup/inference timing, and a
six-row E0110 solved-translation oracle. Its discovery metric excludes those
six oracle rows; its translation metric is exact E0110-key agreement on all
six. E0114 separately tests Qwen and Gemma vision-capable checkpoints directly
on rendered PDF pages before canonical text processing. Both experiments are
now reported with all failures retained; neither promoted semantic facts.
The first six local text cells used the old llama.cpp wrapper. Gemma 4 E4B
was then repeated under the pinned b10405 runtime and conservative single-GPU
configuration after the old loader assertion was isolated as a toolchain
failure (D0055). M3 remains open because the residue was not resolved
reliably. D0056 makes E0115 local-only: it uses the declared Qwen and Gemma
checkpoints through pinned llama.cpp, while DeepSeek and Luna remain historical
controls only. E0115 is the next comparison gate: it gives every
eligible local model the same bounded native evidence tools and runs the complete
predeclared model x protocol x reasoning matrix. Its deterministic local tool
environment and native llama.cpp loop now pass fixture gates and a one-row Qwen
3.5 2B smoke control. Abstention is a measured false negative in E0115, not a
green result. D0058 amends D0057: the gate now recognizes direct definitions,
R401/R402/R403 assumed rules and numbered RHS lexical/operator terminals, UTF-8
byte clipping is safe, and model-class turn caps are 12/16/20. Two provisional
partial cells and a partial Qwen 3.5 4B control exposed deterministic boundary
bugs; all are retained as harness controls and excluded from model results. The
first complete local bounded-tool cell (Qwen 3.5 2B, reasoning off) is recorded:
6 accepted, 57 abstentions and 64 hard failures over 127 rows, with 4/6 exact
oracle translations and one novel accepted row. The corrected convergence
cells start with Qwen 3.6 35B-A3B and 27B, then use smaller fallback cells.
D0059 now fixes the semantic recovery boundary: deterministic normalization
accepts unique typed source relations; a bounded local LLM may only navigate
evidence or propose a small typed predicate for the residual; deterministic
schema, provenance and behavioral gates remain authoritative. The complete
Qwen 3.6 35B-A3B adaptive cell resolves 127/127 residue rows and 6/6 solved
oracle rows exactly. The remaining local model cells are a cross-model
comparison of this protocol, not semantic promotion. Campaign data and
commands are recorded in git, generated plot files remain ignored, and PNGs
are handed off through slopbox. Unavailable checkpoints and inapplicable visual
cells remain explicit denominator entries.

D0060 closes the source-backed name/evidence subphase. The deterministic
closure covers 127/127 residue rows; the complete bounded local text matrix
has nine Qwen/Gemma cells with one declared retry stage. Adaptive results range
from 84/127 to 127/127, with exact solved-translation oracle results from 0/6
to 6/6. The matrix and initial-to-adaptive convergence figures are generated
by `assemble-results.py`, `plot.py` and `plot-convergence.py`; their PNGs are
ignored and handed off through slopbox. This closes name/evidence acquisition,
not the whole semantic milestone. The next M3 slice is the typed-predicate
pilot for an actually constraining rule such as C702. No model output from
E0115 is promoted into StandardIR. D0061 now fixes the completion protocol:
one local Qwen 3.6 35B-A3B proposer, bounded source tools, typed JSON
predicates, deterministic schema/source/replay gates, and a terminal record for
every constraint row.
[D0062] amends that protocol after the first C702 smoke: relation operands are
typed by position, prior controls are parsed canonically, source-span failures
stay inside the tool boundary, and promotion requires an independent witness
stage for a generic source form.
[D0063] then defines control replay and one bounded retry over only unresolved
or hard-failure row keys; both attempts remain immutable and are merged only by
validated row key.
[D0064] keeps malformed native tool JSON inside the episode as a counted,
bounded repair turn instead of ending the row before its declared turn cap.
[D0065] raises the bounded output budget to 1536, adds one generic
source-backed `relation` constructor for quantified/cross-clause residuals,
and forces submission after repeated or exhausted evidence retrieval. The
official llama.cpp tool protocol is used for named forcing; no model-specific
or C-number-specific branch is added.
[D0066] repairs the bounded dialogue generically: it adapts one recognized Qwen
XML content call, excludes malformed assistant calls from the next context,
and gives exact gate rejection feedback before the next proposal. [D0067]
adds bounded transient transport retries, proposal-loop detection, one-turn
forced-tool consumption, submit-only finalization, llama.cpp timing telemetry,
and an explicit fresh thinking-on escalation for failed no-thinking rows. The
local Qwen service must expose a bounded reasoning budget for that fallback;
normal rows still request thinking off.
[D0070] supersedes D0068 for future runs: the semantic service advances to a
clean CUDA build of the latest verified upstream llama.cpp `master`, installed
beside the old runtimes with a reversible versioned service path. The active
E0117 run retains its original `650913862` runtime pin and is not rewritten.
[D0069] requires the next proposal protocol to carry concrete fact maps and
expected outcomes. The deterministic evaluator may report self-consistency,
but self-consistency is not independent semantic promotion.

The numbered M3 execution sequence is:

1. Reconstruct the complete E0081 Core 0 constraint denominator, preserving
   repeated cross-reference occurrences and distinguishing them from primary
   rule bodies.
2. Run the deterministic source pass for each row: source bytes, page, rule
   association, canonical hash and standard-document hash.
3. Give Qwen one constraint at a time with `read_constraint`, bounded rule and
   search tools, and the typed predicate schema; never give it wiring authority.
4. Validate each proposal mechanically: exact row identity, source evidence,
   allowed constructors, typed fact identifiers and prior accepted controls.
5. Repair a rejected proposal within the declared turn budget and retain every
   rejection, tool call, model error, timing and final row state.
6. Run the independent replay and mutation gates over all rows, with zero
   parser projections and zero dropped or duplicated occurrences.
7. Generate the semantic proposal ledger and dependency inventory, keeping
   `accepted`, `unresolved`, `hard_failure` and `reference-only` states explicit.
8. Promote a predicate only after the separate behavioral witness gate agrees;
   a schema-accepted Qwen proposal alone is not a StandardIR fact.
9. In parallel, advance `ffc-new`'s target-independent typed MIR boundary and
   stable importer/exporter without importing ISA or ABI details.
10. In parallel, advance `fortback-new`'s source-preserving RISC-V/AArch64
    codec/decoder coverage without redefining `mir-v0`.

Steps 1--8 are the M3 semantic lane. Steps 9--10 are independent production
lanes and do not block semantic formalization. M3 closes only after the
complete Core 0 semantic ledger has a measured accepted, unresolved and
disputed state and its promoted subset passes the behavioral witness gate.

The current M3 execution is E0123, a fresh bounded retry of E0117's 53
unresolved or hard-failure rows. It uses the local Qwen 3.6 35B-A3B service,
the verified upstream llama.cpp master build, thinking off first and one
thinking-on escalation, while retaining the other 234 E0117 rows as immutable
controls. Its one-shot service preflight passed; the run is recorded as
`R000206` in the manifest and remains unreported until validation, witnesses
and exact row-key merging finish. D0073 forbids deterministic semantic
rewrites during this retry: only transport representation may be repaired.

The predecessor and source-oracle evidence remain historical controls. E0117
is `R000193` with 233 schema-accepted proposals, 16 unresolved rows, 37 hard
failures and one reference-only occurrence; it made no semantic promotion.
E0118 is `R000194`, with 30/30 matches over its five-row independent overlap.
E0120 is `R000195`, with 23 source-reconstructed records and no promotion.
E0121 is `R000196`, with 34 exact matches among 49 emitted finite cases.
E0122 is `R000199`, with 36/36 exact matches among 93 emitted cases and 57
explicit candidate-unavailable outcomes. These source-oracle experiments
validate portions of the gate; they do not close M3 or promote semantic facts.

The immediate post-E0123 handoff is fixed: run the exact replacement merge,
replay `validate.py`, run the independent witness gate, and append one terminal
run record retaining both trajectories. If all 287 rows are terminal and the
independent witness gate agrees, promote only that witnessed subset. If any
row remains unresolved or hard-failed, open a successor experiment using D0074
and its explicit shape examples; do not start a broad model comparison or
change the schema opportunistically.

### M4. Generated frontend vertical slice (pending)

`fortfront-new` parses a closed profile, builds the generated AST, resolves a
small semantic contract, emits source-linked diagnostics, and lowers one
useful construct. Structural wiring comes from schemas and architecture
metadata. No local fragment adds compiler-wide modules, callers, or dispatch.

E0119 is the first gate for this milestone. D0071 separates its typed AST
contract from the frontend result contract. It consumes the pinned
`contracts/frontend-ast-v0.sxs` schema and its fixed witness, and measures
whether program-root, program-declaration and program-unit records, canonical
SX and wiring can be generated and compiled without handwritten
language-specific dispatch. The generator, freshness command and independent
behavioral oracle now exist. Its first deterministic slice is reported
accepted as `R000192`; this is a gate for the AST/wiring slice only, not
completion of M4's lexer, parser, semantic or lowering requirements.

### M5. Practical generated frontend (pending)

The generated frontend accepts a pinned real Fortran corpus, agrees with
independent compiler oracles on the declared behavior, and has measured
throughput and memory against at least two established frontends.

### M6. Self-hosted compiler pipeline (pending)

The generated compiler compiles the SX reader, StandardIR engine, ImplIR
checker, and generators. The result reports the deterministic, search,
model-assisted, and handwritten fractions of the language-specific
implementation.

**Immediate syntax-closure gate (E0098 and D0029, complete):**

- [x] Reintegrate D0024, D0026, D0027 and fixed errata into the complete
      522-record projection. Do not use the narrower E0074 alias-only profile
      as the current baseline.
- [x] Apply R401/R402/R403 mechanically as typed source-provenanced
      expansions, preserving list repetition/separators, aliases and scalar
      constraints.
- [x] Classify every remaining reference as explicit, assumed-expansion,
      lexical, erratum/token, semantic-only, disputed or unresolved. Retain
      provenance for every state and silently drop none.
- [x] Reach zero unclassified parser names in EBNF, ANTLR4, Bison, tree-sitter
      and direct wiring. Semantic-only records may remain outside parser
      aliases, but not without source-linked facts. Tree-sitter may still
      report target conflicts under D0029.
- [x] Decide whether any residue warrants a small-model local proposal. No
      model is used to rediscover R401/R402/R403; E0098 required none.

E0098 closes the source-side reference state: 469 explicit reference classes,
100 assumed expansions, 5 lexical facts, 8 errata, and zero unresolved or
disputed parser names. EBNF, ANTLR4, Bison and direct wiring pass. Tree-sitter
still has the documented target-specific conflict after the compact one-group
extension; D0029 makes that export non-gating. Regenerate with
`research/experiments/E0098-can-the-current-complete-standardir-proj/analyse.sh`.

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
- [ ] Restore that accepted deterministic projection in the current complete
      integration and close the reference state machine mechanically (E0098,
      manifest recorded. The analysis script is added with the run.)
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
- [x] Compose the E0071 accepted relations with the existing D0019 records:
      219 provenance-bearing fact rows, 29 semantic facts kept out of parser
      aliases, and 11 deterministic parser-projection rows (E0072, regenerate
      with `research/experiments/E0072-can-accepted-normative-relations-compose/analyse.sh`)
- [x] Validate the E0072 parser-resolution sidecar in EBNF, ANTLR4, Bison,
      tree-sitter and direct Fortran: 11 rows per target, 55 provenance
      instances, zero semantic leaks (E0073, regenerate with
      `research/experiments/E0073-can-the-e0072-parser-resolution-sidecar-/analyse.sh`)
- [x] Integrate the validated sidecar with the complete syntax projection and
      direct-parser wiring: preserve all 522 records, compile 522 provenance
      dispatch rows, and retain 178 unresolved names (E0074, regenerate with
      `research/experiments/E0074-can-the-accepted-e0072-aliases-integrate/analyse.sh`)
- [x] Classify the remaining 178 names from existing source-provenanced facts:
      18 semantic-role, 8 lexical-class, 1 metavariable, 151 unresolved, and
      no new aliases (E0075, regenerate with
      `research/experiments/E0075-can-the-178-name-post-alias-residue-be-c/analyse.sh`)
- [x] Apply the deterministic normative-prose procedure to the 151 unresolved
      names: 3 source-linked semantic-role candidates and 148 names retained
      unresolved (E0076, regenerate with
      `research/experiments/E0076-how-much-of-the-151-unresolved-residue-h/analyse.sh`)
- [x] Adjudicate the three E0076 candidates: retain all three contextual
      occurrences and add no parser relation (E0077, regenerate with
      `research/experiments/E0077-can-source-controlled-adjudication-separ/analyse.sh`)
- [x] Compose the retained E0077 candidates with the 148-name residue and rerun
      full target integration: 151 source-linked residue rows, 3 retained
      contextual records, 148 records without bounded evidence, 0 parser leaks,
      and byte-stable 522-record integration and dispatch (E0078, regenerate
      with `research/experiments/E0078-can-retained-e0077-candidates-compose-wi/analyse.sh`)
- [x] Use the E0078 composed profile as input to a generated complete-parser
      facade over real source: 72 source-linked complete-source records, 73
      source-linked AST nodes, 68 parent and child links, and one source-linked
      diagnostic (E0079, regenerate with
      `research/experiments/E0079-can-the-e0078-composed-profile-drive-a-g/analyse.sh`)
- [x] Extend the E0079 facade to generated expression and precedence operations
      over a combined real-source corpus: 9 witnesses, 54 source-linked nodes,
      54 parent links, 9 known queries and one rejected unknown query (E0080,
      regenerate with
      `research/experiments/E0080-can-the-e0079-profile-owned-facade-exten/analyse.sh`)
- [x] Inventory source-linked Core 0 semantic relation and constraint
      candidates before formalization: 266 unresolved-name candidate spans,
      287 Core 0-associated numbered constraints, and zero accepted semantic
      facts (E0081, regenerate with
      `research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh`)
- [x] Adjudicate the E0081 candidates into typed StandardIR facts while
      retaining false positives and unresolved records: 10 exact
      definition/relation facts, 256 retained modal candidates, and 287
      unresolved-body constraint records, with no parser projections or model
      calls (E0082, regenerate with
      `research/experiments/E0082-can-source-controlled-adjudication-turn-/analyse.sh`)
- [x] Formalize a bounded set of retained constraint bodies mechanically:
      8 resolved predicates, 279 unresolved records, 18 fact-dependency edges,
      and a validated topological order, with no parser projections or model
      calls (E0083, regenerate with
      `research/experiments/E0083-can-deterministic-predicate-patterns-for/analyse.sh`)
- [x] Expand mechanical predicate formalization to cross-clause constraints:
      6 resolved predicates, 281 unresolved records, 22 fact-dependency edges,
      and a validated topological order, with no parser projections or model
      calls (E0084, regenerate with
      `research/experiments/E0084-can-deterministic-cross-clause-fact-patt/analyse.sh`)
- [x] Test continuation-aware longer alternatives and source references:
      5 resolved predicates, 282 unresolved records, 19 fact-dependency edges,
      and one selected implicit-typing record retained unresolved, with no
      parser projections or model calls (E0085, regenerate with
      `research/experiments/E0085-can-continuation-aware-deterministic-nor/analyse.sh`)
- [x] Preserve a competing formalization as disputed: 2 resolved predicates,
      1 disputed record carrying 2 candidates, 284 unresolved records, and 8
      accepted fact-dependency edges, with no parser projections or model calls
      (E0086, regenerate with
      `research/experiments/E0086-can-the-formalization-ledger-preserve-co/analyse.sh`)
- [x] Compose the four deterministic semantic slices into one 287-row ledger:
      21 resolved, 1 disputed, 265 unresolved, 67 accepted fact-dependency
      edges, and zero adjudication-gate violations (E0087, regenerate with
      `research/experiments/E0087-can-one-composite-semantic-ledger-preser/analyse.sh`)
- [x] Adjudicate the disputed C734 candidate from three independent normative
      prohibition witnesses: the `not-or` predicate, zero independent-oracle
      difference, agreement across two compiler behavioral controls, and zero
      model calls (E0088, regenerate with
      `research/experiments/E0088-can-independent-normative-prohibition-wi/analyse.sh`,
      [D0037](research/decisions/D0037-cross-clause-prohibition-normalization.md))
- [x] Compose the E0088 successor state into a new semantic ledger. E0089
      preserves the predecessor rows, resolves 22 constraints, retains 265
      unresolved constraints, and derives 71 accepted dependency edges
      (regenerate with
      `research/experiments/E0089-can-the-e0088-adjudication-compose-into-/analyse.sh`,
      [D0037](research/decisions/D0037-cross-clause-prohibition-normalization.md))
- [x] Generate the first semantic rule table from all 22 E0089 accepted
      predicates and 22 deterministic dispatch rows. Evaluate C601 on positive
      and negative real-source witnesses with a source-linked diagnostic. Both
      generated checking and gfortran agree (E0090, regenerate with
      `research/experiments/E0090-can-accepted-predicates-generate-a-seman/analyse.sh`)
- [x] Extend operational evaluation to C719, deriving its nonnegative bound
      from the accepted predicate and agreeing with gfortran on positive and
      negative witnesses with source-linked diagnostics (E0091, regenerate
      with `research/experiments/E0091-can-the-generated-rule-table-evaluate-c7/analyse.sh`)
- [x] Generalize the evaluator across `le`, `ge` and `exists`/`ne` constructors
      over C601, C603 and C719. Run six witnesses with six gfortran agreements
      and source-linked results (E0092, regenerate with
      `research/experiments/E0092-can-one-generic-evaluator-execute-three-/analyse.sh`)
- [x] Feed the generic evaluator through one generated structured diagnostic
      operation. Emit six source-linked records with StandardIR locations,
      source-file hashes and predicates, with no selected rule IDs in the
      operation (E0093, regenerate with
      `research/experiments/E0093-can-the-generic-evaluator-feed-a-generat/analyse.sh`)
- [x] Classify all 22 accepted predicate rows with one generic dispatcher over
      9 top-level constructors, retaining 22 provenance matches and rejecting
      an unknown-constructor mutation (E0094, regenerate with
      `research/experiments/E0094-can-one-generic-predicate-dispatcher-cla/analyse.sh`)
- [x] Execute a nested `implies` predicate with generic `and`, `present` and
      `eq` interpretation over true, false and vacuous C721 witnesses, with
      three gfortran agreements and source-linked results (E0095, regenerate
      with `research/experiments/E0095-can-one-generic-evaluator-execute-a-nest/analyse.sh`)
- [x] Execute a nested `not`/`or` predicate with generic `eq` and
      `intrinsic-type-name` facts over C734 witnesses, agreeing with gfortran
      and Flang on all three cases (E0096, regenerate with
      `research/experiments/E0096-can-one-generic-evaluator-execute-a-nest/analyse.sh`)
- [x] Execute C7117 and C7118 through one generic finite-domain `in` evaluator
      over six binary and octal DATA witnesses, with four accepted cases, two
      rejected cases, and six agreements across gfortran and Flang (E0097,
      regenerate with
      `research/experiments/E0097-can-one-generic-evaluator-execute-finite/analyse.sh`)
- [ ] Connect the generated diagnostic operation to the production
      `fortfront-new` frontend. Keep unresolved rows, including C1588, out of
      accepted semantic wiring
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

The E0081--E0097 records are bounded historical semantic measurements. New
semantic formalization, model escalation and frontend work wait at the
D0041/E0098 syntax-closure gate so that the unresolved-name denominator is not
contaminated by an incomplete integration layer.

- [ ] StandardIR constraints, definitions, relations and rules over Core 0
      clauses
- [x] E0083 records subject, applicability, required facts and provided facts
      for a bounded constraint slice
- [x] E0083 derives a fact dependency graph and topological order for the
      bounded slice
- [x] Mechanical formalization patterns first, measured by E0083
- [x] Small-model then larger-model escalation on the residue, one run record
      per attempt including failures
- [x] E0116: complete Qwen 3.6 35B-A3B typed-predicate proposal pass over the
      Core 0 constraint denominator, with replay and mutation gates; E0116 is
      reported and its unresolved/hard-failure residue is retained
- [x] E0117: retain source-backed fact witnesses for every E0116 terminal row
- [ ] E0123: retry the E0117 unresolved/hard-failure residue with exact row-key
      merge, validator, witness and mutation gates
- [x] `unresolved` and `disputed` states exercised on real clauses, not just
      supported in principle (E0085 and E0086)
- [x] Composite adjudication gate preserves the three states and excludes
      disputed and unresolved rows from accepted dependency wiring (E0087)
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
- [x] E0081 deterministic Core 0 semantic candidate inventory recorded
- [x] E0082 source-controlled semantic candidate adjudication recorded
- [x] E0083 deterministic bounded Core 0 constraint formalization recorded
- [x] E0084 deterministic cross-clause Core 0 fact formalization recorded
- [x] E0085 continuation-aware deterministic constraint normalization recorded
- [x] E0087 composite semantic ledger and adjudication gate recorded
- [x] `scripts/index.sh` reports all declared experiments from run records

**Gate.** E0001--E0003 report, from run records rather than by hand: complete
syntax coverage and the fraction extracted with zero model calls, complete
semantic coverage and the fraction formalized mechanically, the minimum model
size per remaining rule, and the comparison-corpus disagreement rates with
adjudications. The comparison report must separate structural grammar
comparisons from behavioral oracle comparisons.

### Deferred paper plan ([D0040](research/decisions/D0040-defer-paper-for-broader-result.md))

- [x] Retire the syntax-only manuscript and submission package
- [x] Preserve its evidence in append-only runs, artifact manifests and
      ignored generated outputs
- [x] Record Christopher Albert as sole planned author
- [x] Record *Nature Computational Science* as the aspirational target
- [ ] Measure the semantic mechanical/model-assisted residue
- [x] Run the deterministic-first source-backed name/evidence campaign across
      the local Qwen/Gemma matrix; retain all failures and publish its matrix
      and convergence plots through the D0059/D0060 slopbox handoff
- [ ] Run the typed-predicate pilot for a genuinely constraining residual rule
      such as C702; retain deterministic schema, provenance and behavioral
      gates
- [ ] Promote only typed semantic predicates that pass source, schema and
      behavioral gates; keep unresolved prose separate from generated wiring
- [ ] Start and validate the generated `fortfront-new` frontend
- [ ] Compare generated infrastructure with established frontends on a real
      Fortran corpus
- [ ] Write the broader manuscript after those measurements
- [ ] Reassess venue fit and submit

---

## Phase 2. `fortfront-new`: generated frontend

Phase 2 is unblocked by the D0041/E0098 mechanical syntax-closure gate and
D0029's selected production-parser boundary. The frontend starts from a
closed, provenance-bearing Fortran profile without requiring a generalized
document-ingestion framework.

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

This is the central implementation roadmap for the future `../fortback-new`
checkout. Do not add a second production roadmap merely to repeat these gates.

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
- Target-specification extraction, provenance, encoders, decoders, register
  metadata, ABI metadata and object writing may proceed before Phase 4 has a
  stable MIR. Backend legalization and instruction selection wait for the
  integrated `mir-v0` contract; neither production lane may redefine it.
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
