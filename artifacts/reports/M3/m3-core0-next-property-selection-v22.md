# Post-C752 residual bounded-property selection

Selection status: `PASS-SELECTION-ONLY`. Run the following command against the
pinned ledger to regenerate the partition:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751","C752"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It produces 139 rows: 81 `disputed` and 58 `unwitnessed`, with `C754@1`
first. The row is model-self-consistency evidence only and is not promoted.

## Selected source

C754 is J3-24-007 clause 7, canonical lines 3847--3848, printed page 79,
byte span `241715:150`:

```text
33 C754 (R737) If neither the POINTER nor the ALLOCATABLE attribute is specified, each component-array-
34 spec shall be an explicit-shape-spec-list.
```

The span is contained by page-index record 93 (`start 239957`, `length 2451`).
Existing StandardIR supplies R737 (`data-component-def-stmt`), R738
(`component-attr-spec`), R739 (`component-decl`) and R740
(`component-array-spec`). The next bounded candidate should preserve unknown
attribute and shape states rather than infer them.

Pinned hashes: witness ledger
`77c6758a8b0fe5ffbdbe599b8f417b34e8e708ca495ce69b0753454cb144b20c0`, canonical
text `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page
index `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
StandardIR `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`,
and normative PDF `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

No model ran and no semantic fact was promoted.
