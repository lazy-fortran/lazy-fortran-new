# D0024. Resolution record for assumed syntax expansions

Date: 2026-08-12
Status: accepted
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

Use a distinct typed `assumed-expansion` resolution record. It retains the
original term, its source rule and citation, the `xyz` metavariable binding,
and a typed expansion expression. The two canonical expansion forms are:

* R401: `repeat(xyz, minimum=1, maximum=unbounded, separator=comma)`.
* R403: `xyz` with the source-linked C401 scalar constraint.

The generator lowers these records to grammar structure and semantic facts.
R401 therefore retains cardinality and separators, while R403 retains the
scalar relationship. `xyz` remains a metanotation binding and is never
silently turned into a lexical class or an ordinary `name` alias.

The record is the authoritative representation. Exporters may fuse its
lowering into direct productions and checks, so the final compiler has no
generic expansion interpreter or runtime lookup table.

## Rejected

Treating every R401 or R403 term as an R402 alias to its base term is rejected.
That would turn `xyz-list` into one `xyz` item and would erase the separator
and repetition semantics. It would also turn `scalar-xyz` into an unconstrained
`xyz` reference and discard C401.

Resolving the terms by copying a comparison grammar is rejected by the
repository's provenance gate.

An alias record with an optional expansion field is rejected because it makes
two different contracts share one variant and forces every consumer to test
which alias semantics apply. Retaining the terms unresolved is rejected for
the same reason: it postpones a deterministic source fact and prevents the
specialized parser input from being generated.

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
