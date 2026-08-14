# E0118 deterministic source-finite gate

`analyse.sh` consumes the frozen E0117 terminal ledger and writes a reproducible
analysis under `.cache/runs/E0118/R000001`.

```bash
research/experiments/E0118-can-independently-generated-source-deriv/analyse.sh
```

The input defaults to
`.cache/runs/E0117/R000003-full/rows.jsonl`. `E0117_ROWS` selects another
ledger and `E0118_OUTDIR` selects another ignored output directory. The command
makes zero model calls and invokes no compiler.

## Denominator and row statuses

The command requires 287 unique retained row keys. It writes one record for
each input row to `rows.jsonl`, including hard failures, unresolved rows, and
the reference-only row. Rows without a proposal receive
`no_model_predicate`, except the reference-only row, which receives
`reference_only`. Accepted proposals receive `schema_source_accepted` after
constructor, source-hash, source-location, and evidence checks. A failed check
receives `schema_source_rejected`.

The terminal E0117 model file hash is absent from the retained ledger. Each
candidate record therefore records `model_file_sha256: null` and
`model_file_sha256_status: unavailable_in_terminal_ledger`. This prevents a
promotion claim and leaves the missing provenance visible.

## Independent case construction

Case materialization runs before candidate evaluation and accepts only the
predicate, its literal operands, and fixed typed boundary values. It never
reads `witnesses`, witness fact maps, or witness `expect` values. The supported
finite constructors are `and`, `or`, `not`, `implies`, `eq`, `ne`, `lt`, `le`,
`gt`, `ge`, `in`, `not-in`, `present`, `absent`, `has`, `same-as`, `type-is`,
and `rank-is`.

Boolean facts use false and true. Integer and real facts use every predicate
literal plus one typed value on either side. String facts use each predicate
literal, the empty string, and `__other__`. `same-as` uses the two fixed symbol
values `__same__` and `__different__`. A conflicting type, unsupported
constructor, or case product above the fixed 4096-case limit receives
`oracle_unavailable`. The unsupported form remains in the row output with its
reason.

`source_expectation` is a separate source-relation traversal. The candidate
traversal is `evaluate_candidate`. Every generated case records both the
mechanically derived `source_expected` value and the separately evaluated
`candidate_result`. Case statuses are `match`, `mismatch`, or
`evaluator_error`. Model witness comparisons are diagnostic only and use the
statuses `self_consistent`, `self_inconsistent`, `evaluator_error`, and
`not_compared`.

## Outputs

- `rows.jsonl` contains the complete row denominator and row-level statuses.
- `cases.jsonl` contains materialized cases, source expectations, candidate
  results, provenance, and model-consistency diagnostics.
- `compiler-cells.jsonl` contains one explicit unavailable cell per case and
  each declared compiler. No compiler agreement is inferred from executable
  presence. A faithful fixture is a prerequisite for invocation.
- `mutations.jsonl` records expected-outcome substitution, source-hash and
  provenance substitution, and changed typed fact controls. A rejected
  mutation has `passed: true`. An accepted mutation has `passed: false`.
- `summary.json` and `summary.tsv` contain the declared metrics and hashes of
  the input and generated case set.

The command records `semantic_promotions: 0`. It does not edit StandardIR or
any historical E0117 artifact.

## Tests

```bash
bash -n analyse.sh selftest.sh
selftest.sh
```

The fixed ledger in `fixtures/ledger.jsonl` has one row per requested logical
form, plus an unsupported `relation` constructor.
The shell assertions are behavioral checks with expected truth values, case
unavailability, compiler unavailability, and mutation rejection. They do not
compare generated files with checked-in snapshots.

The current implementation has no safe compiler fixture for the full
standard-derived cells. All compiler cells are therefore explicit unavailable
and no compiler agreement is claimed.
