# Roadmap

Snapshot: 2026-08-15. Live repository state is reported by
`scripts/status.sh`. Experiment manifests pin the exact commits used by each
result. The lab and `standard-new` checkouts are clean and their current
default-branch CI state is reported separately from those immutable pins.

Live status belongs to each repository. This file records cross-repository
order, the steps in each phase, and the gate that ends it, so that facts are
not copied into several places and left to rot. Any count appearing here names
the command that regenerates it.

**Active critical path.** The next gate is producer-generated profile
correctness, not another model run or parser conflict reduction. The selected
profile must explicitly name its entry rule and target-specific EOF policy in
EBNF, ANTLR4, Bison and tree-sitter. The independent validator is
`research/experiments/E0171-can-current-standardir-grammar-projectio/validate-profile-contract.py`;
its negative control is E0171/R000400. It must pass before any grammar
generator, corpus comparison, semantic extraction, LLM work or backend work
is resumed. This ordering follows D0102 and D0103.

A checked box means the thing exists and was observed working, not that someone
intended it. A phase ends when its gate is demonstrated by a named artifact.

**Current execution checkpoint.** E0125 is accepted as `R000234` at
`standard-new` commit `d8740159f2fcfee359480d77f4391ef1edd0550c`; it scales the
source-backed grammar producer to ordered transactional batches. E0127 is also
accepted as `R000235` at `fortback-new` commit
`fbeedd4c8c232116bdf6e9389f6a698ba7f787b0`, providing a bounded mixed-target
normalized TargetIR table. E0126 is now accepted as `R000236` at
`fortfront-new` commit `d37e7a62d25a168eb9dd54bc79e36ffd410275bf`, providing
language-neutral nullable and first-symbol fixed-point analysis over the flat
grammar table. Neither semantic promotion nor parser/backend wiring is implied
by these slices. E0128 is accepted as `R000237` at `ffc-new` commit
`7691adc1a7b96fef171f9fd0059c89401ad1c4f1`, providing a complete
target-independent MIR opcode histogram over validated function bodies with
no `mir-v0` revision. E0129 is accepted as `R000238` at `standard-new`
commit `25486db92b0805201fa90104dc6f637ecce84942`, providing deterministic
batch export to EBNF, ANTLR4, Bison and tree-sitter with ordered provenance.
E0131 is accepted as `R000239` at `fortback-new` commit
`576c7a4b55aa772e0723b274333dcf411f35071d`, providing transactional mixed
RISC-V/AArch64 source normalization. E0130 is accepted as `R000240` at
`fortfront-new` commit `5fda6dc7858f268ac82cf8ad81e8a1483df4449f`, providing a
bounded parser-neutral frontier that preserves accepted, rejected, ambiguous
and unresolved outcomes. E0142 is abandoned under D0084. Its completed cells
remain immutable evidence; E0115 was stopped at 65 of 127 rows and is recorded
as `R000266`, while E0116, E0117 and E0123 were not started in this campaign.
E0123 is reported as `R000254`: its exact merge, replay validator and witness
gate completed without row loss, but 69 rows remain unwitnessed and 94
disputed, so it promotes no semantic fact and does not close M3.
E0133 is
accepted as `R000241` at `fortback-new` commit
`deb66f94126143d76ea25c1faf197d5150c7c0f4`: no additional parsed family is
currently represented, so the generic batch now has explicit unsupported-shape
and unknown-family transaction controls. E0132 is accepted as `R000242` at
`ffc-new` commit `998ab62d180b4f2940e25d2f987f4f99317c5771`, adding an
independent canonical MIR body round-trip gate and fixing failure-output
clearing without changing `mir-v0`. E0134 is accepted as `R000245` at the
existing `standard-new` commit `25486db92b0805201fa90104dc6f637ecce84942`:
the 519-record accepted composite emits all four grammar formats with 519
provenance annotations, while the three source-only records remain explicit.
The E0142 model gate is frozen. Its results do not establish the next semantic
input because the StandardIR syntax validity gate is open. E0123's
deterministic post-run gate remains complete as `R000254`; its unresolved,
disputed and unwitnessed outcomes remain part of the historical evidence.
E0135 is accepted as `R000247` at `ffc-new` commit
`335629b753f440b2960bf9fef0e6b275094c79ec`, adding a target-independent
in-memory block-range table without revising `mir-v0`. E0136 is accepted as
`R000246` at `fortback-new` commit `403a1ba`, adding a generic exact-source
provenance query over normalized records. Neither adds target/ABI behavior or
silently changes a contract.
E0137 is accepted as `R000248` at `fortfront-new` commit
`d27f2bbc6cde7dc351320e4f3de82a61a8f435d6`. It uses available nullable/FIRST
facts to gate the existing bounded frontier while retaining ambiguity and
unresolved outcomes. This is a frontier transition slice, not complete parser
state or tokenization, and adds no Fortran token policy.
E0138 is accepted as `R000250` at `fortfront-new`
`268e312dbd8ba11cce00d8581479cf47ec077061`: its bounded incremental session
agrees with independent transition traces for accepted, rejected, ambiguous,
unresolved and malformed abstract-token outcomes, with no lexer or
Fortran-specific dispatch. E0139 remains accepted as `R000249` at `fortback-new`
`ba96b13`, adding a generic whole-array query over existing TargetIR-v0 feature
metadata with source/origin preservation and no schema or ISA dispatch.
E0140 is accepted as `R000251` at `ffc-new`
`5ac3cefe88e8c8a3d71d28533c75686712c4a812`: it constructs validated
multi-block partitions by deterministic prefix sums without changing `mir-v0`.
E0141 is accepted as `R000252` at `standard-new`
`5121aa5d79b988c1d0a62bae006288801449f64d`: `sxsemantic` canonically and
transactionally consumes source-backed semantic-items SX, preserving
provenance and explicit resolution states without inferring semantic content.
The parallel production wave is also complete: E0143/R000255 adds
transactional StandardIR grammar-cycle rejection at `standard-new` `cc8a7e1`,
E0144/R000256 makes the generic grammar session push transactional at
`fortfront-new` `db5eaec`, E0145/R000257 adds exact canonical SX-size reporting
at `ffc-new` `3253849`, and E0146/R000258 adds the generic TargetIR source-origin
query at `fortback-new` `a149015`. All four passed full `fo` with zero warnings;
their task branches and worktrees are removed. These slices remain independent
of semantic promotion.

E0147 remains open. The earlier normalization failure and the qualified
reviews remain immutable historical evidence (`R000270`, `R000271`, `R000275`,
and `R000277`). The historical production replay `E0147/R000018` at
`standard-new` `424853273a9c424d0483303478a794090756aa80`: its source-bound
projections, ANTLR4, Bison, tree-sitter and negative-control gates pass, and
the generic lexical repair emits canonical `-` and `'` while retaining the
PDF glyphs. This is still not the final selected-parser gate because E0149
found target factoring, selected-root, lexer-contract, duplicate-lineage and
normalization-witness work remaining. The independent manual comparison is
E0149/R000001 (baseline), E0149/R000002 (post-repair replay), and Luna review
R000281. Regenerate the source replay with
`research/experiments/E0147-can-source-backed-standardir-validity-close/run-source-backed-closure.sh`.

