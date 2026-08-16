# E0171 findings

E0171 was narrowed from “match reference parser quality” to an evidence-level
audit. That wording was wrong: head counts and generator acceptance are not a
parser-quality measure, and a reference grammar is not a normative oracle.

## R000388: corrected structural inventory

The corrected analyzer compares the same trusted generated run under two
explicit identity-replay labels. It no longer calls one input a
`role-family-candidate`, and it does not infer a behavioral result from the
comparison.

The source-backed and generator gates pass for both replay roles:

| evidence | result |
|---|---|
| source alternatives | 1,068/1,068 |
| generated formats | EBNF, ANTLR4, Bison, tree-sitter |
| source-lineage sets | equal |
| ANTLR4/Bison/tree-sitter generators | pass |
| negative controls | retained by the upstream run |
| reference hashes | verified |

The structural inventory reports 659 EBNF heads, 659 ANTLR4 heads, 1,337
Bison heads and 666 tree-sitter heads. The Bison and tree-sitter additions are
target scaffolding identified by the inventory; they are not defects or proof
of equivalence. The pinned references differ substantially in factoring,
lexer ABI, actions, precedence, extensions and parser root policy. Those
differences require classification and behavioral witnesses, not name-count
matching.

Artifacts are under:

```text
.cache/runs/E0171/R000388-evidence-level-inventory/
```

Regenerate with:

```text
python3 research/experiments/E0162-can-all-four-standardir-grammar-projecti/analyse.py \
  .cache/runs/E0164/R000385-four-format-regeneration \
  .cache/runs/E0157/R000354 \
  .cache/runs/E0164/R000385-four-format-regeneration \
  .cache/runs/E0157/R000354 \
  ../standard/grammars/src/Fortran2023Parser.g4 \
  ../kaby76-fortran/comp/Fortran2023Parser.g4 \
  .cache/runs/E0162/reference/parser.yy \
  ../llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  <ignored-output-dir> \
  --left-label identity-replay-a --right-label identity-replay-b
```

## What was rewritten

The corrected procedure now has separate gates for source fidelity, target
well-formedness, transformation provenance, bounded language behavior, parse
structure and reference comparison. E0159 must consume a producer-emitted
selected grammar; it may not rewrite `%start` in a copied file. Bison
counterexamples are retained for conflict analysis, but conflict totals and
LFortran’s `%expect` values remain diagnostics rather than correctness goals.

The next gate is therefore not “reduce the count to LFortran’s count”. It is a
machine-readable transformation map plus independent positive/negative
behavioral witnesses for the selected root and lexer profile.
R000399 closes the transformation-map part; the behavioral witness remains
open.

## R000393: corrected Bison audit

The Bison analyzer now consumes the producer-emitted selected `program` file
directly. It refuses an all-root or otherwise unlabelled file rather than
editing `%start` to manufacture a profile. It runs Bison with state, solved-
conflict and counterexample reports and retains the generated stderr/output.

The result is:

| profile | shift/reduce | reduce/reduce | result |
|---|---:|---:|---|
| selected `program` | 427 | 2,266 | inventory |
| all roots | 758 | 3,885 | inventory |
| pinned LFortran | 238 | 180 | declared policy matches observed |

The report is under
`.cache/runs/E0171/R000393-bison-evidence-audit/`. The totals are unchanged,
which is expected: the audit procedure changed, not the grammar. The retained
counterexamples are diagnostic evidence for the next conflict-classification
slice; they are not a correctness denominator and do not justify copying
LFortran’s `%expect`, precedence declarations or actions.

## Transformation-witness negative control

The independent lab validator is
`validate-transformation-witness.py`. It compares the producer-emitted JSONL
witness with the `source-lineage` set in the exact generated target and checks
JSON shape, target hashes, source-hash policy and profile consistency.

It correctly rejects the first production witness replay: the target contains
1,068 source lineages, while the witness contains 1,064. The four missing
lineages are:

```text
R1028:1@492928+28
R1221:1@748220+82
R1221:2@748220+82
R1323:1@849508+55
```

They are retained in the generated target as `omitted-before-target-lowering`
source-preservation records. This is a producer defect, not a source or PDF
defect. The witness implementation must serialize that existing pruned
provenance generically; the four rule IDs are a failure witness, not an
exception list. R000399 below makes the validator pass and closes the
transformation gate.

