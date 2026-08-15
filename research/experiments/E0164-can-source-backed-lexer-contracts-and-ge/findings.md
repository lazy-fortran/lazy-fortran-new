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
normative oracle; the 24-test run is a production lexer-suite summary; and the
generated parser runtime was absent in R000348.

The generic runtime slice was then implemented in `fortfront-new` at
`d6de5f47afa8870c7e1dbec5dff06ec0ba79f7a3` and replayed as R000349. Its
contract-to-frontier bridge passes the focused lexer tests (2/2), focused
generic parser-runtime test (1/1), and full `fo` (25/25, lint and formatting,
zero warnings). The initial named-test invocation after cleaning the
disposable build directory failed because it did not rebuild the executable;
that retained harness log is not counted as a production failure. This slice
is generic and intentionally bounded; it does not yet execute all 1,068
selected source alternatives or establish full parser behavior.

Therefore E0164 remains reported with status `OPEN-GENERATED-PARSER-RUNTIME`,
not presented as a complete frontend behavior result. The next production slice
must lift the generic runtime over the complete selected grammar without
language-specific rule wiring or model repair, then run execution-level
positive/negative corpus gates.

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

The runtime-slice replay uses the same command with the R000349 directories,
`lexer-test.log`, `--lexer-test-count 2`, `--runtime-test-log runtime-test.log`
and `--runtime-test-count 1`.
```
