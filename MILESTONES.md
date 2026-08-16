# Cross-repository delivery milestones

Milestone status is changed only after the central verification command and
its independent oracle pass. Component repositories do not maintain a second
milestone ledger.

## Current verification state

The historical evidence below is preserved. L0, L1, L2 and M1-M2 corrected
replays and focused reviews pass. The bounded M3 C1106 replay passes its
central verifier; focused review is pending. Full M3 remains open.

## M3 — bounded C1106 semantic-oracle slice

Current status: `OPEN`; central verifier `R000473` is `PASS`, focused review
and final promotion reconciliation are pending. Full Core 0 semantics are not
claimed.

The slice binds J3/24-007 C1106 to StandardIR R1102/R1103/R1106. Its typed
name-side contract uses an optional name value, and its deterministic oracle
returns `ACCEPTED`, `REJECTED` or `UNRESOLVED` with no model promotion path.
The replay produces six case outcomes and three mutation failures; regenerate
those observations with:

```text
tests/e2e/run-m3-c1106.sh .cache/runs/E0175/R000473
```

Evidence: `research/decisions/D0124-first-m3-associate-name-oracle.md`,
`research/decisions/D0125-m3-c1106-case-insensitive-names.md`,
`contracts/m3-c1106-semantic-oracle-v0.sxs`,
`tests/e2e/validate_m3_c1106.py`,
`artifacts/traces/m3-c1106-source-backed-v0.json`, and
`research/runs/2026-08.jsonl#R000471` and
`research/runs/2026-08.jsonl#R000473`.

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
