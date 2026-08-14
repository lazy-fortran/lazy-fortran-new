# E0118 independent source-oracle gate

`analyse.sh` consumes the frozen E0117 terminal ledger and the committed E0083
oracle table. It makes no model calls and invokes no compiler.

```bash
research/experiments/E0118-can-independently-generated-source-deriv/analyse.sh
```

The default inputs are
`.cache/runs/E0117/R000003-full/rows.jsonl` and
`research/experiments/E0083-can-deterministic-predicate-patterns-for/independent-oracle.tsv`.
Use `E0117_ROWS`, `E0118_ORACLE`, and `E0118_OUTDIR` to select alternate files.
The command writes to the ignored `.cache/runs/E0118/R000001` directory.

## Independent source predicate

The E0083 table is parsed as an S-expression table by `analyze.py`. Its
predicate AST is separate from the JSON predicate in each E0117 proposal.
Case materialization reads only the E0083 AST, its source-linked fact names,
its literal operands, its declared fact fields, and fixed typed boundaries.
The E0117 model predicate is evaluated after materialization. Neither model
witness facts nor model expected Booleans enter the case generator.

`source_expected` is computed from the parsed E0083 AST. A case record also
contains the independently evaluated `candidate_result`, the E0083 predicate
text, and the E0083 file hash. A model proposal is compared only when its
`constraint_id` has an E0083 row. An accepted proposal without that oracle row
gets zero cases and `source_case_status: oracle_unavailable`.

The E0083 oracle hash is recorded in `summary.json`, `summary.tsv`, and the
case provenance. Recompute it with:

```bash
sha256sum research/experiments/E0083-can-deterministic-predicate-patterns-for/independent-oracle.tsv
```

## Row and case statuses

The analyzer requires the E0117 retained denominator and writes one `rows.jsonl`
record for every input `row_key`, including hard failures, unresolved rows, and
the reference-only row. Rows without proposals receive `no_model_predicate`,
except the reference-only row, which receives `reference_only`.

Accepted proposals receive `schema_source_accepted` after the E0116 schema and
source provenance checks. A failed check receives `schema_source_rejected`.
The terminal ledger lacks a model-file hash, so each candidate records that
field as unavailable. This blocks promotion without changing the historical
ledger.

Finite comparison cases use `match`, `mismatch`, `evaluator_error`, and
`oracle_unavailable`. Model witness scoring is diagnostic only and uses
`self_consistent`, `self_inconsistent`, `evaluator_error`, and `not_compared`.
Unsupported oracle forms remain explicit with their reason.

## Outputs

- `rows.jsonl` contains the complete row denominator and overlap status.
- `cases.jsonl` contains only E0083-derived cases for rows with both an E0117
  proposal and an E0083 oracle row. It contains explicit unavailable records
  where finite derivation fails.
- `compiler-cells.jsonl` contains unavailable cells for every emitted case and
  each declared compiler. Executable presence does not count as agreement.
- `mutations.jsonl` records expected-outcome substitution, source-hash and
  provenance substitution, and changed typed fact controls.
- `summary.json` and `summary.tsv` contain overlap counts, case outcomes, file
  hashes, and promotion status.

The command records `semantic_promotions: 0`. It does not edit StandardIR or
any historical E0117 or E0083 artifact.

## Tests

```bash
bash -n analyse.sh selftest.sh
selftest.sh
```

The fixed fixture oracle has a model predicate that differs from its source
predicate. The selftest asserts that the independent comparison emits a
mismatch. It also checks logical forms, an unsupported oracle constructor, the
oracle hash, compiler unavailability, and mutation rejection. The assertions
inspect expected behavior rather than comparing generated files to snapshots.

The full standard-derived compiler fixtures remain unavailable. No compiler
agreement is claimed, and no compiler is invoked until a faithful fixture is
added under a later bounded slice.
