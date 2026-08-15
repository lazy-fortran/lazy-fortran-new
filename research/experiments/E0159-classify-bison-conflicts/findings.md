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

## R000368: current selected-contract replay

R000368 reruns the inventory after E0158/R000364 and the fresh
E0154/R000365 four-format regeneration. It uses the current selected Bison
grammar and the retained all-root report, then regenerates the selected-program
and pinned LFortran reports with the committed `analyse.py` command. It
reproduces:

| profile | shift/reduce | reduce/reduce |
|---|---:|---:|
| all roots | 758 | 3,885 |
| selected `program` | 427 | 2,266 |
| LFortran | 238 | 180 |

LFortran's observed totals still equal its declared `%expect` and `%expect-rr`
policy. The current structural category table is retained in
`.cache/runs/E0164/R000368-bison-conflict-inventory/summary.tsv`; it remains
an inventory, not a resolution policy. E0165/R000360 is the negative control
against global common-prefix factoring: that candidate increased the all-root
totals and caused a selected Bison assertion. No generic factoring,
precedence or ambiguity transformation is promoted by R000368.

## Current target-control comparison

The current post-fidelity output was compared with the pinned LFortran parser
using E0155's deterministic inventory command. The generated file has 1,332
target rule heads, one aggregate `%token` declaration line, GLR enabled, zero
precedence directives and zero action braces. LFortran has 237 heads, 254 token
declaration lines, GLR enabled, 11 precedence directives and 1,902 action
braces. The generated file retains 1,068 source alternatives with positive
identity and 2,437 provenance comments. These are target-shape differences,
not claims that the normative grammar should copy the implementation grammar.

The current selected conflict categories are:

| category | states | shift/reduce | reduce/reduce |
|---|---:|---:|---:|
| expression-or-precedence | 75 | 206 | 563 |
| lexical-or-literal | 13 | 12 | 3 |
| other-grammar-structure | 54 | 61 | 77 |
| role-or-name-family | 127 | 148 | 1,623 |

The role/name family is the dominant selected reduce/reduce source. E0163's
generic `data-ref` role-family projection reduces that selected inventory to
425/2,135 and passes 359 positive and 636 negative bounded cases, but the
all-roots result worsens to 760/3,894. It remains opt-in selected-profile
lowering, not a default source grammar rewrite.

The source-shaped expression ladder does not by itself justify Bison
precedence declarations: a probe adding the corresponding target precedence
names without production annotations leaves the conflict totals at 427/2,266
and emits useless-precedence warnings. `%expect` would only hide the remaining
ambiguity. D0100 therefore keeps GLR as the default and defers precedence or
action generation until a source-derived production transformation has an
independent language gate.

## R000398: counterexample-witness inventory

The corrected analyzer now parses the retained Bison state reports into a
separate `counterexamples.tsv`. Each row records the profile, state, conflict
kind, lookahead token, competing rule numbers and symbols, visible StandardIR
rule IDs, stable hashes of both example derivations, and whether both example
derivations were present. It does not decide that a conflict is harmless.

The replay reports:

| profile | conflict actions | counterexample groups | complete groups |
|---|---:|---:|---:|
| all roots | 758 shift/reduce, 3,885 reduce/reduce | 4,512 | 4,512 |
| selected `program` | 427 shift/reduce, 2,266 reduce/reduce | 766 | 766 |
| LFortran | 238 shift/reduce, 180 reduce/reduce | 443 | 443 |

The group count is not expected to equal the action count: Bison may emit one
counterexample group for a state/token conflict while a state contains several
conflicting actions. The old structural category inventory remains available,
but the new witness rows are the evidence used for any later source-lineage or
ambiguity analysis.

The accepted replay is under
`.cache/runs/E0159/R000398-counterexample-witness/`. Reproduce it with the
`analyse.py` command in the manifest. This remains `INVENTORY_ONLY`; no
precedence, action, `%expect` or role-family policy is promoted by this run.
