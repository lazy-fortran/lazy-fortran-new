# D0072 — Stop expanding hand-maintained target instruction cases

Date: 2026-08-14
Status: accepted

## Context

The RISC-V backend has now exercised several source-backed RV64I codec cases,
including the `SLTIU` slice at `fortback-new` commit
`dcbae9882850efbe246b8faf22394306589ce530` and the `XORI` slice at
`205fe1c2cf994274b87f676f07c57fddb911da23`. Each preserves source identity
and passes independent encoding, decoding and rejection controls. The code
still contains hand-maintained instruction-kind and mnemonic branches,
however. Continuing to add cases in that form would turn the bootstrap
fixture into a special-case backend and would not test the intended
specification-generated architecture.

## Decision

Treat the existing instruction cases as bounded bootstrap witnesses and
regression controls. The next backend milestone must make the source-to-
TargetIR-to-codec path generic: accepted source records are normalized into
TargetIR data, and encoder/decoder metadata or code is generated from that
data. New instruction cases may be added only when they expose a missing
generic TargetIR or generator capability, not merely to extend a hand-written
dispatch list.

The lab retains the source manifests, experiment records and provenance. The
production repository retains the importer, TargetIR types, generator and
generated output; it must not receive ISA payloads or laboratory notes.

## Rejected

- Continuing to hand-add one mnemonic, enum value and branch per instruction;
  this makes maintenance proportional to instruction count and hides whether
  the upstream specification can drive the backend.
- Treating the current fixtures as the final backend architecture; they are
  useful behavioral witnesses but do not provide generated coverage.
- Waiting for `mir-v0` before building the generic codec generator; source
  ingestion, TargetIR normalization and codec generation are independent of
  instruction selection.

## Reversal condition

Write a successor if the pinned RISC-V or AArch64 source families cannot be
represented by a compact generic TargetIR without target-specific branches,
or if generated codecs fail the same independent controls that the bounded
fixtures pass. A successor must identify the concrete source feature or
schema limitation that justifies retaining a manual exception.