E0142 is abandoned under D0084. The externally managed Qwen 3.8 27B service
at `http://127.0.0.1:8080/v1/chat/completions` remains available for later,
source-valid residual work. No model replication, model comparison, plot
campaign or semantic promotion may resume until E0147 closes the
source-backed StandardIR validity gate. Historical manifests and append-only
runs remain unchanged except for the new stopped-run record `R000266`.

The first valid E0142/E0112 cell is now terminal as `R000262`: strict
pointer-only prompts and validation agree, with 4/4 solved-oracle overlap
agreements, 123 abstentions, zero model errors and zero rejected proposals
over 127 rows. The preceding `R000261` is retained as a harness contract
failure because its prompts allowed target-bearing responses while the
validator required pointer-only responses. The corrected runner and regression
tests are in `1349c81`; no later E0142 cell has been started.

The independent audit recorded in D0083 and expanded by D0084 reopens the
StandardIR syntax validity gate. E0013/E0033 proved structural extraction,
provenance, round-trip and projection reproducibility; they did not prove
faithful right-hand sides. The concrete root causes are page-local
continuation detection, whitespace tokenization, first-character terminal
classification and R-number-only occurrence identity. E0147 is the required
source-backed audit and repair boundary in `standard-new`; no model run may
consume its output as normative grammar before that gate closes.

The unified read-only research library is now the single human-facing browser
for this state. Start it with `scripts/browse.sh serve`; D0082 supersedes the
run-only browser decision D0039. Its overview derives lane percentages from
`research/progress.toml`, its rule register spans StandardIR/semantic/MIR/
TargetIR levels, and its flows/source library connect the standard PDF,
generated grammars, prompts, production source, ISA/ABI/microarchitecture
material and backend. It writes no index or database and does not start work.
The progress numbers are named evidence gates, not code-coverage claims; update
them only when the corresponding gate is accepted and recorded in the ledger.

**Current goal-mode handoff.** E0147's source-validity subgate remains
accepted as `R000267`; the corrected body-bound replay is `R000276` and Luna's
qualified review is `R000277`. The source-backed input replay is
`E0147/R000022`, generated with `--selected-root program`; its four exports,
source-projection witness and negative controls pass after the generic
selected-disposition audit fix. The current production candidate is
`E0151/R000002-candidate` at `standard-new`
`dc75e7f4905e58d9b89d04c77f4f09223b57a579`, with the reachability fix merged
and pushed. Regenerate these runs with
`research/experiments/E0147-can-source-backed-standardir-validity-close/run-source-backed-closure.sh`
and
`research/experiments/E0147-can-source-backed-standardir-validity-close/validate-grammar-exports.sh <run-directory>`.

The selected replay contains 1,068 source alternatives, 1,061 emitted bodies
and six explicitly omitted declared roots accounting for seven omitted
alternatives. Bison reports 427
shift/reduce and 2,266 reduce/reduce conflicts. The all-root replay reports
758 shift/reduce and 3,885 reduce/reduce conflicts. These are target
diagnostics, not language-equivalence claims. R000288 corrected the
validator's useless-symbol metric;
R000289 corrected the explicit omitted-root report; R000285 is Luna's review
of the previous production pin. E0151/R000293 at `standard-new`
`dc75e7f4905e58d9b89d04c77f4f09223b57a579` now removes the four normalized
unreachable targets and seven useless rules generically; the independent graph
and Bison both report zero remaining useless targets. E0151 is reported, with
Luna review R000294. The selected parser milestone remains open because
conflict policy, language preservation and behavioral corpus coverage are not
yet witnessed. A fresh all-root replay at `standard-new`
`9cd164d45a29ef325ea0751496ddd2c2d5b41fc4` (`E0147/R000023`) passes the
four target validators and the body-bound source projection, but reports the
closure diagnostics of 758 shift/reduce and 3,885 reduce/reduce conflicts. It
does not substitute for the selected parser gate.

The first exact selected-root identity replay is E0154/R000308 at
`standard-new` `c8ebb22`. It deliberately fails: the independent witness
covers 1,052 of 1,068 source alternatives in each format, while the negative
mutation is rejected. The failure is now actionable and generic: the
non-ASCII canonical SX hash path disagrees with the UTF-8 oracle, one merged
provenance annotation buffer truncates a long hash list, and synthetic
R401/R402/R403 assumed-expansion records are incorrectly labelled as if they
had normative source RHS expressions. E0154/R000309 records that ANTLR4,
Bison and tree-sitter still accept these files; that subordinate validator
pass does not close identity. No model work resumes while this deterministic
repair is open. D0095 fixes the typed contract: source RHS identity, generated
target identity and explicit source absence are separate values.
Luna's required review R000310 additionally found a generic normalization
projection gap: nullable-reference simplification removes source optionality
from R1404/R1416 without a target-body witness. This is recorded as M048 and
must be preserved or proven generically before the gate closes.

The typed-identity repair is now pushed as `standard-new` `cdec3fa` and its
fresh replay is E0154/R000311. It fixes standalone UTF-8 hashing, long merged
lineage capacity, nullable normalization witnesses and separate target hashes,
but the real closure path still hashes after lexical canonicalization and seven
source alternatives disappear into generated helpers. D0096 is the accepted
next boundary: capture the raw RHS identity before any target normalization,
carry every source alternative through merged/factored output, and emit a
separate typed source-preservation witness when no one-to-one target body
exists. Parser-generator acceptance remains subordinate; no model experiment
resumes until this deterministic gate passes.

That raw-witness boundary is now implemented and pushed as `standard-new`
`83f055d`. E0154/R000314 is the clean replay at lab `65c7b69`: its source
preflight runs before `fo` and all grammar generators; the independent identity
gate then covers 1,068/1,068 source alternatives in EBNF, ANTLR4, Bison and
tree-sitter, with positive and negative controls passing. ANTLR4, Bison and
tree-sitter validators pass after identity succeeds, and the omitted-root audit
explicitly accepts seven annotation-only witnesses for six declared roots.
The exact source-expression gate is closed. The generated Bison grammar still
reports 427 shift/reduce and 2,266 reduce/reduce conflicts; conflict policy,
language preservation and real-corpus behavior remain successor gates. No LLM
or semantic experiment is unlocked by the identity result.

E0155 is the current bidirectional LFortran comparison at pinned commit
`caf87b660f803148f000046392a5da803f9fc630`, using
`research/experiments/E0155-how-does-the-corrected-source-backed-sta/analyse.sh`.
It records genuine StandardIR advantages (normative rule/page/byte/hash
lineage, exact source identity and four-format derivation) and genuine
LFortran advantages (lexer/runtime contract, typed values, actions, precedence,
factoring and explicit conflict budget). It is not a language-equivalence
claim. The comparison also found a real target projection defect: EBNF still
prints U+2013/U+2019 in grammar bodies at the lexical anchors listed in
`research/experiments/E0154-can-exact-source-expression-identity-and/reviews/R000316-luna.md`,
despite D0090/D0091 requiring canonical ASCII target spellings. E0156 is now
the next deterministic gate; no parser-quality, semantic or model work resumes
until every format passes its lexical witness checks. Only after that gate do
we reduce and witness ambiguity and parser behavior without copying reference
productions.

E0156/R000317 now makes the lexical defect independently reproducible at lab
`5350ae7` and `standard-new` `83f055d`: the checker reports 11 raw U+2013/U+2019
occurrences in EBNF executable bodies, while ANTLR4, Bison and tree-sitter each
report zero and pass their canonical target checks. The negative mutation
passes. This is the current production repair slice; no downstream parser or
LLM work is allowed to bypass it.

