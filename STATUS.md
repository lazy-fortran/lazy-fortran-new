# Lazy Fortran delivery status

## Active milestone

L3 — first raw-source-to-executable Fortran slice

M3 bounded semantic-oracle slices remain retained evidence; full Core 0 remains
pending. D0173 retires residual CXXX intake as the default frontier. The
bounded L3 path has now passed the raw-source, declaration, typed-AST, source-
derived-name, program-root-name and intrinsic-type leaves. The generated
storage, sequence, STOP and PRINT waves are integrated; its central replay passes 146 routes
and is regenerated with `bash tests/e2e/check-generated-chain.sh`. The
single-expression witness exits 1, the ordered two-, three-, four-, five- and six-assignment
witnesses exit 8, 9, 10, 11 and 12, and the program-unit-v2
declaration/execution envelopes exit 8, 11 and 12 through matching stack
slots. The seven-, eight-, nine- and ten-assignment generated routes now also
carry the same storage transport and exit 13, 14, 15 and 16. The
two-assignment, five-assignment and six-assignment envelopes carry
the source-backed R509 execution-part boundary into FFC and fortback; the
six-assignment route uses `frontend-ast-v2/execution-part-6`. This remains
bounded sequence transport, not general statement parsing, name resolution,
arbitrary storage or full M3 semantics. The source-backed `STOP 7`, `PRINT *, 7`,
`PRINT *, 7, 8`, `PRINT *, 7, 8, 9`, `PRINT *, 7, 8, 9, 10` and
`PRINT *, 7, 8, 9, 10, 11`, `PRINT *, 7, 8, 9, 10, 11, 12`,
`PRINT *, 7, 8, 9, 10, 11, 12, 13`, `PRINT *, 7, 8, 9, 10, 11, 12, 13, 14`
and `PRINT *, 7, 8, 9, 10, 11, 12, 13, 14, 15` waves are integrated. The
nine-item route preserves
R1212/R1215/R1217 provenance, emits typed MIR
`const/output` repeated nine times then `return`, rejects three mutation
controls, and produces exact stdout `7` plus newline followed by `8` plus
newline and `9` plus newline and `10` plus newline and `11` plus newline and
`12` plus newline and `13` plus newline under qemu. The next parallel boundary
`14` plus newline and `15` plus newline under qemu. The next parallel boundary
is a ten-item output list; the next slice removes the current cardinality/value
specialization from the generated PRINT item path and checks novel values
`17, 18, 19` through one generated route. The stored-variable slice
now carries `integer :: x`, `x = 17` and `x = 23` with `PRINT *, x` through
generated AST-v2, MIR-v0 and RISC-V/qemu with exact stdout `17\n` and `23\n`;
its source-bound oracle also
rejects three source neighbours and fourteen artifact mutations. This does not parse
arbitrary Fortran, implement general I/O controls or formats, or promote M3
semantics. The generic integer PRINT-list successor now passes
`bash tests/e2e/check-generated-print-list.sh` for mixed three-item and
five-item lists, four rejected source neighbours, exact qemu output and the
preserved 146-route replay; its focused promotion review is retained at
`artifacts/reports/L3/generic-integer-print-list-focused-review-v1.md`. It
replaces item-numbered fields for this new
source shape but does not yet provide general I/O, formatted output, arrays,
non-integer output or corpus breadth.

The L3 slice `T-L3-generic-print-expression` now passes
`bash tests/e2e/check-generated-print-expression.sh`: two positive generic
PRINT sources carry the fixed `x + 1` expression item through typed AST,
load/const/add/output MIR, RISC-V and qemu, while AST/MIR/ELF mutations and
four source neighbours are rejected. The prior generic PRINT-list replay
also remains green. This is still one bounded integer-expression item, not
general expression parsing, formatted I/O, arrays, non-integer output or
semantic promotion.

The L3 slice `T-L3-generic-print-variable-expression` now passes
`bash tests/e2e/check-generated-print-expression-variable.sh`: two positive
generic PRINT sources carry the fixed `x + x` item through typed AST,
load/load/add/output MIR, RISC-V and qemu, while AST/MIR/ELF mutations and
four source neighbours are rejected. The prior x+1 expression and generic
PRINT-list replays remain green. This is still one bounded two-variable
expression item, not general expression parsing or semantic promotion.

The L3 slice `T-L3-generic-print-expression-multiply` is now integrated; it was prepared
with source-backed R1006/R1009 evidence and an independent oracle for `x * 2`
as one generic PRINT item. The component implementation and central replay now
pass; this remains one bounded multiplication expression item, not general
operator parsing or semantic promotion.

The L3 slice `T-L3-generic-print-expression-divide` was prepared
with source-backed R1006/R1009 evidence and an independent oracle for `x / 2`
as one generic PRINT item. Its component implementation wave is next.
The division component implementation and central replay now pass; the
negative neighbor is the still-out-of-scope `x ** 11` form. This remains one
bounded division expression item, not general operator parsing or semantic
promotion.

The L3 slice `T-L3-generic-print-expression-power` was prepared
with source-backed R1008 evidence and an independent oracle for `x ** 2` as
one generic PRINT item. Its component implementation and central replay now
pass; the preserved power negative is now the still-out-of-scope `x ** 11`.
This remains one bounded power expression item, not general operator parsing
or semantic promotion.

The L3 slice `T-L3-generic-print-expression-power-three` is now integrated:
the same source-backed generic PRINT item shape with exponent `3` produces
exact output `27`, while x**2 remains supported. Its independent
AST/MIR/ELF/qemu oracle passes both positive list shapes, four negative
controls and three artifact mutations. This is a bounded value extension,
not general power semantics or semantic promotion.

The L3 slice `T-L3-generic-print-expression-power-four` is now integrated:
the same source-backed generic PRINT item shape with exponent `4` produces
exact output `81`, while x**2 and x**3 remain supported. Its independent
AST/MIR/ELF/qemu oracle passes both positive list shapes, four negative
controls and three artifact mutations. The unsupported x**11 neighbor remains
explicit; this is a bounded value extension, not general power semantics.

The L3 slice `T-L3-generic-print-expression-power-literal` is now integrated:
the generated PRINT power path accepts integer-literal exponents 2–10,
including x**5, x**7 and x**10 with exact multi-digit runtime output. Its
independent dynamic AST/MIR/ELF/qemu oracle passes three positives, four
negative controls and artifact mutations. Variable, negative and malformed
exponents remain explicit refusals; arbitrary expression semantics remain open.

The next active L3 slice is `T-L3-generic-print-expression-power-variable`:
the bounded source-backed shape `x ** x`, requiring dynamic AST/MIR
load/load/pow lowering and runtime output `27`. Its contract, fixtures and
independent oracle are prepared; frontend, FFC, backend implementation and
central replay are pending. This is one variable-exponent property, not
general semantic analysis.

