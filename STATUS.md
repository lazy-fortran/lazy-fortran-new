# Lazy Fortran delivery status

## Active milestone

M3 — thirteen bounded semantic-oracle slices promoted; full Core 0 remains
pending

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
review. M3 is now open through the promoted C1106, C702, C601, C603, C721,
C725, C718, C723, C729, C719, C738, C1579 and C1586 contracts. The full Core 0
semantic milestone remains unpromoted.

## Component pins

These are the clean component revisions currently pinned by the control plane.
Verify the table
with `scripts/check_pins.sh` after changing a component pin.

| Component | Repository | Commit | Purpose | Local verification |
|---|---|---|---|---|
| standard-new | lazy-fortran/standard-new | `f94c4c51b51fce22b533b7eeda08741970320913` | normative source → StandardIR | clean main; full `fo` recorded in E0174/R000010 |
| fortfront-new | lazy-fortran/fortfront-new | `73cf2af7a1ee7c13bae302868dc1595aa4ed0a79` | frontend | clean main; registered L2 frontend trace |
| ffc-new | lazy-fortran/ffc-new | `bcaadcb58c24af613204aa398541c0d2e35abf91` | compiler driver and middle end | clean main; registered L2 MIR trace |
| fortback-new | lazy-fortran/fortback-new | `c578904a8d18e9d5410934f5489a21d5dadfad05` | backend | clean main; registered L2 executable trace |

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
- M3 is `OPEN` through the promoted C1106, C702, C601, C603 and C721 slices.
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

Current fixture: `T-M3-c717-kind-selector-oracle`. D0139/E0189 selects the
bounded C717 kind-selector legality property over StandardIR R706. The source
binding is canonical lines 3263--3264 on page 80, with the page-index span and
R706 metadata pinned. Corrected clean replay R000478 passes one accepted, five
rejected, three unresolved and eight mutation controls with zero model calls
and semantic promotions. Focused review `R000479` found a central-revision
durability defect; full M3 remains open and C717 is not promoted. Do not resume
E0172 or start broad semantic work.

## Active task

ID: `T-M3-c717-focused-review` — independently review the frozen C717 replay
packet before any bounded promotion. Full M3 remains open.

Verifier: the focused independent review of R000478. One lane checks the
semantic property, source binding, typed states and nonclaims; the other
checks clean pushed parity, exact pins, mutation controls, trace identity and
task wiring. Review may promote only the bounded C717 slice.

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
deterministic audit gate. Reconciliation R000076 also passes: it joins all
thirteen promoted contract IDs and leaves 158 outside-promoted residual rows
(91 disputed and 67 unwitnessed). Full M3/Core 0 remains blocked
by the retained 287-row ledger: 4 hard failures, 2 unresolved rows, 94
disputed rows and 69 unwitnessed rows. The corrected C718 replay and focused
reviews are green. The
C723 replay and focused review are green. The C729 replay and focused review
are green; R000043 retains the earlier reproducibility failure. C719 replay
R000051 and focused review R000052 are green. C738 replay R000053 and focused
review R000055 are green. C1579 replay R000004 is green in R000062 and
focused review R000064 passes; C1586 replay R000067 and focused review
R000072 also pass, so thirteen bounded slices are promoted. The audit residual
identities are C601@1, C603@1, C719@1, C738@1, C704@2, C1579@1 and C1586@1;
the first four are hard failures, C704@2 is reference-only, and the last two
are unresolved. These residual states do not close the complete ledger gate.
The current blocker is witness closure outside the bounded slices: 158 rows
(91 disputed and 67 unwitnessed) remain after the five residual rows attached
to promoted contracts are separated. A green bounded slice alone does not
close full M3. The selected C717 contract and corrected clean replay R000478
pass. Focused review R000479 records a reproducibility `NEEDS_FIX`: its
central revision pin predates the durable R000478 record and handoff metadata.
The replay establishes only the bounded C717 observable, not semantic promotion
of the retained ledger.
Regenerate the E0181 counts with:

```text
E0123_RETRY_ROWS=.cache/runs/E0123/R000001/rows.jsonl E0123_RETRY_TRAJECTORY=.cache/runs/E0123/R000001/trajectory.jsonl E0123_ANALYSIS_OUTDIR=.cache/runs/E0181/R000002/analysis research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/analyse.sh
```

## Next executable task

Repair the R000479 central-revision finding, run and record a fresh C717 replay,
then rerun `T-M3-c717-focused-review`. The preceding corrected replay is
`research/runs/2026-08.jsonl#R000478`; the outside-promoted residual remains the
full-M3 blocker. Its exact inventory verifier is:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), row_keys: map(.row_key)}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
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
zero model calls or semantic promotions. Review `R000479` finds a
central-revision durability defect; the active task remains
`T-M3-c717-focused-review` for the corrected replay.
```

## Blacklisted pseudo-progress

- Component-local success reported as integration success.
- New contracts or provenance fields not consumed by the central fixture.
- Generated code compiling treated as normative or semantic correctness.
- Unpinned sibling artifacts.
- A second fixture family before the first reaches its final observable.
