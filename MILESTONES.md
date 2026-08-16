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

- [ ] `standard-new` is pinned and clean.
- [ ] Normative source locator and source hash are recorded.
- [ ] The StandardIR artifact regenerates deterministically.
- [ ] A source-to-generated manifest is stored centrally.
- [ ] One valid fixture succeeds.
- [ ] One invalid near-neighbor fails with the expected diagnostic class.
- [ ] An independent oracle passes.
- [ ] The central clean-checkout command passes.
- [ ] The result enters the regression corpus.

## L1 — Frontend slice

Blocked by: L0

```text
source fixture
→ lexical/layout
→ fortfront-new
→ StandardIR
→ central normalized observable
```

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

Do not define L3 until L2 passes.
