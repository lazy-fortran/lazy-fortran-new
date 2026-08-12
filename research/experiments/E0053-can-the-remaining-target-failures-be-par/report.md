# E0053. Residue partition for the open decisions

## Question

Can the remaining target failures be partitioned into source-provenance
decision buckets without guessing resolutions?

## Method

The analysis command reruns E0052 and reads its complete unresolved-name set.
It classifies each target name by deterministic spelling and checks the
non-expansion names against the source-cited E0049 resolution table. A second
traversal checks the R401 and R403 family counts. The generated table retains
the target spelling, bucket, decision reference, source term, rule and page.

## Result

The 103 unresolved target names partition into 80 R401 expansion names, 17
R403 expansion names, three lexical-class names, one metanotation name, and
two ambiguous Unicode or quotation names. The expansion bucket contains 97
names and is governed by D0024/D0026. The lexical bucket is governed by
proposed D0027. The `xyz` metanotation name remains part of the expansion
decision. The two Unicode or quotation names remain unresolved under accepted
D0020. All three target tools still reject the candidate, and tree-sitter
reaches the unresolved-symbol boundary without the earlier structural error.

The controlled bucket mutation fails the exact-count validator. No model calls
were made.

## Boundary

E0053 does not resolve a target name. It gives the planning model a complete,
non-overlapping handoff for D0024, D0026 and D0027. Once those choices are
accepted, the deterministic wiring generator can apply them and rerun the
three target validators. The paper can then move from a partial composite
input to a parser that accepts a pinned real-source corpus.
