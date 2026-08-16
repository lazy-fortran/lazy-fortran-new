# Cross-repository delivery milestones

Milestone status is changed only after the central verification command and
its independent oracle pass. Component repositories do not maintain a second
milestone ledger.

## Current verification state

The historical evidence below is preserved. L0, L1 and L2 corrected replays
pass. M1-M2 is the active open milestone.

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

Current status: `OPEN`.

Active task: `T-M1M2-source-backed-fixture`.

Boundary decision: `research/decisions/D0123-m1m2-central-source-gate.md`.

The first central M1-M2 gate will pin and retrieve external source material,
consume a source-backed StandardIR grammar input, preserve source identity and
lexical spellings, emit EBNF, ANTLR4, Bison and tree-sitter projections, run
their independent validators, and retain positive, negative and mutation
controls. Cached historical replays do not satisfy this milestone until the
central clean-checkout and provenance contract consumes them.

### Definition of done

- [ ] Source material has an external manifest, hash and retrieval command.
- [ ] A central fixture consumes the pinned source-backed StandardIR input.
- [ ] Source identity and lexical target witnesses pass before generators run.
- [ ] All four grammar projections regenerate deterministically.
- [ ] ANTLR4, Bison and tree-sitter validators pass with the declared conflict
      policy and no undefined symbols.
- [ ] Positive, negative and mutation controls pass independently.
- [ ] A complete trace, clean-checkout command and regression entry pass.

Do not begin parser-conflict reduction or semantic/model work before this
gate has an executable central verifier.