E0158/R000352 is the current authoritative PDF-fidelity gate: all 522 source
records, duplicate occurrences, source hashes and token/ref leaves agree with
the pinned canonical extraction; the PDF-to-canonical manifest lineage and
R741, R843, R1103, R1307 and R1315 continuation/page-break witnesses pass.
E0157/R000354 is the corrected fresh all-root inventory and minimal Luna
adjudication; its feature rows are source-lineage structural evidence, not
behavior or language equivalence. The first trusted all-root regeneration after
that gate is E0154/R000353 at
`standard-new` `bedd9abc7210fc7fc16607d275ea4fa7b24144f8`: all 1,068 source
alternatives are covered in EBNF, ANTLR4, Bison and tree-sitter, all identity
and lexical mutations fail, and all three parser generators accept their
outputs. It reports 758 shift/reduce and 3,885 reduce/reduce Bison conflicts,
with no useless symbols or undefined references. These diagnostics are the
next parser-quality slice; lexer/runtime, precedence/actions, language
preservation and corpus behavior remain closed gates. No semantic extraction,
LLM experiment, plot, backend or model comparison resumes before those
deterministic gates are addressed.

E0149/R000005 is the current pinned LFortran comparison, regenerated with
`research/experiments/E0149-manually-compare-source-backed-standardi/analyse.sh`.
It uses the selected E0147/R000022 export directly; the analysis script no
longer manufactures a second start condition. M022--M024 record that the
previously alleged R741, R843, R1103, R1307, R1315 and R1416/R1417 defects are
not present in the current source-backed output. M025 is closed by E0151's
generic reachability slice. M026 records a real
LFortran advantage in runtime lexer/actions/precedence/conflict policy, while
M008 and M021 record genuine StandardIR provenance and source-boundary
advantages. E0151/R000293 and R000294 explicitly preserve this bidirectional
comparison. E0150/R000007--R000015 are the current deterministic role-family
probes,
regenerated with
`research/experiments/E0150-can-generic-parser-target-role-factoring/analyse.sh`.
They show that indiscriminate alias factoring is worse, while one mechanically
discovered data-reference family is promising but not yet independently
proven. E0160 now records the typed opt-in mechanism at `standard-new`
`7d011f49e0e74e95b88a90c5894ea3358fc5ee82`: the source-role lineage,
four-format witnesses, mutation controls and parser-generator gates pass on
both all-roots and selected-program replays. The selected diagnostic Bison
inventory improves from 427/2,266 to 425/2,135; the all-roots projection gets
worse, from 758/3,885 to 760/3,894. These counts are regenerated by
`research/experiments/E0159-classify-bison-conflicts/analyse.py` against the
recorded E0160 outputs. E0160 therefore closes only the generic mechanism
subgate. E0161 still must establish independent positive/negative language
preservation before any projection can become a production policy. No
semantic or model work resumes until that source-validity lane closes.
The source audit is regenerated by:

    fo exec --no-build pdfproductions <canonical.text> <pages.index> <productions.jsonl> 1 688
    fo exec --no-build pdfstandardir <productions.jsonl> <standardir.sx> <source-sha256> 5
    fo exec --no-build pdfvalidity <canonical.text> <productions.jsonl> <standardir.sx> <audit.txt>

The complete source-backed replay is:

    research/experiments/E0147-can-source-backed-standardir-validity-close/run-source-backed-closure.sh

The validator can also be rerun against an existing run directory:

    research/experiments/E0147-can-source-backed-standardir-validity-close/validate-grammar-exports.sh <run-directory>

The source-validity subgate is closed, but the selected profile's closure and
export gates are not. Do not resume E0142 or any older model matrix. Luna may
identify grammar-quality defects and harness improvements, but it cannot
rewrite, validate, or promote StandardIR. Any finding must become a generic
deterministic fix, a retained failure, or a decision record before the gate is
re-evaluated.

**Current success path.**

1. Keep the E0147 source-valid syntax baseline immutable and retain both the
   superseded acceptance and the correction failure.
2. Verify that every source-backed alternative is represented by the generated
   projection or explained by a generic provenance-preserving transformation;
   fail closed on dropped or misattributed alternatives. The next concrete
   gate is E0154's exact source-expression identity witness; rule/page/byte
   comments alone are insufficient.
3. Verify every declared root and lexical fact has an emitted or explicit
   deterministic disposition, and require typed hash and origin labels in all
   projections.
4. Run ANTLR4, Bison and tree-sitter in the same command, retain complete logs,
   and preserve Bison conflict and reachability warnings as named metrics.
5. Have Luna inspect the pinned SX input and all four projections with the
   minimal question, “How well does this represent the Fortran 2023 standard?”
6. Fix only generic mechanisms, rerun the complete replay, and append a new
   immutable run record for every correction or review outcome.
7. Add compact source-backed errata only for documented inconsistencies; never
   hand-edit generated grammars or repair a named Fortran rule.
8. Keep duplicate target-body merging with complete source lineage (now in
   `standard-new` `c955c23bd57a078c8fceb30de1df101280b25e2c`), wire the
   source-backed lexer-contract companion into the replay, and generate
   parser-target role factoring and selected-root reachability from generic
   metadata. Selected-root reachability is reported by E0151 and E0160's
   opt-in role-family mechanism passes its source/provenance and generator
   subgates. Applying it to a production profile remains gated by E0161's
   independent positive/negative language corpus. Each transformation needs a
   retained mapping and an independent language/corpus witness (D0092, D0093,
   D0094). D0095 additionally requires source and generated expression
   identities to remain typed and aligned. E0154/R000314 now closes the exact
   identity slice; a real selected-parser corpus or parser-runtime result
   still requires successor conflict, language-preservation and behavior gates.
9. Resume Qwen 3.8 27B only after E0147 closes, on a new source-valid residue
   manifest with deterministic replay and an independent source-span witness.
10. Promote the closed syntax/reference layer into semantic extraction, then
   connect the generated frontend to the production backend contracts.

**Frozen replication checklist — E0142 / Qwen 3.8 27B.** This checklist is
retained as historical protocol documentation. It is not an execution queue.
The campaign stopped under D0084 because its StandardIR-derived task input is
not yet source-valid. E0112, E0113 and E0114 are terminal historical cells;
E0115 stopped at 65 of 127 rows as `R000266`; E0116, E0117 and E0123 are
deferred and must not be started from this checklist:

The row sets are regenerated by the existing commands named in
`research/experiments/E0142-does-qwen-3-8-27b-reproduce-the-bounded-/PROTOCOL.md`
and the pinned E0112/E0113/E0115/E0116/E0117/E0123 scripts; model output never
changes a denominator.

- [ ] Preflight: record model ID/hash, llama.cpp build, quantization, context,
      KV cache, flash attention, sampler, reasoning settings and image
      capability.
- [x] E0112: repeat fixed-pointer residue resolution for all 127 rows
      (**TERMINAL** in `.cache/runs/E0112/R000012/qwen38-27b-pointer-off-a4/`;
      the detached-launch failure is retained as `R000253`, the pre-control-
      harness cell as `R000259`, the insufficient-output-budget cell as
      `R000260`, and the pointer-contract mismatch as `R000261`; the valid
      apples-to-apples result is `R000262`, recorded in the append-only ledger).
