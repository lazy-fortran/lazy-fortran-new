# E0043. D0019 source-controlled resolution slice

## Question

Can a source-controlled D0019 resolution slice classify lexical classes,
aliases, and metanotation without guessing?

## Method

The analysis command consumes the pinned complete-core StandardIR SX, canonical
text, and E0022 unresolved-reference audit:

```text
research/experiments/E0043-can-a-source-controlled-d0019-resolution/analyse.sh
```

The seed contains eight records whose supporting source excerpts are checked verbatim
against the canonical text. Three are aliases established by R402, four are
lexical classes, and one is the `xyz` metavariable described by R401--R403. The
remaining audit names are emitted as `unresolved` records. The comparison
grammars are not used as resolution sources.

The command independently checks the output cardinality, source hash on every
row, alias targets, source occurrence for every audit name, and a controlled
mutation of the `program-name` record. It also derives a partial SX and ANTLR4
alias projection from the typed records. That projection is intentionally not
claimed as a complete parser input.

## Result

The command produced 182 typed resolution records. The records contain 3
aliases, 4 lexical classes, 1 metavariable, 0 semantic-role records, 174
unresolved records, and 0 disputed records. All 182 rows carry the pinned
J3/24-007 source hash. The alias projection contains 3 rows and 8 syntax
witnesses. The independent difference is 0 and the negative control observed
the expected failure.

The three aliases are `program-name`, `entity-name`, and `type-name`, each
projected to `name` under R402 while retaining the original semantic role. The
lexical records preserve `letter`, `digit`, the `_` character, and `rep-char` as
source-defined classes. `xyz` remains metanotation and is not emitted as a
parser symbol. Terms such as `enum-type-name` remain unresolved because this
slice has no normative resolution witness for them.

## Boundary

This result establishes the D0019 record shape and a mechanically derived
alias projection. It does not establish a complete Fortran parser. The full
composite input still needs lexical token definitions, resolution or explicit
exclusion for the remaining unresolved terms, constraints, and profile closure.
The generated ANTLR4 slice is therefore an artifact of the experiment, not a
replacement for the authoritative StandardIR records.
