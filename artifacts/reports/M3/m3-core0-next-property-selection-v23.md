# M3 residual selection after C754

Selection status: `PASS-SELECTION-ONLY`.

The exact partition command was:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751","C752","C754"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The command produces 138 rows: 81 `disputed` and 57 `unwitnessed`. The first
row is C757@1, with status `disputed` and witness mode
`model-self-consistency`; that status is retained and is not promoted.

## Source binding

C757 is J3-24-007 clause 7, canonical lines 3851--3852, printed page 79 and
byte span `242052:120`, covered by page-index record `93:239957:2451`. The
canonical source text is:

```text
C757 (R737) If the CONTIGUOUS attribute is specified, the component shall be an array with the POINTER
attribute.
```

The source document SHA-256 is
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, the
normative PDF SHA-256 is
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`, the
page-index SHA-256 is
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`, and the
StandardIR SHA-256 is
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`.
Existing StandardIR rows R737, R738 and R739 supply the reusable component
definition, attribute and array-shape structure.

This selects a source occurrence only. No model ran and no semantic fact was
promoted. The next task must define the bounded C757 contract and its
independent oracle.