- [x] E0113: repeat full-retrieval repair and the six-row solved-translation
      oracle (**TERMINAL** in `.cache/runs/E0113/R000002/qwen38-27b-full-
      retrieval-off/`, recorded as `R000264`; Qwen 3.8 accepted 2/127 rows,
      exactly 2/6 oracle translations, with no hard failures or model errors).
- [x] E0114: repeat the visual-first six-row oracle (**TERMINAL** in
      `.cache/runs/E0114/R000002/qwen38-27b-visual-first-off/`, recorded as
      `R000265`; Qwen 3.8 matched 5/6 targets, with five retained model errors
      and one hard failure).
- [ ] E0115: stopped at 65 of 127 rows, recorded as `R000266`; its preliminary
      accepted count is not a terminal model result.
- [ ] E0116: deferred until a source-valid semantic input exists.
- [ ] E0117: deferred until a source-valid semantic input exists.
- [ ] E0123: deferred until a source-valid predecessor exists.
- [ ] E0147: close the source-backed StandardIR validity audit, reference
      closure, and ANTLR4/Bison/tree-sitter validator gates. `R000276` passes
      the source/projection subgate and `R000277` is Luna's qualified review;
      the current all-root `R000020` and selected-root `R000022` replays pass
      the four-format gates after selected-root disposition handling was fixed.
      E0149/R000005, E0150/R000007--R000015 and E0150/R000306 record the
      comparison and role work; E0151/R000293--R000294 closes generic target
      reachability. Full-profile conflict, language-preservation and corpus
      gates remain open. No model work is
      unlocked by the projection subgate alone.
- [x] E0154: close exact source-expression identity for every selected target
      alternative and helper across EBNF, ANTLR4, Bison and tree-sitter, with
      independent positive/negative mutations. R000308 and R000311 remain the
      retained failed replays; R000313 is the focused repair gate and R000314
      is the clean final replay. This closes source identity and target
      generator acceptance only; it does not claim lexer/runtime,
      precedence/actions, conflict-policy or real-source acceptance
      equivalence.
- [x] E0155: complete the pinned bidirectional LFortran Bison comparison and
      independent Luna review. Record every difference as a StandardIR
      advantage, reference advantage, scope difference or inconclusive result;
      do not copy reference productions. R000315 and Luna R000316 are recorded;
      E0156 tracks the newly exposed canonical-lexical-spelling defect.
- [x] E0156: prove that EBNF, ANTLR4, Bison and tree-sitter preserve the
      original Unicode glyph only in provenance while emitting canonical ASCII
      target spellings. R000318 and the broader post-fidelity R000323 replay
      pass the independent checker and its mutation controls.
- [x] E0157: correct the cross-format/reference inventory and obtain Luna's
      minimal independent adjudication. R000350 records the authoritative
      tree-sitter `r_*` rule count, StandardIR/source-lineage feature
      derivation and the explicit structural-only limitation; R000322 remains
      historical evidence from the previous checker, R000324 is the
      preliminary selected-profile replay, and R000354 is the fresh all-root
      replay with Luna adjudication.
- [x] E0158: pass the authoritative PDF-fidelity gate before fresh generation.
      R000321 checks the original post-fidelity input; R000351 records a
      preliminary strict recheck failure; and R000352 rechecks the exact
      current E0154/R000318 source against all spans, duplicate occurrences,
      all-record token/ref leaves, canonical-text/PDF manifest lineage and
      R741, R843, R1103, R1307 and R1315. R000352 is the authorized gate for
      the next regeneration. No rule-number extractor repair was needed.
- [x] E0159: classify the all-root Bison conflict inventory (758 shift/reduce,
      3,885 reduce/reduce) and compare the result with the pinned LFortran
      conflict policy (238/180 declared conflicts). Add only generic
      inventory categories; R000329 and fresh R000356 confirm the exact state
      totals and LFortran policy. This is inventory-only and does not claim a
      resolution.
- [x] E0160: evaluate the generic typed role-family projection. R000336 and
      R000337 pass source/lexical/lineage mutation gates and all four parser
      generators; the selected profile's diagnostic inventory is 425/2,135,
      while the all-roots projection is worse at 760/3,894. The independent
      full-profile language corpus was deliberately not claimed.
- [x] E0161: compare baseline and opt-in selected exports on an independently
      enumerated positive/negative parser corpus. R000340 covers the selected
      root, the typed representative and all automatically discovered common
      role-family contexts: 359 complete bounded positives and 636 negative
      mutations, with no mismatch or truncation. The command is
      `research/experiments/E0161-can-an-opt-in-role-family-projection-pre/run-language-gate.sh`.
- [x] E0162: adjudicate all four generated formats against the pinned
      references after the corrected E0157 audit. R000346 confirms identical
      canonical EBNF/ANTLR4 heads, classifies 672 Bison `h_*` helpers plus six
      target wrappers and seven tree-sitter lexical wrappers, and preserves
      source identity in both variants. Reference head counts remain
      structural evidence, not language equivalence.
- [x] E0163: classify the selected Bison conflict states against pinned
      LFortran policy and adjudicate generic role-family factoring. R000347
      confirms the selected candidate improves 427/2,266 to 425/2,135 while
      E0161 preserves 359 positive and 636 negative cases. The all-roots
      candidate is 760/3,894 versus 758/3,885 and is therefore not promoted;
      no expression-precedence rewrite is inferred from this result.
- [x] E0164 selected deterministic checkpoint: consume the complete
      source-backed `standardir-grammar-v0` closure and pass bounded runtime
      behavior. R000363 emits 1,220 selected rows from the raw syntax,
      R401/R402/R403 classifications and lexical facts; R000369 independently
      verifies 0 missing references, 0 lineage failures, mechanical origin and
      resolved status on every row. R000364 is the current PDF-fidelity gate;
      R000365 regenerates all four formats and runs ANTLR4, Bison and
      tree-sitter; R000367/R000370 accept two positive and reject two negative
      runtime witnesses. `fortfront-new` `7ab3df0` passes all 26 tests and full
      `fo` with no production-slice warnings.
- [ ] E0164 broad behavior successor: extend the independent positive/negative
      parser corpus over the selected generated runtime and expand lexical
      coverage beyond the five currently declared lexical facts. The bounded
      E0161 359/636 and E0041 10/10 results remain upstream evidence; they do
      not silently become a full-runtime claim. This is still deterministic
      production work, not a lab-side parser or a model task.
- [x] E0165: test a rule-independent parser-quality candidate only after the
      trusted source/PDF gates. The global common-prefix candidate passes source
      identity and generator smoke but worsens all-root Bison conflicts from
      758/3,885 to 948/4,572, creates useless selected rules and triggers a
      Bison assertion. R000360 rejects it; `standard-new` is reverted to the
      baseline projection at `8d5ee41`. No precedence rewrite is justified.

- [x] E0167: correct and replay the cross-format/reference audit after the
      deterministic source gate. Tree-sitter counts only `r_*` grammar heads
      (664 in the current output); generated feature presence is the
      intersection of StandardIR rule IDs and emitted source lineage; Flang is
      separately compared through the same IDs and its 195 retained `R####`
      comments. R000371 and Luna's `reviews/R000371-luna.md` pass the bounded
      structural audit. The report is
      `.cache/runs/E0167-audit-replay-v2`; it does not claim language
      equivalence.
