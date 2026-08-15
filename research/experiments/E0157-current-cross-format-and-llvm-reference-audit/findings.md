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
