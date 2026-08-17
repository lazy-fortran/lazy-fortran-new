# M3 post-C744 bounded-property selection

Status: `PASS` for selection only. No semantic fact is promoted and full M3
remains `OPEN`.

## Residual verifier

The exact twenty-four-contract partition reports 147 residual rows: 84
`disputed` and 63 `unwitnessed`, with `C745@1` first. Its compact output has
SHA-256 `31bc085283e7a85f2fab7a9bdad8aea00e8880e0b9d2a6083fef2f373ee519b9`.
The selected model-origin row is input only; it is not evidence.

Regenerate the partition with:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

## Source binding

C745 is bound to J3-24-007, clause 7, canonical lines 3665--3667, printed
page 89, byte span `232141:276`. The exact UTF-8 source bytes are:

```text
20 C745 (R726) If SEQUENCE appears, the type shall have at least one component, each data component shall
21 be declared to be of an intrinsic type or of a sequence type, the derived type shall not have any type
22 parameter, and a type-bound-procedure-part shall not appear.
```

The existing StandardIR bindings are R726 (`derived-type-def`, page 88), R731
(`sequence-stmt`, page 89) and R735 (`component-part`, page 93). All three
rows carry source SHA-256
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`.
The canonical source, page index, StandardIR and normative PDF hashes are
respectively `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9`,
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

## Selected property

D0151 selects the first C745 obligation only: when SEQUENCE appears, the
derived type has at least one component. The typed candidate is:

```text
sequence-presence: absent | present | unknown
component-presence: zero | one-or-more | unknown
context: derived-type-def | other | unknown
```

The next bounded oracle shall return `ACCEPTED` for absent SEQUENCE in the
derived-type-def context and for present SEQUENCE with one-or-more components;
`REJECTED` for present SEQUENCE with zero components there; and
`UNRESOLVED` otherwise. It shall cover the 27-state product, positive
vacuous/satisfied witnesses, one negative neighbour, unresolved controls and
source/page/StandardIR/contract mutations. It shall not parse definitions,
count real components, classify component types, inspect type parameters or
type-bound procedures, execute a model or promote a semantic fact.

The exact byte offset was computed from UTF-8 bytes using:

```text
nl -ba .cache/runs/E0001/R000003/j3-24-007.canonical.txt | sed -n '3665,3667p'
rg -n '^page 89 ' .cache/runs/E0001/R000003/j3-24-007.pages.index
sed -n '77,81p' .cache/runs/E0171/R000433-provenance-replay/standardir.sx
```

Selection central revision: `59556cebfa31f9e0d65374e3112f048bd01696ec`.
No model calls or semantic promotions were performed.
