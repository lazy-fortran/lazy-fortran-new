# E0149 manual Bison audit

Reproduce the deterministic inventory with:

```text
research/experiments/E0149-manually-compare-source-backed-standardi/analyse.sh \
  .cache/runs/E0149/R000001
```

The post-repair replay is:

```text
research/experiments/E0149-manually-compare-source-backed-standardi/analyse.sh \
  .cache/runs/E0149/R000002 E0147/R000018
```

`R000001` is the immutable pre-repair baseline. `R000002` is a new observation
against `standard-new` `424853273a9c424d0483303478a794090756aa80`; neither run
edits the other. The checked-in `comparison-matrix.tsv` is the manual anchor
ledger: 21 rows across 10 lanes. The generated `production-coverage.tsv` is
the complete production-head inventory for both files, with a deterministic
lane and normalized-head correspondence label for every production head. This
is exhaustive as an inventory and divergence ledger, not as a claim that the
two differently factored grammars have a one-to-one language equivalence.
The script reruns Bison and reports the distinction explicitly.

## Result at the pinned baseline

The pinned StandardIR export has 1,346 production heads and 2,835 production
alternatives, including 675 generated helper heads. The pinned LFortran file
has 234 production heads and 1,023 alternatives. The difference is expected:
the two grammars factor names, lexical tokens, separators, expressions and
implementation actions differently.

Both files compile with Bison. The StandardIR all-root closure grammar has
758 shift/reduce and 5,033 reduce/reduce conflicts. A replay with `r_program`
as the selected start has 427 shift/reduce and 3,357 reduce/reduce conflicts,
plus 10 useless nonterminals and 514 useless rules. LFortran has 238
shift/reduce and 180 reduce/reduce conflicts and no useless output. These
counts are diagnostic evidence, not a normative language comparison.

The high StandardIR reduce/reduce count has a concrete cause visible in the
Bison states: normative semantic-role aliases such as `object-name`,
`procedure-name`, `type-name`, `array-element`, `coindexed-named-object` and
`structure-component` often reduce through the same `name` or `data-ref`.
LFortran collapses these parser categories and distinguishes them later while
building its AST. The correct response is a generic parser-target
specialization that preserves role metadata in StandardIR; it is not to erase
the roles from the source IR or copy LFortran's grammar.

## Post-repair replay

The two definite target defects in the baseline are repaired by the generic
lexical spelling change in `standard-new` commit
`424853273a9c424d0483303478a794090756aa80` (the agent implementation was
`d4ec7ed`). R000018 retains U+2013 and U+2019 as source facts and emits the
canonical Bison spellings `-` and `'`. ANTLR4, Bison, tree-sitter and the
source-projection witness all pass in the replay. The target names
`EN_DASH` and `RIGHT_SINGLE_QUOTE` remain provenance labels; they are not the
source spellings.

The baseline matrix keeps M005 and M006 as historical `target_defect` rows.
Their current status is `repaired`, not an outstanding StandardIR defect.

## Current replay after generic lineage merging

The historical replay is E0149/R000003, regenerated with:

```text
research/experiments/E0149-manually-compare-source-backed-standardi/analyse.sh \
  .cache/runs/E0149/R000003 E0147/R000020
```

It uses `standard-new` `c955c23bd57a078c8fceb30de1df101280b25e2c`, including
the generic duplicate-body lineage merge and the companion lexer-contract
projection. The all-root Bison export remains valid and reports 758
shift/reduce and 3,885 reduce/reduce conflicts. The selected `program` replay
reports 427 shift/reduce and 2,266 reduce/reduce conflicts before selected
reachability pruning. These are target diagnostics, not language-equivalence
claims. The source-backed selected replay E0147/R000022 is the authoritative
four-format validation of the selected export.

The lineage merge is a genuine target improvement: repeated identical target
bodies are emitted once while all source occurrences remain in the lineage.
The corresponding source-projection audit now treats explicitly omitted
selected roots as dispositions, so omission is not confused with source loss.

## Remaining defects and gaps

The comparison also records these generic follow-up gaps:

* The separate source-backed lexer-contract companion now exists in
  `standard-new` `c955c23bd57a078c8fceb30de1df101280b25e2c`; the selected replay
  still needs to invoke it and pin its output beside each parser export. A
  parser `.y` file can declare terminals, but it does not itself define how
  `LETTER`, `DIGIT`, `REP_CHAR` and source spellings reach `yylex`.
