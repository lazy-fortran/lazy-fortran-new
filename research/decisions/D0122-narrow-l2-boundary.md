# D0122. Narrow L2 to the observed frontend-witness handoff

Date: 2026-08-16
Status: accepted
Supersedes: D0121

## Context

The first L2 runner and four independent reviews found that the available
component path is real but narrower than D0121 stated. The runner starts from
a pinned `frontend-v0` witness, not from `standard-new` or `fortfront-new`.
FFC emits canonical `mir-v0` SX. Fortback parses that SX and constructs its
internal target metadata and ELF emission directly; it does not consume a
serialized `targetir-v0` or `emission-v0` boundary artifact. The central
contract schema also needed its actual MIR instruction list declared.

## Decision

L2 is the bounded, observed path:

```text
frontend-v0 SX witness
→ ffc-new canonical mir-v0 SX
→ fortback-new bounded RV64 Linux ELF
→ qemu-riscv64 exit-status and instruction-sequence oracle
```

The central L2 contract boundary is `frontend-v0` to `mir-v0`. Fortback's
TargetIR and ELF emission types are implementation-internal evidence in this
slice, not claimed cross-repository serialized contracts. The central runner
must test the exact witness profile, canonical MIR semantics, independent
RV64 code words, deterministic ELF bytes, runtime exit status, and malformed
and out-of-scope MIR rejection without artifacts.

`mir-v0` therefore declares the `instructions` list used by the component.
The targetir and emission contracts remain available for a later slice that
actually crosses those boundaries.

## Rejected

Claiming source-to-frontend or StandardIR behavior here is rejected because
the active input is already a frontend-v0 artifact. Claiming serialized
TargetIR/emission consumption is rejected because no such values cross the
current component boundary. Adding adapters solely to make this first slice
appear broader is rejected; it would add machinery without a delivered
observable.

## Reversal condition

Replace this boundary when a central fixture reaches the real frontend from a
source input or when a component path produces and consumes versioned
TargetIR/emission values. Those later boundaries must have their own
independent fixtures and oracles.