## Central goal

Progress through the cross-repository delivery path from normative source to
an executable compiler observable:

```text
normative source fact
→ standard-new artifact
→ frontend contract
→ StandardIR
→ downstream contract
→ deterministic observable
```

The result must have an independent oracle. This remains a bounded delivery
target, not a claim that the complete standard or compiler is implemented. L2
is promoted; M1-M2 is promoted by its corrected central replay and focused
review. Full Core 0 semantics remain open and no semantic fact is promoted.
C763 is the latest promoted bounded leaf, verified by its pushed clean replay
and focused review/evidence gate recorded in R000642; post-promotion
regression R000643 reproduces it. C762 is the preceding implemented leaf and
C760 is the preceding harvested leaf, recorded in R000623. The C768 worker
result is retained as parked local evidence and is not centrally integrated or
promoted.
The provisional harvest contains
110 packets with readiness counts `READY=17`, `NEEDS_REVIEW=7` and
`NOT_READY=86`; regenerate those values with
`jq -c '{packet_count,readiness_counts}' artifacts/staging/m3-harvest-v0.json`.
Selection R000568 passes for C747 at canonical lines 3766--3767, printed page
77, over existing StandardIR R727/R732/R733. The corrected C747 replay R000574
and focused review R000575 pass; C747 is promoted only as a bounded oracle
leaf. D0154 amends D0153 to record the two page coordinate systems separately.
Post-C747 selection R000576 identifies C748@1 as the next residual. C748's
corrected at-most-once replay R000579 and focused review R000580 pass, so it is
promoted only as the twenty-eighth bounded oracle leaf. E0215/R000582 passes
the deterministic post-C748 residual selection: 143 rows remain (82
`disputed`, 61 `unwitnessed`), with C749@1 first. The selected source is C749
at canonical lines 3835--3837, printed page 79, byte span `240824:234`,
page-index record 93, over existing StandardIR R703/R737. The selection used
no model and made no semantic promotion. E0216/R000593 and focused review
R000592 pass for C749, which is promoted only as a bounded oracle leaf with 4
`ACCEPTED`, 1 `REJECTED`, 49 `UNRESOLVED`, twelve rejected mutations, zero
model calls and zero semantic promotions. E0217/R000594 selects C750@1 as the
next source-backed property. E0218/R000596 passes its bounded replay with 1
`ACCEPTED`, 1 `REJECTED`, 25 `UNRESOLVED`, twelve rejected mutations, zero
model calls and zero semantic promotions. Focused review/evidence gate R000597
passes, so C750 is promoted only as a bounded oracle leaf. The full Core 0
semantic milestone remains unpromoted. E0219/R000598 then selects C751@1,
the C751 coarray/ALLOCATABLE relation at canonical lines 3840--3841, byte span
`241193:142`, over existing R737/R739/R809/R810/R811. D0161 records the bounded
candidate; no semantic fact is promoted. E0220/R000599 passes the technical
C751 replay with 4 `ACCEPTED`, 4 `REJECTED`, 4 `UNRESOLVED`, twelve rejected
mutations, zero model calls and zero semantic promotions. The focused review
passes in R000601 with two independent reviewers, and the integrated clean
replay R000602 passes. C751 is promoted only as the thirty-first bounded
oracle leaf; full Core 0 remains open.
E0221/R000606 then selects C752@1 as the next bounded property at canonical
lines 3842--3844, byte span `241335:223`, over R702/R703/R704/R737/R739. The
named module-defined type identities are not direct StandardIR rows; unknown
type identity must remain unresolved.
E0222/R000615 passes the corrected C752 replay with 6 `ACCEPTED`, 3 `REJECTED`,
6 `UNRESOLVED`, thirteen rejected mutations, zero model calls and zero semantic
promotions. Focused review/evidence gate R000616 passes with two independent
reviewers, so C752 is promoted only as the thirty-second bounded oracle leaf;
full Core 0 remains open. E0223/R000617 then selects C754@1 as the next bounded
property at canonical lines 3847--3848, byte span `241715:150`, over existing
R737/R738/R739/R740 witnesses. E0224/R000618 passes the C754 replay with 19
`ACCEPTED`, 1 `REJECTED`, 7 `UNRESOLVED`, thirteen rejected mutations, zero
model calls and zero semantic promotions. Two independent focused reviewers
and the evidence gate pass in R000620; pushed-revision regression R000622 also
passes, so C754 is promoted only as the thirty-third bounded oracle leaf. The
post-C754 residual is 138 rows (81
`disputed`, 57 `unwitnessed`), with C757@1 first. The separate provisional
harvest is retained as intake material; it does not change this residual
selection or promote a semantic fact.

E0225/R000623 closes the first harvested bounded slice, C760/R741, for the
at-most-once occurrence of `proc-component-attr-spec` in a
`proc-component-def-stmt`. The clean replay has 2 `ACCEPTED`, 1 `REJECTED`
and 1 `UNRESOLVED` case, rejects ten mutation controls, and records zero model
calls and zero semantic promotions. Two independent focused reviewers pass;
the evidence gate passes for the bounded leaf only. C760 is therefore closed
as a bounded oracle claim, while full M3 remains open.

E0225/R000624 closes C757/R737 as the next bounded leaf. Its clean replay
covers the 27-state CONTIGUOUS/POINTER/component-array product: 11 `ACCEPTED`,
5 `REJECTED` and 11 `UNRESOLVED`; fifteen source, page, PDF, identity,
contract and semantic-item mutations are rejected. It records zero model calls
and zero semantic promotions. The expected table is controller-derived and
`MECHANICAL`; the candidate semantic packet remains `LLM` and disputed. Two
independent medium-depth focused reviewers pass and the evidence gate passes
for this bounded leaf only. Pushed-revision regression R000625 reproduces the
same result and trace from central `360eb5303ace29863c756358080d19088332e15a`.
Full M3 remains open.

E0226/R000626 selects C759@1 as the next bounded source-backed property.
The residual is 136 rows: 79 `disputed` and 57 `unwitnessed`. Independent
source audit binds C759/R736 to canonical lines 3854--3855, byte span
`242269:126`, printed page 79, ledger page 92, PDF/page-index record 93 and
StandardIR occurrence R736@86. The harvest's incomplete one-line binding is
not reused. This is selection evidence only; no model call or semantic
promotion occurred.

The C759 implementation and corrected review gate now pass in R000627. The
four-state replay produces 2 `ACCEPTED`, 1 `REJECTED` and 1 `UNRESOLVED`,
rejects fifteen mutation controls, and records zero model calls and zero
semantic promotions. The first review found and the controller repaired a
schema-to-fixture correspondence defect; the corrected replay and two fresh
focused reviews pass. C759 is closed only as a bounded oracle leaf; full M3
remains open.

