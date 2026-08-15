# E0164 findings

E0164 is now a bounded deterministic parser-runtime gate. It does not make a
claim of complete Fortran behavior or semantic coverage.

## Corrected source and projection evidence

The authoritative prerequisites are:

- E0157/R000354: corrected tree-sitter rule counting, StandardIR/source-lineage
  feature derivation, fresh all-root inventory and Luna's minimal review. Luna
  adjudicated this as a bounded structural pass, open for equivalence.
- E0158/R000364: current-source PDF-fidelity gate. It passes all 522 source
  spans, 20 duplicate rule families, all-record token/ref leaves, PDF lineage,
  and R741, R843, R1103, R1307 and R1315. R1307 removes two page-layout header
  lines while preserving the production. The 46 surface differences are the
  standard's optional-plus-ellipsis shorthand; leaf content passes.
- E0154/R000365: source preflight, fresh EBNF/ANTLR4/Bison/tree-sitter
  regeneration, identity and lexical mutation gates, and all three parser
  generator oracles. The selected profile covers 1,068/1,068 source
  alternatives. The selected Bison report has 427 shift/reduce and 2,266
  reduce/reduce conflicts, with no undefined symbols or useless rules.

The exact commands are:

```text
research/experiments/E0158-authoritative-pdf-fidelity-gate/check.sh \
  .cache/runs/E0154/R000353/input/standardir.sx \
  .cache/runs/E0001/R000003/j3-24-007.canonical.txt \
  .cache/j3-24-007.pdf .cache/runs/E0164/R000364-pdf-fidelity.tsv \
  artifacts/runs/E0001/R000003-canonical-text.toml \
  .cache/runs/E0001/R000003/j3-24-007.pages.index

research/experiments/E0154-can-exact-source-expression-identity-and/run-selected.sh \
  .cache/runs/E0164/R000365-four-format-regeneration program \
  .cache/runs/E0154/R000353
```

## Source-backed runtime contract

`build-contract.py` now consumes three declared inputs: raw StandardIR syntax,
the R401/R402/R403 classification facts, and lexical facts. It treats aliases,
lists and scalar wrappers as parser-projection closure records, emits the
three source-backed lexical primitives, maps declared Unicode canonical
spellings, and computes a generic reachability closure from `program`.
Semantic-only `xyz` is not invented as a parser rule. No rule number is
special-cased.

R000363 emits 1,220 selected contract rows from 522 syntax records, 160
classification records and five lexical facts. The independent
`validate-contract.py` gate reports 655 unique left-hand sides, 586 unique
references, zero missing references, zero source-lineage failures, mechanical
origin on every row and resolved status on every row. Its output is
R000369.

The production runtime is `fortfront-new` commit `7ab3df0`. Luna's generic
two-pass loader fix removed the earlier quadratic table-copy failure observed
at about 46 GiB resident memory. The follow-up generic identity fix bounds
generated helper names with stable digests rather than truncating or
special-casing long source names. Focused and full `fo` pass with zero lint
warnings in the production slice.

The selected runtime load and behavior witnesses are:

- R000367: 1,220 rows load successfully; `END` and `END PROGRAM` are accepted;
  `BOGUS` and incomplete `PROGRAM` are rejected.
- R000370: an independent checker records two positive and two negative cases,
  with all four expected outcomes.

The load-only invocation with no token is intentionally rejected at
finalization because `program` requires a program unit; that is not a loader
failure. The runtime used about 1.5 GiB peak RSS for this selected contract,
which is bounded but remains a performance follow-up rather than a correctness
claim.

## Conflict inventory and boundary

R000368 reruns the deterministic E0159 inventory against the fresh selected
Bison output. It reproduces 758/3,885 all-root and 427/2,266 selected
conflicts. LFortran's pinned grammar observes and declares 238/180. The
structural categories are retained in `summary.tsv` and `conflict-states.tsv`;
they do not identify semantic equivalences or justify a precedence rewrite.
E0165/R000360 remains the negative control: global common-prefix factoring
worsened the all-root totals and caused a selected Bison assertion, so it is
not promoted.

The deterministic grammar/runtime checkpoint is therefore closed only for the
selected contract and its bounded behavior witnesses. The following remain
open and block semantic, LLM, plot, model-comparison and backend work:

- a larger generated-parser positive/negative corpus over the selected
  StandardIR profile;
- lexer/runtime coverage beyond the five currently declared lexical facts;
- any conflict-resolution or language-preservation transformation; and
- complete Fortran behavior or semantic validation.

Historical E0164/R000348 and R000349 remain immutable narrow evidence. They are
not overwritten by this corrected closure replay.
