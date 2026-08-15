# E0157 plan

This is the successor to the historical E0152/E0153 inventories. It will use
the first E0154 replay that passes E0156, not the old `c8ebb22`, `dc75e7f` or
`83f055d` outputs. The reproducible command will be:

```text
research/experiments/E0157-current-cross-format-and-llvm-reference-audit/analyse.sh \
  <current-post-E0156-run> \
  /home/ert/code/standard/grammars/src/Fortran2023Parser.g4 \
  /home/ert/code/kaby76-fortran/comp/Fortran2023Parser.g4 \
  /tmp/lfortran-pinned-parser.yy \
  /home/ert/code/llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  <E0156-lexical-report> \
  <report-dir>
```

The script checks the existing source-expression and grammar-oracle reports,
then inventories each generated format and each pinned reference. It also
records a fixed feature matrix for modern Fortran constructs and Flang's
source rule-comment inventory. It never copies reference productions.

The expected comparison is deliberately two-sided. StandardIR can be better
on source lineage, exact cross-format identity, source-root disposition and
normative feature coverage. The references can be better on executable lexer
integration, parser factoring, actions, precedence, conflict policy and
implementation-oriented runtime behavior. A lower or higher head count alone
does not establish either result.

## R000319: current deterministic comparison

The report was generated from E0154/R000318 after its source, identity and
lexical gates passed:

```text
research/experiments/E0157-current-cross-format-and-llvm-reference-audit/analyse.sh \
  .cache/runs/E0154/R000318 \
  /home/ert/code/standard/grammars/src/Fortran2023Parser.g4 \
  /home/ert/code/kaby76-fortran/comp/Fortran2023Parser.g4 \
  /tmp/lfortran-pinned-parser.yy \
  /home/ert/code/llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  .cache/runs/E0154/R000318/lexical-witnesses.tsv \
  .cache/runs/E0157/R000319
```

The independent report passes source identity, lexical witnesses, all three
target parser validators, reference hashes and exact equality of the four
generated lineage sets. The generated inventories are 659 EBNF heads, 659
ANTLR4 heads, 1,337 Bison heads, 669 tree-sitter heads and 1,111 common
source-lineage values. The Bison excess is generated helper/lowering
structure; the tree-sitter excess is its lexical rule layer. These counts are
not language-equivalence metrics.

The pinned comparison inventories are 57 house ANTLR4 heads, 646 kaby76
ANTLR4 heads, 237 LFortran Bison heads and 195 distinct `R<number>` comments
in Flang's parser source. The selected `program` profile intentionally omits
unreachable bodies for FAIL IMAGE, NOTIFY WAIT, SELECT RANK and FORM TEAM;
their source-backed witnesses remain in all four outputs. This is a
`selected_profile_gap`, not evidence that StandardIR lost those source rules.
The next all-root/profile gate must exercise those bodies before claiming
feature coverage at parser level.

The genuine StandardIR advantages observed here are normative document,
clause, page, byte-range, source hash and alternative lineage on every
generated format; exact 1,068-source-alternative identity; one source
projection producing four validator-accepted formats; and explicit
source-root disposition. The genuine reference advantages are executable
lexer/runtime integration, parser factoring, typed semantic values, actions,
precedence and declared conflict policy. LFortran's pinned Bison file also
regenerates with its declared 238 shift/reduce and 180 reduce/reduce conflict
budget, whereas the current generated Bison output reports 427 and 2,266.
No reference production was copied and no equivalence claim is made.
