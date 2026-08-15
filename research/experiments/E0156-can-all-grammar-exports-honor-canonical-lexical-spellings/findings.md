# E0156 findings

The gate command is:

```text
research/experiments/E0156-can-all-grammar-exports-honor-canonical-lexical-spellings/check.sh \
  .cache/runs/E0154/R000314 \
  .cache/runs/E0156/R000317-lexical.tsv
```

The checker reads the lexical facts from the pinned run input's
`input/lexical-facts-v0.sx`, removes only
target-format comments, checks that source glyphs remain in provenance, checks
that canonical spellings are present in executable target material, and runs a
negative mutation that must fail. It does not invoke a grammar generator.

## R000317: current production fails the lexical target gate

The current run uses lab `fec5aa0` metadata and production
`standard-new` `83f055d`. The source-expression identity gate remains green,
but EBNF target bodies still contain U+2013 and U+2019 after comments are
removed. The ANTLR4, Bison and tree-sitter target lexical declarations already
use ASCII `-` and `'`; their source glyphs remain in provenance comments.

This is a target-lowering defect, not a PDF or StandardIR source-fact defect.
The repair must make the EBNF emitter consume the same typed lexical facts as
the other projections. It may not replace the source glyph in StandardIR or
add R-number-specific substitutions.