## R000399: transformation witness closure

The production fix reuses the existing source-disposition collector and emits
the pre-lowering omissions in the same JSONL witness stream. The independent
validator now passes on the exact producer-emitted selected `program` target:

| evidence | result |
|---|---:|
| target source lineages | 1,068 |
| witness source lineages | 1,068 |
| missing/extra lineages | 0 / 0 |
| witness rows | 1,198 |
| target transformations | 666 normalized, 471 identity, 40 merged-provenance, 10 generated-helper |
| omitted transformations | 7 pre-lowering, 4 reachability |
| target/witness hashes | valid |

The target grammar is byte-identical to the trusted R000385 Bison output. The
production commit is `standard-new` `2c2cc7f55640304769c431c0bfdc13961aad2daf`,
and full `fo` passes with zero warnings. This closes the deterministic
transformation-provenance gate only; it does not establish language or
parse-tree equivalence.

## R000400: profile-contract negative control

The independent profile validator was run before any parser generator on the
pre-fix R000385 selected output. It correctly rejects the output because the
four artifacts do not share a checked entry/EOF contract: EBNF has no explicit
wrapper, ANTLR4 has no `standardir_start : r_program EOF` entry, and
tree-sitter's first grammar rule is `r_letter`. Bison's existing
`standardir_start` wrapper is recognized, but that one passing target does not
make the profile green. The normalized five-row lexer contract remains green.

The policy and validator are:

```text
research/experiments/E0171-can-current-standardir-grammar-projectio/profile-policy.tsv
research/experiments/E0171-can-current-standardir-grammar-projectio/validate-profile-contract.py
```

This is a retained negative control, not a claim against PDF extraction. The
producer fix must make the selected profile pass this gate before parser
generators are invoked again. Source preflight, identity and lexical checks
remain the gates that precede production of the four artifacts. The validator uses bounded line-oriented
inspection rather than whole-file backtracking; its own runtime is part of the
reproducibility boundary.

## R000401: explicit profile replay reaches a tree-sitter target defect

The selected profile emitted by `standard-new` `ca210a8` passes all four
profile rows and the normalized five-row lexer contract. Source preflight,
identity and lexical witnesses also pass. ANTLR4 4.13.2 and Bison 3.8.2 accept
their outputs; Bison reports the same 427 shift/reduce and 2,266 reduce/reduce
diagnostics as the prior inventory.

Tree-sitter 0.26.9 rejects the generated target because non-start `r_block`
matches the empty string. The source reason is a generic nullable production,
not a defect unique to `block`; the source rule is retained only as a failure
witness. Tree-sitter's documented restriction means the projection needs a
generic nullable-rule elimination/lowering pass, with provenance for every
propagated or omitted alternative. No parser conflict or language result is
promoted from this failure.

## R000402: nullable lowering passes, target conflict remains

The generic nullable lowering from `standard-new` `4ffa985` removes the
previous tree-sitter empty-non-start rejection. Source preflight, identity,
lexical, profile, ANTLR4 and Bison gates remain green, and the Bison inventory
remains 427 shift/reduce plus 2,266 reduce/reduce diagnostics. The lowering
also passes the production transformation-witness tests and the selected
target retains all 1,068 source alternatives in the independent identity
witness.

The full tree-sitter generator now stops at an unresolved conflict for `SAVE`
followed by `LETTER`, between `r_save_stmt` and `r_saved_entity_list`. This is
the expected next evidence level: nullable target lowering is no longer the
blocker, but tree-sitter conflict policy and language preservation are still
open. The witness is not converted into a precedence declaration or a
target-specific exception. The next slice must classify these conflicts
against Bison counterexamples and the declared lexer/profile contract, then
apply only a generic, witnessed target policy.

## R000403: the replay harness now checks the exact producer witnesses

The corrected replay requests `--transformation-witness` on every producer
invocation and validates the resulting JSONL against the exact EBNF, ANTLR4,
Bison and tree-sitter files before running parser generators. All four formats
cover 1,068/1,068 source lineages. The first three have 1,198 witness rows;
tree-sitter has the same source coverage plus its generic nullable-lowering
rows. These counts are regenerated by `run-selected.sh` and the four
`validate-transformation-witness.py` invocations in the run directory.

