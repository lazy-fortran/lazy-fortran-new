# M3 residual selection after C759 and C760

Selection status: `PASS-SELECTION-ONLY`.

## Partition

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751","C752","C754","C757","C759","C760"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It produces 135 rows: 79 `disputed` and 56 `unwitnessed`. The first row is
C761@1, status `disputed`, constraint C761. No model ran and no semantic fact
was promoted.

## Independent source audit

C761 is J3-24-007 R741, canonical line 3871, printed page 79, ledger page 93,
and byte span `242981:74` in the pinned canonical text:

```text
9 C761 (R741) POINTER shall appear in each proc-component-attr-spec-list.
```

The page-index binding is `page 93 start 239957 length 2451`. The source is on
PDF page 94, which carries printed page 79. Existing StandardIR R741 has lhs
`proc-component-def-stmt`, page 94, byte span `242577:118` and occurrence 91;
R742 has the `POINTER` alternative in `proc-component-attr-spec`, so the
bounded target can reuse existing source-backed shapes.

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
task may implement the finite pointer-presence oracle, but it must provide an
independent expected-outcome table, negative neighbours, mutation controls,
replayable artifacts and zero model-driven promotion.