- [x] E0168: replay the authoritative PDF-fidelity gate against the exact
      current source used for the four-format output. R000372 passes all 522
      source spans, 20 duplicate families/40 occurrences, all token/ref leaves,
      page continuation handling, R741/R843/R1103/R1307/R1315, PDF lineage and
      the negative mutation. No extractor repair or rule-number exception is
      justified.
- [x] E0169: compare the current Bison target controls with LFortran. The
      generated file is GLR and source-lineage-bearing but has no precedence
      declarations or actions; LFortran has 11 precedence directives, typed
      actions and a declared/observed 238/180 policy. The current StandardIR
      selected inventory is 427/2,266 and is retained as unresolved parser
      quality evidence. The exact report is
      `.cache/runs/E0169-lfortran-comparison.tsv`; D0100 records why no
      precedence or `%expect` rewrite is promoted.
- [ ] E0170: close target correctness without weakening source fidelity. First
      implement the executable lexer/runtime and broader positive/negative
      corpus gates. Then test only source-derived production transformations:
      the selected-only role-family projection remains opt-in after E0163;
      precedence/actions require a production-level witness and independent
      all-root plus selected language preservation. Do not add `%expect`, copy
      LFortran controls, or promote a lower conflict count without behavior.
- [x] E0171: replace the misleading structural “match reference parser
      quality” claim with explicit evidence levels. R000388 is the corrected
      identity-replay inventory; R000393 is the producer-emitted selected
      Bison counterexample inventory. They pass source/generator structural
      gates and retain reference hashes, but prove neither language
      equivalence nor parser quality. D0102 now requires explicit root/EOF,
      lexer-contract, transformation, bounded behavior and conflict-
      classification witnesses before those claims can be made.

D0084's source-validity priority now extends through the E0164 selected
deterministic checkpoint and its broad-behavior successor. No semantic
extraction, model comparison, backend work or plotting is valid evidence until
the broad runtime/corpus gate closes. D0081 remains the plotting boundary for
a later campaign; historical rows remain visible, but no new model row is
scheduled now.

E0164/R000348 and R000349 remain historical narrow evidence. The current
selected deterministic checkpoint is R000363--R000370: the source-backed
contract has 1,220 rows and zero missing references; the current four-format
outputs cover 1,068/1,068 source alternatives; the executable runtime accepts
two positive and rejects two negative witnesses; and the independent checks
pass. The current pushed production pins are `standard-new` `8d5ee41`,
`fortfront-new` `7ab3df0`, `ffc-new` `3253849`, and `fortback-new` `a149015`.
M2 remains open for broad generated-runtime corpus behavior, full lexical
coverage, conflict policy and language preservation. No semantic, LLM,
backend or plotting work is unlocked.
E0142 is abandoned; E0123's deterministic post-run gate is
reported as `R000254`, and the production slices do not close semantic
promotion.

E0152 is now reported as the corrected cross-format inventory gate. Its
reproducible command is
`research/experiments/E0152-can-cross-format-grammar-inventories-and/analyse.sh
.cache/runs/E0152/R000001`. The four exact generated exports share 650
comparable source-derived heads, 1,191 provenance headers and 1,031 unique
lineage identifiers; the inherited source projection reports 1,061/1,068
alternatives covered, seven explicitly skipped, zero missing and zero header
gaps. The corrected structural counters are EBNF 1,188, ANTLR4 1,197, Bison
2,286 and tree-sitter 1,231 alternatives. These are not language scores. The
analysis now verifies generated/reference/source evidence hashes and exact
lineage sets. Its Luna review is `E0152/R000296`.

E0152 also exposed two gates that must not be hidden by a validator PASS. The
current source-projection check is body-bound rather than an expression
identity witness, so D0087/D0088 remain open; and the StandardIR input uses
`source-sha256` for canonical extracted text while the artifact manifest pins
the PDF hash. The hashes are different evidence objects and must be typed
distinctly at the production serialization boundary. Flang's pinned LLVM
parser source is derived from the Fortran 2018 draft, so its 199 `Rxxx`
comment occurrences are comparison evidence, not a Fortran 2023 denominator.

E0153 is the current manual LFortran adjudication, rerun against the E0151
candidate rather than the stale E0149 output. Its command is
`research/experiments/E0153-can-a-current-standardir-selected-export/analyse.sh
.cache/runs/E0153/R000001`, and its 26-row inherited matrix plus current rows
records all seven source anchors, the selected-root boundary, source lineage,
lexer/runtime, precedence, actions, role factoring, extensions and language-
equivalence limits. It records a genuine StandardIR advantage—typed
normative lineage and one source feeding four exports—and genuine LFortran
advantages—executable lexer/actions, typed values, precedence, factoring and
conflict policy. It does not claim a winner or close M2; Luna review is the
required next record. The expanded R000002 audit now records thirteen feature
surfaces with exact source/reference locations, copies and hashes its source
evidence, and confirms the comparison is bidirectional. It does not claim a
winner or close M2; the current remaining gaps are target/runtime and witness
gaps, not the stale R741/R843/R1307/R1315/R1416--R1418 defects.

The first generic role-family factoring implementation in E0150 was rejected
by R000299--R000305 for lineage, witness, oracle, lint and size defects; those
failures remain in the ledger. The repaired and reviewed commit
`standard-new` `9cd164d45a29ef325ea0751496ddd2c2d5b41fc4` is now merged and
pushed. It is opt-in and does not silently change the normative StandardIR or
claim full language equivalence.

The comparison is explicitly bidirectional. LFortran, Flang, gfortran and the
other reference artifacts are independent evidence, not authorities. A finding
is recorded as an advantage of StandardIR when it demonstrates a stronger
property with cited evidence—for example normative source lineage, preserved
source occurrences, or one source projected to several formats. A finding is
recorded as a reference advantage when the reference supplies a property we do
not yet have, such as executable lexer/runtime behavior or parser factoring.
Neither direction is inferred from raw counts or from the fact that one file
looks more familiar. Every claimed advantage needs a named property, an
evidence location and a next action or explicit disposition.

The reusable local runner now sends llama.cpp's per-request
`chat_template_kwargs.enable_thinking` control for both reasoning modes and
derives the strict response schema from the prompt manifest. The first retry
also exposed a prompt-generation/validator pointer-contract mismatch; that
cell is retained as `R000261`, and the regenerated strict prompt set produced
the valid `R000262` result. E0142 is frozen and has no later cell to launch;
any future Qwen run requires a successor manifest after E0147.

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
producer/consumer implementation wave is integrated for the declared
source-witness handoff. This contract is an input to deterministic generation;
it is not itself a parser and does not authorize copying grammar payloads into
the frontend.

The typed consumer boundary from D0076 remains integrated at `fortfront-new`
`49dd337728df9bbcc451042ed11a26842f92341b` as `R000228`. The source-backed
producer boundary remains integrated at `standard-new`
`071acf5cc23200441b28309b50a6c8ccd5922e0e` as `R000229`. E0124 then connects
the actual source-side structured production records to the contract at
`standard-new` `4b7b0650db93b32636398e33f6be86c89c685d5e` (`R000232`) and
reads the canonical contract SX into the typed frontend consumer at
`fortfront-new` `fe3dde3d1fabf89055d7c2494892b243fd4df0b9` (`R000233`). Both
passed the declared positive and negative witness gate, including nested
structure, alternatives, provenance, origin/resolution and output clearing.
E0124 is accepted for its declared witness denominator; full-document
production and parser generation remain open. Neither slice adds PDF
heuristics, aliases, parser dispatch or semantic facts.

