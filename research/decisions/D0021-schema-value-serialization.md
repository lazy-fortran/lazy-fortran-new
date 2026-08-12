# D0021. Schema value serialization for generated APIs

Date: 2026-08-12
Status: accepted

## Context

E0035 and E0036 establish the v0 `.sxs` declaration language and deterministic
Fortran type emission. E0037 drives the committed schema to a byte-stable,
formatted generated module. The next roadmap item is to generate readers,
writers, validators, visitors, equality, hashing and printers.

D0006 fixes SX as the one canonical tree serialization and requires canonical
field order, integer spelling, string escaping and stable hashing. It does not
yet say how a schema value represents a record field, a sum variant and its
payload, an absent optional, a list boundary, or a primitive value. The v0 sum
syntax (`(sum item syntax constraint ...)`) names tags but carries no payload
type. A generated reader/writer would therefore have to invent semantics or
infer them from names.

## Decision

The schema language records enough information to derive one canonical SX value
for every schema declaration. Schema declarations use these forms:

1. A record value is a list whose first atom is the declaration name. Each
   field follows as a named pair in schema order. For example,
   `(source-ref (document 1) (clause 5) (rule 501))`.
2. A sum declaration lists explicit variant records. A variant without a
   payload is `(variant-name)`. A variant with a payload of type `T` is
   `(variant-name value)`, and the declaration records `T`. For example,
   `(item (syntax syntax-value))` carries a `syntax-value` payload.
3. An optional value is `none` when absent and `(some value)` when present.
   The schema determines the type of `value`.
4. A list value is a list whose first atom is the list declaration name,
   followed by zero or more element values. For example,
   `(items value-1 value-2 value-3)`.
5. Boolean atoms are `true` and `false`. Signed decimal integers have no
   leading zeroes except for zero itself. Names and enum values are canonical
   atoms in their schema spelling. External text uses SX quoted strings with
   canonical escaping. All record fields and list elements retain schema
   order.

These forms are mechanically derivable from the schema. Generated readers and
writers may group or fuse procedures, but their bytes must follow this contract.
Fixed canonical fixtures and an independent round-trip oracle are required
before generated APIs are accepted.

## Rejected

**Infer sum payloads from declaration names.** A naming convention is not a
schema contract, cannot represent aliases or multiple payload choices, and
would make generated APIs depend on accidental spelling.

**Use target-language Fortran syntax as the schema-value format.** That would
make the IR serialization depend on one emitter and lose the small, canonical
SX boundary.

**Generate placeholder readers and writers first.** A routine that accepts a
value but has no specified canonical bytes cannot establish round-trip or hash
correctness. It would turn an unresolved representation choice into code.

## Reversal condition

Reverse this decision if a source-cited general schema demonstrates that
another value representation retains the same provenance, round-trip and
deterministic-hash guarantees without explicit variant payload declarations.
