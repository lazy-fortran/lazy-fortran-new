# M3 Core 0 witness-coverage reconciliation v1

Status: `PASS` for the reconciliation task; full M3 remains `NEEDS EVIDENCE`.

Revision: `52ef9dd`

Task: `T-M3-core0-witness-coverage-reconciliation`

## Inputs and commands

The retained witness ledger is
`.cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl`, SHA-256
`77c6758a8b0fe5ffbdbe599b8f417b34e8e708ca495ce69b0753454cb144b20c`.

The named task verifier is:

```text
jq -s 'map(select(.status == "disputed" or .status == "unwitnessed")) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), row_keys: map(.row_key)}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The reconciliation uses the same pinned input and the explicit promoted set
`C1106`, `C702`, `C601`, `C603`, `C721`, `C725`, `C718`, `C723`, `C729`,
`C719`, `C738`, `C1579`, `C1586`:

```text
jq -s '
  def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586"];
  def is_promoted($id): any(promoted[]; . == $id);
  {
    promoted_contract_rows: (map(select(is_promoted(.constraint_id)) | {row_key, constraint_id, status}) | sort_by(.constraint_id)),
    residual_by_bucket: (map(select(.status == "disputed" or .status == "unwitnessed")) | group_by(if is_promoted(.constraint_id) then .constraint_id else "outside-promoted-contracts" end) | map({bucket: (if is_promoted(.[0].constraint_id) then .[0].constraint_id else "outside-promoted-contracts" end), count: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), row_keys: map(.row_key)}))
  }
' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The independent check requires the retained E0181 clean replay `R000075` to
pass, and checks that the reconciliation partition has no missing or duplicate
row keys. It is a partition check only; it cannot promote a semantic fact.

## Reconciliation result

The named verifier reports 163 residual rows: 94 `disputed` and 69
`unwitnessed`. The promoted-contract join is:

| Contract | Ledger row | Retained witness status |
|---|---|---|
| C1106 | C1106@1 | self-consistent |
| C702 | C702@1 | disputed |
| C601 | C601@1 | not-applicable |
| C603 | C603@1 | not-applicable |
| C721 | C721@1 | self-consistent |
| C725 | C725@1 | disputed |
| C718 | C718@1 | unwitnessed |
| C723 | C723@1 | disputed |
| C729 | C729@1 | unwitnessed |
| C719 | C719@1 | not-applicable |
| C738 | C738@1 | not-applicable |
| C1579 | C1579@1 | not-applicable |
| C1586 | C1586@1 | not-applicable |

The five residual rows attached to already promoted bounded contracts remain
bounded evidence only. They do not make the other ledger rows witnessed and do
not close full M3.

The residual rows outside the promoted set are 158: 91 `disputed` and 67
`unwitnessed`. The exact row-key list is emitted by the reconciliation command
above. It is:

```text
C717@1, C720@1, C722@1, C724@1, C726@1, C731@1, C732@1, C733@1, C735@1,
C743@1, C744@1, C745@1, C746@1, C747@1, C748@1, C749@1, C750@1, C751@1,
C752@1, C754@1, C757@1, C759@1, C760@1, C761@1, C762@1, C763@1,
C768@1, C771@1, C772@1, C773@1, C776@1, C777@1, C780@1, C781@1,
C782@1, C785@1, C789@1, C790@1, C792@1, C793@1, C794@1, C795@1,
C796@1, C797@1, C7101@1, C7102@1, C7107@1, C7108@1, C7118@1,
C7120@1, C801@1, C803@1, C807@1, C829@1, C846@1, C873@1, C895@1,
C8101@1, C908@1, C909@1, C910@1, C912@1, C913@1, C914@1, C919@1,
C920@1, C921@1, C922@1, C923@1, C924@1, C925@1, C938@1, C939@1,
C940@1, C941@1, C949@1, C954@1, C1002@1, C1005@1, C1006@1, C1009@1,
C1011@1, C1016@1, C1017@1, C1018@1, C1019@1, C1024@1, C1025@1, C1026@1,
C1028@1, C1031@1, C1032@1, C1037@1, C1039@1, C1148@1, C1152@1,
C1153@1, C1154@1, C1162@1, C1163@1, C1164@1, C1165@1, C1166@1,
C1167@1, C1168@1, C1169@1, C1174@1, C1175@1, C1176@1, C1184@1,
C1189@1, C1204@1, C1206@1, C1303@1, C1304@1, C1307@1, C1308@1,
C1311@1, C1312@1, C1313@1, C1401@1, C1404@1, C1405@1, C1406@1,
C1412@1, C1415@1, C1501@1, C1502@1, C1505@1, C1507@1, C1509@1,
C1510@1, C1515@1, C1521@1, C1523@1, C1524@1, C1525@1, C1526@1,
C1527@1, C1552@1, C1556@1, C1559@1, C1570@1, C1572@1, C1574@1,
C1575@1, C1576@1, C1577@1, C1580@1, C1581@1, C1583@1, C1584@1,
C1585@1, C1587@1, C1589@1, C1590@1, C1805@1, C1806@1
```

No model was run. No semantic fact was promoted. The precise remaining blocker
is the outside-promoted set above; the next task is
`T-M3-core0-next-bounded-property-selection`.