The scale wave runs from the pushed checkpoint `06a9859`. E0125 is accepted at
`standard-new` commit `d8740159f2fcfee359480d77f4391ef1edd0550c` (`R000234`):
the source-backed grammar producer now batches ordered records transactionally
and preserves the single-record result, provenance and failure clearing. E0126
is accepted at `fortfront-new` commit
`d37e7a62d25a168eb9dd54bc79e36ffd410275bf` (`R000236`): its language-neutral
analysis computes nullable and first-symbol fixed points over the flat table,
with explicit unresolved and overlapping-first states. E0127 is accepted at
`fortback-new` commit
`fbeedd4c8c232116bdf6e9389f6a698ba7f787b0` (`R000235`): its bounded table
preserves mixed-target order and provenance and reuses generic lookup/codecs.
Neither slice adds parser/token dispatch, semantic promotion, ISA mnemonic
branches, ABI/MIR wiring or a new cross-repository contract. E0129 is accepted
as `R000238` at `standard-new` commit
`25486db92b0805201fa90104dc6f637ecce84942`: it batch-emits the four declared
grammar formats from normalized records, preserving rule/alternative order and
source annotations. It retains the existing emitter boundary and rejects
unresolved/disputed rules, interleaved LHS groups and unsupported normalized
shapes. E0131 is accepted as `R000239` at `fortback-new` commit
`576c7a4b55aa772e0723b274333dcf411f35071d`: it batches the existing RISC-V and
AArch64 source families transactionally into the generic TargetIR table while
preserving provenance and rejecting all declared controls. Neither E0129 nor
E0131 adds PDF parsing, comparison-grammar copying, parser dispatch, ISA
mnemonic branches, ABI/MIR wiring or a new cross-repository contract.

The parallel backend slice is integrated at `fortback-new`
`c68bf54844fbdbb79f012c5e5e977dacc6301ce2` and recorded as `R000230`. It
adds a generic private SX round trip for normalized TargetIR encoding records,
including target/operation identity, fixed and ordered variable fields and
provenance, with malformed, range, capacity and output-clearing controls.
`D0077` keeps this representation private until a second production consumer
requires a versioned serialized TargetIR contract; it does not add ISA
dispatch, ABI, MIR or instruction selection.

`D0078 <research/decisions/D0078-scale-reusable-mechanisms-before-more-witnesses.md>`
now governs the post-witness order: scale reusable batch, fixed-point and
table mechanisms before adding isolated instruction, token or accessor
witnesses.

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
E0123 is reported as `R000254` from
`.cache/runs/E0123/R000001/summary.json` and
`.cache/runs/E0123/R000001/analysis/report.json`, generated by the E0116
`run-semantic.py` command and the deterministic post-run gates. All 53 retry
rows were processed, the exact 53-row replacement set was verified, all 287
rows were merged, and the negative control failed as expected. The merged
ledger has 280 schema/source-gate-accepted rows, 4 hard failures and 2
unresolved rows; the witness gate reports 69 unwitnessed and 94 disputed rows.
No semantic fact was promoted. E0142 was the planned Qwen 3.8 27B replication,
but D0084 stopped it because its source task layer is not yet source-valid.
These semantic results remain historical controls and do not define the next
input.

D0073 fixes the repair boundary for this and later semantic runs: deterministic
processing may repair transport representation, but may not rewrite predicate
operators, invent facts, infer missing nesting or substitute evidence. The
model must receive the rejection and submit a bounded replacement; every
attempt remains retained.
D0074 adds compact, generic constructor-shape examples to successor prompts
after the E0123 predecessor's repeated nesting and fact-versus-literal gate
errors. It does not relax validation or change E0123's pinned prompt.

The semantic extraction boundary is now explicit. Deterministic processing
extracts definitions, numbered constraints, cross-references, source spans,
fact vocabulary and dependency candidates from canonical standard text;
repeated source forms compile mechanically. Qwen receives one local residual
task and bounded source tools, and returns only a typed local fragment. It may
not invent fact names, citations, dependencies or wiring. Schema, provenance,
replay and independent witness gates decide acceptance; a schema-valid model
proposal is not itself a semantic fact. Qwen 3.8 27B will apply this boundary
only after E0147 produces a source-valid residual, in a new successor
manifest that retains every attempt, failure, timing, token count and
unavailable visual cell.

D0075 fixes the next lexer boundary: source-defined lexical facts remain
source-backed data queried by generic code, while processor-defined facts are
explicit non-match/unsupported results until a separate target policy exists.
The frontend may not hardcode Fortran token names or reread the PDF. The first
production lookup slice is integrated in `standard-new` and recorded as
`R000215`; the active frontend task consumes this boundary without importing
the sibling repository at build time.

The current production pins after the latest bounded integration wave are
`standard-new` `25486db92b0805201fa90104dc6f637ecce84942`,
`fortfront-new` `d27f2bbc6cde7dc351320e4f3de82a61a8f435d6`, and
`fortback-new` `ba96b13`; these are clean
`main` branches with coordinator-side full `fo` verification. The FFC pin
is `335629b753f440b2960bf9fef0e6b275094c79ec`.

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

### M1. Normative syntax extraction (historical structural gate; validity reopened)

The pinned J3/24-007 PDF yields the historical numbered syntax span as
provenance-bearing StandardIR, and the canonical SX round-trip plus the EBNF,
ANTLR4, Bison, tree-sitter, and direct-parser projections are reproducible.
Those are structural gates, not a proof that every right-hand side faithfully
matches the PDF. D0083 reopens the validity gate for page continuations,
punctuation tokenization, occurrence handling and independent source-span
witnesses.

### M2. Closed syntax and sane selected generated grammars (validity pending)

The historical closure and projection reports exist, but the complete
selected Fortran syntax profile is not yet accepted as faithful. Before this
milestone can close again, every referenced name must be accounted for as an
explicit production, an R401/R402/R403 assumed expansion, a lexical fact, a
fixed erratum/token operation, or a source-backed semantic-only fact, and the
new D0083 validity audit must pass. An explicitly unsupported profile feature
is a separate exclusion decision, not a hidden resolution.

The selected production parser inputs—EBNF, ANTLR4, Bison and tree-sitter—are
structurally sane. They retain provenance, contain no unresolved symbols, and
pass their target validators without fatal errors. The three validators run in
the same automatic procedure; a target-specific rewrite or a hand-maintained
conflict list is not a gate. Target warnings remain reported as evidence under
D0030, and any warning that indicates lost source structure or unresolved
symbols blocks this milestone. The direct parser has no dispatch collisions,
and its generated source compiles. A production parser export additionally
has a selected root, deterministic reachability dispositions, a companion
lexer contract, generated role factoring and normalization witnesses; the
all-root closure grammar alone cannot close M2.

### M1/M2 recovery sequence: source validity before model use

E0147 is the next gate. The implementation belongs in `standard-new`; the lab
owns the denominator, decision, manifest and run evidence. The production
repair is one generic pipeline with these boundaries:

1. Preserve canonical source evidence. Each production occurrence keeps its
   raw lines, page rectangles, byte start and end, source rule and document
   hash. A span may cross a page boundary. Page headers, footers and prose are
   classified as layout or boundary records, not discarded before the grammar
   parser sees them.
