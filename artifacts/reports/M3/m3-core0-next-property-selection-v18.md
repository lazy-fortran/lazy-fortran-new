# Post-C748 residual bounded-property selection

Selection status: `PASS`. The exact post-C748 partition leaves 143 residual
rows: 82 `disputed` and 61 `unwitnessed`; `C749@1` is first.

Regenerate the result with:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The first residual is C749, J3-24-007 clause 7, canonical lines 3835--3837,
printed page 79, byte span `240824:234`:

```text
21 C749 (R737) If neither the POINTER nor the ALLOCATABLE attribute is specified, the declaration-type-
22 spec in the component-def-stmt shall specify an intrinsic type, or a previously defined derived, enum, or
23 enumeration type.
```

The span is contained by canonical page-index record 93 (`start 239957`,
`length 2451`). The reusable StandardIR witnesses are R703
(`declaration-type-spec`, page 77, byte span `197098:309`) and R737
(`data-component-def-stmt`, page 93, byte span `240182:115`).

D0157 selects one bounded relation: when the context is a
`component-def-stmt`, neither POINTER nor ALLOCATABLE is specified, and the
declaration-type category is intrinsic, previously defined derived, enum or
enumeration, the candidate is eligible; the same context and absent
pointer/allocatable condition with another category is ineligible; all other
typed states are `UNRESOLVED`. This is a selection contract, not the C749
implementation. No model was run and no semantic fact was promoted.

Pinned source hashes: canonical text
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page index
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`, StandardIR
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and PDF
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.
