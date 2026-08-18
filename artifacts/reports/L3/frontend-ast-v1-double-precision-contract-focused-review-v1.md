# Focused review: bounded DOUBLE PRECISION type-spec contract

Task: `T-L3-frontend-double-precision-contract`

Frozen central revision: `306952a6ee96f09156f147861e1f8f2ae87dfc11`

The contract is a pre-implementation handoff, not a semantic promotion. It
contains one exact `double precision :: x` source case, the promoted REAL case
as a changed-type control, and a malformed `double precision ::` negative. The
independent validator binds the exact source bytes, source witness path and
hash, `main`/`main`/`x` identity fields, exact boundary/property, actual
StandardIR file and hash, canonical source lines, and expected outcomes.

Three initial adversarial packets found and corrected in sequence: missing AST
identity assertions, missing actual StandardIR path/hash validation, and
missing boundary/property scope binding. The reproducibility packets passed
throughout; those caught failures remain retained in the run ledger.

Final focused review:

- Scope C, adversarial correctness and oracle independence: `PASS`.
- Scope D, reproducibility and evidence integrity: `PASS`.

Both final reviewers used `gpt-5.6-luna` with medium reasoning on the same
immutable revision. The contract is verified as `PASS-BOUNDED-ONLY`; it makes
no claim about general intrinsic-type parsing, arbitrary Fortran, or full M3.
