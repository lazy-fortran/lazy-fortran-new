# Independent Luna review protocol

Luna reviews are independent evidence checks, not a planning committee. Use
the installed `parallel-luna` skill with the same immutable packet, exact
claim and assigned scope. Reviewers must not see another reviewer's prompt,
draft, verdict or conclusions before issuing their own verdict.

## Fast-wave model policy

Native Luna workers used for M3 fixture generation and implementation default
to `gpt-5.6-luna` with reasoning effort `medium`. Low effort is reserved for
non-semantic mechanical tasks and is not a fixture-generation setting. A
higher effort requires a task-specific blocker and is recorded with the wave.

Harvest review is batch-oriented. The controller first checks the batch
schema, source envelopes, hashes and duplicate keys. A worker packet remains
provisional until that intake passes. The controller does not turn a worker's
semantic proposal into an accepted fact during intake.

## Review levels

### Micro (default)

Use one reviewer for ordinary meaningful code, derivation, experiment or
interpretation work. Return only `PASS` or:

```text
FIRST ISSUE: ...
MINIMAL FIX: ...
```

The micro-review is ephemeral. A PASS needs no report, ledger entry or commit;
an issue returns to the active task.

### Focused (promotion boundary)

Use two or three independent scoped reviewers only for milestone promotion,
cross-component interface changes, major reusable artifacts and release-level
claims. Select only relevant scopes from:

1. milestone truth and scope;
2. contract and interface;
3. oracle independence and adversarial correctness;
4. reproducibility, determinism and maintainability.

Each reviewer returns:

```markdown
Verdict: PASS | NEEDS FIX | INVALID
First fatal issue: [none if PASS; otherwise one exact issue]
Evidence: [path, command output, counterexample or dependency]
Required correction: [one minimal corrective action]
```

The coordinator promotes only if every selected reviewer passes. A valid
fatal issue is not removed by majority vote.

For a fast wave, focused review covers the reusable contract, intake boundary
or milestone claim. It does not require a separate review report for every
provisional packet. A selected implementation candidate still needs its own
independent oracle and verifier before it can enter the focused packet.

### Full

Use all relevant scopes only for publication or release, a terminal claim,
irreversible architecture, or an explicit user request. Full review is not the
default.

## Retention and historical evidence

Review does not replace the central verifier, component tests or independent
oracle. Micro results remain ephemeral unless they find a defect. Focused and
full reports are retained only when they support a durable promotion or
record a defect that must survive restart. Existing historical four-lane
reports remain immutable evidence; this protocol defines the default for new
reviews and does not change milestone status.
