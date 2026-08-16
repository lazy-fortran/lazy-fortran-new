# E0175 — C1106 semantic-oracle vertical slice

This experiment is the first bounded M3 delivery contract. It checks one
source-backed property: an ASSOCIATE opening and closing statement either both
omit their construct name or both specify the same name. The property is the
J3/24-007 C1106 constraint and is bound to the already represented StandardIR
rows R1102, R1103 and R1106.

The candidate is a typed pair of `start` and `end` name sides. Each side has
`known`, `present` and nullable `value` fields. The mechanical oracle returns
`ACCEPTED`, `REJECTED` or `UNRESOLVED`; an unknown side cannot be promoted to a
semantic rejection. Model output is not an input and cannot promote a fact.

Run the complete gate with:

```text
tests/e2e/run-m3-c1106.sh
```

The command builds and canonicalizes the pinned semantic-items SX through
`standard-new`, checks the normative PDF and canonical text hashes, binds the
three StandardIR source rows, evaluates the five fixed witnesses, runs three
source mutations that must fail closed, and compares the replay trace with
`artifacts/traces/m3-c1106-source-backed-v0.json`.

This is not arbitrary Fortran parsing, a semantic analyzer, compiler IR,
parser-conflict work, or a model experiment. A later M3 slice needs its own
accepted contract and verifier.
