# D0033. Extend the generated expression ladder from StandardIR operators

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0066 validates generated binary, unary and array-constructor structure for a
small arithmetic family. The next real-source witnesses include power,
character concatenation, dotted logical operators, character and logical
literals, kind-suffixed real literals, and intrinsic function references.

## Decision

Extend the same generated flat AST array with the precedence ladder already
described by StandardIR. The generated operation recognizes the operator
spellings mechanically, emits structural nodes with their StandardIR rule
identities, and keeps source references on every internal node and leaf.
Represent a function reference as a typed `call-expr` node whose children are
the function name and argument expressions. Keep the operator ladder and
function-reference shape deterministic. Do not introduce a runtime operator
table or a second expression IR.

This is an autonomous decision under D0028 and D0032. The smallest generated
extension that preserves direct traversal, source provenance and compilation
performance is preferred.

## Rejected

A separate parser for each operator spelling is rejected because the
StandardIR operator facts already determine the token class and precedence.
A model-generated operator dispatcher is rejected because it would make
structural wiring non-deterministic. Typed array constructors, user-defined
operators, substring designators, and semantic type checking remain outside
E0067 until a corpus and independent oracle justify them.

## Reversal condition

Write a successor if this ladder requires source-specific exception branches,
loses precedence or provenance, or fails to compile and pass the independent
real-source checks without a compact general rule.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in Supersedes, Amends or Retracts.
Only the Status line may then point at the successor.
-->
