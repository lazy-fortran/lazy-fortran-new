# Cross-repository delivery milestones

Milestone status is changed only after the central verification command and
its independent oracle pass. Component repositories do not maintain a second
milestone ledger.

## Current verification state

The historical evidence below is preserved. L0, L1, L2 and M1-M2 corrected
replays and focused reviews pass. The bounded M3 C1106, C702, C601, C603, C721,
C725, C726, C731, C732 and C733 slices are promoted by their central verifiers and
focused reviews.
The bounded C718 slice is promoted by its corrected replay and focused reviews.
The bounded C723 slice is promoted by replay `R000037` and focused review
`R000038`. The bounded C729 slice is promoted by replay `R000042` and focused
review `R000044`; failed review `R000043` is retained. Full M3 remains open.
The bounded C719 slice is promoted by replay `R000051` and focused review
`R000052`. The bounded C738 slice is promoted by replay `R000053` and focused
review `R000055`. The bounded C1579 slice is promoted by replay `R000062` and
focused review `R000064`. The bounded C1586 slice is promoted by replay
`R000067` and focused review `R000072`. Full M3 remains open.
The C717 contract, durable-pin clean central replay `R000480`, and focused
review `R000481` pass. C717 is promoted as a bounded slice only; full M3
remains open. `R000479` retains the repaired central-revision failure.
C735 is promoted by replay `R000527` and focused review `R000528`; C743 is
promoted only as its bounded oracle leaf by replay `R000531` and focused review
`R000532`. Full M3 remains open.
The C749 bounded oracle passes replay `R000593` and focused review/evidence gate
`R000592`. The C750 bounded oracle passes replay `R000596` and focused
review/evidence gate `R000597`; both are bounded leaves only, and full M3
remains open.

## M3 — bounded C1106 semantic-oracle slice

Bounded-slice status: `PASS`; central verifier `R000474` and focused review
`R000476` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3/24-007 C1106 to StandardIR R1102/R1103/R1106. Its typed
name-side contract uses an optional name value, and its deterministic oracle
returns `ACCEPTED`, `REJECTED` or `UNRESOLVED` with no model promotion path.
The replay produces six case outcomes and three mutation failures; regenerate
those observations with:

```text
tests/e2e/run-m3-c1106.sh .cache/runs/E0175/R000474
```

Evidence: `research/decisions/D0124-first-m3-associate-name-oracle.md`,
`research/decisions/D0125-m3-c1106-case-insensitive-names.md`,
`contracts/m3-c1106-semantic-oracle-v0.sxs`,
`tests/e2e/validate_m3_c1106.py`,
`artifacts/traces/m3-c1106-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000471`,
`research/runs/2026-08.jsonl#R000473`, and
`research/runs/2026-08.jsonl#R000474`,
`research/runs/2026-08.jsonl#R000475`, plus focused review
`research/runs/2026-08.jsonl#R000476` and reports under
`artifacts/reports/M3/`.

## M3 — bounded C702 semantic-oracle successor

Bounded-slice status: `PASS`; central replay `R000012` and focused review
`R000015` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3/24-007 C702, canonical-text lines 3095--3096, to the
already represented StandardIR rows R701, R832 and R856. Its typed candidate
contains a colon type-parameter value and an attribute-context enum. Pointer
and allocatable contexts are `ACCEPTED`, neither is `REJECTED`, and unknown is
`UNRESOLVED`. Three source/rule mutation controls must fail closed; regenerate
the complete inventory with:

```text
tests/e2e/run-m3-c702.sh .cache/runs/E0176/R000012
```

Evidence: `research/decisions/D0126-second-m3-c702-type-param-colon-oracle.md`,
`research/experiments/E0176-can-a-deterministic-oracle-enforce-c702-/`,
`contracts/m3-c702-semantic-oracle-v0.sxs`,
`tests/e2e/validate_m3_c702.py`,
`artifacts/traces/m3-c702-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000001` through `#R000015`, plus focused review
reports under `artifacts/reports/M3/`. No model output can promote a semantic
fact.

## M3 — bounded C603 semantic-oracle slice

Bounded-slice status: `PASS`; central replay `R000001` and focused review
`R000027` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3/24-007 C603, canonical-text line 2878, to the already
represented StandardIR row R611. Its typed candidate carries a label spelling.
A valid one-to-five-digit spelling containing a nonzero digit is `ACCEPTED`,
an all-zero spelling is `REJECTED`, and a non-label spelling is `UNRESOLVED`.
The deterministic oracle does not parse statements, analyze scope or consume
model output. Five source/provenance mutation controls must fail closed;
regenerate the complete inventory with:

```text
tests/e2e/run-m3-c603.sh .cache/runs/E0178/R000001
```

Evidence: `research/decisions/D0128-fourth-m3-c603-label-digit-oracle.md`,
`research/experiments/E0178-can-a-deterministic-oracle-enforce-c603-/`,
`contracts/m3-c603-label-digit-oracle-v0.sxs`,
`tests/e2e/validate_m3_c603.py`,
`artifacts/traces/m3-c603-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000023` through `#R000027`, plus focused review
reports under `artifacts/reports/M3/`. This promotes only the bounded C603
slice; no model output can promote a semantic fact.

## M3 — bounded C721 semantic-oracle slice

Bounded-slice status: `PASS`; central replay `R000001` and focused review
`R000029` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3/24-007 C721, canonical-text line 3355, to the already
represented StandardIR rows R714 and R716. Its typed candidate carries
kind-parameter and exponent-letter states. A kind parameter paired with `E`
is `ACCEPTED`, a kind parameter paired with `D` is `REJECTED`, an absent kind
parameter makes the implication vacuous and is `ACCEPTED`, and an unknown state
is `UNRESOLVED`. The deterministic oracle does not parse real literals,
evaluate constants or consume model output. Five source/provenance mutation
controls must fail closed; regenerate the complete inventory with:

```text
tests/e2e/run-m3-c721.sh .cache/runs/E0179/R000001
```

Evidence: `research/decisions/D0129-fifth-m3-c721-exponent-letter-oracle.md`,
`research/experiments/E0179-can-a-deterministic-oracle-enforce-c721-/`,
`contracts/m3-c721-exponent-letter-oracle-v0.sxs`,
`tests/e2e/validate_m3_c721.py`,
`artifacts/traces/m3-c721-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000028` and `#R000029`, plus focused review
reports under `artifacts/reports/M3/`. This promotes only the bounded C721
slice; no model output can promote a semantic fact.

## M3 — bounded C725 semantic-oracle slice

Bounded-slice status: `PASS`; central replay `R000001` and focused review
`R000031` pass.
Full Core 0 semantics remain open and are not claimed.

The slice binds J3/24-007 C725, canonical-text line 3452, to the already
represented StandardIR rows R723 and R708. Its typed candidate carries the
`kind_param` state for an integer-literal use. An absent kind parameter is
`ACCEPTED`, a present kind parameter is `REJECTED`, and an unknown state is
`UNRESOLVED`. The deterministic oracle does not parse integer literals,
evaluate values, inspect processor representations or consume model output.
Five source/provenance mutation controls must fail closed; regenerate the
complete inventory with:

```text
tests/e2e/run-m3-c725.sh .cache/runs/E0180/R000001
```

