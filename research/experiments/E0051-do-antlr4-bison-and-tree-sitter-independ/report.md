# E0051. Independent target-tool validation of the partial candidate

## Question

Do ANTLR4, Bison and tree-sitter independently expose the same remaining
boundary in the E0049 partial candidate?

## Method

The analysis command reruns E0049, verifies the candidate hash, and sends the
same 522-record partial StandardIR input to the deterministic Bison and
tree-sitter emitters. The E0049 ANTLR export is copied without modification.
ANTLR4, Bison and tree-sitter then validate their own generated target
formats. Independent scans count target definitions, and ANTLR/Bison
diagnostics are normalized to unresolved rule names and compared as sets.

## Result

All three target validators reject the candidate. Each format contains 502
unique left-hand-side definitions, with no duplicate definitions. ANTLR4 and
Bison each report 103 unresolved names, and their unresolved-name sets are
identical. tree-sitter reaches an earlier structural failure: the generated
JavaScript contains `seq(, ...)` for the `where-construct-stmt` rule after an
erratum repair flattened a reference and its following colon inside an
optional group.

The controlled deletion of one ANTLR definition changes the independent
definition count and fails the negative control as expected. No model calls
were made.

## Boundary

The common validator status is informative but does not mean the three tools
have identical failure mechanisms. ANTLR4 and Bison expose the same 103-name
resolution residue. tree-sitter exposes a deterministic structural
composition bug before it can validate that residue. E0051 therefore does
not accept D0024 or D0026 and does not claim a complete parser input.

The next implementation slice is deterministic: preserve the repaired
reference-plus-punctuation group structure through every optional/alternative
projection, rerun this target validation, and keep the R401/R403 representation
decision separate.
