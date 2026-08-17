# Post-C746 M3 residual selection

Selection status: `PASS`; no semantic fact is selected or promoted by this
audit. The next bounded source-backed property is `C747@1`.

## Mechanical partition

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It returns 145 residual rows: 84 `disputed` and 61 `unwitnessed`, with
`C747@1` first. The pinned witness ledger is SHA-256
`77c6758a8b0fe5ffbdbe599b8f417b34e8e708ca495ce69b0753454cb144b20c`. The
partition uses no model execution and performs no semantic promotion.

## Source binding

C747 is J3-24-007 clause 7, canonical lines 3766--3767, printed page 77,
UTF-8 byte span `237572:183`, rule R732. Its existing StandardIR witnesses
are R727 (`derived-type-stmt`), R732 (`type-param-def-stmt`) and R733
(`type-param-decl`). The selected contract is recorded in
`research/decisions/D0153-twenty-seventh-m3-c747-type-parameter-name-exact-once.md`:
a typed occurrence-cardinality relation between a type-param-name supplied by
its derived-type-stmt and its occurrences in type-param-def-stmts in the same
derived-type-def.

The retained C747 model row has `duplicate-def`, `extra-def`, `missing-def` and
`valid-single-match` cases. It is an ordering input only. Its self-consistency
result is not evidence for the source-backed contract, and the `extra-def`
case remains outside this C747 leaf because C746 owns membership.

The pinned canonical text SHA-256 is
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, the page
index SHA-256 is
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`, and the
StandardIR SHA-256 is
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`.

## Bounded contract

The next implementation task shall use the typed fields:

```text
derived-name-presence: absent | present | unknown
definition-occurrence-cardinality: zero | one | many | unknown
context: derived-type-def | other | unknown
```

Its deterministic oracle shall accept the vacuous absent case and the
present/one case in derived-type-definition context, reject present/zero and
present/many, and return `UNRESOLVED` for all other states. It shall include
missing and duplicate negative neighbors, unresolved controls and source,
page, rule, StandardIR and contract-identity mutations. It shall record zero
model calls and zero semantic promotions. It shall not parse definitions,
compare real names, resolve names, check extra definition names or close M3.
