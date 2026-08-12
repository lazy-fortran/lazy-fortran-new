# D0021. Schema value serialization for generated APIs

Date: 2026-08-12
Status: proposed

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

## Proposed decision

Do not generate schema-specific readers or writers until the schema records an
explicit value encoding. Extend sum declarations with source-level variant
records that may name a payload type, rather than inferring a payload type from
a constructor name. Keep the following questions explicit in the successor
decision:

1. whether record values retain field names or use schema-order positional
   values;
2. the canonical form for a tagged sum with and without a payload;
3. the canonical form for an absent optional and the boundary of a list; and
4. the canonical atom spelling for each primitive type, including names,
   booleans, integers and quoted strings.

The successor must make those forms mechanically derivable from the schema and
must provide fixed fixtures before API generation begins.

## Rejected

**Infer sum payloads from declaration names.** A naming convention is not a
schema contract, cannot represent aliases or multiple payload choices, and
would make generated APIs depend on accidental spelling.

**Use target-language Fortran syntax as the schema-value format.** That would
make the IR serialization depend on one emitter and lose the small, canonical
SX boundary.

**Generate placeholder readers and writers first.** A routine that accepts a
value but has no specified canonical bytes cannot establish round-trip or hash
correctness; it would turn an unresolved representation choice into code.

## Reversal condition

Accept a successor decision when a source-cited schema value grammar and fixed
canonical fixtures define every v0 form, including sum payloads and absence.
Reject the proposed explicit variant payload field only if a demonstrated
general schema proves that another representation retains the same provenance,
round-trip and deterministic-hash guarantees without name inference.