## Component pins

These are the clean component revisions currently pinned by the control plane.
Verify the table
with `scripts/check_pins.sh` after changing a component pin.

| Component | Repository | Commit | Purpose | Local verification |
|---|---|---|---|---|
| standard-new | lazy-fortran/standard-new | `08209c87a7d463b9a121b6f80ed763711d9bf98e` | normative source → StandardIR | generated R708/R901/R902/R903/R509/R1008/R1162/R1164/R1212/R1215/R1217 facts; focused gates pass; full `fo` retains the known schema declaration-count failure |
| fortfront-new | lazy-fortran/fortfront-new | `f12a4104a52b0c03dcf1ec0615d4d85d73bf1923` | frontend | generated program-unit-v2 CLI, bounded assignment sequences, STOP 7, repeated PRINT items, generic mixed integer output-list AST-v2, and generated integer-literal power expressions 2–10; focused gates pass |
| ffc-new | lazy-fortran/ffc-new | `6cfc59e85e81f60429a5c03fc98dced0e2fdc235` | compiler driver and middle end | generated v2 assignment envelopes, sequence MIR routes, generic mixed integer output-list lowering, and dynamic decimal power-expression lowering; `fo` passes |
| fortback-new | lazy-fortran/fortback-new | `6025b5e5c29af7bf807d8c1721c84be32926f6ca` | backend | generated stack-slot/sequence routes, generic mixed integer output-list RISC-V lowering, and dynamic integer-power decimal emission for exponents 2–10; `fo` passes |

## Historical milestone evidence

L0 was recorded as passed by `R000437`. The pinned
`standard-new/specs/lexical-facts-v0.sx` source regenerated a deterministic
canonical SX output and generated schema artifact. The reviewed golden and
independent oracle passed; the malformed neighbor produced `unclosed SX list`;
the source-hash mutation was rejected by the oracle. See
`artifacts/traces/l0-lexical-slice-v0.json`.

L1 was recorded as passed by `R000438`. The pinned `standard-new`
canonicalized the two-rule StandardIR grammar fixture and the pinned
`fortfront-new` grammar frontier accepted `PROGRAM` and rejected `BAD`; the
malformed StandardIR neighbor and independent oracle passed. See
`artifacts/traces/l1-frontend-slice-v0.json`. This remains historical evidence,
not current promotion evidence.

## Current verification state

- L0: `PASS`. The corrected component-local boundary replay, independent
  oracle, clean-build/toolchain checks, deterministic outputs, committed trace
  comparison, and all four independent Luna reviews pass. The v2 reports are
  retained historical evidence; the v3 reports are the active review evidence.
- L1: `PASS`. The corrected replay and all four independent Luna reviews pass;
  v1 reports retain the two repaired review failures and v2 reports are the
  active evidence.
- L2: `PASS`; the corrected bounded central execution gate is `PASS` in
  `R000441`. The first fresh review wave is retained as `R000442`; three lanes
  passed and the oracle lane found that recorded tool/runtime pins were not
  consumed as the evidence authority. The runner and oracle now consume those
  pins and the runtime expectation. The next review wave, `R000443`, found
  stale state wording, an unvalidated runtime-oracle identity, and an
  incomplete reproducibility trace. Those corrections are committed in
  the current clean checkout; its central gate passes and three valid focused
  Luna scopes pass in `R000444`. The promotion reports are retained under
  `artifacts/reports/L2/replay-v4-luna-*.md`.
- M1-M2: `PASS`. The source-backed gate passes in corrected replay `R000454`
  from pushed commit `cf84423`; `R000450` remains the exact payload authority.
  The fixture, regression corpus, trace, environment record and failed review
  history are retained under `artifacts/` and `research/runs/2026-08.jsonl`.
  Focused integration review `R000455` passes; no source, grammar or oracle
  defect remains open.
- E0174: the source-node-aware correspondence replay passes in cold run
  `R000467`; fast reuse control `R000468` completes in 7.84 seconds with
  exact cache, log, environment and output-hash checks. These runs do not
  claim target insertion or semantic promotion. The focused independent
  reviews pass at central revision `572ed6c`.
- E0172 remains abandoned before its model cell: R000456 found that the
  endpoint exposed Qwen 3.8 27B while the experiment declared Qwen 3.6
  35B-A3B. No model output was accepted. E0174 is closed.
- M3 is `OPEN` through thirty promoted bounded slices, including C717,
  C720, C722, C724, C726, C731, C732, C733, C735, C743 and C744; full Core 0 remains open.
  D0126 selects
  C702's type-parameter colon legality over the already represented R701, R832
  and R856 shapes. The exact mechanical gate is
  `tests/e2e/run-m3-c702.sh .cache/runs/E0176/R000012`; replay `R000012` and
  focused review `R000015` pass. D0127 selects C601's maximum name length over
  the already represented R601, R602 and R603 shapes. The exact C601 gate is
  `tests/e2e/run-m3-c601.sh .cache/runs/E0177/R000003`; replay `R000003` and
  focused review `R000022` pass. D0128 selects C603's nonzero-label-digit
  restriction over the already represented R611 shape. The exact C603 gate is
  `tests/e2e/run-m3-c603.sh .cache/runs/E0178/R000001`; replay `R000001` and
  focused review `R000027` pass. No model output is promoted and full Core 0
  remains open. D0129 selects C721's exponent-letter implication over the
  already represented R714/R716 shapes. The exact C721 gate is
  `tests/e2e/run-m3-c721.sh .cache/runs/E0179/R000001`; replay `R000001` passes
  and focused review `R000029` pass. No model output is promoted and full Core
  0 remains open.
  D0130 selects C725's int-literal kind-parameter exclusion over the already
  represented R723/R708 shapes. The exact C725 gate is
  `tests/e2e/run-m3-c725.sh .cache/runs/E0180/R000001`; replay `R000001`
  passes and focused review `R000031` passes. No model output is promoted and
  full Core 0 remains open.
  D0131 records the E0181 Core 0 closure audit: the retained 287-row ledger
  still has 4 hard failures, 2 unresolved rows, 94 disputed rows and 69
  unwitnessed rows, with zero semantic promotions. D0131 selected C718 as the
  next bounded contract, not a restart of the abandoned E0172 model lane.
  Its exact replay is `tests/e2e/run-m3-c718.sh .cache/runs/E0182/R000002`;
  R000034 and focused review R000036 pass. D0132 selects C723 as the next
  bounded contract; it does not restart E0172 or close full M3. C723 replay
  R000037 and focused review R000038 now pass. D0133 selects C729; replay
  R000042 and focused review R000044 pass. R000043 retains the earlier
  reproducibility failure and its repair. D0134 selects C719 over R709;
  final replay R000051 and focused review R000052 pass. The bounded C719
  slice is promoted; D0135 selects C738 and corrected replay R000053 plus
  focused review R000055 pass.
  D0136/D0137 correct C1579; replay R000004 is recorded as R000062 and final
  focused review R000064 passes. R000058, R000059, R000061 and R000063 retain
  earlier review or replay failures. C1579 is promoted as a bounded slice;
  full M3 remains open. The exact E0181 residual-selection audit passes again
  in R000065; D0138 selects the bounded C1586 statement-function self-name
  projection over the existing R1547 shape. The first candidate replay is
  retained as `R000066`; corrected replay `R000067` and focused review `R000072`
  pass with eight mutation failures and zero model calls or semantic
  promotions. C1586 is promoted as a bounded slice; full M3 remains open.
  D0145/E0196 define the C731 character-length constant-expression oracle.
  Clean replay R000511 and focused review R000510 pass with 2 `ACCEPTED`, 2
  `REJECTED`, 8 `UNRESOLVED`, twelve mutation failures and zero model calls or
  semantic promotions. C731 is promoted only as this bounded oracle slice;
  full M3 remains open. E0197/R000513 selects C732 at canonical line 3493,
  page 85, byte span `221195:107`, over existing StandardIR R724
  (`char-literal-constant`). The next bounded contract is the
  kind-parameter representation-method relation; it does not inspect a real
  processor or parse literals. E0198 central replay `R000514` passes with
  `1 ACCEPTED`, `1 REJECTED`, `7 UNRESOLVED`, twelve rejected mutation
  controls, zero model calls and zero semantic promotions. Focused review
  `R000515` passes; C732 is promoted only as this bounded oracle slice.
  Post-C732 reconciliation `R000516` leaves 151 residual rows (87 disputed,
  64 unwitnessed), with C733@1 first.

