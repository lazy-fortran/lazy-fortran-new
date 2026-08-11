# D0004. A generated backend, RISC-V and AArch64 first

Date: 2026-08-11
Status: accepted

## Context

The original plan lowered MIR to LLVM IR and treated a native backend as distant
work, with `liric` available as an alternative. Examining `liric` changed the
picture in both directions.

It is more capable than assumed: about 50,000 lines of C11 with its own LLVM IR
parser, bitcode decoder, JIT, instruction selection for x86-64, AArch64 and
RISC-V, ELF and Mach-O writers, and a reported order-of-magnitude speedup
against LLVM on its own 95-file corpus. A native backend for this class of IR is
demonstrably tractable.

It is also hand-written, which under this project's own thesis makes it the
weakest link: every other layer would be generated from a specification and
checked against oracles, while code generation rested on 50,000 lines someone
maintains by hand. Its own roadmap reports producer, nightly and compatibility
evidence as red, 78% of its commits come from a single month, and `TODO.md` is
stale at HEAD with an unresolved optimized-bitcode defect.

## Decision

A separate repository, `fortback-new`, generates the backend from official
machine-readable ISA specifications, exactly as `standard-new` generates the
frontend from the normative language document. `ffc-new` keeps the
ISA-independent driver, MIR and optimization.

**RISC-V and AArch64 first; x86-64 last.**

- RISC-V: `riscv-opcodes` for encodings, the Sail model as official executable
  semantics, BSD licensed, with Spike and QEMU as behavioural oracles. Sail
  makes per-compilation translation validation achievable.
- AArch64: ARM's Machine Readable Architecture gives every A64 encoding plus ASL
  semantics, and it runs natively on hardware already in use here.
- x86-64: no official machine-readable specification. Encodings come from Intel
  XED data files and Zydis; semantics from nothing authoritative; the SDM is a
  PDF, which is the same extraction problem one layer down.

LLVM remains a differential oracle and performance baseline, off the production
path.

## Rejected

**Adopt `liric` as the production backend.** Fastest to native code and makes
the hand-written layer permanent, at the exact point where the project's claim
is strongest and easiest to check.

**LLVM first, native later.** Safe, and keeps a very large external dependency
on the critical path for years while deferring the most interesting result.

**x86-64 first because that is where the machines are.** Convenient and inverts
the quality ordering: it is the ISA where a generated backend is hardest to
build and impossible to validate formally, so it is the worst place to discover
whether the method works.

## Consequences

Two targets from the start means roughly 1.5× the early backend work, and turns
"the cost of a generated backend tracks specification quality" from an assertion
into a measurement with two data points, then three (E11).

Self-hosting on RISC-V requires emulation; AArch64 covers native execution.

## Reversal condition

If generating a correct encoder from `riscv-opcodes` plus Sail turns out to cost
more than hand-writing one, measured, not estimated, the premise is wrong and
the whole backend argument needs restating. E11 is built to detect that case.
