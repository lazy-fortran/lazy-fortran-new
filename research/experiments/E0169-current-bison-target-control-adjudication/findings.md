# E0169 findings

The current generated Bison target is GLR and regenerates successfully. It has
1,332 target heads, one aggregate token declaration line, no precedence
directives and no semantic action braces. The pinned LFortran parser has 237
heads, 254 token declaration lines, GLR, 11 precedence directives and 1,902
action braces. The generated file retains 1,068 source alternatives and 2,437
provenance comments; these are different target contracts, not a reason to
copy implementation productions.

The selected conflict inventory is 427 shift/reduce and 2,266 reduce/reduce;
LFortran declares and observes 238 and 180. The largest selected category is
role/name-family ambiguity at 1,623 reduce/reduce conflicts. E0163's generic
`data-ref` factoring reduces the selected result to 425/2,135 and passes its
359-positive/636-negative language gate, but worsens all roots to 760/3,894.
It remains opt-in selected-profile lowering.

A precedence-only probe leaves the selected conflict totals unchanged and
emits useless-precedence diagnostics. D0100 therefore keeps GLR, rejects
copied `%expect`/precedence/actions, and requires a production-level
source-derived transformation plus independent selected and all-root behavior
gates before any promotion.

The current target-control report is `.cache/runs/E0169-lfortran-comparison.tsv`.
