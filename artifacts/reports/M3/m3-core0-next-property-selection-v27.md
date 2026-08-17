# M3 residual selection after C762

Selection status: `PASS-SELECTION-ONLY`.

## Partition

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751","C752","C754","C757","C759","C760","C761","C762"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It produces 133 rows: 77 `disputed` and 56 `unwitnessed`. The first row is
C763@1, status `disputed`, constraint C763. No model ran and no semantic fact
was promoted.

## Independent source audit

C763 is J3-24-007 R741, canonical lines 3874--3875, printed page 79, PDF page
94, ledger page 94, and byte span `243182:139` in the pinned canonical text:

```text
12 C763 (R741) If PASS (arg-name) appears, the interface of the procedure pointer component shall have a dummy
13 argument named arg-name.
```

The page-index binding is `page 94 start 242409 length 2660`; the source span
falls within that record. PDF page 94 independently contains the C763 text and
printed page 79. Existing StandardIR R741 has lhs
`proc-component-def-stmt`, page 94, byte span `242577:118` and occurrence 91;
R742 has lhs `proc-component-attr-spec`, page 94, byte span `242765:96` and
occurrence 92, including the `PASS (arg-name)` alternative. R603@31 and
R1534@509 are retained as the existing `name` and `dummy-arg-name` shapes; the
bounded candidate supplies only their name relation.

The canonical text SHA-256 is
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9`; the
page-index SHA-256 is
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`; the
StandardIR SHA-256 is
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`; and the
normative PDF SHA-256 is
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

This selects a source occurrence and a bounded conditional-name contract
target only. The next task may implement the finite typed oracle, but it must
provide an independent expected-outcome table, negative neighbours, mutation
controls, replayable artifacts and zero model-driven promotion.