The L0 runner currently consumes `standard-new/specs/lexical-facts-v0.sx`
and the component's `specs/schema-v0.sxs` generator fixture. It is now
explicitly classified as a component-local generator boundary, not as a
consumer of central `contracts/standardir-v0.sxs`; the accepted D0022
decision says that local schema is not the complete StandardIR contract. The
recorded L1 run predates the commit containing its final central inputs; the
current replay supersedes it for promotion purposes. L2's active claim is
limited to the pinned `frontend-v0` witness → canonical `mir-v0` SX → bounded
RV64 Linux ELF → QEMU exit status and independent code-word checks. It does
not claim source parsing, StandardIR conversion, or serialized TargetIR and
emission contract interchange.

## Active fixture

Current fixture: `T-L3-generated-print-variable-sixty-one-eighty-batch`.
Its source-bound generated replay passes 126 routes; regenerate that count with
`bash tests/e2e/check-generated-chain.sh`. The exact stored-variable witness
is bounded to `program main`, `integer :: x`, `x = 17` or `x = 23`, and `PRINT *, x`;
the multiplication-expression witness is now integrated as a bounded leaf with
exact qemu output `46\n`, four rejected source neighbours, and three rejected
artifact mutations. It does not promote general variable handling or full M3
semantics. The arithmetic batch now adds subtraction `x = x – 2` and division
`x = x / 2`, with exact qemu outputs `21\n` and `12\n`, eight rejected source
neighbours, and six rejected artifact mutations. The power batch now adds
`x = 2; x = x ** 3; PRINT *, x` with exact qemu output `8\n`, four rejected
source neighbours, and three rejected artifact mutations.
The value-generalization witness is now integrated as `x = 3; x = x ** 2; PRINT *, x`,
with exact qemu output `9\n`, four negative neighbours and three rejected
artifact mutations.
The stored-variable two-item witness is now integrated as `x = 3; x = x ** 2;
PRINT *, x, x`, with exact stdout `9\n9\n`, three rejected source neighbours
and three rejected AST/MIR/ELF mutations. Focused review was skipped for this
ordinary bounded slice. It does not promote general output lists or full M3
semantics.
The stored-variable three-item witness is now integrated as `x = 3; x = x ** 2;
PRINT *, x, x, x`, with exact stdout `9\n9\n9\n`, four rejected source
neighbours and three rejected AST/MIR/ELF mutations. Focused review was skipped
for this ordinary bounded slice. It remains a bounded three-item route.
The stored-variable four-item witness is now integrated as `x = 3; x = x ** 2;
PRINT *, x, x, x, x`, with exact stdout `9\n9\n9\n9\n`, four rejected source
neighbours and three rejected AST/MIR/ELF mutations. Focused review was skipped
for this ordinary bounded slice. It remains a bounded four-item route.
The stored-variable five-item witness is now integrated with exact output
`9\n9\n9\n9\n9\n`, four rejected source neighbours and three rejected
AST/MIR/ELF mutations; the central replay passes 51 routes. The stored-variable
six-item witness is now integrated with exact output `9\n9\n9\n9\n9\n9\n`,
four rejected source neighbours and three rejected AST/MIR/ELF mutations; the
central replay passes 52 routes.
The stored-variable `PRINT` seven-, eight-, nine- and ten-item batch is now
integrated with exact output of seven, eight, nine and ten `9` lines; the
central replay passes 56 routes. Its eleven-through-twenty successor is now
integrated with exact output of eleven through twenty `9` lines, forty rejected
source neighbours and three rejected AST/MIR/ELF mutations per route; the
central replay passes 66 routes. It remains a bounded output-cardinality
family, not general I/O or arbitrary output-list handling.
The twenty-one-through-forty successor is now integrated with exact output of
twenty-one through forty `9` lines, eighty rejected source neighbours and
three rejected AST/MIR/ELF mutations per route; the central replay passes 86
routes. It remains a bounded output-cardinality family, not general I/O or
arbitrary output-list handling.
The forty-one-through-sixty and sixty-one-through-eighty successors add forty
more generated routes with exact output of 9 lines, four rejected source
neighbours per route and three rejected AST/MIR/ELF mutations per route. The
central replay now passes 126 routes; regenerate that count with
`bash tests/e2e/check-generated-chain.sh`. They remain bounded
output-cardinality families, not general I/O or arbitrary output-list handling.
The following M3 records are retained historical evidence, not the active
fixture.
C735 is promoted only as a bounded typed type-attribute uniqueness oracle.
Clean replay R000527 and focused review R000528 pass. The replay binds C735
line 3620, page 88, byte span `229534:101`, to existing StandardIR R727/R728;
it records 2 `ACCEPTED`, 1 `REJECTED`, 9 `UNRESOLVED`, twelve rejected
mutation controls, zero model calls and zero semantic promotions. Reconciliation
R000529 records the post-C735 partition: 149 outside-promoted rows (85
disputed and 64 unwitnessed), with C743@1 first. E0203/R000530 selects C743
at canonical line 3637, page 89, byte span `230736:105`, over existing
StandardIR R726/R729. Full M3 remains open; do not resume E0172 or start broad
semantic work. E0204/R000531 and focused review R000532 pass, promoting C743
only as a bounded typed oracle leaf. The post-C743 reconciliation R000534
leaves 148 outside-promoted rows (85 disputed and 63 unwitnessed), with
C744@1 first. E0205/R000537 selects the C744 END TYPE name relation over
R727/R730 at canonical lines 3639--3640, byte span `230888:137`, page 89.
E0206/R000538 replays it, R000539 provides two focused independent reviews,
and final clean handoff R000540 passes;
C744 is promoted only as a bounded typed oracle leaf. The post-C744 partition
has 147 outside-promoted rows (84 disputed and 63 unwitnessed), with C745@1
first. E0207/R000542 selects the first C745 obligation over R726/R731/R735 at
canonical lines 3665--3667, byte span `232141:276`, page 89. E0208/R000556
and focused review R000560 pass; C745 is promoted only as this bounded oracle
leaf. Full M3 remains open. The post-C745 correction R000564 leaves C746@1
first and binds it to canonical lines 3764--3765, page 77, and existing
StandardIR R727/R732/R733. E0210/R000566 and focused review R000567 pass for
C746, which is promoted only as a bounded typed membership oracle. The
post-C746 partition leaves 145 outside-promoted rows (84 disputed and 61
unwitnessed), with C747@1 first. R000568 selects C747's occurrence-cardinality
relation, and R000574/R000575 promote it only as a bounded oracle leaf.
Post-C747 selection R000576 leaves 144 rows (83 disputed and 61 unwitnessed),
with C748@1 first. R000576 binds C748 line 3834, printed page 79, byte span
`240727:97` to canonical page-index record 93 and StandardIR R737. The first
C748 replay R000577 is retained but not promotable: focused review R000578
found that its exact-once oracle rejected valid zero-occurrence states. D0156
corrects the contract to at-most-once; replay R000579 and focused review
R000580 pass with 6 `ACCEPTED`, 1 `REJECTED`, 29 `UNRESOLVED`, twelve rejected
mutations, zero model calls and zero semantic promotions. The complete replay command is
`M3_C748_EXPECTED_CENTRAL_COMMIT=b3abc202c9e0b82058feccfc1c06099715b589c9 tests/e2e/run-m3-c748.sh --fresh`.
E0215/R000582 then selects C749@1 as the next bounded property. D0157 binds
the typed relation to the C749 source span and existing R703/R737 witnesses.
E0216/R000593 and focused review R000592 pass the C749 replay and evidence
gate. The bounded C749 oracle is promoted only as a leaf; its full M3 parent
remains open. E0217/R000594 selects C750@1 at canonical lines 3838--3839,
printed page 79, byte span `241058:135`, over existing StandardIR R737/R740.
E0218/R000596 passes the bounded C750 replay with the independent validator,
and focused review/evidence gate R000597 passes. C750 is promoted only as a
bounded oracle leaf; full M3 remains open. E0219/R000598 selects C751@1.