The source, lexical, profile and witness gates pass. ANTLR4 and Bison pass;
tree-sitter still fails on the unresolved `SAVE`/`LETTER` conflict. This is a
useful failure, not a source-fidelity failure: the previous replay had allowed
the transformation-witness assertion to come from a separate run. R000403 was
generated before the timeout hardening and is retained. R000404 repeats the
same command from the committed harness and is the authoritative replay.

## R000404: clean committed replay confirms the harness boundary

R000404 uses lab commit `2b6add8` and the unchanged producer commit
`4ffa9859a6af551a9ceb1d45bc5744a1522e135e`. The four producer-emitted
transformation witnesses again cover 1,068/1,068 source lineages, and the
source, lexical, profile and witness gates pass before parser generators run.
ANTLR4 and Bison pass; Bison reports 427 shift/reduce and 2,266 reduce/reduce
diagnostics. Tree-sitter 0.26.9 still fails only on the unresolved `SAVE` /
`LETTER` conflict. The exact artifacts and hashes are in the append-only
R000404 run record. The next work is conflict classification under D0105, not
another source-extraction or model run.

## R000405: conflict evidence is normalized; the lexer contract is incomplete

`normalise-conflict-witness.py` consumes the pinned selected-profile Bison
counterexample table and the exact R000404 Tree-sitter diagnostic. It produces
767 unclassified records: 766 Bison counterexample groups and one Tree-sitter
diagnostic. The counts are regenerated by that script; the lossless logs and
the generated grammar remain the evidence.

The Tree-sitter record names `r_save_stmt` and
`r_saved_entity_list`, whose source lineages are R859 and the mechanically
derived R401 list. The selected Bison table contains the corresponding
`LETTER` reduce/reduce witness with R859 in the source lineage set. Bison's
retained first and second derivations use the same abstract token prefix and
therefore establish ambiguity in the current token/profile contract.

This is not yet evidence that the Fortran source language is ambiguous. The
current normalized lexer contract has five rows and no statement-termination
event. It cannot distinguish `SAVE X` in one statement from `SAVE` followed by
a new statement beginning with `X`. The provisional classification is
`lexer/profile-interaction-candidate`, not an accepted target policy. The next
gate must add independent statement-boundary and keyword/name behavior
witnesses, then rerun the exact generated profiles. No Tree-sitter `conflicts`
entry, associativity, precedence or Bison `%expect` is justified by this run.

R000405 contained the same artifact but an invalid manually typed lab commit
pin. It is retained as an immutable failed record; R000406 supersedes it with
the committed normalizer pin and changes no evidence or classification.

## R000407: the normative source confirms the missing lexer contract

The source-anchor replay uses:

```text
for p in $(seq 1 688); do
  pdftotext -f "$p" -l "$p" -layout .cache/j3-24-007.pdf -
done
```

with the checked-in rows in `statement-boundary-anchors.tsv`. The source
anchors are clause 4.1.4, page 45 (statement classes are delimited by
end-of-line or semicolon), clause 5.5.2, page 65 (statement keywords are not
reserved and same-spelling names are allowed), and clause 6.3.2.5, page 72
(an uncontinued free-form statement is terminated by comment or end of line).
The PDF hash in every row is the pinned J3/24-007 hash.

This confirms that the `SAVE`/`LETTER` witness cannot be resolved from the
current five-row lexical contract. The missing information is normative source
behavior, not a Tree-sitter-specific exception. The production slice must
therefore add a versioned target lexer contract and independent boundary/name
behavior witnesses while leaving StandardIR syntax unchanged.

## Contract boundary after R000407

D0107 defined the central `contracts/lexical-layout-v0.sxs` companion
contract. It has three source-backed record families: statement boundaries,
continuation signals and keyword/name policy. `scripts/check-contracts.sh`
validates the schema, fixture, registry entry and negative control at lab
commit `3bed17d`. This is an interface gate, not a grammar result: the
production consumer, its positive and negative behavior witnesses, and the
replayed parser targets remain open. No conflict declaration is justified by
the contract's existence alone.

## R000408: production consumes the layout contract

