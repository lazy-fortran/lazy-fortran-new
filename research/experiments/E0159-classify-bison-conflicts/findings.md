# E0159 findings

This experiment inventories the generated Bison diagnostics after the source
identity, lexical, PDF-fidelity and four-format parser-generator gates. It
does not change StandardIR or choose conflict resolutions.

## R000329: state inventory and LFortran policy comparison

The accepted run uses lab `c1856b8`, `standard-new`
`bedd9abc7210fc7fc16607d275ea4fa7b24144f8`, and the pinned LFortran parser at
the SHA recorded in `lfortran-parser.yy.sha256`. The all-root report with
counterexamples was generated directly from the trusted E0154/R000323 Bison
output; its 130.52-second generation and 5,195 counterexample groups remain
under `.cache/runs/E0159/R000324/`. The committed analysis then regenerated
the selected-program and LFortran state reports and recomputed every total
from their state headers.

The exact policy comparison is:

| profile | shift/reduce | reduce/reduce | interpretation |
|---|---:|---:|---|
| all roots | 758 | 3,885 | broad export inventory |
| selected `program` | 427 | 2,266 | selected parser-target inventory |
| LFortran declared | 238 | 180 | `%expect` / `%expect-rr` policy |
| LFortran observed | 238 | 180 | policy check passes |

The generated conflict states are assigned one deterministic primary category
from their retained state symbols; the categories are an inventory aid, not a
cross-parser semantic correspondence. For the all-root profile the totals
are:

| category | conflict states | shift/reduce | reduce/reduce |
|---|---:|---:|---:|
| broad-start-entry | 1 | 112 | 514 |
| expression-or-precedence | 263 | 533 | 2,352 |
| lexical-or-literal | 38 | 14 | 69 |
| nullable-or-list-boundary | 30 | 10 | 57 |
| other-grammar-structure | 211 | 9 | 259 |
| role-or-name-family | 107 | 80 | 634 |

For the selected `program` profile, the corresponding totals are expression
or precedence 206/563 in 75 states, lexical or literal 12/3 in 13 states,
other grammar structure 61/77 in 54 states, and role or name family 148/1,623
in 127 states. The role/name family is therefore the largest selected
reduce/reduce family under this structural classifier, consistent with D0092,
but the count is not a language-equivalence result.

The all-root minus selected-profile delta is 331 shift/reduce and 1,619
reduce/reduce conflicts. Only the 112/514 state-0 entry conflicts are directly
labelled broad-start entry. The remainder is retained as a profile delta,
not falsely attributed to the wrapper alone.

The LFortran classifier is intentionally not interpreted by these StandardIR
symbol-name categories: its C++ semantic-value grammar uses different names,
and its declared budget is the independently checked comparison. LFortran's
lower policy volume reflects parser factoring, precedence/actions and its
target contract, not permission to copy productions into StandardIR.

The next slice is E0160: evaluate a generic role-family target specialization
and any precedence/factoring projection against independent language-
preservation witnesses. No source rule, target conflict, or LFortran
production may be special-cased. Until that successor gate passes, the
current GLR export remains the accepted deterministic policy under D0089.

Development attempts R000325--R000328 exposed only harness defects (wrong
report path, an interrupted quadratic state-summary lookup, and a tuple-unpack
bug); they were not accepted as scientific results. The final committed
analysis is R000329.

## R000356: fresh post-fidelity conflict inventory

R000356 reruns the same independent state-header classifier against the fresh
E0154/R000353 Bison output. The all-root report is retained under
`.cache/runs/E0159/R000355/`; the analyzer regenerates the selected-program and
pinned LFortran reports. The totals are unchanged: all roots 758/3,885,
selected `program` 427/2,266, and LFortran observed and declared 238/180.
The state totals recompute exactly, and LFortran's `%expect` policy matches.

The fresh category table is also unchanged within the classifier: the
selected profile has expression/precedence 206/563, lexical/literal 12/3,
other grammar structure 61/77, and role/name family 148/1,623. This remains an
inventory only. Generic factoring, precedence or ambiguity handling requires a
separate source-lineage and language-preservation gate; no conflict is fixed
by a rule-number-specific exception.