## Active task

ID: `T-L3-generated-print-variable-multiply-expression-wave` — PASS. The
central verifier passed 45 routes at promotion; the current replay passes 47.
Regenerate it with
`bash tests/e2e/check-generated-chain.sh`. The multiplication-expression
fixture and four negative neighbours pass, and two independent focused reviews
pass for this bounded leaf. This does not promote general multiplication,
expression evaluation, name resolution, or full L3/M3 semantics.

Current task: `T-L3-generated-print-variable-arithmetic-batch` — PASS. The
the central verifier passed 45 routes at promotion; the current replay passes
47. Two independent focused reviews pass for
this bounded leaf. This does not promote general arithmetic, expression
evaluation, divide-by-zero semantics, or full L3/M3 semantics.

Current task: `T-L3-generated-print-variable-power-expression-batch` — PASS.
The central verifier passed 46 routes at promotion; the current replay passes
47. Two independent focused reviews pass for
this exact bounded leaf. This does not promote general power semantics,
arbitrary Fortran, or M3.

Current task: `T-L3-generated-print-variable-power-value-batch` — PASS. The
central verifier passes 47 routes; two independent focused reviews pass for
this bounded value pair. This does not promote general value ranges, power
semantics, arbitrary Fortran, or M3.

Current task: `T-L3-generated-print-variable-four-item-batch` — PASS. The source
fixtures were prepared before implementation; the central replay passes 50
routes with exact output `9\n9\n9\n9\n`, four rejected source neighbours and
three rejected AST/MIR/ELF mutations. This remains a bounded four-item route,
not general I/O, arbitrary Fortran, or M3 semantics.
Current task: `T-L3-generated-print-variable-five-item-batch` — PASS. The source
fixtures were prepared before implementation; the central replay passes 51
routes with exact output `9\n9\n9\n9\n9\n`, four rejected source neighbours
and three rejected AST/MIR/ELF mutations. This remains a bounded five-item
route, not general I/O, arbitrary Fortran, or M3 semantics.
Current task: `T-L3-generated-print-variable-six-item-batch` — PASS. The source
fixtures were prepared before implementation; the central replay passes 52
routes with exact output `9\n9\n9\n9\n9\n9\n`, four rejected source neighbours
and three rejected AST/MIR/ELF mutations. This remains a bounded six-item route,
not general I/O, arbitrary Fortran, or M3 semantics.
The following M3 material is retained historical evidence.
Historical task: `T-M3-c763-pass-arg-name-oracle` — OPEN. Selection R000635 passes for
`T-M3-core0-next-bounded-property-selection-after-c762`. The exact residual
command is recorded in `TASK_POOL.yaml`; it yields 133 rows, 77 `disputed` and
56 `unwitnessed`, with C763@1 first. The source audit binds C763/R741 to
canonical lines 3874--3875, byte span `243182:139`, printed page 79, PDF page
94, ledger page 94, page-index record `94:242409:2660`, and existing StandardIR
R741/R742 plus R603/R1534 name-shape witnesses. D0171 defines the bounded
conditional-name target; no semantic fact is promoted.

The
bounded C761 implementation passes its pushed clean replay and focused review
gate in R000630; post-promotion regression R000631 reproduces it. Selection
R000629 bound C761/R741 to J3-24-007 canonical line
3871, source span `242981:74`, printed page 79, PDF page 94, ledger page 93,
page-index record 93 and StandardIR occurrence R741@91. The pre-C761 residual
was 135 rows: 79 `disputed` and 56 `unwitnessed`.

