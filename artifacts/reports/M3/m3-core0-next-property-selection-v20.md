# Post-C750 residual bounded-property selection

Selection status: `PASS`. The exact post-C750 partition leaves 141 residual
rows: 82 `disputed` and 59 `unwitnessed`; `C751@1` is first. The retained
row is model-self-consistency evidence only and is not promoted.

Regenerate the partition with:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745","C746","C747","C748","C749","C750"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id, first_status: .[0].status}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

## Selected source

C751 is J3-24-007 clause 7, canonical lines 3840--3841, printed page 79, and
byte span `241193:142`:

```text
26 C751 (R737) If a coarray-spec appears, it shall be a deferred-coshape-spec-list and the component shall have
27 the ALLOCATABLE attribute.
```

The span is contained by canonical page-index record 93 (`start 239957`,
`length 2451`). Existing StandardIR provides the component context through
R737 (`data-component-def-stmt`) and R739 (`component-decl`), and the coarray
shape alternatives through R809 (`coarray-spec`), R810
(`deferred-coshape-spec`) and R811 (`explicit-coshape-spec`). The relevant
page-index records are page 93 (`239957:2451`), page 121 (`314530:3127`) and
page 122 (`317658:2535`).

## Candidate contract

D0161 proposes one bounded C751 relation over:

```text
coarray-spec: absent | deferred-coshape-list | explicit-coshape-spec | unknown
allocatable-attribute: absent | present | unknown
```

The fixed context is a data component represented by R737/R739. The proposed
deterministic oracle accepts an absent coarray-spec (the C751 condition is
vacuous) and a deferred-coshape-list with ALLOCATABLE present; it rejects a
deferred-coshape-list without ALLOCATABLE and every explicit-coshape-spec; it
returns `UNRESOLVED` for unknown states. This is a selection contract, not an
implementation or a claim about arbitrary Fortran declarations.

No model was run and no semantic fact was promoted.

Pinned hashes: witness ledger
`77c6758a8b0fe5ffbdbe599b8f417b34e8e708ca495ce69b0753454cb144b20c`, canonical
text `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page
index `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
StandardIR `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`,
and normative PDF `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.