Evidence: `research/decisions/D0130-sixth-m3-c725-int-literal-kind-oracle.md`,
`research/experiments/E0180-can-a-deterministic-oracle-enforce-c725-/`,
`contracts/m3-c725-int-literal-kind-oracle-v0.sxs`,
`tests/e2e/validate_m3_c725.py`,
`artifacts/traces/m3-c725-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000030` and `#R000031`, plus focused review
reports under `artifacts/reports/M3/`. This promotes only the bounded C725
slice; full M3 remains open.

## M3 — bounded C718 scalar-int-constant semantic-oracle slice

Bounded-slice status: `PASS`; central replay `R000034` and focused review
`R000036` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3/24-007 C718, canonical-text line 3296, to StandardIR R709,
whose `kind-param` production contains the `scalar-int-constant-name` shape.
Its typed candidate carries named-constant and value-type states. The oracle
accepts `(present, integer)`, rejects known non-matches, and returns
`UNRESOLVED` for unknown state. It does not perform name resolution, type
inference, constant evaluation, parsing or model inference. Five source and
provenance mutation controls must fail closed. Regenerate the complete
inventory with:

```text
tests/e2e/run-m3-c718.sh .cache/runs/E0182/R000002
```

Evidence: `research/decisions/D0131-m3-core0-closure-after-six-bounded-slices.md`,
`research/experiments/E0182-can-a-deterministic-oracle-enforce-c718-/`,
`contracts/m3-c718-scalar-int-constant-oracle-v0.sxs`,
`tests/e2e/validate_m3_c718.py`,
`artifacts/traces/m3-c718-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000034`, retained failed review
`#R000035`, and focused review `#R000036`, plus reports under
`artifacts/reports/M3/`. This promotes only the bounded C718 slice and does
not close full M3.

## M3 — bounded C723 complex named-constant semantic-oracle slice

Bounded-slice status: `PASS`; central replay `R000037` and focused review
`R000038` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3-24-007 C723 at canonical-text line 3396 and printed page
82 to StandardIR R718, R719 and R720. Its typed candidate carries named
constant shape and value-type states. Scalar integer/real cases are
`ACCEPTED`, known non-scalar or other-type cases are `REJECTED`, and unknown
states are `UNRESOLVED`. The oracle does not resolve names, parse expressions,
evaluate literals, select kinds, inspect processors or consume model output.
The replay produces two accepted, one rejected, one unresolved and five
mutation failures; regenerate those observations with:

```text
tests/e2e/run-m3-c723.sh .cache/runs/E0183/R000001
```

Evidence: `research/decisions/D0132-seventh-m3-c723-complex-named-constant-oracle.md`,
`research/experiments/E0183-can-a-deterministic-oracle-enforce-c723-/manifest.yaml`,
`contracts/m3-c723-complex-named-constant-oracle-v0.sxs`,
`tests/e2e/validate_m3_c723.py`,
`artifacts/traces/m3-c723-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000037`, focused review
`research/runs/2026-08.jsonl#R000038` and reports under `artifacts/reports/M3/`.
This promotes only the bounded C723 slice; full M3 remains open.

## M3 — bounded C729 optional-comma semantic-oracle slice

Bounded-slice status: `PASS`; central replay `R000042` and focused review
`R000044` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3-24-007 C729 at canonical-text line 3466 and printed page
84 to StandardIR R722, R703 and R801. Its typed candidate carries comma and
context states. An absent comma or a present comma in the allowed
`declaration-type-spec`/`type-declaration-stmt` context is `ACCEPTED`, a
present comma in another known context is `REJECTED`, and unknown state is
`UNRESOLVED`. The oracle does not parse statements, analyze declarations,
resolve names, type-check or consume model output. The replay produces two
accepted, one rejected, one unresolved and five mutation failures; regenerate
those observations with:

```text
tests/e2e/run-m3-c729.sh --fresh
```

Evidence: `research/decisions/D0133-ninth-m3-c729-optional-comma-oracle.md`,
`research/experiments/E0184-can-a-deterministic-oracle-enforce-c729-/manifest.yaml`,
`contracts/m3-c729-optional-comma-oracle-v0.sxs`,
`tests/e2e/validate_m3_c729.py`,
`artifacts/traces/m3-c729-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000042`, retained failed review
`#R000043`, successful focused review `#R000044`, and reports under
`artifacts/reports/M3/`. This promotes only the bounded C729 slice; full M3
remains open.

## M3 — bounded C719 kind-param nonnegative semantic-oracle slice

Bounded-slice status: `PASS`; central replay `R000051` and focused review
`R000052` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3-24-007 C719 at canonical-text line 3297 and printed page
80 to the already represented StandardIR R709 `kind-param` production. Its
typed candidate carries kind-parameter presence and value states. An absent
kind parameter or a present nonnegative value is `ACCEPTED`, a present
negative value is `REJECTED`, and unknown state is `UNRESOLVED`. The oracle
does not parse numeric literals, evaluate constant expressions, inspect
processor representation methods or consume model output. Regenerate the
replay with:

```text
tests/e2e/run-m3-c719.sh --fresh
```

Evidence: `research/decisions/D0134-tenth-m3-c719-kind-param-nonnegative-oracle.md`,
`research/experiments/E0185-can-a-deterministic-oracle-enforce-c719-/manifest.yaml`,
`contracts/m3-c719-kind-param-nonnegative-oracle-v0.sxs`,
`tests/e2e/validate_m3_c719.py`,
`artifacts/traces/m3-c719-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000046`, corrected replay `#R000047`, prior
replay `#R000048`, repair replay `#R000050`, final replay `#R000051`, and
focused review `#R000052`, with reports under `artifacts/reports/M3/`.
Promotion is bounded to this slice; full M3 remains open.

## M3 — bounded C738 abstract deferred-binding semantic-oracle

Bounded-slice status: `PASS`; corrected central replay `R000053` and focused
review `R000055` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3-24-007 C738 at canonical-text lines 3623--3624 and printed
page 87 to the already represented StandardIR R726/R728/R746/R752 shapes. Its
typed candidate carries deferred-binding and ABSTRACT states. A non-deferred
type or a deferred binding with ABSTRACT is `ACCEPTED`, a deferred binding
without ABSTRACT is `REJECTED`, and unknown state is `UNRESOLVED`. The oracle
does not parse type definitions, infer deferred bindings, perform inheritance
analysis or consume model output. Regenerate the replay with:

```text
tests/e2e/run-m3-c738.sh --fresh
```

Evidence: `research/decisions/D0135-eleventh-m3-c738-abstract-deferred-binding-oracle.md`,
`research/experiments/E0186-can-a-deterministic-oracle-enforce-c738-/manifest.yaml`,
the C738 contract, validator, fixtures and trace, `research/runs/2026-08.jsonl#R000053`,
retained failed review `#R000054`, focused review `#R000055`, and reports under
`artifacts/reports/M3/`. Promotion is bounded to this slice; full M3 remains
open. The next task is the retained E0181 residual-selection audit.

## M3 — bounded C1579 RESULT entry-name semantic-oracle slice

Bounded-slice status: `PASS`; clean central replay `E0187/R000004` is recorded
as `R000062` and focused review `R000064` passes. R000058, R000059, R000061 and
R000063 retain earlier review or replay failures. Full Core 0 semantics remain
open and are not claimed.

The slice binds J3-24-007 C1579 at canonical-text lines 15386--15387 and
printed page 357 to the already represented StandardIR R1532/R1544 shapes. Its
typed candidate carries RESULT-presence and entry-name declaration states. A
missing RESULT or missing declaration is `ACCEPTED`, both present is
`REJECTED`, and unknown state is `UNRESOLVED`. The oracle does not parse
statements, resolve scopes, infer declaration state or consume model output.
Regenerate the replay with:

