# D0108. Use prose locators in the lexical-layout contract

Date: 2026-08-15
Status: superseded by D0109
Supersedes: D0107

## Context

The first production projection of `lexical-layout-v0` passed its local
behavioral gate as E0171/R000408. Review before source extraction found that
the contract's `source-ref` required a `rule` field. The relevant J3/24-007
evidence is prose in clauses 4.1.4, 5.5.2 and 6.3.2.5, not a numbered syntax
rule. The test therefore used invented rule labels. That would preserve a
shape while falsifying provenance.

## Decision

Supersede `lexical-layout-v0` with `lexical-layout-v1`. Replace the mandatory
prose source field `rule` with the neutral `locator`, which identifies a
source paragraph or mechanically located phrase without claiming that it is a
grammar rule. Add `all` to the source-form domain so a form-independent fact
such as “a statement keyword is not a reserved word” does not acquire a false
free-form restriction.

The v0 projection and its run remain immutable historical evidence. New source
extraction, production projection and parser behavior work must consume v1.
The source locator is still accompanied by document, clause, page and source
document hash; a locator is not permission to omit any of those fields.

## Rejected

* Retaining `rule` and assigning a synthetic rule number to normative prose.
* Omitting the locator and relying only on page numbers, which is too coarse
  for a page containing several independent claims.
* Encoding the prose claim as a StandardIR grammar production.
* Treating a source-form-independent rule as free-form merely because the
  current conflict witness comes from a free-form profile.

## Reversal condition

Write a successor if the source standards provide a stable normative rule
identifier for these layout facts, or if an independent provenance audit shows
that clause/page/hash plus the chosen locator is insufficient to recover the
exact source passage.

## Evidence

* E0171/R000407: the three normative anchors are prose clauses, not syntax
  rules.
* E0171/R000408: v0 projection tests passed only after synthetic rule labels
  were supplied; the run therefore cannot establish correct prose provenance.
* D0106 and D0107: layout remains a target lexer contract and does not change
  normative StandardIR syntax.