`standard-new` commit `0a293b6ce8c970d042bb1bcc9e1f88454ba337da` adds the
target-neutral `standardir_lexical_layout` projection and `sxlexicallayout`
producer for the exact `lexical-layout-v0` interface. Its independent test
covers all three record families, source provenance, invalid enum/field
rejection, duplicate facts, distinct facts sharing one source anchor and
JSONL emission. The full `fo` pipeline is green with zero warnings. The task
worktree and branch were removed after the main-branch replay.

This closes only the interface/projection gate. It does not yet extract the
facts from the PDF, feed them into the generated parser, establish positive
and negative source behavior, or classify the `SAVE` / `LETTER` conflict.

## D0108 correction before source extraction

Review of the v0 projection found a provenance defect: its `source-ref`
required `rule`, although all three layout anchors are prose clauses. The
production test consequently supplied synthetic rule labels. R000408 remains
an immutable record of that v0 behavior, but it is not evidence of faithful
provenance. D0108 supersedes it with `lexical-layout-v1`, using `locator` for
the mechanically located paragraph or phrase and `all` for form-independent
facts. The source-backed producer and the next production replay must use v1.

## R000409/R000410: source phrases produce v1 layout facts

The table-driven extractor `extract-lexical-layout.py` verifies the pinned PDF
hash, strips only printed page-number columns, normalizes whitespace across
PDF line breaks, and checks each phrase on its declared page. The pattern table
contains the source-specific phrase witnesses; the extractor contains no
grammar rule-number branches. It emitted nine facts from pages 45, 65 and 72,
both as an anchor TSV and as v1-compatible SX. Re-running against the same
output paths is rejected, preserving append-only run directories.

`standard-new` commit `a08760554bddaff9bb82db76ffcfe1d8733117b0` consumed the
generated SX. Its v1 header, locator provenance, form-independent keyword fact,
and all nine records passed the independent projection test and full `fo`
pipeline. R000409 contained manually mistyped hashes for the committed pattern
and extractor files; R000410 corrects those metadata pins without changing the
artifacts or result. This closes source discovery and projection only. The
generated parser targets still do not consume the layout contract, and no
positive or negative source behavior has yet adjudicated `SAVE` / `LETTER`.

## R000411: v2 carries statement applicability

The pattern table now includes the clause 4.1.4 fact that syntactic classes
ending in `-stmt` follow the source-form statement rules. The extractor emits
ten facts, including `(statement-class-suffix ... (suffix -stmt) ...)`, and
`standard-new` commit `4479a23fd680bdcc9af19bb7e3a606b22f1fd787` consumes the
result with a version-2 header. This prevents a later target generator from
silently hard-coding the suffix relation. Generated parser targets still do
not consume the contract, and the `SAVE` / `LETTER` behavior gate remains
open.

## D0110: boundary lowering must follow source-derived sequence topology

The useful comparison with LFortran is architectural rather than textual. Its
lexer produces newline/comment separator tokens and its generic statement rule
consumes a separator around a complete statement. That is materially different
from adding an EOS token to every StandardIR class whose name ends in
`-stmt`. The latter would put a boundary inside nested `IF (...) action-stmt`
and would encode a source-form exception as a target rule.

The next artifact is therefore a deterministic statement-sequence witness. It
will compute statement-bearing repeated contexts and first-item-plus-repeated
contexts from the StandardIR expression graph, retain the expression path and
source facts, and reject unsupported/ambiguous contexts. It is not a conflict
declaration. The four target generators and parser behavior gates remain behind
that witness and an independent separator/continuation/keyword behavior gate.

## R000415: statement-sequence witness closes the shape inventory

`derive-statement-sequences.py` reads the source StandardIR records and the
v2 layout facts. It computes statement reachability and nullable symbols by
fixed point, then records repeated direct items, first-item-plus-repeat
boundaries, and compound repeated items such as `(case-stmt block)`. The
source input has 189 statement-reachable classes and 58 candidate boundary
rows. The five compound shapes that the first pass reported as unsupported are
now represented generically; the replay reports zero unsupported rows.

The fixture tests cover a nested `IF (...) action-stmt` shape and a compound
`(case-stmt block)` repeat. The result is still only a structural witness. It
does not prove that a target lexer emits or consumes the right separator at
each boundary, so the independent positive/negative behavior gate remains
open. Reproduce it with:

```
python3 research/experiments/E0171-can-current-standardir-grammar-projectio/test-derive-statement-sequences.py
python3 research/experiments/E0171-can-current-standardir-grammar-projectio/derive-statement-sequences.py <standardir.sx> <layout-facts.sx> <output.tsv>
```

