# D0036. Bounded predicate formalization records

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0082 retained 287 source-linked Core 0 constraints with unresolved bodies.
The first formalization slice needs a record shape that distinguishes a
normative predicate from its source sentence and exposes the facts needed by
the generated dependency graph. The slice must remain small enough for an
independent oracle to check every field.

## Decision

For the first deterministic constraint slice, each formalization record carries
the constraint ID, associated syntax rules, source line and page, predicate
form, subject, applicability, required facts, provided facts, normalized
predicate, source hash, origin and source text.

Use a bounded vocabulary of direct predicate forms: maximum, existence,
type-membership, nonnegative, implication, exclusion and finite-domain. A
record is `resolved` only when an exact source witness and a predeclared
normalized predicate agree. Every other eligible constraint remains
`unresolved` with no predicate. The dependency graph has one edge from each
required fact to its rule and one edge from the rule to each provided fact.
Parser projections remain outside this formalization slice.

## Rejected

Inferring predicates from constraint names or from parser comparison grammars is
rejected because neither supplies normative evidence. Assigning a resolved
status to every modal sentence is rejected because a sentence can require
cross-clause facts or an implementation-specific domain. Sending the complete
constraint inventory to a model before measuring direct patterns is rejected by
D0035.

## Reversal condition

Write a successor if independent formalizations repeatedly require a predicate
form outside the vocabulary, if the record cannot express a required fact
dependency without hidden phase ordering, or if source-linked mutation and
independent oracle checks fail on a bounded slice. A low resolved fraction is a
measurement, not a reason to reverse the record contract.
