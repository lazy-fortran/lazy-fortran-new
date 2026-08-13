# D0048. Strict source-form semantic acceptance

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0106 reduced the unresolved-name residue to source-structure candidates, but
many unique records are grammar productions in which the candidate occurs on
the right-hand side. A structural match alone therefore does not establish
that the normative document defines the candidate. M3 needs a falsifiable
boundary between source evidence and an accepted semantic fact.

## Decision

Accept a deterministic definition fact only when the canonical normative text
contains an exact, source-provenanced definition form in which the candidate
is the defined subject or an explicit name-heading subject. Accepted forms are
limited to the predeclared `is`, `is one of`, `means`, `consists of`, and
explicit name-heading forms, with their required grammatical subject position.

A candidate appearing only on the right-hand side of a grammar production, in
a continuation owned by another rule, in a cross-reference, or in an ordinary
use sentence remains evidence and is not promoted. Every accepted fact must
retain the exact source span, page, document, clause/rule when available,
source hash, form and `MECHANICAL` origin. Ambiguous and unsupported rows stay
explicitly unresolved.

The rule applies equally to later model proposals: a model may propose a
small local fact, but the coordinator accepts it only after the same citation,
source-position, independent-validation and semantic-role checks. No model or
local fact may add parser wiring, dispatch, phase ordering or compiler-wide
structure.

## Rejected

Promoting every unique structure match is rejected because E0106 includes
right-hand-side grammar references and continuation fragments. Treating a
recurring suffix as an alias is rejected because repetition is not a normative
definition. Inferring subject position from a comparison grammar is rejected
because comparison grammars are not normative sources.

## Reversal condition

Write a successor if a source-backed corpus demonstrates that the accepted
forms systematically miss normative definitions with an unambiguous alternate
form, or if an independent validator shows that the subject-position rule
accepts non-definitional uses.