R000416 supersedes R000415 after an audit noticed that the first output kept
page and byte offsets but not the complete source document, clause and source
hash on every row. The successor retains all of those fields and has the same
58-row, zero-unsupported result.

## R000419: adjacent sequence boundaries are included

D0111 extends the witness beyond repeat sites. The table-driven source replay
now emits `sequence-internal` rows after a direct statement class whenever the
remaining sequence is nullable or statement-bearing. This adds the boundaries
inside `if-construct`, `case-construct`, `select-rank-construct`,
`select-type-construct`, and `where-construct`, while the nested `action-stmt`
in `if-stmt` remains a final child and receives no inner boundary.

The replay has 95 candidate rows, zero unsupported rows, and complete source
lineage on every row. R000416 is retained as the earlier repeat-only evidence
and is superseded by this successor. This is still a structural witness; the
independent source behavior gate and production/full-corpus parity remain open.

R000420 supersedes R000419 after a review tightened the adjacent-boundary
predicate: the suffix is scanned left-to-right, allowing only nullable material
before the next statement-bearing expression. A required non-statement payload
therefore cannot create a false boundary. The full source result remains 95
rows with zero unsupported shapes.

## R000421: production topology projection is fixture-green

`standard-new` `2b13568` now contains the typed production projection of the
same D0111 analysis. Its focused test covers direct and adjacent boundaries,
compound repeats, nested action-statement exclusion, deterministic derivation
ordering, malformed RHS rejection, source-form scope, and retained rejected
rows with source provenance and status. The full `fo` pipeline passes 44 tests
with zero warnings.

This is deliberately not recorded as full-corpus parity. The production API
has not yet been driven over the 522-source-record input and compared row for
row with R000420. That is the next deterministic gate before any grammar
generator consumes the witness.

The bounded behavior cases are now pinned as
`research/corpora/statement-boundary-behavior-v0.toml`. They are not a grammar
source: the future gate generates their payloads in the ignored run cache and
compares the generated target with independent parser behavior. The cases keep
newline, comment, semicolon, continuation, same-line `SAVE name`, nested
`IF (...) action-stmt`, and missing-separator rejection separate so a passing
aggregate cannot hide a wrong boundary class.

## R000426: independent source behavior oracle

The first source-level replay exposed an invalid fixture: `SAVE` is a
specification statement and cannot be the `action-stmt` of a single-line IF.
The corrected nested-action cases use `CONTINUE`. A second replay then exposed
undeclared `x` in the `SAVE name` cases; declaring it before the SAVE statement
removed that semantic confounder without changing the boundary property.

R000426 generates the nine source cases from the manifest recipes and runs
them through GNU Fortran 16.1.1, Flang 22.1.8 and LFortran 0.58.0. All seven
expected accepted cases and both expected rejected cases agree. The report is
`.cache/runs/E0171/R000426-statement-boundary-behavior/behavior.tsv`; reproduce
it with:

```text
python3 research/experiments/E0171-can-current-standardir-grammar-projectio/run-statement-boundary-behavior.py \
  research/corpora/statement-boundary-behavior-v0.toml \
  <ignored-output-directory>
```

This closes only the independent source-language oracle. It does not close the
generated lexer/runtime gate, which must consume the R000423 statement witness
and reproduce these outcomes before grammar conflicts are adjudicated.

## R000427: the typed boundary plan is green, insertion remains open

`standard-new` `d2835f4` adds a typed statement-boundary plan. Its validator
preserves source rule/LHS, canonical expression path, candidate kind,
derivation, complete source lineage and the stable boundary marker. It rejects
malformed paths, missing lineage, unsupported statuses and exact duplicate or
ambiguous source sites. Distinct source occurrences with the same rule and
path remain distinct when their source byte positions differ. The focused test
and the complete `fo` pipeline pass with 46 tests, lint/format clean and zero
warnings. Reproduce the production gate with:

```text
(cd ../standard-new && fo test test_standardir_statement_boundary && fo)
```

The plan intentionally reports `insertion_supported=false`. It is not a lexer,
parser or target grammar result. Mapping source paths through target
normalization is the next production boundary.

