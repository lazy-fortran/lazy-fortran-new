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
