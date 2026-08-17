# M3 residual selection after C757

Selection status: `PASS-SELECTION-ONLY`.

## Partition

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751","C752","C754","C757","C760"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It produces 136 rows: 79 `disputed` and 57 `unwitnessed`. The first row is
C759@1, status `unwitnessed`, witness mode `model-self-consistency`. That
status is retained and is not promoted.

## Independent source audit

C759 is J3-24-007 clause 7, canonical lines 3854--3855, printed page 79,
ledger page 92, and byte span `242269:126` in the pinned canonical text:

```text
40 C759 (R736) Each type-param-value within a component-def-stmt shall be a colon or a component specification
41 expression.
```

The page-index binding is `page 93 start 239957 length 2451`; PDF page 93
contains the same two-line source occurrence. Existing StandardIR R736 has
lhs `component-def-stmt`, page 93, byte span `240100:81`, occurrence 86.

The canonical text SHA-256 is
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`; the
page-index SHA-256 is
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`; the
StandardIR SHA-256 is
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`; and the
normative PDF SHA-256 is
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

The source audit used byte-offset inspection, page-index inspection,
`pdftotext` PDF comparison and hash checks. The provisional harvest packet is
not reused as source authority: it omits the continuation line, gives no byte
span and labels the printed page incorrectly.

This selects a source occurrence and a bounded contract target only. No model
ran for the selection and no semantic fact was promoted. The next task must
define and independently validate the finite C759 oracle before any claim is
closed.
