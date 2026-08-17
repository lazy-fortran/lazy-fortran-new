# Post-C745 M3 residual selection

Selection status: `PASS`; no semantic fact is selected or promoted by this
audit. The next bounded source-backed property is `C746@1`.

## Mechanical partition

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witnesses.jsonl
```

It returns 146 residual rows: 84 `disputed` and 62 `unwitnessed`, with
`C746@1` first. The pinned witness ledger is SHA-256
`77c6758a0eb52587c7847420bd72e56560b1e1cb5cb0d6acc5d0e69229e53b1b`.
The partition uses no model execution and performs no semantic promotion.

## Source binding

C746 is J3-24-007 clause 7, canonical lines 3764--3765, printed page 77,
UTF-8 byte span `237401:171`, rule R732. Its existing StandardIR witnesses
are R727 (`derived-type-stmt`), R732 (`type-param-def-stmt`) and R733
(`type-param-decl`). The next contract is recorded in
`research/decisions/D0152-twenty-sixth-m3-c746-type-parameter-name-membership.md`:
a typed membership relation between the name in a type-param-def-stmt and the
names in its derived-type-stmt, with derived-type-def context.

The retained C746 model row is `unwitnessed` because its evaluator does not
support the subset relation. It is input for residual ordering only, not
evidence for the source-backed relation.

The pinned canonical text SHA-256 is
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, the page
index SHA-256 is
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`, and the
StandardIR SHA-256 is
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`.
