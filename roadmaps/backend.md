# Backend lane

Owner: `fortback-new`. Inputs: `targetir-v0`, `emission-v0`, later `mir-v0`.
Source manifests and verified downloads belong to the laboratory under
`artifacts/isa/` and `.cache/`. Importers, TargetIR production types, generated
encoders/decoders and behavioral tests belong to `fortback-new`.

## Dependency order

- scaffold the production repository and contract reader.
- ingest RISC-V and AArch64 machine-readable source families independently.
- generate register, feature, encoder and decoder infrastructure.
- add ABI, relocation and object-format records.
- ingest x86-64 as a separately classified, lower-authority source family.
- connect `mir-v0` only after its contract revision is integrated.
- synthesize and verify instruction selection, then measure cost.

The bounded `riscv-opcodes` and AARCHMRS source importers, canonical
TargetIR-v0 SX handoff, AArch64 fixed ADD/SUB codec, reloc-free RISC-V ELF64
object writing, stream-unit output, single-instruction RISC-V-to-ELF witness,
and the AArch64 ELF64 witness are integrated and preserve source identity
through their encoding fixtures. ISA ingestion, semantics, encoders, decoders,
ABI metadata and object writing do not wait for the frontend.
Legalization and instruction selection do wait for `mir-v0`. RISC-V and
AArch64 remain the first correctness targets. x86-64 is a concurrent
source-quality comparison, not a prerequisite for them.

The current target codec slices are `fortback-new` commit
`02837b1387315929545b6d33bc03e38a6bfc90e8`; it adds generic bounded variable
bit-range metadata to the AArch64 source records, preserving fixed mask/match
fields and rejecting malformed, overlapping and out-of-range fields. The same
history retains the generic AArch64 fixed-record validator/matcher from
`600457fb60eb74ee99cd2d647c6382bcf21f1afe` and the source-record-driven RV64I
I-format encoder/decoder from `c48922d5dd9ebc9b0524a1f6eb14c3697c5e7327`
over the existing `XORI`, shift-shaped
and `JALR`-shaped records, with independent canonical, malformed metadata,
unsupported-format, invalid-operand, wrong-target and provenance controls.
The AArch64 zero-operand NOP and
source-preserving RISC-V `SLTI` slices and earlier RV64 shift and
AArch64 `adr`/`adrp` slices remain in its history.
D0072 now makes these instruction cases bootstrap witnesses rather than the
backend's scaling mechanism. Further instruction coverage waits for the
generic source-record to TargetIR normalization and generated codec path;
adding another mnemonic branch alone is not an accepted backend slice.
The generic I-format helper, AArch64 fixed-record matcher and variable-range
metadata are the first three steps across that boundary; none adds a mnemonic
enum, importer whitelist entry or instruction-kind dispatch branch.

## Provenance and exit

Every TargetIR fact retains artifact identity, source object, source hash and
origin class. Normative, derived, comparison and differential sources remain
distinguishable. The first useful backend gate is a real object emitted from a
small fixed machine witness and checked against an independent encoder or
execution oracle. No ISA payload is committed to the production repository.
