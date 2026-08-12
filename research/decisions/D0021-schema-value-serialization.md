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

Schema values use **positional, schema-directed canonical SX**. The schema is
the contract that gives positions their meaning; values do not repeat field
names.

1. A record value is a list headed by its record constructor, followed by
   fields in schema order. For example:

   ```text
   (source-ref j3-24-007 8.5.8 C851)
   ```

   is interpreted from the schema declaration of `source-ref`. Named-field
   maps are not part of v0.

2. Sum declarations explicitly declare variants and their payload types. The
   schema syntax becomes conceptually:

   ```text
   (sum item
     (variant syntax syntax-item)
     (variant constraint constraint-item)
     (variant relation relation-item)
     (variant rule rule-item)
     (variant definition definition-item))
   ```

   A payload-carrying sum value is `(syntax <payload>)`. A payloadless variant,
   if one is later needed, is `(variant-name)` and is declared explicitly as
   payloadless. Payload types are never inferred from constructor spelling.

3. Optional values use exactly two forms:

   ```text
   none
   (some <value>)
   ```

   `none` is a reserved canonical atom in an optional position; `(some ...)`
   contains exactly one value of the optional's element type.

4. List values always have an explicit boundary:

   ```text
   (list <value> ...)
   ```

   The empty list is `(list)`. A surrounding record or variant never relies on
   arity or look-ahead to infer where a list ends.

5. Primitive canonical spellings are:

   - `bool`: `true` or `false`;
   - `int`: canonical base-10 integer, no leading `+`, no redundant leading
     zeroes, and `0` rather than `-0`;
   - `name`: an SX atom interned immediately after parsing;
   - `status`: represented by its declared symbolic atom, then decoded to the
     generated enum/integer representation;
   - an actual textual primitive is not part of the v0 StandardIR/ImplIR
     internal type set. If a later schema requires one, it uses canonical
     quoted UTF-8 SX string escaping under D0006 and D0011.

6. The artifact root carries or is paired with the exact schema identity
   needed to decode positional values: schema name/version plus canonical
   schema hash. A value is never interpreted under an unspecified schema
   revision.

7. Generated readers, writers, validators, equality, hashing and printers are
   derived mechanically from the same schema. Their fixed fixtures include
   every v0 primitive, record, sum, optional and list form before the generated
   APIs are accepted.

The format is intentionally terse. Human readability comes from the small
constructors and from the schema itself; repeating every field name would make
LLM output and canonical artifacts larger without adding information.

## Rejected

**Infer sum payloads from declaration names.** A naming convention is not a
schema contract, cannot represent aliases or multiple payload choices, and
would make generated APIs depend on accidental spelling.

**Named fields in every record value.** They make values self-describing, but
repeat information already fixed by the schema, enlarge model output and
canonical artifacts, and introduce field-order canonicalization that positional
schema order avoids.

**Implicit list boundaries.** A parser would have to infer list extent from
surrounding arity or element types. Explicit `(list ...)` keeps the SX tree and
schema decoder simple.

**Use target-language Fortran syntax as the schema-value format.** That would
make the IR serialization depend on one emitter and lose the small, canonical
SX boundary.

**Generate placeholder readers and writers first.** A routine that accepts a
value but has no specified canonical bytes cannot establish round-trip or hash
correctness. It would turn an unresolved representation choice into code.

## Reversal condition

Write a successor decision if fixed fixtures or the first real StandardIR and
ImplIR schemas show that positional schema order cannot represent a required
value without ambiguity, or if measured small-model generation shows a
material reliability advantage from a different canonical form. A successor
must preserve mechanically derivable decoding, explicit sum payload types,
round-trip stability and deterministic hashing; it may not reintroduce payload
inference from names.
