# D0109. Carry the source statement-class selector

Date: 2026-08-15
Status: accepted
Supersedes: D0108

## Context

The source-backed v1 replay extracts statement termination, continuation and
keyword/name facts. It does not state which StandardIR syntax classes receive
the statement-boundary behavior. The normative prose in J3/24-007 clause
4.1.4 says that syntactic class names ending in `-stmt` follow the source-form
statement rules. Without recording that relation, a target generator would
have to hard-code an `lhs` suffix test. That would be a Fortran-specific
semantic decision hidden in target wiring rather than a source-backed fact.

## Decision

Supersede `lexical-layout-v1` with `lexical-layout-v2`. Add a
`statement-class-suffix` record carrying the source form and the source-backed
suffix selector. The initial fact is the literal `-stmt` suffix from clause
4.1.4. Generated target code may apply statement-boundary behavior to a syntax
class only through this record; it may not contain an unproven suffix test or
rule-number exception.

The v1 projection and R000410 remain immutable historical evidence. New source
extraction, projection and parser-target work consumes v2. This record supplies
applicability; it does not itself add an EOS production or choose a
Tree-sitter/Bison conflict policy.

## Rejected

* Hard-coding `lhs` names ending in `-stmt` in a parser generator.
* Treating every syntax class as a statement because it occurs in a statement
  context.
* Adding an EOS token to normative StandardIR without a source application
  relation.
* Using a reference grammar's list of statement nonterminals as the selector.

## Reversal condition

Write a successor if the source standard supplies a more precise, non-suffix
statement-class relation for the selected profile, or if an independent target
projection shows that the selector cannot express the source application
boundary without an additional source-backed relation.

## Evidence

* E0171/R000407: J3/24-007 clause 4.1.4, page 45, states the `-stmt` source
  form rule.
* E0171/R000410: v1 projects the termination facts but has no applicability
  selector.
* Lämmel and Zaytsev, “An Introduction to Grammar Convergence,”
  <https://doi.org/10.1007/978-3-642-00255-7_17>, for preserving named source
  transformations instead of hiding them in a target grammar.
