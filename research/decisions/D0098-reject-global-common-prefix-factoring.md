# D0098. Reject global common-prefix factoring without a behavior gate

Date: 2026-08-15
Status: accepted

## Context

After the authoritative PDF-fidelity gate, a generic target-normalization
candidate factored common prefixes and emitted merged lineage witnesses. It
passed source identity and four-format generator smoke checks, but the fresh
all-root Bison inventory worsened from 758/3,885 to 948/4,572. Its selected
projection emitted 12 useless nonterminals and 516 useless rules, then caused
Bison to abort internally before selected conflict totals could be computed.

## Decision

Do not promote global common-prefix factoring. Keep the authoritative
StandardIR grammar and the existing D0089 GLR export policy. A future generic
parser transformation must pass source-lineage, parser-generator, selected
and all-root diagnostics, and independent positive/negative language witnesses
before it can become a default. The validated D0092/E0163 role-family
specialization remains opt-in and selected-profile only.

## Rejected

* Promoting a transformation because it looks generic or adds provenance.
* Using a lower warning count as a language-equivalence proof.
* Adding precedence or ambiguity declarations to conceal a failed target.
* Repairing the candidate with rule-number-specific exceptions.

## Reversal condition

Write a successor if a generic factoring or precedence transformation produces
valid selected and all-root parser reports, preserves source/lineage witnesses,
and passes an independent positive/negative language gate without a broad
conflict increase.