The completed implementation was the smallest bounded C761 property: a typed
`proc-component-attr-spec-list` state of `pointer-present`, `pointer-absent`
or `unknown`, with deterministic `ACCEPTED`, `REJECTED` or `UNRESOLVED`
outcomes. R000630 records 1 `ACCEPTED`, 1 `REJECTED` and 1 `UNRESOLVED`,
eleven rejected mutations, zero model calls and zero semantic promotions. The
exact claim is closed only as a bounded oracle leaf; no Fortran parser,
model-driven promotion or full M3 claim is in scope.

R000632 selected C762@1 from 134 residual rows (78 `disputed`, 56
`unwitnessed`). The C762 implementation then passed its pushed clean replay
and focused review in R000633, with post-promotion regression R000634, with 4 `ACCEPTED`, 1 `REJECTED`, 4 `UNRESOLVED`,
twelve rejected mutations, zero model calls and zero semantic promotions. The
next controller-exclusive selection leaves 133 rows (77 `disputed`, 56
`unwitnessed`) with C763@1 first; R000635 records the independent source
selection. The implementation contract is the 3-by-3 typed product
`pass_argument_state = present|absent|unknown` crossed with
`dummy_name_relation = matching|nonmatching|unknown`, with deterministic
`ACCEPTED`/`REJECTED`/`UNRESOLVED` outcomes, negative neighbours, mutation
controls and zero model-driven promotion. The completed C761 verifier was
`tests/e2e/run-m3-c761.sh --fresh`. The completed C759 verifier remains
`tests/e2e/run-m3-c759.sh --fresh`; its pushed clean regression is R000628 at
central `c7041685dc0a0a35394cc2b37b34616b2a626929`.

C763 implementation replay R000641 and focused review R000642 pass. The
corrected validator checks complete schema/witness fields and the exact
15-control inventory. The bounded C763 leaf records 4 `ACCEPTED`, 1
`REJECTED`, 4 `UNRESOLVED`, zero model calls and zero semantic promotions;
full M3 remains open. Post-promotion regression R000643 reproduces the result
and committed trace from pushed central `834c90b7c66bc64cbbe033f56e98f5b26d729fa1`.
The next controller-exclusive selection R000644 leaves 132 rows (76
`disputed`, 56 `unwitnessed`) with C768@1 first; its source audit binds C768/
R737 to canonical lines 3977--3979, byte span `249918:239`, printed page 82,
PDF/ledger page 96, page-index `96:247480:3187`, and StandardIR
R737/R738/R739/R743. D0172 records the bounded initialization-attribute
target; implementation is not yet registered as promoted.

The completed C754 verifier was `tests/e2e/run-m3-c754.sh --fresh`. Its
27-state typed product crosses pointer attribute, allocatable attribute and
component-array-spec shape, each `absent`, `present` or `unknown`; it produced
19 `ACCEPTED`, 1 `REJECTED` and 7 `UNRESOLVED`, rejected thirteen source and
provenance mutations, and recorded zero model calls and zero semantic
promotions. It does not parse Fortran or promote a semantic fact.

The completed C744 verifier was `tests/e2e/run-m3-c744.sh --fresh`. Its
oracle must classify the complete 3-by-3-by-3 typed product of END TYPE name
presence (`absent`, `present`, `unknown`), name relation (`same`, `different`,
`unknown`) and context (`derived-type-def`, `other`, `unknown`) as
`ACCEPTED`/`REJECTED`/`UNRESOLVED`, bind C744 lines 3639--3640/page 89 to
R727/R730, reject source/page/rule/identity mutations, and record zero model
calls and zero semantic-fact promotions. It must not parse definitions,
compare real identifier spellings or resolve names.

## Current blocker

The L2 boundary and M1-M2 source-backed fixture are promoted. The D0119
correspondence replay verifier passes in E0174/R000467, with fast iteration
control R000468 and both focused independent reviews passing. D0084 keeps
the broad semantic/model lane closed while the bounded M3 contract is
verified. E0172's runtime identity failure is retained as R000456. The
central C1106 replay R000474 and focused review R000476 pass. C702 replay
R000012 and focused review R000015 pass. C601 replay R000003 and focused
review R000022 pass. C603 replay R000001 and focused review R000027 pass. C721
replay R000001 and focused review R000029 pass. C725 replay R000001 and
focused review R000031 pass. The fresh E0181 closure audit is recorded as
R000074, and clean pushed replay R000075 reproduces it; both pass the
deterministic audit gate. Reconciliation R000076 passes for the pre-C717 set.
Post-promotion reconciliation R000482 joins fourteen promoted contract IDs and
leaves 157 outside-promoted residual rows (90 disputed and 67 unwitnessed).
Full M3/Core 0 remains blocked
by the retained 287-row ledger: 4 hard failures, 2 unresolved rows, 94
disputed rows and 69 unwitnessed rows. The corrected C718 replay and focused
reviews are green. The
C723 replay and focused review are green. The C729 replay and focused review
are green; R000043 retains the earlier reproducibility failure. C719 replay
R000051 and focused review R000052 are green. C738 replay R000053 and focused
review R000055 are green. C1579 replay R000004 is green in R000062 and
focused review R000064 passes; C1586 replay R000067 and focused review
R000072 also pass, and C717 replay R000480 and review R000481 pass. C720 replay
R000486 and focused review R000487 pass. C722 replay R000490 and focused
review R000491 pass. C724 replay R000494 and focused review R000495 pass, and
  C726 replay R000504 with focused review R000505 passes. C731 replay R000511
  and focused review R000510 pass. C732 replay R000514 and focused review
  R000515 pass, so twenty bounded slices are promoted. C733 replay R000518
  and focused review R000519 also pass, making twenty-one bounded slices
  promoted. C735 replay R000527 and focused review R000528 pass, making
  twenty-two bounded slices promoted. C743 replay R000531 and focused review
  R000532 pass, making twenty-three bounded slices promoted only as bounded
  oracle leaves.
  C744 replay R000538 and focused review R000539 pass, making twenty-four
  bounded slices promoted only as bounded oracle leaves. C745 replay R000556
  and focused review R000560 pass, and C746 replay R000566 with focused review
  R000567 also pass. C747 replay R000574 and focused review R000575 pass,
  making twenty-eight bounded slices promoted only as bounded oracle leaves.
  C749 corrected replay R000593 and focused review R000592 pass, making
  twenty-nine bounded slices promoted only as bounded oracle leaves. C750
  replay R000596 and focused review/evidence gate R000597 pass, making thirty
  bounded slices promoted only as bounded oracle leaves; full Core 0 remains
  open.
  C746 records
  4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`, twelve rejected mutations,
  zero model calls and zero semantic promotions.
  The audit residual
identities are C601@1, C603@1, C719@1, C738@1, C704@2, C1579@1 and C1586@1;
the first four are hard failures, C704@2 is reference-only, and the last two
are unresolved. These residual states do not close the complete ledger gate.
The current blocker is witness closure outside the bounded slices: the
  post-C746 partition records 145 residual rows (84 disputed and 61 unwitnessed),
  with C747@1 first. R000568 binds that row to the C747 exactly-once contract;
  R000571 retains the failed provenance review, while R000574 and R000575
  record the corrected replay and focused review. R000576 then selects C748@1.
  C748 implementation replay R000579 and focused review R000580 pass after the
  exact-once semantic defect in R000578; C748 is promoted only as a bounded
  at-most-once oracle. E0215/R000582 selected C749; E0216/R000593 and focused
  review R000592 pass, promoting only the bounded C749 oracle leaf. C750
  replay R000596 and focused review/evidence gate R000597 pass, promoting only
  the bounded C750 oracle leaf; full M3 remains open.
C744 is now promoted only as a bounded typed oracle leaf by E0206/R000538 and
focused review R000539. E0207/R000542 selects C745's first component-presence
obligation. The corrected implementation replay E0208/R000556 and focused
review R000560 pass with the independent human-authored expected-outcome table,
4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`, twelve rejected mutations, zero
model calls and zero semantic promotions. R000543--R000546, R000548--R000550
and R000557 retain the failed replay and review evidence; R000558/R000559
record the parseable-ledger correction. C745 is promoted only as a bounded
oracle leaf; it does not close full M3.
A
  green bounded slice alone does not close full M3. The C717, C720, C722, C724
  and C726 replays, durable pins and focused reviews pass only their bounded
  claims; no retained-ledger semantic fact is promoted.
