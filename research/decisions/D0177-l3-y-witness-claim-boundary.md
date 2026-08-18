# D0177. Narrow the typed variable-name successor claim

Date: 2026-08-18
Status: accepted
Amends: D0176

## Context

D0176 selected the `integer :: y` successor to test the typed AST v1 boundary.
The producer and replay accept the exact y source witness and preserve the
existing x witness, but the bounded bridge recognizes only those exact
witnesses. That evidence cannot establish general source-derived identifier
handling.

## Decision

For E0236, promote only this exact observable:

> The pinned producer accepts the exact `program p / integer :: y / end program
> p` source witness and emits the corresponding typed AST v1 variable name `y`,
> while rejecting the exact malformed `integer ::` neighbour.

The claim does not say that arbitrary source names are derived or preserved.
The exact-witness bridge, generated v1 record, schema-linked oracle and zero
promotion guards are sufficient for this bounded leaf. A future source-name
property must add an independent changed-name or third-name control and a
separate contract before it can be promoted.

## Rejected

Promoting general identifier/name derivation from the two hard-coded accepted
witnesses is rejected. General identifier parsing, declarations, symbols,
semantics, MIR and full M3 remain outside scope.

## Reversal condition

Reverse this boundary if a future independent mutation control demonstrates
that the producer's name handling is source-derived beyond the exact accepted
witness set, or if the exact y replay itself fails.