2. Record occurrences before canonicalization. The identity key is the source
   document hash, source byte span and occurrence ordinal. The normalized
   production key is separate. Repeated identical occurrences, repeated
   definitions and conflicting occurrences become explicit outcomes.
3. Lex the notation with a source-independent token policy. The lexer must
   separate punctuation, delimiters, Unicode operators, ellipsis, quoted
   terminals and identifier-like metavariables even when the PDF has no spaces.
   It must retain the raw lexeme and emit `unclassified` when policy cannot
   decide. Capitalization and first-character tests are not grammar meaning.
4. Parse notation before assigning StandardIR semantics. The parser produces a
   lossless notation tree. A declared normalization table then maps only
   supported alternatives, sequences, optional groups, repetition, terminals,
   references and standard list forms into StandardIR nodes. A failed mapping
   remains rejected or unresolved with its source witness.
5. Audit continuation and source coverage independently. The audit compares
   every accepted normalized expression with its complete canonical source
   span. It has positive witnesses for same-page, cross-page, page-furniture,
   punctuation, Unicode, ellipsis and list cases, plus mutation controls that
   must fail when a continuation, token boundary or span is changed.
6. Classify the reference closure. Every reference is reported as a numbered
   production, lexical fact, R401/R402/R403 assumed syntax, fixed D0025 erratum,
   semantic-only name or unresolved. An unresolved reference is a measured
   state. It is not silently converted into a parser alias.
7. Generate exports only from `source-valid` records. EBNF, ANTLR4, Bison,
   tree-sitter and the direct parser receive the same accepted StandardIR
   stream. A deterministic closure pass supplies only source-backed implicit
   records. Generic target projection may simplify nullable wrappers, remove
   duplicate alternatives and eliminate left recursion, but may not contain a
   rule-specific repair. Identical target bodies are emitted once only when
   their complete source lineage is merged. Role aliases may be factored only
   when generated metadata preserves the role set. Each export must retain
   source provenance, pass its own validator, and report warnings and
   unsupported constructs separately.
8. Close M1 and M2 separately. M1 closes when source spans, notation and
   occurrence identity pass the independent audit. M2 closes only when the
   selected reference profile is classified and every selected export passes
   its target gate. Historical structural exports remain available for
   comparison but cannot close either gate.

E0149 is the required independent comparison before this gate can close. Its
replay command is
`research/experiments/E0149-manually-compare-source-backed-standardi/analyse.sh`.
The immutable E0149 baseline confirmed two target defects: U+2013 was emitted
as an `EN_DASH` target terminal rather than canonical source `-`, and U+2019
was emitted as `RIGHT_SINGLE_QUOTE` rather than canonical source `'`. D0090
and D0091 are implemented in `standard-new` `424853273`; E0147/R000018 proves
the generic repair across the four projections. The remaining E0149 findings
are target/projection gaps: duplicate source bodies need merged lineage, the
all-roots Bison export is a closure validator rather than a parser entry point,
selected-root output needs explicit reachability dispositions, a lexer
contract must be declared separately, role aliases need deterministic target
factoring (D0092), and normalization needs language-preservation witnesses
(D0093). E0149 inventories every production head and alternative count in
`production-coverage.tsv`, but its LFortran comparison is not a one-to-one
language-equivalence or conformance oracle. Luna's review is
`research/experiments/E0149-manually-compare-source-backed-standardi/reviews/R000281-luna.md`.
No model or semantic experiment is unlocked by this audit. Its status is
`verification_failure` until the generic selected-target fixes and witnesses
replay cleanly.

The Qwen 3.8 27B path starts after step 8. It receives only the bounded
source-backed residue produced by this pipeline. It may propose a typed local
interpretation or unresolved state. Deterministic source checks, provenance,
replay and independent witnesses decide acceptance. It never repairs the
complete grammar, chooses wiring or changes the denominator. Semantic M3 work
may be designed in parallel, but no result is promoted into compiler wiring
until M1 and M2 are closed.

### M3. Source-backed Core 0 semantics (pending)

The M3 model lane is frozen by D0084 until M1 and M2 have a source-valid
StandardIR input. The paragraphs below record historical experiments and
their gates. They are not an execution queue. The next Qwen 3.8 27B task is a
new residual-resolution experiment created after E0147, not a continuation of
E0142.

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

E0123's model execution is complete: it retried E0117's 53 unresolved or
hard-failure rows with Qwen 3.6 35B-A3B, retained the other 234 rows as
immutable controls, and wrote `.cache/runs/E0123/R000001/summary.json`.
The summary is generated by the E0116 `run-semantic.py` command and reports 47
schema-accepted proposals, four hard failures and two unresolved rows. Its
deterministic validation, witness and exact row-key merge gates remain
pending. D0073 still forbids semantic rewrites during that post-run gate.

E0142 is abandoned. The next M3 execution plan is conditional: close E0147,
construct the source-valid residual and then create a new Qwen 3.8 27B
successor cell with the source-span and witness gates intact.

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

**Historical syntax-closure projection (E0098 and D0029, structurally complete;
source-validity reopened by D0084):**

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

E0098 closes the historical source-side reference projection: 469 explicit
reference classes, 100 assumed expansions, 5 lexical facts, 8 errata, and zero
unresolved or disputed parser names in that projection. It does not establish
that the extracted right-hand sides or source spans are faithful. EBNF,
ANTLR4, Bison and direct wiring pass their historical structural gates.
Tree-sitter still has the documented target-specific conflict after the
compact one-group extension; D0029 makes that export non-gating. Regenerate with
`research/experiments/E0098-can-the-current-complete-standardir-proj/analyse.sh`.
E0147 must independently re-establish source validity before this projection
can feed a normative parser.

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
- [x] E0123: complete the already-run residual retry's exact row-key merge,
      validator, witness and mutation gates (`R000254`); retain its unresolved,
      disputed and unwitnessed outcomes and promote no semantic fact
- [ ] E0142: abandoned under D0084 after E0115 was stopped at 65 of 127 rows;
      do not restart its matrix
- [ ] E0147: close the source-backed StandardIR validity gate before any new
      semantic model cell; E0149/R000005 is the current comparison and defect
      inventory, regenerated with
      `research/experiments/E0149-manually-compare-source-backed-standardi/analyse.sh`
- [x] E0150: finish the opt-in generic parser-target role-factoring mechanism
      with source-record lineage, selected-root protection, complete witness
      validation, independent bounded language preservation and all four target
      exports. It is merged in `standard-new` `9cd164d`; full-profile
      application and corpus equivalence remain M2 gates.
- [x] E0149: compare the source-backed Bison projection against the pinned
      LFortran parser architecture, inventory every production head, classify
      all observed divergences, retain the repaired lexical baseline, and
      record both genuine StandardIR advantages and genuine reference
      advantages. The remaining target issues are carried by D0092/D0093/D0094,
      E0150 and the current Luna review.
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

## Current deterministic grammar checkpoint

E0156 is reported and accepted by `R000318`. The generic EBNF lexical repair
is pushed at `standard-new` `bedd9abc7210fc7fc16607d275ea4fa7b24144f8`, and
the lab gate-order change is pushed at `9618213`. The replay command is:

```text
research/experiments/E0154-can-exact-source-expression-identity-and/run-selected.sh \
  .cache/runs/E0154/R000318 program .cache/runs/E0154/R000314
```