```text
tests/e2e/run-m3-c1579.sh --fresh
```

Evidence: `research/decisions/D0136-twelfth-m3-c1579-result-entry-name-oracle.md`,
`research/decisions/D0137-c1579-printed-page-correction.md`,
`research/experiments/E0187-can-a-deterministic-oracle-enforce-c1579/manifest.yaml`,
the C1579 contract, validator, fixtures and trace, `research/runs/2026-08.jsonl#R000062`,
retained failures `#R000058`, `#R000059`, `#R000061` and `#R000063`, focused
review `#R000064` and reports under `artifacts/reports/M3/`, plus the retained
E0181 selection evidence. Promotion is bounded to this slice; full M3 remains
open.

## M3 — bounded C1586 statement-function self-reference semantic-oracle slice

Bounded-slice status: `PASS`; candidate replay `R000067` and focused review
`R000072` pass. The earlier trace-gate failure is retained as `R000066`, and
the four corrected handoff review failures are retained as `R000068`--`R000071`.

D0138/E0188 select only the C1586 prohibition on a statement-function
reference having the same name as the statement function being defined. The
source binding is canonical-text lines 15464--15469, with the decisive
prohibition on lines 15468--15469, on PDF/page-index page 358, with the already
represented StandardIR R1547 `stmt-function-stmt` production. The typed
oracle returns `ACCEPTED` for no reference or a
different name, `REJECTED` for the same name and `UNRESOLVED` for unknown
relevant state. It does not parse expressions, resolve names, decide
definition ordering or cover the remainder of C1586. The implementation gate
is:

```text
tests/e2e/run-m3-c1586-self-reference.sh --fresh
```

Evidence: `research/decisions/D0138-thirteenth-m3-c1586-statement-function-self-reference-oracle.md`,
`research/experiments/E0188-c1586-statement-function-self-reference/manifest.yaml`,
the C1586 contract, validator, fixtures and trace, the focused review reports
under `artifacts/reports/M3/`, and `research/runs/2026-08.jsonl#R000065`
through `#R000073`. This promotes only the bounded C1586 projection; full M3
remains open.

## M3 — bounded C717 kind-selector legality semantic-oracle slice

Bounded-slice status: `PASS`; durable-pin replay `R000480` and focused review
`R000481` pass. This promotes only the bounded C717 projection. Full Core 0
semantics remain open and are not claimed.

D0139/E0189 selects the fourteenth bounded delivery contract. It binds
J3-24-007 C717, canonical lines 3263--3264 on printed/page-index page 80, to
the already represented StandardIR R706 `kind-selector` row. The typed
candidate carries `kind_value` (`negative`, `nonnegative`, `unknown`) and
`representation_method` (`absent`, `present`, `unknown`). The deterministic
oracle returns `ACCEPTED` for `(nonnegative, present)`, `REJECTED` for either
known violation and `UNRESOLVED` for either unknown state. It does not evaluate
expressions, inspect processor capabilities, parse Fortran or consume model
output. Eight source, page-index, StandardIR, semantic-item, contract and
precedence mutations must fail closed. Durable-pin clean replay `R000480` has
one accepted, five rejected, three unresolved, eight mutation failures and zero
model calls or semantic promotions. D0140 makes known violations take
precedence over unknown state and requires the complete nine-row table.

The exact central verifier is:

```text
tests/e2e/run-m3-c717.sh --fresh
```

Evidence: `research/decisions/D0139-fourteenth-m3-c717-kind-selector-oracle.md`,
`research/experiments/E0189-can-a-deterministic-source-backed-oracle/manifest.yaml`,
the C717 contract, fixtures, validator, trace and
`artifacts/reports/M3/m3-core0-next-property-selection-v1.md`, D0140, the
retained failed review reports, and `research/runs/2026-08.jsonl#R000478` through
`#R000482`.

## M3 — Core 0 closure audit

Audit and reconciliation status: `PASS` for coverage accounting only; full M3
status remains `NEEDS EVIDENCE`. The next task is
`T-M3-core0-next-bounded-property-selection-after-c722`. E0181/R000074 and clean pushed
replay R000075 reproduce the retained 287-row ledger: 4 hard failures, 2
unresolved rows, 1 reference-only row, 117 self-consistent rows, 94
disputed rows, 69 unwitnessed rows, 7
not-applicable rows and zero semantic promotions. The counts are regenerated
by:

```text
E0123_RETRY_ROWS=.cache/runs/E0123/R000001/rows.jsonl E0123_RETRY_TRAJECTORY=.cache/runs/E0123/R000001/trajectory.jsonl E0123_ANALYSIS_OUTDIR=.cache/runs/E0181/R000002/analysis research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/analyse.sh
```

The audit report is recorded in
`research/experiments/E0181-does-the-retained-core-0-ledger-satisfy-/`,
`artifacts/reports/M3/m3-core0-closure-audit-v2.md`, and
`research/runs/2026-08.jsonl#R000074` and `#R000075`. Reconciliation
`research/runs/2026-08.jsonl#R000076` maps the thirteen pre-C717 promoted IDs;
post-promotion reconciliation `R000482` maps fourteen promoted IDs and leaves
157 outside-promoted rows: 90 disputed and 67 unwitnessed. The residual
reconciliation `R000488` maps fifteen promoted IDs and leaves 156 outside-
promoted rows: 89 disputed and 67 unwitnessed. Post-C722 reconciliation
`R000492` maps sixteen promoted IDs and leaves 155 outside-promoted rows: 88
disputed and 67 unwitnessed. The residual
identities from the audit are C601@1,
C603@1, C719@1, C738@1, C704@2, C1579@1 and C1586@1. The 94 disputed and 69
unwitnessed rows are the total retained witness status; the outside-promoted
blocker is the 157-row partition above. These counts keep full M3 open and do
not authorize semantic promotion. The coverage report is
`artifacts/reports/M3/m3-core0-witness-coverage-v1.md` and
`artifacts/reports/M3/m3-core0-witness-coverage-v2.md`.

## M3 — selected C720 kind-param representation-method oracle

Selection status: `PASS`; bounded C720 implementation and focused review
tasks are `PASS`. D0141/E0190 binds
canonical line 3298 on page 80 to StandardIR R708. The typed candidate has
`representation_method = absent | present | unknown`, with outcomes
`ACCEPTED`, `REJECTED` and `UNRESOLVED`. The selection report is
`artifacts/reports/M3/m3-core0-next-property-selection-v2.md`; the exact
selection verifier is the promoted-contract partition recorded in
`research/runs/2026-08.jsonl#R000483`.
The first implementation replay is retained as R000484; corrected replay
`research/runs/2026-08.jsonl#R000486` passes the exact
`M3_C720_EXPECTED_CENTRAL_COMMIT=abecd36ed9a1f560dc675bb8ea0b6679e2f042c3 tests/e2e/run-m3-c720.sh --fresh`
gate with one outcome in each of ACCEPTED, REJECTED and UNRESOLVED, eight
mutation failures and zero model calls or semantic promotions. Focused review
`R000487` passes. C720 is promoted as a bounded oracle slice only. The next
task is `T-M3-core0-next-bounded-property-selection-after-c720`.
Post-C720 reconciliation `R000488` records 156 outside-promoted rows, with
89 disputed and 67 unwitnessed. Full M3 remains open.

