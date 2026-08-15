# D0092. Generate parser-target role specialization from StandardIR

Date: 2026-08-15
Status: accepted

## Context

E0149's complete production inventory and pinned LFortran comparison show a
target problem rather than a source-rule defect. StandardIR deliberately keeps
normative roles such as `object-name`, `procedure-name`, `type-name`,
`array-element` and `structure-component`. A direct Bison projection leaves
many of those roles reducing after the same `name` or `data-ref`, producing
large reduce/reduce families. LFortran has lower parser conflict volume because
it factors parser categories and defers distinctions to AST construction.

## Decision

StandardIR remains authoritative and retains every normative role and source
lineage. A parser projection may deterministically generate role-family
specialization: structurally identical aliases may share a parser production,
while the generated node or transition retains the complete source-role set
and provenance needed by later semantic analysis. The specialization is
derived from the grammar graph and declared target capabilities, not from
LFortran source and not from a rule-number or mnemonic exception.

Every merge, delayed distinction and source-lineage union is emitted as a
machine-checkable witness. A target that cannot preserve the role set or prove
the normalization is rejected. The source IR is never rewritten to achieve a
lower conflict count.

## Rejected

* Copying LFortran's parser categories or AST actions into StandardIR.
* Deleting normative role productions because they are parser aliases.
* Adding one-off Fortran rule exceptions to reduce Bison conflicts.
* Treating raw conflict counts as a language-equivalence proof.

## Reversal condition

Write a successor if the generic specialization loses a normative role,
source lineage or accepted/rejected language behavior in an independent
witness, or if the retained role metadata cannot be consumed deterministically
by semantic generation.
