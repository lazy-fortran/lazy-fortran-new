# Central vertical-slice contract

## Active fixture

The active fixture, content hash and expected observable are recorded in
`STATUS.md` before implementation begins. An unset value is an open blocker.

## Declared path

```text
frontend-v0 SX witness
→ mir-v0 contract
→ bounded RV64 Linux emission
→ deterministic runtime observable
```

The active L2 slice is intentionally a downstream witness boundary. It does
not claim to execute source parsing, StandardIR conversion, or serialized
TargetIR/emission interchange; those are later slices with their own fixtures.

Every executed stage records its contract revision, producer commit, input and
output hashes, source-span mapping and diagnostics. No stage is PASS merely
because it wrote a file; its output is consumed by the next stage or checked
as the final observable.

## Acceptance

The slice requires one valid fixture, one invalid near-neighbor, a named
independent oracle and a clean-checkout command. The final observable is an
accepted normalized artifact, generated output, runtime result or stable
diagnostic—whichever the active milestone declares.