* Identical target bodies from repeated PDF occurrences should be emitted once
  with all source lineage, not as repeated alternatives.
* The all-root grammar is a closure validator. The selected-root export and
  deterministic post-normalization reachability pass now exist in
  `standard-new` `dc75e7f4905e58d9b89d04c77f4f09223b57a579`; behavioral and
  language-preservation witnesses remain open.
* Left-recursion removal, list expansion, nullable helpers and role-alias
  factoring need generic language-preservation witnesses.
* The generated Bison target should record a generated conflict policy or
  budget after selected-root generation exists, rather than comparing raw
  conflict counts to LFortran's hand-maintained `%expect` values.

These are target/projection issues, not evidence that the source-backed
right-hand sides are wrong. The next production change is therefore a generic
target specialization and witness lane, not a manual repair of a named
Fortran production.

## Differences that are not defects

LFortran's `units` and `script_unit` intentionally accept partial sources and
extensions. Its expression grammar is flattened and uses Bison precedence
directives. Its parser carries AST actions, separator/trivia handling and
implementation-specific forms. StandardIR's numbered categories and exact
optionality are therefore not expected to have one-to-one names or bodies.
The matrix records these differences instead of “fixing” StandardIR toward
LFortran.

## Positive results

StandardIR is already better for this project's provenance question: every
retained source-backed alternative carries J3-24-007 rule, page, byte and
source-hash lineage, while the pinned LFortran Bison source has no equivalent
normative provenance. StandardIR also keeps the clean source boundary: it does
not copy LFortran actions or extensions into the normative IR. Those are
genuine advantages, but not claims of parser runtime superiority.

The audit therefore does not say “LFortran wins.” It says that LFortran has a
more mature parser-oriented target factoring, while StandardIR has stronger
normative provenance and source coverage. The next work is to generate that
parser factoring deterministically from StandardIR and prove the normalization
classes with independent witnesses. The LFortran file is a parser-engineering
reference only; J3-24-007 remains the normative adjudicator.

## Current selected replay and explicit stale-critique check

The source-backed selected replay is E0147/R000022, generated by the
pre-reachability `standard-new` pin
`c955c23bd57a078c8fceb30de1df101280b25e2c`, and compared in E0149/R000005.
The analysis script now detects a selected-root
export from its generated header. The previous comparison script manufactured a
second start condition by replacing `%start standardir_start` with
`%start r_program`; that was a method error and is no longer used for the
selected replay.

An independent critique identified R741, R843, R1103, R1307, R1315 and the
R1416/R1417 region as possible truncation or tokenization defects. Direct
inspection of the current output and its source-backed records does not confirm
those defects:

* R741 contains the procedure interface, component-attribute list, `::` and
  procedure declaration list.
* R843 contains the implied-do variable, both bounds, optional stride and
  closing parenthesis.
* R1103 emits `ASSOCIATE ( association-list )` with the list as a reference.
* R1307 contains the complete I/B/O/Z/F/E/EN/ES/EX/G/L/A/AT/D/DT family.
* R1315 separates `T`, `TL`, `TR` from the referenced `n`, and emits `n X`.
* R1416 retains both optional body parts; R1417 and R1418 retain the
  `SUBMODULE` parent identifier and optional ancestor/parent-submodule form.

These are now regression anchors classified as `no_defect_found` or
`expected_difference` in M022--M024. The concrete gap in that historical
replay was the mutually recursive R918/R915 normalization: the generated
selected Bison file had four unreachable normalized nonterminals and seven
useless rules after source lineage had been substituted into the designator
path. E0151/R000293--R000294 closes that gap with generic normalized-target
reachability pruning and a source-backed disposition witness. It does not
delete source rules or add a Fortran-specific exception; language-preservation
and corpus evidence remain separate gates.

The comparison also records a genuine LFortran/reference advantage: its
parser.yy includes executable lexer actions, token payload types, precedence,
AST actions and an explicit conflict budget. StandardIR's genuine advantages
remain source rule/page/byte/hash lineage and the clean normative boundary.
Both are retained; neither is converted into a claim that one grammar is
globally “better.”