## M3 — bounded C722 kind-param approximation-method oracle

Bounded-slice status: `PASS`; implementation replay `R000490` and focused
review `R000491` pass. D0142/E0191 binds canonical line 3356 on page 82 to
StandardIR R714. The typed candidate has
`approximation_method = absent | present | unknown`, with outcomes
`ACCEPTED`, `REJECTED` and `UNRESOLVED`; eight source/identity mutations are
rejected and model calls and semantic promotions are zero. C722 is promoted
only as this bounded oracle slice. It does not evaluate kind expressions,
inspect processor capabilities, parse Fortran or close full M3.

The post-promotion reconciliation `R000492` reports 155 outside-promoted rows
(88 disputed and 67 unwitnessed). Selection replay `R000493` selects C724@1;
the next task verifies the bounded C724 oracle.

## M3 — bounded C724 scalar-int-constant-expr legality oracle

Bounded-slice status: `PASS`; implementation replay `R000494` and focused
review `R000495` pass. D0143/E0192 binds canonical lines 3450--3451 on page
83 to existing StandardIR R721 on page 84. The typed candidate has
`value_sign = negative | nonnegative | unknown` and
`representation_method = absent | present | unknown`; the complete table
returns 1 `ACCEPTED`, 5 `REJECTED` and 3 `UNRESOLVED`, with eight mutations
rejected and zero model calls or semantic promotions. C724 is promoted only
as this bounded oracle slice; it does not evaluate expressions, inspect
processors, parse Fortran or close full M3.

Post-C724 reconciliation `R000496` reports 154 outside-promoted rows (88
disputed and 66 unwitnessed). Selection replay `R000497` selects C726@1 from
that residual without semantic promotion.

## M3 — bounded C726 type-param-value star-context oracle

Bounded-slice status: `PASS`; current clean replay `R000504` and focused review
`R000505` pass. D0144/E0194 bind canonical lines 3453--3457 and 3460--3461,
across pages 84--85, to existing StandardIR R721/R722/R723. The typed
candidate varies `type_param_value = star | explicit | unknown` and seven
source-named context states. The complete table returns 17 `ACCEPTED`, 1
`REJECTED` and 3 `UNRESOLVED`; twelve source, page, identity and boundary
mutations reject. The independent validator records zero model calls and zero
semantic promotions. C726 is promoted only as this bounded oracle slice; it
does not parse Fortran, infer context, claim full C726 semantics or close M3.

The post-C726 reconciliation `R000506` reports 153 outside-promoted rows (88
disputed and 65 unwitnessed), with C731@1 first. Selection `R000507` binds
C731 to canonical lines 3469--3470 on page 85 and existing StandardIR R721.
The bounded C731 replay `R000511` and focused review `R000510` pass. D0145/E0196
bind the typed 12-state constant-expression/context oracle to that source span;
the result is bounded-only with zero model calls and semantic promotions. Full
M3 remains open.

Post-C731 reconciliation `R000512` reports 152 outside-promoted rows (88
disputed and 64 unwitnessed), with C732@1 first. The next controller task is
selection of one source-backed bounded property; selection replay `R000513`
binds C732 canonical line 3493, page 85, byte span `221195:107`, to existing
StandardIR R724 (`char-literal-constant`). The next task is the bounded C732
kind-parameter representation-method oracle. Central replay `R000514` passes
with 1 `ACCEPTED`, 1 `REJECTED`, 7 `UNRESOLVED`, twelve rejected mutation
controls, zero model calls and zero semantic promotions. Focused review and
remote parity pass in `R000515` and the pushed `8e4fbe47` revision, so C732 is
promoted only as this bounded oracle slice. Post-C732 reconciliation `R000516`
leaves 151 residual rows (87 disputed, 64 unwitnessed), with C733@1 first.
Selection `R000517` binds C733 canonical line 3564, page 87, byte span
`226248:107`, to existing StandardIR R725 (`logical-literal-constant`). The
bounded C733 kind-parameter representation-method oracle is now promoted only
as a bounded slice;
central replay R000518 passes with 1 `ACCEPTED`, 1 `REJECTED`, 7 `UNRESOLVED`,
twelve rejected mutation controls, zero model calls and zero semantic
promotions. Focused review R000519 passes. Post-C733 reconciliation R000520
leaves 150 residual rows (86 disputed and 64 unwitnessed), with C735@1 first.
Corrected selection `R000522` binds C735 canonical line 3620, page 88, byte
span `229534:101`, to existing StandardIR R727/R728. C735 replay `R000527`
and focused review `R000528` pass, so C735 is promoted only as its bounded
typed uniqueness oracle. Reconciliation `R000529` records the post-C735
selection: 149 residual rows (85 disputed and 64 unwitnessed), with C743@1
first; full M3 remains open.

## M3 — bounded C735 derived-type attribute uniqueness oracle

Bounded-slice status: `PASS`; E0202 replay `R000527` and focused review
`R000528` pass. D0148 binds C735 canonical line 3620, page 88, byte span
`229534:101`, to existing StandardIR R727/R728. The typed oracle covers
`none`, `distinct`, `duplicate` and `unknown` attribute-occurrence states in
the derived-type-stmt context: 2 `ACCEPTED`, 1 `REJECTED`, and 9 `UNRESOLVED`.
Twelve source, page, identity and contract mutations reject. This is a
bounded oracle only; it does not parse derived-type statements, resolve
attribute names, promote a C735 semantic fact, or close full M3. The exact
functional revision is
`579767e1ce69fcff99b12dee6ec8c1efa5b82ac4`, and the final replay command is:

```text
M3_C735_EXPECTED_CENTRAL_COMMIT=ffdda31c289531d4b6ac4b0a32ce6db6fb6bb1de tests/e2e/run-m3-c735.sh --fresh
```

The completed controller selection after C735 is recorded by E0203/R000530.
Its post-C735 partition is regenerated with:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

Regenerate the C735 selection evidence with:

```text
jq -c 'select(.row_key == "C735@1")' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
nl -ba .cache/runs/E0001/R000003/j3-24-007.canonical.txt | sed -n '3620p'
sed -n '93p' .cache/runs/E0001/R000003/j3-24-007.pages.index
sed -n '78,79p' .cache/runs/E0171/R000433-provenance-replay/standardir.sx
```

Regenerate the C731 result with:

```text
M3_C731_EXPECTED_CENTRAL_COMMIT=2855a9e3e9e65875eacbd4199ddfe84cca32f5c6 tests/e2e/run-m3-c731.sh --fresh
```

Regenerate the C732 result with:

```text
M3_C732_EXPECTED_CENTRAL_COMMIT=40bad4f842a87000ceddb68449a801c2282e2b60 tests/e2e/run-m3-c732.sh --fresh
```

Regenerate the C733 result with:

```text
M3_C733_EXPECTED_CENTRAL_COMMIT=5716db592fed41799e4ef8e7000a56cf37a8c1bd tests/e2e/run-m3-c733.sh --fresh
```

The retained post-C733 residual partition command is kept above for history.

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

The historical post-C735 residual partition is regenerated with:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

## M3 — bounded C743 private-or-sequence uniqueness oracle