The required Luna review then identified two truthful-status repairs for the
next slice: generic exporters must not label arbitrary partial input as
`Fortran2023`, and serialized byte offsets must be ordered numerically. It also
confirmed that the plan's deliberate non-insertion boundary is appropriate.
D0113 records those repairs; no downstream grammar or model run was started.

## R000428: review repairs pass

The successor production replay at `standard-new` `107d7a3` closes those
review findings. Boundary plans now require a 64-hex source hash and sort
validated byte offsets numerically. The generic ANTLR and tree-sitter exporters
use `StandardIR`/`standardir` identities, and the README states that the
complete normative corpus is not committed in the production repository and
that semantic storage is not semantic coverage. The focused and full `fo`
gates pass with 46 tests, lint/format clean and zero warnings. A coordinator
CLI smoke over the 522-record source emits 502 ANTLR and 502 tree-sitter
productions with the neutral tree-sitter identity.

This closes truthful labeling and plan validation only. It does not authenticate
the source document inside production, map paths through target normalization,
insert separators, or establish lexer/parser behavior.

## R000429: raw-source boundary mapping closes the selected witness

`standard-new` `54700a2` adds a read-only `sxstatementboundarymap` CLI and a
reusable raw-SX source mapper. The mapper matches the complete source
occurrence lineage, navigates the canonical path before alternative flattening,
and records the raw node kind, name, pre-order index and selected alternative.
The CLI retains candidate, suppressed and unsupported input rows as explicit
dispositions and rejects unknown statuses.

The replay uses the 522-record StandardIR SX input from R000404 and the
95-row candidate witness from R000420. It produces exactly 95 data rows:

```text
mapped       95
ambiguous     0
unsupported   0
suppressed    0
```

R1505 is the required raw-alternative control: `rhs/1/1` maps to
`function-stmt` and `rhs/2/1` maps to `subroutine-stmt`. The final output is
`.cache/runs/E0171/R000429-source-boundary-mapping/mapping-final.tsv` and has
no trailing whitespace. Reproduce it after a clean production build with:

```text
(cd ../standard-new && fo clean && fo)
(cd ../standard-new && fo exec --no-build sxstatementboundarymap \
  ../lazy-fortran-new/.cache/runs/E0171/R000404-clean-witness-replay/input/standardir.sx \
  ../lazy-fortran-new/.cache/runs/E0171/R000420-statement-sequence-candidates/candidates.tsv \
  ../lazy-fortran-new/.cache/runs/E0171/R000429-source-boundary-mapping/mapping-final.tsv)
```

The mapper output is in deterministic plan order. The independent review in
R000430 found six reordered rows for duplicated source definitions (`R1532`,
`R1537` and `R1541`) when compared with the witness's original order. This is
not a loss because the audit key is the complete row set, but the result is
not an order-preserving replay. The output's byte locations are locators; they
do not authenticate the PDF or include extracted source text. The 95 rows are
the selected statement-boundary denominator, not the complete 502-record
syntax corpus and not semantic coverage.

## R000430: independent Luna review confirms the bounded claim

The read-only Luna review confirms raw path fidelity, source-lineage retention,
and the R1505 alternative control. It accepts the claim “95/95 selected
boundary sites mapped” and rejects any broader claim that the Fortran 2023
grammar is 95/95 mapped or that the result proves language equivalence,
parser behavior, target insertion, lexer completeness, or StandardIR PDF
fidelity. The remaining target and authenticity gates stay open.

## R000431: selected source boundaries join the generic target trace

`standard-new` `2fef265fe08543828f5574026babbcdd2d0a91df` adds an opt-in
correspondence witness. It retains source occurrence lineage, normalized
target paths, transformation names, source and target expression hashes, and
explicit `mapped`, `suppressed`, `ambiguous` or `unsupported` dispositions.
The producer fails closed for unsupported recursion and serializes a stable
JSONL contract rather than asking a later audit to infer correspondence from
rule names or hashes.

The replay uses the 522-record StandardIR SX input and the 95-row raw source
boundary witness. The audit command is:

```text
python research/experiments/E0171-can-current-standardir-grammar-projectio/audit-correspondence-witness.py \
  .cache/runs/E0171/R000429-source-boundary-mapping/mapping-final.tsv \
  .cache/runs/E0171/R000431-correspondence-witness/correspondence.jsonl \
  .cache/runs/E0171/R000431-correspondence-witness/joined.tsv \
  .cache/runs/E0171/R000431-correspondence-witness/summary.json
```

