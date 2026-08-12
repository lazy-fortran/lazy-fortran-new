# D0032. Generated precedence trees are structural

Date: 2026-08-12
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0064 provides typed expression-role nodes and E0065 provides source-linked
token leaves. The next boundary must demonstrate that operator precedence and
literal structure can be represented in the same generated node array without
introducing an interpreter or a second hand-maintained expression model.

## Decision

Represent precedence by generated AST nesting. Binary, unary and array
constructor nodes are ordinary typed nodes with StandardIR rule identities,
source references and deterministic child links. The generator emits the
precedence structure directly from the accepted expression specification. A
runtime precedence table is not authoritative and is not required on the
generated path.

Use the smallest initial operator family needed by the declared real-source
witnesses, while retaining the general node shape for later operator and
literal families. Keep source references on internal nodes and leaves. Query
and diagnostic operations traverse the same generated node array.

This is an autonomous decision under D0028: the smallest generated structure
that preserves direct traversal, source provenance and the performance path is
preferred, and work continues without asking for a planning choice while those
principles and the evidence agree.

## Rejected

A runtime operator-precedence interpreter is rejected because it adds dispatch
and table lookup to a structure known at generation time. A separate expression
IR is rejected because it duplicates the AST contract and its provenance.
Flattening operators and operands into an unstructured token list is rejected
because it loses the parent-child relation needed by later semantic analysis
and direct specialization.

## Reversal condition

Write a successor if representative measurements show that structural trees
cannot support required incremental updates or cache behavior, or if a
different generated representation preserves the same source provenance and
direct traversal with lower total cost.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of
this file may then be edited, to point at the successor.
-->
