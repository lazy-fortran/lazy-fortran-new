# E0164 findings

The source-backed lexer contract is mechanically emitted from the pinned
`standard-new` lexical facts. It contains five distinct token rows, all with
complete J3 document/clause/rule/page/hash provenance and `MECHANICAL` origin.
The adjudicator now compares every row with the lexical facts and verifies the
source hash against `artifacts/standards/j3-24-007.toml`. The baseline and
selected role-family candidate carry identical contracts. This is the current
five-fact lexical slice, not a claim that the full Fortran lexical inventory is
closed.

Both projections pass the independent E0147 generator smoke gate for ANTLR4,
Bison and tree-sitter, including the deliberate undefined-reference negative
control. Both pass E0156's selected canonical lexical-spelling check and its
mutation. The source projection still reports 1,068 alternatives, 1,061
emitted bodies and seven omitted bodies, with six declared roots omitted. The
baseline conflict inventory is 427/2,266 and the candidate inventory is
425/2,135; E0163 remains the adjudication of that candidate, not E0164.

The production `fortfront-new` lexical runtime passes all 24 tests at commit
`db5eaecd118f08851e4dd26f6aaa186fbc9fbef9`. E0161's independent bounded
recognizer preserves 359 positive and 636 negative cases, and E0041's three
external frontend oracles agree on all ten reference fixtures with 30
diagnostic files retained.

Luna's independent review confirms that these are narrow, useful gates, not a
complete Fortran 2023 grammar/lexer/runtime result. In particular, the bounded
language and ten-fixture external corpus are differential evidence, not a
normative oracle; the 24 tests are a production lexer-suite summary; and the
generated parser runtime is absent.

Therefore E0164 is reported with status `OPEN-GENERATED-PARSER-RUNTIME`, not
presented as a complete frontend behavior result. The next production slice is
a generic generated parser-runtime integration using the already-pinned grammar
contract; no language-specific rule wiring or model repair is permitted.

Reproduce the adjudication with:

```text
research/experiments/E0164-can-source-backed-lexer-contracts-and-ge/analyse.py \
  .cache/runs/E0164/R000348/baseline \
  .cache/runs/E0164/R000348/candidate \
  ../standard-new/specs/lexical-facts-v0.sx \
  artifacts/standards/j3-24-007.toml \
  .cache/runs/E0161/R000340/language-report.json \
  .cache/runs/E0041/R000001/summary.tsv \
  .cache/runs/E0164/R000348/fortfront-fo-test.log \
  .cache/runs/E0164/R000348/report.tsv
```