The audit produces exactly one target-trace row for each of the 95 selected
boundary rows: zero missing and zero multiple joins. The selected rows are:

```text
mapped        86
suppressed     9
ambiguous      0
unsupported    0
```

The nine suppressions are explicit generic `rule-deduplicate` transformations
with empty target paths and slot zero. They are not silently treated as
mapped. The complete trace has 4,053 mapped, 715 suppressed, 85 unsupported
and zero ambiguous rows. The replay generated 4,853 valid 26-field JSONL rows
in deterministic order and took approximately 94 seconds after a clean
production build. No parser generator or format oracle was run in this gate.

This closes only the bounded source-lineage join. It does not yet establish
that a suppressed source occurrence points to its retained target occurrence,
nor does it prove target insertion, lexer behavior, parser behavior or PDF
fidelity.

## R000432: independent Luna review of the correspondence witness

The read-only GPT-5.6 Luna review checked all 4,853 rows, the 26-field
contract, nonempty 64-hex hashes, deterministic ordering and the full join.
It confirmed 95 one-to-one joins with no zero or many matches, 86 selected
mapped rows, nine explicit suppressions, and no selected ambiguous or
unsupported rows.

The review also fixed the evidence vocabulary. `source_hash` is the canonical
StandardIR source-text hash, not a PDF hash. `source_expression_sha256` and
`target_expression_sha256` are alternative-level hashes; `input_expression`
and `output_expression` hashes identify transformation-node inputs and
outputs. The fields are useful only with those scopes stated.

The accepted bounded claim is: the selected 95-row witness has a deterministic
source-lineage-preserving correspondence relation through the current generic
normalizer, with explicit suppression rather than fabricated target paths.
The next gate is to connect the nine suppressions to retained target
occurrences. Parser generators remain downstream and were not run.

## R000435: corrected correspondence replay exposes duplicate candidate identity

The replay was regenerated from the corrected source-provenance StandardIR at
`standard-new` `30c973f`. The selected mapping still has 95 rows and every row
finds one trace row, but the corrected audit now includes `source_node_kind`
and reports only 71 distinct structural source keys: 24 groups contain 48
duplicate rows. These are generic derivation overlaps, including
`first-plus-repeat` and `repeat-item` naming the same source node and path.

The correspondence trace has 4,871 rows in 37 fields. Its full disposition
counts are 4,069 mapped, 717 suppressed and 85 unsupported; the selected
95-row subset is 86 mapped and 9 `rule-deduplicate` suppressions. The full
trace has 124 retained target relations, and all 124 `rule-deduplicate` rows
have one. The audit status is `FAIL` because duplicate structural candidate
keys are not yet resolved; its selected subset counts must not be mistaken for
whole-trace quality.

Reproduce the corrected audit with:

```text
python research/experiments/E0171-can-current-standardir-grammar-projectio/audit-correspondence-witness.py \
  .cache/runs/E0171/R000435-correspondence-replay/mapping.tsv \
  .cache/runs/E0171/R000435-correspondence-replay/correspondence.jsonl \
  .cache/runs/E0171/R000435-correspondence-replay/joined-v2.tsv \
  .cache/runs/E0171/R000435-correspondence-replay/summary-v2.json
```

This is a useful deterministic failure: no downstream grammar generator or
parser oracle was run, and no source candidate was silently discarded.

## R000436: independent Luna review keeps the correspondence gate open

The read-only GPT-5.6 Luna review confirms the 37-field contract, numeric and
hash validation, 95 selected joins, and complete retained provenance for the
nine selected rule-deduplication rows. It rejects the stronger phrase “95
one-to-one source boundaries” because the input contains 24 duplicate
structural-key groups. It also notes that the trace does not carry the
candidate derivation kind, so the current join cannot distinguish those
evidence rows.

The review supports only this bounded statement: every selected candidate row
has one deterministic lookup result under the current structural key, and the
nine selected rule-deduplication rows retain source/target provenance. Before
separator insertion, the pipeline must either carry complete candidate
identity through the generic trace or coalesce equal structural boundaries
while retaining all contributing derivations. D0119 records that boundary.
