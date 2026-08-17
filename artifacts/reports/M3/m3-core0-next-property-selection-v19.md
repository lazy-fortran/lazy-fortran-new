# Post-C749 residual bounded-property selection

Selection status: `PASS`. The exact post-C749 partition leaves 142 residual
rows: 82 `disputed` and 60 `unwitnessed`; `C750@1` is first.

Regenerate the result with:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The first residual is C750, J3-24-007 clause 7, canonical lines 3838--3839,
printed page 79, byte span `241058:135`:

```text
24 C750 (R737) If the POINTER or ALLOCATABLE attribute is specified, each component-array-spec shall be
25 a deferred-shape-spec-list.
```

The span is contained by canonical page-index record 93 (`start 239957`,
`length 2451`). The reusable StandardIR witnesses are R737
(`data-component-def-stmt`) and R740 (`component-array-spec`).

D0159 selects one bounded relation: in a component definition, a present
POINTER or ALLOCATABLE attribute paired with a deferred-shape component-array
spec is eligible; the same attribute paired with an explicit-shape spec is
ineligible; all other typed states are `UNRESOLVED`. This is a selection
contract, not the C750 implementation. No model was run and no semantic fact
was promoted.

Pinned source hashes: canonical text
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page index
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`, StandardIR
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and PDF
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.
