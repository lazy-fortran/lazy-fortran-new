# D0019. Proposed composite parser-symbol resolution

Date: 2026-08-12
Status: proposed

## Context

E0022 found 181 unresolved StandardIR reference names in the complete-core
syntax projection. The audit shows that these are not one class of defect:
some are assumed-syntax metanotation (`xyz`), some are lexical classes
(`letter`, `digit`, `rep-char`), and many are source-defined role names such as
`program-name`, `entity-name` and `type-name`. The pinned kaby76 grammar exposes
145 of the names as parser rules. The pinned house grammar exposes 3.
neither comparison grammar is normative evidence.

D0018 already rejects guessed placeholder productions. A further representation
choice is needed before the composite parser input can be generated.

## Decision needed

The planning model or user must choose whether to accept the proposed
source-cited resolution policy below as D0019, amend it with a narrower alias
vocabulary, or defer the composite parser input until a lexical and prose
adjudication slice supplies the missing evidence. Accepting it permits the
next composite-input implementation. Deferring it keeps the raw syntax
exports as the only supported parser projection.

## Decision

Proposed policy for review:

1. Keep the source term in the authoritative StandardIR syntax record and keep
   its source provenance.
2. Add an explicit composite-input resolution record only when the normative
   document establishes the relationship. For example, `program-name is name`
   becomes a source-cited alias/resolution fact. The parser projection may then
   lower it to the `name` parser symbol while retaining `program-name` for
   semantic roles and diagnostics.
3. Represent lexical classes such as `letter`, `digit`, the `_` character
   `rep-char` in a separate lexical projection with character-set provenance.
4. Keep constraints and prose restrictions as restrictions or semantic facts;
   do not encode them as arbitrary parser predicates in ANTLR4, Bison or
   tree-sitter exports.
5. Leave any term without a normative resolution record as `unresolved` or
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

**Encode prose restrictions as target-specific grammar predicates.** That would
move normative semantics into one export technology and make the projections
non-comparable.

## Reversal condition

Reject or amend this proposal if a source-controlled adjudication shows that
role aliases cannot be represented independently of semantic facts, or that the
selected parser technology requires a different lossless composite projection.
The replacement must retain source provenance and an explicit unresolved state.
