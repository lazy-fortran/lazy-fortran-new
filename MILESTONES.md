# Cross-repository delivery milestones

Milestone status is changed only after the central verification command and
its independent oracle pass. Component repositories do not maintain a second
milestone ledger.

## Current verification state

The historical evidence below is preserved. L0, L1, L2 and M1-M2 corrected
replays and focused reviews pass. The bounded M3 C1106, C702, C601, C603, C721
and C725 slices are promoted by their central verifiers and focused reviews.
The bounded C718 slice is promoted by its corrected replay and focused reviews.
The bounded C723 slice is promoted by replay `R000037` and focused review
`R000038`. The bounded C729 slice is promoted by replay `R000042` and focused
review `R000044`; failed review `R000043` is retained. Full M3 remains open.
The bounded C719 slice is promoted by replay `R000051` and focused review
`R000052`. The bounded C738 slice is promoted by replay `R000053` and focused
review `R000055`. The bounded C1579 slice is promoted by replay `R000062` and
focused review `R000064`. Full M3 remains open.

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

## M3 — Core 0 closure audit

Audit status: `NEEDS EVIDENCE`. E0181/R000032 reproducibly replays the retained
287-row ledger: 4 hard failures, 2 unresolved rows, 94 disputed rows, 69
unwitnessed rows, 7 not-applicable rows and zero semantic promotions. The
counts are regenerated by:

```text
E0123_RETRY_ROWS=.cache/runs/E0123/R000001/rows.jsonl E0123_RETRY_TRAJECTORY=.cache/runs/E0123/R000001/trajectory.jsonl E0123_ANALYSIS_OUTDIR=.cache/runs/E0181/R000001/analysis research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/analyse.sh
```

The audit report is recorded in
`research/experiments/E0181-does-the-retained-core-0-ledger-satisfy-/`,
`artifacts/reports/M3/m3-core0-closure-audit-v1.md`, and
`research/runs/2026-08.jsonl#R000032`. These counts keep full M3 open and do
not authorize semantic promotion.

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

Do not define L3 until L2 passes.

The initial execution gate was superseded by corrected run `R000441`. The
failed reviews `R000442` and `R000443` remain retained evidence. The corrected
runner and oracle are pinned by the current clean checkout; focused review
`R000444` passes three valid scopes at the exact snapshot. The active boundary
is recorded in `research/decisions/D0122-narrow-l2-boundary.md`.

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
