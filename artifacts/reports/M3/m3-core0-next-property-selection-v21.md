# Post-C751 residual bounded-property selection

Selection status: `PASS`. The exact post-C751 partition leaves 140 residual
rows: 81 `disputed` and 59 `unwitnessed`; `C752@1` is first. The retained row
is model-self-consistency evidence only and is not promoted.

Regenerate the partition with:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750","C751"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

## Selected source

C752 is J3-24-007 clause 7, canonical lines 3842--3844, printed page 79, and
byte span `241335:223`:

```text
28 C752 (R737) If a coarray-spec appears, the component shall not be of type C_PTR or C_FUNPTR from
29 the intrinsic module ISO_C_BINDING (18.2), or of type TEAM_TYPE from the intrinsic module
30 ISO_FORTRAN_ENV (16.10.2).
```

The span is contained by canonical page-index record 93 (`start 239957`,
`length 2451`). Existing StandardIR supplies the data-component context through
R737 (`data-component-def-stmt`) and R739 (`component-decl`), and type-shape
categories through R702 (`type-spec`), R703 (`declaration-type-spec`) and R704
(`intrinsic-type-spec`).

The named module-defined types `C_PTR`, `C_FUNPTR` and `TEAM_TYPE` are not
currently represented as direct StandardIR rows. That is an explicit boundary
for the next slice: a candidate with unknown type identity must remain
`UNRESOLVED`; the implementation must not infer module type identity from a
keyword or from model output.

Pinned hashes: witness ledger
`77c6758a8b0fe5ffbdbe599b8f417b34e8e708ca495ce69b0753454cb144b20c`, canonical
text `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page
index `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
StandardIR `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`,
and normative PDF `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

No model was run and no semantic fact was promoted.

The first ledger attempt is retained as R000603 because runs are append-only;
its selector path was malformed. Corrected replay R000604 is also retained
because the report and decision hashes were corrected after that append-only
record. R000605 is the authoritative selection record and uses the path shown
above.
