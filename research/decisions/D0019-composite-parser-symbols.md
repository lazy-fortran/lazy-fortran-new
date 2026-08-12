# D0019. Composite parser-symbol resolution

Date: 2026-08-12
Status: accepted

## Context

E0022 found 181 unresolved StandardIR reference names in the complete-core
syntax projection. The audit shows that these are not one class of defect:
some are assumed-syntax metanotation (`xyz`), some are lexical classes
(`letter`, `digit`, `rep-char`), and many are source-defined role names such as
`program-name`, `entity-name` and `type-name`. The pinned kaby76 grammar exposes
145 of the names as parser rules, while the pinned house grammar exposes 3;
neither comparison grammar is normative evidence.

D0018 already rejects guessed placeholder productions. A further representation
choice is needed before the composite parser input can be generated.

## Decision

1. Keep the source term in the authoritative StandardIR syntax record and keep
   its source provenance. A parser projection may lower a term only through a
   separate source-provenanced resolution fact.

2. Resolution records are typed. The initial resolution classes are `alias`,
   `lexical-class`, `metavariable`, `semantic-role`, `unresolved` and
   `disputed`. Add another class only when a normative source demonstrates that
   none of these describes the relationship.

3. When the normative document establishes a relationship such as
   `program-name is name`, record it as a StandardIR definition or relation
   with its own source citation. The composite parser projection may then lower
   `program-name` to the `name` parser symbol while retaining `program-name`
   for semantic roles, diagnostics and provenance. Parser-only alias tables are
   derived artifacts, not authoritative inputs.

4. Represent lexical classes such as `letter`, `digit`, `underscore` and
   `rep-char` through source-provenanced lexical facts. The parser projection
   derives its token or character-class representation from those facts.

5. Assumed-syntax metavariables remain explicit metanotation until the source
   establishes how they expand. They are not silently converted into parser
   symbols.

6. Keep constraints and prose restrictions as StandardIR restrictions or
   semantic facts. Do not encode them as arbitrary parser predicates in
   ANTLR4, Bison or tree-sitter exports.

7. Leave any term without a normative resolution fact as `unresolved` or
   `disputed`. It is not emitted as a guessed parser rule. A profile may exclude
   it only through an explicit profile decision.

Under this policy, target-tool validation is required for the composite parser
input after all selected references have a source-cited resolution state. Raw
syntax exports remain partial comparison projections under D0018.

## Rejected

**Copy every alias from kaby76 into StandardIR.** This violates the provenance
boundary and treats a comparison implementation as a normative source.

**Replace every unresolved role name with `name` mechanically.** Some terms
carry additional semantic restrictions, and the source does not establish that
all 181 names are equivalent to the lexical `name` class.

**Maintain parser-only alias tables as another source of truth.** Any alias or
role relationship that affects parser construction must be represented as a
source-provenanced StandardIR fact and projected mechanically.

**Encode prose restrictions as target-specific grammar predicates.** That would
move normative semantics into one export technology and make the projections
non-comparable.

## Reversal condition

Write a successor decision if source-controlled adjudication shows that the
resolution classes above cannot represent a normative relationship without
loss, or if a selected parser technology requires a different lossless
projection. A replacement must retain the original source term, source
provenance and explicit unresolved/disputed states. Comparison grammars may
continue to supply evidence, but never become normative resolution sources.
