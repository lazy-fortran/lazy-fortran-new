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