Bounded-slice status: `PASS`; E0204 replay `R000531` and focused review
`R000532` pass. E0203/R000530 mechanically confirms 149 residual
rows, 85 `disputed`, 64 `unwitnessed` and `C743@1` first. The selected source
is J3/24-007 C743 at canonical line 3637, printed page 89, byte span
`230736:105`. Existing StandardIR R726 (`derived-type-def`) contains a
zero-or-more repeat of R729 (`private-or-sequence`).

D0149 defines the bounded candidate as occurrence
`none | single | duplicate | unknown` crossed with context
`derived-type-def | other | unknown`. In the derived-type-def context, none or
single is `ACCEPTED`, duplicate is `REJECTED`, and all other states are
`UNRESOLVED`. The replay produces 2 `ACCEPTED`, 1 `REJECTED`, 9 `UNRESOLVED`,
twelve rejected mutation controls, zero model calls and zero semantic
promotions. This bounded oracle does not parse definitions, distinguish
PRIVATE from SEQUENCE, resolve names or promote a C743 semantic fact. The
exact replay command is:

```text
M3_C743_EXPECTED_CENTRAL_COMMIT=e4e7edf8281050f3dc854a5a984baba80d9aab27 tests/e2e/run-m3-c743.sh --fresh
```

Evidence: `research/decisions/D0149-twenty-third-m3-c743-private-or-sequence-uniqueness-oracle.md`,
`research/experiments/E0204-can-a-deterministic-source-backed-c743-o/`,
`artifacts/traces/m3-c743-source-backed-v0.json`,
`artifacts/reports/M3/m3-c743-source-backed-v0.md`,
`artifacts/reports/M3/m3-c743-focused-review-v1.md`, and runs `R000531` and
`R000532`. Full M3 remains open.

E0205/R000537 selects the next bounded C744 property. Its post-C743 partition
is 148 residual rows (85 `disputed`, 63 `unwitnessed`) with C744@1 first,
regenerated by:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

Regenerate the selected C744 row and source bindings with:

```text
jq -c 'select(.row_key == "C744@1")' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
nl -ba .cache/runs/E0001/R000003/j3-24-007.canonical.txt | sed -n '3639,3640p'
python3 - <<'PY'
from pathlib import Path
lines = Path('.cache/runs/E0001/R000003/j3-24-007.canonical.txt').read_bytes().splitlines(keepends=True)
print('start', sum(map(len, lines[:3638])), 'length', len(lines[3638]) + len(lines[3639]))
PY
rg -n '^page 89 ' .cache/runs/E0001/R000003/j3-24-007.pages.index
sed -n '77,81p' .cache/runs/E0171/R000433-provenance-replay/standardir.sx
```

## M3 — selected C744 END TYPE name relation

Selection status: `PASS`; E0205/R000537 mechanically confirms the pinned
partition and selects C744 at canonical lines 3639--3640, page 89, byte span
`230888:137`, over existing StandardIR R727/R730.

D0150 defines the bounded candidate as END TYPE name presence
`absent | present | unknown` crossed with name relation
`same | different | unknown` and context `derived-type-def | other | unknown`.
Absent in the derived-type-def context and present/same there are `ACCEPTED`;
present/different there is `REJECTED`; all other states are `UNRESOLVED`. The
selection does not parse definitions, compare real identifier spellings,
perform case folding or name resolution. E0206/R000538 and focused review
R000539 pass with 4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`, twelve rejected
mutations, zero model calls and zero semantic promotions. C744 is promoted
only as this bounded typed oracle; full M3 remains open.

The exact clean replay command is:

```text
M3_C744_EXPECTED_CENTRAL_COMMIT=eaa19119e914ca72e62042081b58e948ac98ba6d tests/e2e/run-m3-c744.sh --fresh
```

Evidence: `research/experiments/E0206-can-a-deterministic-source-backed-c744-o/`,
`contracts/m3-c744-derived-type-end-type-name-relation-v0.sxs`,
`tests/e2e/validate_m3_c744.py`,
`artifacts/traces/m3-c744-source-backed-v0.json`,
`artifacts/reports/M3/m3-c744-source-backed-v0.md`,
`artifacts/reports/M3/m3-c744-focused-review-v1.md`, and runs `R000538`,
`R000539` and final clean handoff `R000540`.

The post-C744 partition has 147 residual rows (84 `disputed`, 63 `unwitnessed`)
with C745@1 first. Regenerate it with:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

## M3 — selected C745 SEQUENCE component-presence relation

Selection status: `PASS`; E0207/R000542 corrects the append-only selection
record and binds C745 to canonical lines 3665--3667, printed page 89, byte
span `232141:276`, over existing StandardIR R726/R731/R735.

D0151 selects only the first C745 obligation: SEQUENCE present in a
derived-type-def requires one or more components. The typed candidate is
`sequence-presence × component-presence × context`, with values
`absent|present|unknown × zero|one-or-more|unknown ×
derived-type-def|other|unknown`. The next oracle accepts vacuous absence and
the satisfied one-or-more case, rejects present/zero, and returns
`UNRESOLVED` otherwise. It does not parse definitions, count real components,
classify component types, inspect type parameters or type-bound procedures,
restart E0172 or claim full M3.

Evidence: `research/decisions/D0151-c745-sequence-component-presence-relation.md`,
`research/experiments/E0207-can-the-post-c744-residual-select-one-so/`,
`artifacts/reports/M3/m3-core0-next-property-selection-v12.md`, and runs
`R000541` and corrected `R000542`. The next task implements this bounded
oracle only.

## M3 — bounded C745 SEQUENCE component-presence oracle implementation

Bounded-slice status: `PASS`; focused review R000560 passes. C745 is promoted
only as this bounded oracle leaf. Full M3 remains `OPEN`.

The implementation binds C745 to canonical lines 3665--3667, page 89 and byte
span `232141:276`, over StandardIR R726/R731/R735. Its typed product varies
SEQUENCE presence, component presence and context across 27 states. A
human-authored expected-outcome table is consumed as the independent behavioral
oracle. The corrected replay records 4 `ACCEPTED`, 1 `REJECTED`, 22
`UNRESOLVED`, twelve rejected mutations, zero model calls and zero semantic
promotions. C745 is promoted only as this bounded oracle leaf. It does not
parse definitions, count real components, evaluate the other C745 obligations
or claim full M3. Corrected selection R000564 binds C746 to canonical lines
3764--3765, printed page 77, byte span `237401:171`, and existing StandardIR
R727/R732/R733. D0152 records the next typed membership contract.

Regenerate the replay with:

```text
tests/e2e/run-m3-c745.sh --fresh
```

Evidence: `research/experiments/E0208-can-a-deterministic-source-backed-c745-o/manifest.yaml`,
`tests/fixtures/m3-c745-expected-outcomes-v0.json`,
`artifacts/traces/m3-c745-source-backed-v0.json`,
`artifacts/reports/M3/m3-c745-source-backed-v3.md`, retained replay and review
runs `R000543`--`R000564`, and retained review reports
`artifacts/reports/M3/m3-c745-focused-review-v0.md` and
`artifacts/reports/M3/m3-c745-focused-review-v1.md` and
`artifacts/reports/M3/m3-c745-focused-review-v2.md` and
`artifacts/reports/M3/m3-c745-focused-review-v3.md`. The malformed historical
selection serialization is preserved in
`research/runs/archive/2026-08.jsonl.raw`; correction runs `R000558` and
`R000559` establish the parseable canonical ledger.

## M3 — bounded C746 type-parameter-name membership oracle implementation

Bounded-slice status: `PASS`; replay R000566 and focused review R000567 pass.
C746 is promoted only as this bounded oracle leaf. Full M3 remains `OPEN`.

The implementation binds C746 to J3-24-007 canonical lines 3764--3765,
printed page 77, byte span `237401:171`, over StandardIR R727/R732/R733. Its
typed product varies definition-name presence, declared-name membership and
derived-type-definition context across 27 states. The independent expected
outcome table and deterministic oracle record 4 `ACCEPTED`, 1 `REJECTED`, 22
`UNRESOLVED`, twelve rejected mutations, zero model calls and zero semantic
promotions. The slice does not parse derived-type definitions, compare real
identifier spellings, check C747 cardinality or claim full M3.

Regenerate the replay with:

```text
tests/e2e/run-m3-c746.sh --fresh
```

Evidence: `research/experiments/E0210-can-a-deterministic-source-backed-c746-o/manifest.yaml`,
`contracts/m3-c746-derived-type-type-parameter-name-membership-v0.sxs`,
`tests/fixtures/m3-c746-expected-outcomes-v0.json`,
`artifacts/traces/m3-c746-source-backed-v0.json`,
`artifacts/reports/M3/m3-c746-source-backed-v0.md`,
`artifacts/reports/M3/m3-c746-focused-review-v0.md`, and runs `R000566` and
`R000567`.

The post-C746 residual partition has 145 rows (84 `disputed` and 61
`unwitnessed`) with C747@1 first. R000568 selects C747's bounded
type-parameter-name occurrence-cardinality relation. R000574 and R000575 pass,
so C747 is promoted only as a bounded oracle leaf. Post-C747 selection R000576
leaves 144 rows (83 `disputed`, 61 `unwitnessed`) with C748@1 first; the active
task selects the next bounded property after C748.

## M3 — selected C747 type-parameter-name exact-once relation

Selection status: `PASS`; R000568 is the deterministic post-C746 selection
run. C747 is J3-24-007 clause 7, canonical lines 3766--3767, printed page 77,
byte span `237572:183`, contained by canonical page-index record 91, over
existing StandardIR R727/R732/R733.

D0153 as amended by D0154 defines the typed candidate as derived-name presence, definition
occurrence cardinality and derived-type-definition context. The bounded oracle
accepts the vacuous absent case and the present/one case, rejects present/zero
and present/many, and returns `UNRESOLVED` otherwise. The C747 leaf does not
check extra definition names, parse definitions, compare real names, perform
name resolution or close full M3. No model output can promote a semantic fact.

Evidence: `research/decisions/D0153-twenty-seventh-m3-c747-type-parameter-name-exact-once.md`,
`research/decisions/D0154-c747-page-index-binding.md`,
`research/experiments/E0211-post-c746-residual-bounded-property-sele/manifest.yaml`,
`artifacts/reports/M3/m3-core0-next-property-selection-v16.md`, and
`research/runs/2026-08.jsonl#R000568`, corrected replay
`research/runs/2026-08.jsonl#R000574` and focused review
`research/runs/2026-08.jsonl#R000575`. C747 is promoted only as this bounded
oracle leaf. Post-C747 selection R000576 identifies C748@1 as the next task;
full M3 remains open.