Its order is now fixed: source-only preflight, `fo`, four projections, exact
source-expression identity, canonical lexical witness gate, then ANTLR4/Bison/
tree-sitter parser oracles. A failed gate stops the later stages. R000318
reports 1,068/1,068 source alternatives in each format, zero raw U+2013/U+2019
in executable bodies, passing positive and negative controls, and passing
ANTLR4, Bison and tree-sitter validation. Bison still reports 427
shift/reduce and 2,266 reduce/reduce conflicts; this is the next open parser
quality problem, not a source-extraction or lexical-lowering failure.

E0157's deterministic audit and Luna review are complete. E0162 reran that
audit against the exact pinned LFortran file and independently compared the
four generated formats with the house ANTLR4, kaby76 ANTLR4, pinned LFortran
Bison and Flang parser evidence. E0171/R000388 corrected the interpretation:
this is a structural inventory only. It classifies StandardIR advantages in
normative lineage and exact source identity, reference advantages in parser
factoring/actions/precedence/conflict policy, and target-only scaffolding. No
reference production was copied, and no language-equivalence or parser-quality
claim follows from head counts, generator acceptance or conflict totals.

E0157 is now reported from the authoritative fresh replay `R000354` (the
initial inventories, R000322 and selected-profile R000350 remain retained).
The fresh all-root four generated outputs share exactly 1,111 source-lineage
values. EBNF and ANTLR4 report 665 heads, Bison 1,346 including helpers, and
tree-sitter reports 670 `r_*` grammar heads; its five uppercase lexer
definitions are reported separately rather than counted as grammar rules.
Feature presence is derived from parsed
StandardIR `lhs`/rule IDs intersected with emitted source-lineage metadata,
not from terminal text search. StandardIR remains stronger in normative
provenance, exact source-alternative identity and four-format derivation; the
references remain stronger in executable lexer/runtime integration, factoring,
actions, precedence and conflict policy. This is structural evidence, not
language equivalence.

The audit's reference-name adjudication is now explicit input rather than
hidden Python state. E0157/R000396 reads and hashes
`research/experiments/E0157-current-cross-format-and-llvm-reference-audit/reference-feature-anchors.tsv`
and emits a per-feature/per-reference MATCH table. Its
`source-and-reference-anchor` label means that at least one named reference
grammar exposes the mapped structural head; it does not mean universal
support. `NO_ANCHOR_DECLARED` is an unmade mapping, not a negative language
result. The replay command is the `analyse.sh` command in the E0157 findings;
the output directory is `.cache/runs/E0157/R000396-anchor-input-replay`.

The authoritative PDF-fidelity gate E0158 is revalidated as `R000364` against
the exact current E0154/R000353 source, with R000352 retained as the earlier
authoritative record. It checks all 522 source byte spans and canonical
rule-definition occurrences, all 20 duplicate rule families, and
representative continuation/token-ref witnesses R741, R843, R1103, R1307 and
R1315. It also checks all-record token/ref leaves, source hashes, and the
canonical-text/PDF artifact-manifest lineage. The PDF hash and negative
mutation pass; 46 surface-only optional-plus-ellipsis differences are reported
explicitly. No generic extractor repair is indicated.

E0165 tested the next generic parser-quality candidate only after those trusted
gates. The candidate preserved source identity and generated all four formats,
but increased all-root Bison conflicts to 948/4,572, produced useless selected
rules and triggered a Bison internal assertion. R000360 records the rejection;
`standard-new` was reverted to `8d5ee41`. No precedence rewrite or global
factoring is justified. The accepted parser policy remains D0089 GLR plus the
validated opt-in role-family specialization from D0092/E0163. E0164/R000363--
R000370 now close the selected contract/runtime checkpoint; broad runtime
corpus behavior and full lexical coverage remain open.
D0099 records the generic runtime policy: source occurrences remain in the
contract, while only exact duplicate generated bodies may be coalesced and all
generated names are bounded deterministically.

The current deterministic sequence is therefore: PDF fidelity; source-backed
contract closure; four-format regeneration and parser-generator oracles;
explicit target-root/token/transformation witnesses; Bison conflict
counterexamples and classification; generated-runtime positive/negative
witnesses; then the broad runtime corpus and lexer expansion. Only after that
sequence is complete may semantic extraction, LLM/model comparisons, plots or
backend work resume. A structural inventory never substitutes for a behavioral
gate.

The transformation-witness subgate is now closed by E0171/R000399. The
producer-emitted selected Bison target and its JSONL witness have equal 1,068
source-lineage sets, including pre-lowering and reachability omissions; the
independent validator reports zero missing or extra lineages. The production
commit is `standard-new` `2c2cc7f55640304769c431c0bfdc13961aad2daf`, and the
replay command is recorded in the E0171 manifest. The next open gates are the
declared root/EOF and lexer contract, bounded language behavior, and then
conflict classification; no conflict resolution is inferred from this
provenance result.

The first replay of the explicit profile contract is intentionally red:
E0171/R000400 rejects the pre-fix R000385 outputs. The Bison wrapper alone is
not enough; ANTLR4 and tree-sitter currently rely on target defaults, and EBNF
has no full-input wrapper. `standard-new` must emit the generic selected-root
wrapper and profile metadata for every target, followed by this independent
validator. The next green replay will then regenerate the four targets and
rerun the parser-generator oracles.

E0170 is the active runtime gate. R000377 exposed a real nontermination defect
in the old global-rescanning evaluator, and R000378/R000379 are retained
rejected repairs. D0101 now fixes the implementation boundary: the next
production slice must use a finite deduplicated chart/worklist evaluator with
predictor, scanner and completer transitions, indexed waiting/completed states,
and explicit preservation of epsilon, recursion, ambiguity and unresolved
outcomes. No iteration, depth or state cap may be used as a correctness fix.
The focused independent suite comes before the unchanged 995-case replay; the
experiment's timeout is only a safety guard. The exact algorithm decision is
in `research/decisions/D0101-finite-chart-runtime-evaluator.md`, and its
primary parsing references are listed in `docs/literature.md`.

R000380 is the first replay of that evaluator on the complete 995-case corpus.
It fixes the exact `allocate-object` witness and completes nine root batches
with zero observed mismatches, but the `program` root exceeds the 60-second
safety guard after 90 outcomes; `variable` is not started. The gate therefore
remains open. R000381 then showed that a longer isolated `program` replay can
finish, but 52 cases were compared in different lexical token domains
(`letter` versus generated target token `LETTER`). R000382 removed those false
mismatches with a generic pinned lexical-facts adapter and exposed two separate
issues: GLR `ambiguous` outcomes were incorrectly counted as binary failures,
and the EBNF exporter emitted unescaped quote literals that caused genuine
`malformed` outcomes. The runner now compares boolean acceptance as
`accepted | ambiguous` versus `rejected`, retains an explicit ambiguity count,
and keeps malformed/unresolved/capacity outcomes failing. The generic EBNF
escaping correction is merged in `standard-new` at
`fb6590c4885a38b0106f63112f6e024c20b927b5`. R000385 regenerated E0164 with
the corrected metadata and lexer-contract oracle; R000386 then passed the
complete 1,003-case replay with zero mismatches, zero abnormal outcomes and
zero warnings. The deterministic selected lexer/runtime gate is closed. The
56 preserved ambiguous outcomes remain a parser-quality metric; they do not
close language equivalence or semantic validation.

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
