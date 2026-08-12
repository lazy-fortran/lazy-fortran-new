# D0022. The v0 schema fixture is not the StandardIR schema

Date: 2026-08-12
Status: amended by D0023

## Context

E0035--E0042 establish the `.sxs` declaration language, generated value APIs,
validation, equality, printing and hashing. Their input is deliberately small:
it exercises the generator contract, but it is not the actual StandardIR data
model.

The extracted StandardIR already has a different shape. A syntax object's RHS
contains nested `seq`, `alt`, `optional` and `repeat` nodes, and its provenance
contains document, clause, rule, page, byte-span and source-hash fields. The
current generator rejects cyclic type dependencies, so it cannot yet emit a
typed recursive syntax tree from a direct schema.

## Decision

1. Keep `standard-new/specs/schema-v0.sxs` as a generator contract fixture. Do
   not call it the complete StandardIR schema.
2. Keep the StandardIR-schema roadmap item open until the syntax expression
   tree and its provenance are represented explicitly and an independent
   structural test compares generated values with the existing StandardIR SX.
3. Treat recursive type support as a generator design boundary. The next
   implementation may use recursive generated types or a deterministic arena
   representation, but it must document the representation and preserve the
   canonical SX contract. It must not encode the RHS as an opaque string or
   silently flatten nested groups into implementation-specific names.
4. Do not make the generated fixture module a dependency of the hand-written
   extraction module. The generated StandardIR API becomes authoritative only
   after the schema and differential gate pass.

## Rejected

**Calling `schema-v0` StandardIR.** That would claim typed coverage for
recursive syntax and provenance fields that the fixture does not contain.

**Storing the RHS as a string.** This would move syntax structure outside the
schema and prevent generated validation, traversal and structural comparison.

**Flattening nested groups into names.** The current extractor's temporary
representation is useful for parsing, but its storage details are not a
normative StandardIR contract.

## Reversal condition

Write a successor decision if a fixed StandardIR schema with a documented
recursive or arena representation passes independent parse/write, structural
equality, validation and canonical-hash checks over the pinned thin corpus.