Regenerate the E0181 counts with:

```text
E0123_RETRY_ROWS=.cache/runs/E0123/R000001/rows.jsonl E0123_RETRY_TRAJECTORY=.cache/runs/E0123/R000001/trajectory.jsonl E0123_ANALYSIS_OUTDIR=.cache/runs/E0181/R000002/analysis research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/analyse.sh
```

Current M3 state: C763 is promoted only as a bounded oracle leaf after its
pin-aligned replay and two-review evidence gate. The remaining blocker is the
scope itself—full M3 still lacks a complete semantic verifier and does not
parse arbitrary Fortran. The post-promotion regression R000643 passes. The
declaration implementation is now committed as fortfront revision
`b51aff1`; focused production tests pass. Clean central replay R000651 accepts
exactly one named main program with `integer :: x`, rejects `integer ::`, and
preserves the existing frontend-v0/MIR-v0 observable. The active task is
`T-L3-declaration-source-executable-replay`; focused review R000653 passes and
the successor is promoted only as a bounded L3 claim. The typed AST v1 producer
is pinned at fortfront `394f34d`; R000654 retains the golden mismatch caught by
the independent oracle and corrected replay R000655 passes. The active task is
`T-L3-frontend-ast-v1-replay`; focused reviews R000664/R000665 pass after
retaining the stale-pin, location-dependent-trace and schema-lineage failures
R000658/R000659/R000662. The exact typed-AST leaf is promoted only as a
bounded claim by E0235. D0176 now freezes the next additive source shape
`integer :: y` using the same v1 schema and malformed neighbour. The producer
is pinned at fortfront `d20041c`; its central replay is active. D0177 narrows
the claim to the exact y witness and explicitly refuses general source-name
derivation. E0236/R000670/R000671/R000672 now promote that exact y leaf only;
R000668 retains the rejected broader wording. D0178 freezes the changed-name
`z` contract as the next task. R000673 passes the contract gate; the isolated
fortfront z-name producer passes its component gate as R000674 at pushed
revision `a657f36`. E0237/R000678 and focused reviews R000681/R000682 promote
the exact z witness only. D0179 froze the multi-character name and span
contract; R000683 passed its contract gate, R000684 passed the alpha producer
at pushed fortfront `101965227a3583872eb7db22c04cd6ff40738c82`, and corrected
replay R000686 plus focused reviews R000687/R000688 promote the exact `alpha`
witness only. The initial golden mismatch remains retained as R000685. D0180
stopped the exact-name ladder. D0181/D0182/D0183 freeze and amend the
source-derived variable-name boundary and its replay lineage. E0240/R000693
plus focused reviews R000694/R000695 promote `beta`, `q7` and `theta_2` with
spans 10..27, 10..25 and 10..30 through the same producer at fortfront
`157236b11540d6a55676e159062e6f9423577a0d`; R000689/R000690 remain retained
failures. This is PASS-BOUNDED-ONLY: no general identifier or full M3 claim.
D0184/D0185 now freeze the source-derived program-root-name contract, including
C1401 and canonical lines 13669--13670. The exact contract oracle passes, and
the pushed fortfront `04ca10b9d191366f328a39d0133375fd6aa62e4e` passes the
component gate. E0241/R000698 passes the clean no-bootstrap replay for `main`
and `unit`, preserves `integer :: x`, repeats identically, and rejects the
mismatched end with the independent oracle. Focused reviews R000699/R000700
promote this exact leaf as PASS-BOUNDED-ONLY. D0186 selects the no-kind-selector
REAL type-spec case over the existing AST v1 field. E0242 freezes its contract;
R000705/R000706 pass the focused review and the contract is verified
PASS-BOUNDED-ONLY. E0242/R000709 and R000710/R000711 now promote the exact
REAL producer/replay leaf as PASS-BOUNDED-ONLY; R000707 remains retained.
D0187/R000712 select the no-kind-selector DOUBLE PRECISION alternative. R000720
retains the caught AST-v1 representation failure. D0188 amends the contract to
use canonical atom `double-precision` while pinning the exact source spelling;
R000721/R000722 pass the correction, and E0243/R000726 plus R000727/R000728
promote the exact producer/replay leaf at pushed component
`c3647c4ba3d8740afcf2b96af0ea0cdf39dfad19`. R000724 remains retained stale
metadata. The active task selects the next bounded source-backed boundary.

## Next executable task

