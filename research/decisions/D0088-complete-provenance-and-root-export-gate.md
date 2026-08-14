# D0088. Require complete roots and typed provenance in grammar exports

Date: 2026-08-15
Status: accepted
Amends: D0087

## Context

The exact committed E0147 replay `R000009` passed ANTLR4, Bison and
tree-sitter, and every source alternative was mentioned in annotations. Luna
still found two declared roots omitted, an indirect-recursion helper carrying
the wrong source alternative, unlabelled generated origin, two different hash
objects under one field name, and lexical facts emitted as dead wrappers.
These are completeness and provenance failures, not parser-generator errors.

## Decision

1. Every declared root must either have an emitted production or an explicit
   deterministic skip record naming the root and the generic reason. A count
   of skipped records is not sufficient.
2. Every generated projection identifies its generation origin in its header;
   every transformed production retains the source occurrence and alternative
   that supplied its constructive expression. An annotation that merely lists
   all source alternatives is not a mapping witness.
3. Provenance hashes are typed at serialization boundaries. Canonical-text,
   source-document/PDF and any derived artifact hashes use distinct field
   names; a generic `source-sha256` field cannot represent more than one role.
4. A lexical fact is closed only when the generated grammar uses its exported
   class or explicitly records why the target format cannot use it. An unused
   wrapper is not a lexical closure.
5. Grammar-oracle success is reported as tool acceptance only. The E0147 gate
   additionally requires root completeness, transformation mapping,
   provenance labels, lexical connectivity and the source-to-projection
   equivalence witness.

## Rejected

* Treating declared-root omission as harmless because the roots are
  metanotation, without recording that policy in the generated evidence.
* Treating source-alternative comment coverage as proof that the corresponding
  target expression is present.
* Relying on a manifest to explain an untyped hash in a generated artifact.
* Counting lexical declarations as closure when no grammar production reaches
  their exported class.

## Reversal condition

Write a successor if a target format requires a different generic provenance or
root policy. It must preserve an explicit source mapping and an auditable
explanation for every omission; it may not weaken the completeness gate.
