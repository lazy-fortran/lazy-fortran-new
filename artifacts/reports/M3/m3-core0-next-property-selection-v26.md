# M3 residual selection after C761 and C760

Selection status: `PASS-SELECTION-ONLY`.

## Partition

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751","C752","C754","C757","C759","C760","C761"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It produces 134 rows: 78 `disputed` and 56 `unwitnessed`. The first row is
C762@1, status `disputed`, constraint C762. No model ran and no semantic fact
was promoted.

## Independent source audit

C762 is J3-24-007 R741, canonical lines 3872--3873, printed page 79, ledger
page 93, and byte span `243055:127` in the pinned canonical text:

```text
10 C762 (R741) If the procedure pointer component has an implicit interface or has no arguments, NOPASS shall
11 be specified.
```

The page-index binding is `page 93 start 239957 length 2451`. The source is on
PDF page 94, which carries printed page 79. Existing StandardIR R741 has lhs
`proc-component-def-stmt`, page 94, byte span `242577:118` and occurrence 91;
R742 has lhs `proc-component-attr-spec`, page 94, byte span `242765:96` and
occurrence 92, including the `NOPASS` alternative.

The canonical text SHA-256 is
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9`; the
page-index SHA-256 is
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`; the
StandardIR SHA-256 is
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`; and the
normative PDF SHA-256 is
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

The audit used byte-offset inspection, page-index inspection, PDF page
inspection and hash checks. The Luna harvest remains labelled intake only; it
is not source authority.

This selects a source occurrence and bounded contract target only. The next
task may implement a finite conditional-NOPASS oracle, but it must provide an
independent expected-outcome table, negative neighbours, mutation controls,
replayable artifacts and zero model-driven promotion.
