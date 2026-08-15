# E0152 cross-format grammar comparison

Run the deterministic inventory with:

```text
research/experiments/E0152-can-cross-format-grammar-inventories-and/analyse.sh \
  .cache/runs/E0152/R000001
```

The run directory must contain the four E0151/R000002-candidate exports and
the validator report. The script verifies their SHA-256 values, materializes
the source/projection evidence and four exact pinned comparison files from the
gitignored cache, and extracts inventories. It does not copy reference
productions into StandardIR or rerun parser generators; the exact versioned
validator report is checked as an input to this inventory experiment.

The generated formats share one source-backed input and therefore must agree
on source-derived heads and exact lineage identifiers, modulo explicitly
recorded target helpers. The reference files intentionally do not share that denominator:
LFortran has executable lexer/actions/precedence and parser-oriented factoring,
the ANTLR grammars provide ecosystem compatibility, and Flang provides an
independent LLVM parser rule-ID inventory. Those are comparison evidence, not
normative corrections.

The first run must classify any disagreement as one of `target_defect`,
`projection_gap`, `expected_difference`, `standardir_advantage`,
`reference_advantage`, or `method_gap`. A lower raw conflict count is never
enough to declare a reference winner or a StandardIR defect.

## R000001 result

The exact E0151/R000002 candidate was inventory-checked across all four
generated formats. The inherited ANTLR4, Bison, tree-sitter and
source-projection report are all `PASS`; the four generated inventories expose
1,191 provenance headers and the same 1,031 unique lineage identifiers each.
After removing only target helpers, lexical wrappers and the generated start
symbol from the head comparison, all four formats share the same 650
comparable grammar heads. The remaining head-count differences are target
representation choices: EBNF inlines helpers, while Bison emits helper
nonterminals and the other formats retain a different target spelling for
lexical facts. No cross-format source-backed head disagreement was found.

The corrected alternative counters are structural parser inventories, not
language metrics: EBNF 1,188, ANTLR4 1,197, Bison 2,286 and tree-sitter 1,231.
The target formats encode the same source alternatives differently, and the
counter does not prove body equivalence. The inherited source projection
reports 1,061 of 1,068 source alternatives covered, seven explicitly skipped,
zero missing and zero header gaps. That is a body-bound mapping check, not the
stronger expression-identity witness required by D0087 and D0088.

The pinned reference inventories are now reproducible from the verified cache:

| reference | heads | metric |
| --- | ---: | ---: |
| LFortran Bison | 238 | 1006 grammar alternatives |
| kaby76 ANTLR4 | 646 | 1354 grammar alternatives |
| house ANTLR4 | 57 | 262 grammar alternatives |
| Flang rule comments | 195 | 199 `Rxxx` comment occurrences |

These counts are structural inventories, not language-equivalence scores.
The Flang file is an LLVM parser comparison source derived from the Fortran
2018 draft, as its own header says; its `Rxxx` count is not a grammar
alternative inventory. It remains useful for rule-ID comparison, not as a
Fortran 2023 language denominator.
LFortran remains stronger as an executable parser target with lexer actions,
typed tokens, precedence and AST construction. StandardIR remains stronger as
a source-backed normative representation with rule/page/byte/hash lineage,
role preservation and one deterministic source for all four exports. The
comparison therefore records both genuine advantages and makes no global
winner claim. The current source-projection report uses a body-bound witness:
a same-lineage but wrong RHS would pass it. A future source-expression
identity witness must close that gap before M2.