## M3 — bounded C748 component-attribute at-most-once relation

The C748 source binds J3-24-007 clause 7, canonical line 3834, printed page
79, byte span `240727:97`, canonical page-index record 93, and existing
StandardIR R737. D0155's v0 exact-once interpretation was rejected by focused
review R000578 because zero occurrences are valid under “no more than once”.
D0156 corrects the typed relation to at-most-once. The corrected replay R000579
passes `tests/e2e/run-m3-c748.sh --fresh` with 6 `ACCEPTED`, 1 `REJECTED`, 29
`UNRESOLVED`, twelve rejected mutations, zero model calls and zero semantic
promotions. Focused review R000580 passes with no findings, so C748 is promoted
only as this bounded oracle leaf. E0215/R000582 then selects C749@1 as the
next source-backed property; the active task implements its bounded oracle.
C748 does not parse component definitions, resolve names, check C749--C751 or
close full M3.

## M3 — selected C749 component-type eligibility relation

Selection status: `PASS`; E0215/R000582 recomputes the retained post-C748
partition as 143 rows (82 `disputed`, 61 `unwitnessed`) and selects C749@1.
The source is J3-24-007 clause 7, canonical lines 3835--3837, printed page
79, byte span `240824:234`, contained by page-index record 93, over existing
StandardIR R703/R737. D0157 defines the next typed candidate as
pointer-or-allocatable-attribute state × declaration-type category ×
component-def-stmt context. The bounded oracle will accept the four allowed
type categories when the attribute is absent in that context, reject the
`other` category in that same state, and return `UNRESOLVED` otherwise. The
selection made zero model calls and no semantic promotion. E0216/R000593 and
focused review/evidence gate R000592 now pass the implementation. E0217/R000594
selects C750@1 as the next source-backed property; full M3 remains open.

## M3 — bounded C749 component-type eligibility oracle

Bounded-slice status: `PASS`. The source is J3-24-007 clause 7, canonical lines
3835--3837, printed page 79, byte span `240824:234`, page-index record 93, over
existing StandardIR R703/R737. The complete typed product has 54 states: 4
`ACCEPTED`, 1 `REJECTED` and 49 `UNRESOLVED`. Twelve source, identity, page and
contract mutations are rejected. The replay makes zero model calls and zero
semantic promotions.

Replay command:

```text
M3_C749_EXPECTED_CENTRAL_COMMIT=8622283453e652a0ad1a51cac1cb45288aef515a tests/e2e/run-m3-c749.sh --fresh
```

Evidence: E0216 manifest, D0158, replay report, focused review report and
central runs `R000589`--`R000593` under this repository. This is a bounded
oracle leaf; it does not parse arbitrary Fortran, perform name resolution or
close full M3. E0217/R000594 selects C750@1 as the next property.

## M3 — selected C750 component-array deferred-shape relation

Selection status: `PASS`. E0217/R000594 recomputes the retained post-C749
partition as 142 rows (82 `disputed`, 60 `unwitnessed`) and selects C750@1.
The source is J3-24-007 clause 7, canonical lines 3838--3839, printed page
79, byte span `241058:135`, contained by page-index record 93, over existing
StandardIR R737/R740. D0159 defines the typed candidate as pointer-or-
allocatable-attribute state × component-array-spec state × component-def-stmt
context. The bounded oracle accepts present + deferred-shape-list in that
context, rejects present + explicit-shape-list there, and returns
`UNRESOLVED` otherwise. E0218/R000596 passes the technical replay with 1
`ACCEPTED`, 1 `REJECTED`, 25 `UNRESOLVED`, twelve rejected mutations, zero
model calls and zero semantic promotions. Focused review/evidence gate R000597
passes; full M3 remains open.

## M3 — bounded C750 component-array deferred-shape oracle

Bounded-slice status: `PASS` in E0218/R000596; focused review/evidence gate
R000597 also passes, so C750 is promoted only as a bounded leaf. The exact
command is:

```text
M3_C750_EXPECTED_CENTRAL_COMMIT=7c0bf9740450f26d6bcf879c4a980c7e0d58ce6c tests/e2e/run-m3-c750.sh --fresh
```

