# E0151 result

Run the baseline with:

```text
research/experiments/E0151-can-generic-post-normalization-reachabil/analyse.sh
```

The baseline is the selected E0147/R000022 Bison projection. It reproduced the
same four unreachable normalized nonterminals and seven useless rules reported
by Bison (`R000292`). The independent graph calculation is a target diagnostic;
it does not authorize deleting source-backed StandardIR records.

The candidate is `standard-new` commit
`dc75e7f4905e58d9b89d04c77f4f09223b57a579` (`R000293`). It ignores references
that are not normalized target left-hand sides when constructing the generic
target graph, retains all reachable targets, and emits a deterministic
source-backed witness for normalized targets omitted from the selected export.
On the exact E0147/R000022 input, the graph reports 1,337 normalized target
nonterminals, 1,337 reachable, zero unreachable targets and zero unreachable
rules. Bison independently reports zero useless nonterminals and rules. The
four generated projections cover 1,061 of 1,068 source alternatives; the
remaining seven are explicit, dispositioned normalization skips. ANTLR4,
Bison and tree-sitter all pass, the source-projection audit passes, and the
mutation control detects a removed retained edge.

The candidate closes this experiment's reachability gate, not the language
conformance gate. Bison still reports 427 shift/reduce and 2,266 reduce/reduce
conflicts. A selected-root projection is not proof of acceptance equivalence,
diagnostics, lexer behavior or full Fortran 2023 coverage.

The comparison is deliberately bidirectional. StandardIR is better here at
normative source lineage, byte/page/hash provenance, and keeping parser actions
out of the specification. LFortran is better at executable lexer integration,
typed token payloads, precedence declarations, AST actions and an explicit
conflict policy. Neither advantage licenses copying the other's productions;
each claim remains a separately recorded comparison or oracle result.
