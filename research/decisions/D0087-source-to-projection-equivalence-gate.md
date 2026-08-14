# D0087. Require source-to-projection equivalence before the grammar gate

Date: 2026-08-15
Status: amended by D0088
Amends: D0086

## Context

Luna's review of E0147 `R000269` found that ANTLR4, Bison and tree-sitter
accepted exports even though the projection had collapsed multi-alternative
source productions such as R502 and R515 to their first branch. The validator
checked target syntax, but not whether the target retained every source
alternative. `same_expression` also treated distinct normalized reference
names as equal, and the indirect-left-recursion pass expanded ordinary
non-recursive references.

## Decision

1. A grammar export is not valid until a deterministic source-to-projection
   equivalence witness proves that every source-backed alternative is either
   represented in the target or explicitly mapped by a generic,
   provenance-preserving transformation. A target parser generator accepting
   the file is necessary but not sufficient.
2. The witness is generic: it compares source occurrence/alternative identity
   and normalized expression structure. It fails closed on a dropped branch,
   unexplained suppression, or unequal expression identity. It may not name
   Fortran rule numbers.
3. Normalization preserves ordinary references. Indirect left-recursion
   substitution is permitted only when the left-corner graph proves a cycle;
   duplicate elimination compares kind, name, bounds and all children
   explicitly.
4. Provenance labels distinguish the canonical extracted-text hash from the
   PDF artifact hash. A field named `source-sha256` is not reused for both.
5. E0147 remains open until the corrected production commit, source-to-
   projection witness, all three external validators, the mutation controls,
   and the required Luna review pass on the same pinned run.

## Rejected

* Treating validator acceptance as evidence of fidelity. A parser generator
  can accept an under-approximating grammar.
* Repairing R502, R515 or any other production by name. The defect is in the
  generic normalization/equivalence mechanism.
* Counting source annotations alone. Suppressed provenance can remain visible
  while the corresponding grammar branch has disappeared.

## Reversal condition

Write a successor if a target format cannot admit a faithful generic witness
for a source construct. The successor must retain the source expression,
explain the format-specific projection, and define an independent acceptance
criterion without weakening the source-equivalence gate.