The 27-state product binds C750 canonical lines 3838--3839, printed page 79,
byte span `241058:135`, page-index record 93, and StandardIR R737/R740. It
produces 1 `ACCEPTED`, 1 `REJECTED` and 25 `UNRESOLVED` outcomes, rejects
twelve mutations, and records zero model calls and zero semantic promotions.
Evidence: E0218 manifest, D0160, replay reports, focused review report and
R000596--R000597. This does not parse arbitrary Fortran or close full M3.

## M3 — selected C751 coarray-allocatable relation

Selection status: `PASS`. E0219/R000598 leaves 141 residual rows (82
`disputed`, 59 `unwitnessed`) and selects C751@1. The source is J3-24-007
clause 7, canonical lines 3840--3841, printed page 79, byte span `241193:142`,
over existing StandardIR R737/R739/R809/R810/R811. D0161 defines the bounded
12-state candidate; no model call or semantic promotion occurred.

## M3 — next bounded C751 coarray-allocatable oracle

The technical verifier `tests/e2e/run-m3-c751.sh --fresh` passes in E0220/R000602
with 4 `ACCEPTED`, 4 `REJECTED`, 4 `UNRESOLVED`, twelve rejected mutations,
zero model calls and zero semantic promotions. Focused review R000601 passes
with two independent reviewers, so C751 is promoted only as a bounded oracle
leaf. The bounded contract accepts an absent coarray-spec and a
deferred-coshape with ALLOCATABLE present, rejects a deferred-coshape without
ALLOCATABLE and every explicit-coshape, and leaves unknown states unresolved.
It does not parse arbitrary Fortran or close full M3.

## M3 — selected C752 forbidden coarray-type relation

Selection status: `PASS`. E0221/R000606 records the corrected artifact hashes
for the deterministic post-C751 selection. The pinned residual partition has
140 rows (81 `disputed`, 59 `unwitnessed`), with C752@1 first. The source is
J3-24-007 clause 7, canonical lines 3842--3844, printed page 79, byte span
`241335:223`, and page-index record 93. Existing StandardIR supplies
R702/R703/R704/R737/R739. C_PTR, C_FUNPTR and TEAM_TYPE are not direct
StandardIR rows, so D0164 requires an explicit
`named-module-type-unknown` state; it remains `UNRESOLVED` when a coarray spec
is present. No model ran, no semantic fact was promoted, and full M3 remains
open.
Regenerate the partition with the `jq` command recorded in
`artifacts/reports/M3/m3-core0-next-property-selection-v21.md`.

## M3 — bounded C752 forbidden coarray-type oracle

The completed task was `T-M3-c752-forbidden-coarray-type-oracle`; its exact
verifier was `tests/e2e/run-m3-c752.sh --fresh`. It implemented the 15-state
product of coarray-spec `absent|present|unknown` and component type
`C_PTR|C_FUNPTR|TEAM_TYPE|other|named-module-type-unknown`: absent and
present/other are accepted, present with a forbidden type is rejected, and
present named-module-type-unknown or unknown coarray-spec states are unresolved.
This bounded slice does not parse arbitrary Fortran, inspect C753/C754 or
close full M3 by implication. E0222/R000615 and focused review/evidence gate
R000616 pass, promoting only the bounded C752 leaf.

## M3 — selected C754 component-array-spec relation

Selection status: `PASS`. E0223/R000617 leaves 139 residual rows (81
`disputed`, 58 `unwitnessed`) and selects C754@1. The source is J3-24-007
clause 7, canonical lines 3847--3848, printed page 79, byte span `241715:150`,
over page-index record 93 and existing StandardIR R737/R738/R739/R740. No
model ran, no semantic fact was promoted, and full M3 remains open.
Regenerate the partition with the `jq` command in
`artifacts/reports/M3/m3-core0-next-property-selection-v22.md`.

## M3 — bounded C754 component-array-spec oracle

Bounded-slice status: `PASS`; clean central replay `R000618`, pushed-revision
regression `R000622` and focused review/evidence gate `R000620` pass. Full Core
0 semantics remain open and are not claimed.

The slice binds J3-24-007 C754 at canonical lines 3847--3848, printed page 79
and byte span `241715:150` to StandardIR R737/R738/R739/R740. Its typed
candidate crosses POINTER attribute, ALLOCATABLE attribute and
component-array-spec shape, each `absent|present|unknown`. The deterministic
oracle produces 19 `ACCEPTED`, 1 `REJECTED` and 7 `UNRESOLVED` outcomes across
27 states, rejects thirteen source/provenance mutations, and records zero
model calls and zero semantic promotions.

The lifecycle is:

```text
leaf_id: T-M3-c754-component-array-spec-oracle
claim_id: M3-C754-bounded-oracle
parent_id: M3
leaf_status: PASS
claim_status: CLOSED
parent_status: OPEN
evidence_gate_verdict: PASS
review_verdict: PASS
```

Evidence: `research/experiments/E0224-c754-component-array-spec-oracle/`,
`artifacts/reports/M3/m3-c754-source-backed-v0.md`, the focused packet and
review under `artifacts/reports/M3/`, and
`research/runs/2026-08.jsonl#R000618` and `#R000620`. This promotes only the
bounded oracle leaf; it does not parse arbitrary Fortran or promote a C754
semantic fact. The post-C754 residual has 138 rows (81 `disputed`, 57
`unwitnessed`), with C757@1 first.

## M3 — bounded C601 semantic-oracle successor

Bounded-slice status: `PASS`; central replay `R000003` and focused review
`R000022` pass. Full Core 0 semantics remain open and are not claimed.

The slice binds J3/24-007 C601, canonical-text line 2809, to the already
represented StandardIR rows R601, R602 and R603. Its typed candidate carries a
name spelling. A valid spelling of at most 63 characters is `ACCEPTED`, a
valid longer spelling is `REJECTED`, and a non-name spelling is `UNRESOLVED`.
The deterministic oracle does not parse complete source, resolve names or
consume model output. Five source/provenance mutation controls must fail
closed; regenerate the complete inventory with:

```text
tests/e2e/run-m3-c601.sh .cache/runs/E0177/R000003
```

Evidence: `research/decisions/D0127-third-m3-c601-name-length-oracle.md`,
`research/experiments/E0177-can-a-deterministic-oracle-enforce-c601-/`,
`contracts/m3-c601-name-length-oracle-v0.sxs`,
`tests/e2e/validate_m3_c601.py`,
`artifacts/traces/m3-c601-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000016` through `#R000022`, plus focused review
reports under `artifacts/reports/M3/`. No model output can promote a semantic
fact.

## L0 — Normative lexical slice

### Goal

One small lexical source fixture reaches a deterministic StandardIR
observable through a pinned `standard-new` revision.

### Required component path

```text
standard-new
→ lazy-fortran-new integration harness
```

### Definition of done

- [x] `standard-new` is pinned and clean.
- [x] Normative source locator and source hash are recorded.
- [x] The StandardIR artifact regenerates deterministically.
- [x] A source-to-generated manifest is stored centrally.
- [x] One valid fixture succeeds.
- [x] One invalid near-neighbor fails with the expected diagnostic class.
- [x] An independent oracle passes.
- [x] The central clean-checkout command passes.
- [x] The result enters the regression corpus.
- [x] The boundary is explicitly classified as a component-local
      `standard-new` generator fixture and checked by the central verifier.

