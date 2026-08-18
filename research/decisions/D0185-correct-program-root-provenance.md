# D0185. Correct the program-root boundary provenance

Date: 2026-08-18
Status: accepted
Amends: D0184

## Context

D0184 selected a bounded source-derived main-program-name boundary, but its
initial evidence list named the syntax productions without the constraint
that makes a mismatched `END PROGRAM` name invalid. J3-24-007 C1401, attached
to R1401 on canonical lines 13669--13670 and page 317, states that an included
end-program name must be identical to the program-statement name.

## Decision

Amend D0184 to include C1401 and canonical lines 13669--13670 in the exact
source evidence. The contract remains bounded to `program main` and `program
unit`, the mismatched-end negative, and existing AST v1 root/declaration
fields. Its producer replay must execute both positives and the negative; the
pre-implementation contract oracle alone cannot promote producer behavior.

## Rejected

Treating the mismatched-end rejection as an inference from R1402/R1403 alone,
or promoting the metadata-only contract without a replay harness, is rejected.

## Reversal condition

Write a successor if canonical lines 13669--13670 or C1401 fail against the
pinned J3-24-007 artifact, or if the independent replay cannot distinguish a
changed root name from a mismatched end name.
