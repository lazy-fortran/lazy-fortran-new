# M3 C748 focused review v1

Review status: `PASS`; promote C748 only as a bounded at-most-once oracle
leaf. Full M3 remains `OPEN`.

Frozen review commit: `37e0aa8799da340214438bcdc78ec7dc65f7029c`.

The semantic reviewer independently checked D0156 against canonical line 3834:
“shall appear more than once” is at-most-once, so zero occurrences are valid.
The source binding is exact: printed page 79, byte span `240727:97`, unique
containment by page-index record 93 (`start 239957`, `length 2451`), and
StandardIR R737. The reviewer recomputed the complete product as 6
`ACCEPTED`, 1 `REJECTED` (`present/many/component-def-stmt`) and 29
`UNRESOLVED`; all twelve mutations are rejected.

The reproducibility reviewer verified the E0214 manifest, R000579, the
byte-identical committed trace and result, environment and source hashes,
component pins, clean worktrees, contract negative control and active
verifier. The v0 defect and failed review R000578 remain retained and
non-promotable. Both reviewers found no remaining issue. Model calls and
semantic promotions are zero. This review does not claim parsing, name
resolution, general semantic analysis or compiler completeness.

Lifecycle: leaf `T-M3-c748-component-attr-spec-exact-once-oracle`, parent `M3`;
leaf status `OPEN` at review time, claim status `OPEN`, parent status `OPEN`,
evidence gate `PENDING`, review level `focused`, verdict `PASS`.