Evidence: `R000437`,
`artifacts/manifests/l0-lexical-slice-v0.toml` and
`artifacts/traces/l0-lexical-slice-v0.json`; the active review evidence is
`artifacts/reports/L0/replay-boundary-v3-luna-scope.md`,
`artifacts/reports/L0/replay-boundary-v3-luna-contract.md`,
`artifacts/reports/L0/replay-boundary-v3-luna-oracle.md`, and
`artifacts/reports/L0/replay-boundary-v3-luna-reproducibility.md`. Regenerate
the deterministic evidence with `scripts/run_e2e.sh`.

Current status: `PASS`. The v2 review reports are retained historical evidence;
the v3 four-lane reports are the active promotion evidence. Regenerate with
`scripts/run_e2e.sh` and review with the four independent Luna lanes.

## L1 — Frontend slice

Next after: L0

```text
source fixture
→ lexical/layout
→ fortfront-new
→ StandardIR
→ central normalized observable
```

### Definition of done

- [x] A source fixture and its content hash are recorded centrally.
- [x] The pinned StandardIR artifact is consumed by `fortfront-new`.
- [x] A valid fixture reaches a deterministic frontend observable.
- [x] An invalid near-neighbor reaches the expected diagnostic class.
- [x] An independent oracle and complete stage trace pass from a clean checkout.

Evidence: `R000438`,
`artifacts/manifests/l1-frontend-slice-v0.toml`,
`artifacts/traces/l1-frontend-slice-v0.json`, the v1 failed-review reports,
and the v2 active four-lane reports under `artifacts/reports/L1/`. Regenerate
the deterministic evidence with `tests/e2e/run-l1.sh`.

Current status: `PASS` after the corrected replay and four independent Luna
reviews. The v1 reports are retained failure evidence; v2 is active.

## L2 — First compiled execution slice

Next after: L1

Current status: `PASS`.

Active fixture: `tests/fixtures/l2-first-executable-v0.sx`.

Verifier: `scripts/verify_active_milestone.sh`.

Evidence paths: `tests/e2e/run-l2.sh`, `tests/e2e/oracle_l2.py`,
`tests/fixtures/l2-first-executable-v0.toml`,
`artifacts/manifests/l2-first-executable-v0.toml`, and
`artifacts/traces/l2-first-executable-v0.json`; the independent semantic
oracle is `tests/golden/l2-first-executable-v0.oracle.toml`, and malformed and
out-of-scope MIR controls are under `tests/negative/`.

```text
frontend-v0 SX witness
→ ffc-new MIR-v0
→ fortback-new bounded RV64 Linux emission
→ executable
→ expected runtime exit status
```

This first execution slice deliberately begins with an already-produced
`frontend-v0` witness. It verifies the downstream handoff and executable
behavior; it does not claim a new source-to-frontend or StandardIR conversion.
The central contract boundary is `frontend-v0` to `mir-v0`; fortback's
TargetIR and ELF emission structures remain internal to this bounded slice.

### Definition of done

- [x] A pinned `frontend-v0` witness fixture and content hash are recorded centrally.
- [x] The witness is consumed by the pinned FFC driver path.
- [x] The pinned backend path emits a runnable artifact.
- [x] A valid fixture produces an independently verified runtime result.
- [x] The invalid frontend neighbor reaches the expected diagnostic class.
- [x] Malformed and out-of-scope MIR inputs are rejected without artifacts.
- [x] A complete stage trace and clean-checkout command pass.

The initial execution gate was superseded by corrected run `R000441`. The
failed reviews `R000442` and `R000443` remain retained evidence. The corrected
runner and oracle are pinned by the current clean checkout; focused review
`R000444` passes three valid scopes at the exact snapshot. The active boundary
is recorded in `research/decisions/D0122-narrow-l2-boundary.md`.

## L3 — First raw-source-to-executable Fortran slice

Next after: L2 and M1-M2

Current status: `PASS` for the bounded slice; full M3 remains open.

Active source fixture: `tests/fixtures/l3-raw-program-v0.f90`.

The first positive source is exactly one free-form named main program:

```fortran
program p
end program p
```

The central path is:

```text
raw source file
→ fortfront-new source parser
→ frontend-v0 result
→ ffc-new MIR-v0 lowering
→ fortback-new executable
→ process exit status 0
```

The required negative neighbour mismatches the end name. The slice does not
claim declarations, expressions, I/O, modules, procedures, fixed-form source,
or general Fortran parsing. Its independent oracle checks the accepted and
rejected result, the emitted executable's exit status, and the complete stage
trace from a clean checkout. The exact command is
`L3_EXPECTED_CENTRAL_COMMIT=<pinned-central> tests/e2e/run-l3.sh --fresh`.
Technical replay R000647, focused review R000648 and corrected post-promotion
regression R000650 pass. The exact regression command is
`L3_EXPECTED_CENTRAL_COMMIT=51e867b79c8f6d46322304f688697576a226fa7a
tests/e2e/run-l3.sh --fresh`. The next declaration successor can now start.

The declaration successor is frozen by D0174 and the central contract task
passes `scripts/check-contracts.sh`. Its positive is exactly one `integer :: x`
line in the named main program; its malformed neighbour is `integer ::`. The
production implementation must preserve the existing frontend-v0/MIR-v0
observable and does not yet expose a typed variable declaration.

The declaration technical replay R000651, post-technical regression R000652
and focused review R000653 pass. The successor is promoted only as the exact
source-shape claim. D0175 and the `frontend-ast-v1` contract now pass the
central contract gate. The isolated fortfront producer is pinned at
`394f34d`; E0235/R000654 retains a golden mismatch caught by the independent
oracle. Reviews R000658/R000659/R000662 retained stale central lineage,
absolute-path-dependent trace and schema-lineage failures; corrected replay
R000661 and focused reviews R000664/R000665 pass. The exact typed-AST leaf is
promoted only as a bounded claim. The next task selects one additive typed-AST
contract; full M3 remains open.

## M1-M2 — Source-valid StandardIR and sane generated grammars

Next after: L2

Current status: `PASS`.

Active task: `T-M1M2-source-backed-fixture`.

Boundary decision: `research/decisions/D0123-m1m2-central-source-gate.md`.

The first central M1-M2 gate will pin and retrieve external source material,
consume a source-backed StandardIR grammar input, preserve source identity and
lexical spellings, emit EBNF, ANTLR4, Bison and tree-sitter projections, run
their independent validators, and retain positive, negative and mutation
controls. Cached historical replays do not satisfy this milestone until the
central clean-checkout and provenance contract consumes them.

### Definition of done

- [x] Source material has an external manifest, hash and retrieval command.
- [x] A central fixture consumes the pinned source-backed StandardIR input.
- [x] Source identity and lexical target witnesses pass before generators run.
- [x] All four grammar projections regenerate deterministically.
- [x] ANTLR4, Bison and tree-sitter validators pass with the declared conflict
      policy and no undefined symbols.
- [x] Positive, negative and mutation controls pass independently.
- [x] A complete trace, clean-checkout command and regression entry pass.

Central evidence: `R000450` (exact payload authority) and corrected replay
`R000454`,
`tests/fixtures/m1m2-source-backed-v0.toml`,
`research/corpora/m1m2-source-backed-v0.toml`,
`artifacts/traces/m1m2-source-backed-v0.json`, and the exact-revision focused
review reports under `artifacts/reports/M1-M2/`. The focused integration review
`R000455` passes. R000451–R000453 remain retained failed reviews.

Do not begin parser-conflict reduction or semantic/model work before this
gate has an executable central verifier.
