# D0049. Liberal mechanical discovery with small-model overlap

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0106 found 127 source-structure residue rows. E0107's first strict pass used
the raw candidate spelling and therefore treated attached grammar punctuation,
wrapped source lines and ordinary right-hand-side occurrences conservatively.
At least five candidates have exact normative definitions after removing a
single attached comma. We need one final mechanical discovery pass, but must
not let it turn into a growing Fortran-specific exception program.

## Decision

Run one final bounded deterministic pass (E0110) with a small declarative
normalization profile: whitespace cleanup, logical-line assembly, and removal
of punctuation attached to a token matching the Fortran nonterminal shape.
Discovery may be liberal and emit candidates; acceptance remains D0048's
strict source-form, subject-position, exact-span and independent-validation
gate. No candidate-specific procedural branches are permitted. A documented
erratum may be data, with a source citation, but it cannot become an
undocumented parser rule.

In parallel, run one bounded local Qwen3.5-2B proposal pass (E0111) over the
same 127 rows. The model receives only bounded source windows and may return a
source-cited local proposal or abstain. It cannot choose wiring, dispatch,
phases, aliases or architecture. Deterministic validation owns acceptance;
the first run promotes nothing. E0110 and E0111 are compared on overlapping
candidate, relation and source-span keys.

The mechanical boundary is reached if the pass needs a candidate-specific
branch, an undocumented normalization, heuristic scoring, human tie-breaking,
or a Fortran-specific layer whose procedural code grows beyond the compact
normalization rule text it implements. At that point stop this pass and use the
measured overlap to decide the next model or erratum experiment.

## Rejected

Keeping the raw spelling as the only search key is rejected because PDF grammar
punctuation creates avoidable false residues. Silently stripping arbitrary
punctuation is rejected because it can change lexical tokens such as operators.
Sending the residue directly to a model is rejected because it would confound
source-index defects with model capability. A model-generated semantic fact is
not accepted merely because it agrees with a comparison grammar.

## Reversal condition

Write a successor if E0110's independent validator finds that the bounded
normalization accepts non-definitions, if more than the predeclared
normalization rules are needed, or if E0111 demonstrates that a different
source-backed form is systematically required and can be added without
weakening D0048.
