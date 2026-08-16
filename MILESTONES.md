# Cross-repository delivery milestones

Milestone status is changed only after the central verification command and
its independent oracle pass. Component repositories do not maintain a second
milestone ledger.

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

Evidence: `R000437`,
`artifacts/manifests/l0-lexical-slice-v0.toml` and
`artifacts/traces/l0-lexical-slice-v0.json`. Regenerate with
`scripts/run_e2e.sh`.

## L1 — Frontend slice

Blocked by: L0

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
`artifacts/manifests/l1-frontend-slice-v0.toml` and
`artifacts/traces/l1-frontend-slice-v0.json`. Regenerate with
`scripts/verify_active_milestone.sh`.

## L2 — First compiled execution slice

Blocked by: L1

```text
source
→ frontend
→ StandardIR
→ MIR/TargetIR
→ backend
→ executable
→ expected runtime output
```

### Definition of done

- [ ] A source fixture and content hash are recorded centrally.
- [ ] The verified frontend output is consumed by the pinned driver path.
- [ ] The pinned backend path emits a runnable artifact.
- [ ] A valid fixture produces an independently verified runtime result.
- [ ] An invalid near-neighbor reaches the expected diagnostic class.
- [ ] A complete stage trace and clean-checkout command pass.

Do not define L3 until L2 passes.
