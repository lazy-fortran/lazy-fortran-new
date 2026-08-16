# D0121. First executable vertical slice uses frontend-v0 to MIR-v0 to RV64 Linux

Date: 2026-08-16
Status: superseded by D0122
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

<!-- Optional headers, one per line, when they apply:
Supersedes: D####
Amends: D####
Retracts: D####
-->

## Context

L0 and L1 now pass their central clean replay and independent review gates.
The next dependency-ready task is the first source-to-executable slice. The
component repositories already expose a bounded `frontend-v0` to `mir-v0`
lowering path in `ffc-new`, and `fortback-new` has RISC-V encoding and ELF
building blocks. QEMU and the RISC-V linker are available as behavioral
oracles on the development host. The project needs one executable integration
slice without pretending that general instruction selection or a complete
Fortran frontend already exists.

## Decision

The first L2 delivery slice is:

```text
frontend-v0 SX
→ ffc-new frontend-v0 lowering
→ canonical mir-v0 SX
→ fortback-new bounded RV64 Linux emission
→ qemu-riscv64 execution
→ independent exit-status oracle
```

The slice uses the existing versioned `frontend-v0`, `mir-v0`, `targetir-v0`
and `emission-v0` contracts. The backend may support only the existing
frontend witness's small MIR subset, but it must reject malformed and
unsupported MIR explicitly. The central runner owns the fixture, pins,
trace, negative neighbor, deterministic output checks and runtime oracle.
The slice is a delivery boundary, not a general instruction-selector claim.

## Rejected

Using a host-native executable as the first backend result is rejected because
it would not exercise the new TargetIR/backend path. Waiting for the complete
MIR or a general ABI is rejected because the existing bounded contracts are
enough to establish the first cross-repository executable behavior. Treating a
raw object file as the final observable is rejected because the milestone
requires a runnable artifact and an independent runtime result.

## Reversal condition

Reverse this slice boundary if the existing component APIs cannot express a
reproducible bounded handoff without fixture-specific implementation branches,
or if QEMU and an independently linked RV64 artifact cannot provide a stable
runtime oracle. In that case retain the component work as evidence and record
a successor decision with the smallest verified alternative.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