The L3 declaration contract is frozen by D0174 and passes
`scripts/check-contracts.sh`. The implementation, technical replay and focused
review pass; the bounded successor is promoted. The typed declaration contract
D0175 is now frozen and passes `scripts/check-contracts.sh`; the active task is
the isolated fortfront AST v1 implementation, which is complete at pinned
fortfront `d20041c`; E0235/R000661, focused reviews R000664/R000665 and the
path-independent/schema-lineage gates pass. D0176/D0177 freeze the exact y
witness boundary, and the y producer passes its component gate. The active
task is the central E0236 replay. The replay and two final focused reviews now
pass for the exact y witness only. D0178/R000673 freeze the changed-name
contract, R000674 passes the pushed fortfront component gate, and
E0237/R000678/R000681/R000682 promote the exact z witness only. R000683 passes
the D0179 contract gate; R000684 passed the pushed alpha producer, and
R000686/R000687/R000688 promote the exact alpha witness only. E0240/R000693
and R000694/R000695 now promote the source-derived `beta`, `q7` and `theta_2`
boundary only; R000689/R000690 remain retained failures. D0184/D0185 freeze the
next source-derived program-root-name contract, and E0241/R000698 plus
R000699/R000700 promote the exact root/declaration-name leaf at fortfront
`04ca10b9d191366f328a39d0133375fd6aa62e4e`. D0186 selects the no-kind-selector
REAL type-spec boundary; E0242/R000709 plus R000710/R000711 promote its exact
producer/replay leaf, while R000701/R000703 and R000707 remain retained caught
failures. D0187/R000712 select the no-kind-selector DOUBLE PRECISION contract;
R000720 retains the caught AST-v1 atom mismatch, and D0188 amends the contract
to canonicalize the multi-word term, and R000721/R000722 pass the correction.
E0243/R000726 plus R000727/R000728 promote the exact producer/replay leaf at
pushed fortfront `c3647c4ba3d8740afcf2b96af0ea0cdf39dfad19`; R000724 remains
retained stale metadata. The active task selects the next bounded boundary.
This remains outside full M3. Do not resume
E0172 or start broad semantic work. The C768 worker result remains parked and
is not promoted by this pivot.

The completed C744 contract selected by D0150/E0205 is a bounded oracle only:
typed END TYPE name presence, name relation and context, a deterministic
three-outcome oracle, positive and negative neighbours, unresolved controls,
mutation controls and replayable trace. E0206/R000538 and R000539 pass with
4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`, twelve rejected mutations, zero
model calls and zero semantic promotions. This does not restart E0172, parse
general Fortran or close full M3.

The current post-C744 partition is regenerated with:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The following command is the superseded pre-C733 selection command:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The next gate is selection of one bounded source-backed property after C733.
The bounded oracle lane must reuse trustworthy source/provenance machinery and
leave semantic promotion and model execution at zero. Its exact task is
`T-M3-core0-next-bounded-property-selection-after-c733`.

Historical C732 replay:

```text
M3_C732_EXPECTED_CENTRAL_COMMIT=40bad4f842a87000ceddb68449a801c2282e2b60 tests/e2e/run-m3-c732.sh --fresh
```

The last bounded C733 replay is regenerated with:

```text
M3_C733_EXPECTED_CENTRAL_COMMIT=5716db592fed41799e4ef8e7000a56cf37a8c1bd tests/e2e/run-m3-c733.sh --fresh
```

## Last verified central command

```text
Current L0 replay and four-lane review: PASS.
Current L1 replay and four-lane review: PASS.
Current L2: corrected central execution gate `R000441` `PASS`; focused
promotion review `R000444` `PASS`; L2 is promoted. M1-M2 corrected replay
`R000454` and focused integration review `R000455` are `PASS`; the
current active replay `scripts/verify_active_milestone.sh` also passes at
central commit `bdb8717`. The M3 C1106 central replay `R000474` and focused
review `R000476` are `PASS`; the C702 central replay `R000012` and focused
review `R000015` are `PASS`; the C601 central replay `R000003` and focused
  review `R000022` are `PASS`; the C603 central replay `R000001` and focused
  review `R000027` are `PASS`; the C721 central replay `R000001` and focused
  review `R000029` are `PASS`. The C725 central replay
  `tests/e2e/run-m3-c725.sh .cache/runs/E0180/R000001` is `PASS`; focused
  review `R000031` is `PASS`. The bounded C1106, C702, C601, C603, C721,
  C725 and C718 slices are promoted. C718 replay `tests/e2e/run-m3-c718.sh
  .cache/runs/E0182/R000002` is `PASS` in R000034; focused review R000036 is
  `PASS`. C723 replay `tests/e2e/run-m3-c723.sh
  .cache/runs/E0183/R000001` is `PASS` in R000037; focused review R000038 is
  `PASS`. C729 replay `tests/e2e/run-m3-c729.sh --fresh` is `PASS` in R000042
  and final clean-checkout replay R000045 is `PASS`; focused review R000044
  is `PASS`. C719 replay `tests/e2e/run-m3-c719.sh --fresh` is `PASS` in
  R000051 and focused review R000052 is `PASS`; ten bounded slices are
  promoted. C738 replay `tests/e2e/run-m3-c738.sh --fresh` is `PASS` in
  R000053 and focused review R000055 is `PASS`; eleven bounded slices are
  promoted. C1579 replay `tests/e2e/run-m3-c1579.sh --fresh` is `PASS` in
  `E0187/R000004`, recorded centrally as `R000062`, and focused review
  `R000064` is `PASS`; twelve bounded slices are promoted and full M3 remains
  open. E0181 residual selection is `PASS` in `R000065`; D0138/E0188 bounded
C1586 replay `R000067` and focused review `R000072` pass; post-promotion
regression replay `R000073` also passes. E0181 clean replay `R000075` and
witness reconciliation `R000076` pass without semantic promotion. C717's first
focused review is retained as `R000477` with `NEEDS_FIX`. D0140 repairs the
precedence and truth-table defect; corrected clean replay `R000478` passes with
the exact source binding, nine typed outcomes, eight mutation failures and
zero model calls or semantic promotions. Durable replay `R000480` and focused
review `R000481` pass. C717 is a bounded promoted slice and C720 is a second
bounded promoted slice. Clean selection replay `R000483` selected C720@1. The
first C720 replay is retained as R000484, corrected replay R000486 requires and
records an explicit central worktree revision, and focused review R000487
passes. C722 replay `R000490` and focused review `R000491` pass; selection
replay `R000493` selected C724@1. C724 replay `R000494` and focused review
`R000495` pass. C726 replay `tests/e2e/run-m3-c726.sh --fresh` passes in
`R000504` at central commit `ae6f214`; focused review `R000505` passes, and
post-C726 reconciliation `R000506` reports 153 residual rows (88 disputed
and 65 unwitnessed), with C731@1 first. Selection `R000507` passes and the
next task is `T-M3-c731-constant-expression-oracle`.
C735 replay `R000527` and focused review `R000528` also pass. The exact final
replay command is:
`M3_C735_EXPECTED_CENTRAL_COMMIT=ffdda31c289531d4b6ac4b0a32ce6db6fb6bb1de tests/e2e/run-m3-c735.sh --fresh`.
The C746 replay `tests/e2e/run-m3-c746.sh --fresh` is `PASS` in R000566 and
focused review R000567 passes. Post-C746 selection `R000568` is `PASS` with
145 residual rows, 84 disputed and 61 unwitnessed, and C747@1 first. C749
corrected replay R000593 and focused review R000592 pass; E0217/R000594
selects C750@1. The current active task is
`T-M3-c751-coarray-allocatable-oracle`.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
