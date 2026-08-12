# D0024. Resolution record for assumed syntax expansions

Date: 2026-08-12
Status: proposed
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0042-R000001 and E0043-R000001 established typed source-provenanced
resolution records. E0044-R000001 applied R402 to all 49 absent terms ending in
`-name` and projected them to `name` without an explicit-definition conflict.
E0022-R000001 still contains 80 absent terms ending in `-list` and 20 terms
beginning with `scalar-`. The canonical source defines these families through
R401 and R403:

```text
R401 xyz-list is xyz [ , xyz ] ...
R403 scalar-xyz is xyz
```

R401 adds repetition and separators. R403 carries the C401 scalar constraint.
Neither family is an ordinary parser-symbol alias.

## Decision

No representation has been accepted. The R401 and R403 families remain
unresolved until the decision below is made.

## Decision needed

Choose the authoritative D0019 representation for assumed syntax expansions.

The planning model should choose between:

1. a new typed resolution class such as `assumed-expansion`, with an explicit
   expansion operator and any attached constraint;
2. an extension of `alias` records with a typed expansion field that makes
   repetition and scalar constraints impossible to confuse with R402 aliases;
3. retaining the terms as `unresolved` until the generated semantic and parser
   representations can carry the expansion directly.

The selected representation must keep the R401 or R403 source rule, preserve
the original term, and generate a parser projection that retains list
cardinality or scalar semantics.

## Rejected

Treating every R401 or R403 term as an R402 alias to its base term is rejected.
That would turn `xyz-list` into one `xyz` item and would erase the separator
and repetition semantics. It would also turn `scalar-xyz` into an unconstrained
`xyz` reference and discard C401.

Resolving the terms by copying a comparison grammar is rejected by the
repository's provenance gate.

## Reversal condition

Reverse the selected representation if an independently checked generated
projection loses R401 separators or repetition, loses the C401 scalar
constraint, or requires a second hand-maintained source of the same expansion.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
