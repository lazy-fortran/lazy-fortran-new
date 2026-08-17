# M3 residual selection after C763

Selection status: `PASS-SELECTION-ONLY`.

## Partition

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751","C752","C754","C757","C759","C760","C761","C762","C763"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It produces 132 rows: 76 `disputed` and 56 `unwitnessed`. The first row is
C768@1, status `disputed`, constraint C768. No model ran and no semantic fact
was promoted.

## Independent source audit

C768 is J3-24-007 R737, canonical lines 3977--3979, printed page 82, PDF page
96, ledger page 96, and byte span `249918:239` in the pinned canonical text:

```text
30 C768 (R737) If => appears in component-initialization, POINTER shall appear in the component-attr-spec-
31 list. If = appears in component-initialization, neither POINTER nor ALLOCATABLE shall appear in
32 the component-attr-spec-list.
```

The page-index binding is `page 96 start 247480 length 3187`; the source span
falls within that record. PDF page 96 independently contains C768 and printed
page 82. Existing StandardIR R737@87 has lhs `data-component-def-stmt`,
R738@88 has lhs `component-attr-spec` with POINTER and ALLOCATABLE alternatives,
R739@89 has lhs `component-decl` with optional component-initialization, and
R743@93 has lhs `component-initialization` with `=` and `=>` alternatives.

The source-span SHA-256 is
`587c666dfc654e3eb84b75af6521dedb1c551521777c24ec0be38c6341acf213`. The
canonical text SHA-256 is
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9`; the
page-index SHA-256 is
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`; the
StandardIR SHA-256 is
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`; and the
normative PDF SHA-256 is
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

This selects a source occurrence and a bounded initialization-attribute
contract target only. The next task may implement the finite typed oracle, but
it must provide an independent expected-outcome table, negative neighbours,
mutation controls, replayable artifacts and zero model-driven promotion.
