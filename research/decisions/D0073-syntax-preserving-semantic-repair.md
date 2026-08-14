# D0073 — Keep semantic proposal repair syntax-preserving

Date: 2026-08-14
Status: accepted

## Context

The predecessor diagnosis for E0123 found 53 residual rows. The largest gate
class was a binary value operator applied to two fact-like names; other common
classes were malformed nesting, invalid relation names and exhausted evidence
budgets. The gate already gives a bounded repair message, but it would be
tempting to make the deterministic side rewrite a rejected tree, for example
by changing `eq(a,b)` to `same-as(a,b)` or by wrapping a string in `present`.

Those operations are not syntax cleanup. They choose a semantic
interpretation. Value equality, field identity and fact presence can differ,
and a missing nested predicate does not identify which predicate the source
requires. An automatic rewrite would therefore hide the model's mistake and
could turn an invalid proposal into an apparently valid but unsupported fact.

## Decision

The deterministic semantic gate may repair transport and representation only:
JSON decoding, bounded response extraction, canonical key ordering and other
changes that leave the validated predicate tree unchanged. It must not:

- map one predicate operator to another;
- convert `eq`/`ne` or another value relation into `same-as`;
- invent, rename or infer fact identifiers;
- wrap terms in predicates or synthesize missing conjunctions/implications;
- replace, broaden or fabricate source evidence.

The model receives the gate's precise rejection and may submit a replacement
within the declared episode budget. Original proposals, rejection codes,
repairs and final status remain in the trajectory. A model replacement that
passes the gate retains origin `LLM`; any deterministic transport repair is
recorded separately as `LLM_REPAIR` metadata. No repair, accepted or otherwise,
promotes a StandardIR fact; promotion still requires the independent witness
gate.

## Rejected

- Rewriting fact-to-fact value operators into `same-as`: this assumes field
  identity from a surface shape and can change the source meaning.
- Wrapping bare fact names as `present`, `has` or another unary predicate:
  the missing operator is semantic information, not a formatting defect.
- Adding row-specific repair rules for the current residual: this would make
  the harness proportional to the corpus and conceal the model/protocol
  boundary.

## Reversal condition

Write a successor only if an independently source-backed experiment proves a
transformation over a declared generic predicate family, including positive,
negative and boundary witnesses, with no semantic mismatches. The successor
must name the transformation and preserve the original proposal and repair
provenance.
