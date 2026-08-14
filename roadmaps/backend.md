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
`c68bf54844fbdbb79f012c5e5e977dacc6301ce2`; it adds a generic whole-record
encode/decode composition over ordinal insertion and extraction, preserving
fixed mask/match fields and rejecting malformed, overlapping and out-of-range
fields. The RISC-V continuation now exposes the same source-record boundary
through a generic operand-array whole-record codec with explicit failure
clearing. The new normalized TargetIR encoding boundary adapts both existing
RISC-V I-format and AArch64 source records into one provenance-bearing record
shape with fixed bits and variable fields.
The generic codec over that normalized record is integrated at
`fortback-new` commit `5a44f9c5906068433bf616c1687dc2f486fa5abc`: it performs
source-family-independent encode/decode with fixed-bit matching, ordered
variable fields and explicit failure clearing. Candidate lookup over the same
normalized record shape is integrated at `fortback-new` commit
`e72467d97fbd8978d29c8cc69719e343a687a992`: it validates caller-supplied
records, returns deterministic insertion-order indices, and reports
no-match, ambiguity, malformed, unsupported-word, invalid-target and capacity
states with cleared outputs. Unique decode through that lookup and the generic
record codec is integrated at `fortback-new` commit
`b533414aae80052308434fc725500cf2d028a1ac`: it returns decoded ordered field
values only for one candidate and keeps ambiguity explicit. The normalized
record now also has a private canonical SX serializer/reader at `fortback-new`
commit `c68bf54844fbdbb79f012c5e5e977dacc6301ce2`, recorded as `R000230`. It
retains target and operation identity, fixed bits, ordered variable fields and
source provenance, with malformed, range, capacity and output-clearing
controls. By D0077 this is not yet a central cross-repository TargetIR
contract. The preceding
AArch64 codec
commit is
`9baabf418280812b43181330b67d10d4078e88ae`; the insertion
commit is `70e3e39e32258df01034ad85eedb40f57da4596d`; the extraction
commit is `19bd36aa272115dd8f2029a89fb17761b291c649`; the metadata commit is
`02837b1387315929545b6d33bc03e38a6bfc90e8`. The same
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
The generic I-format helper, AArch64 fixed-record matcher, variable-range
metadata, ordinal extractor, ordinal inserter and whole-record codec are the
first steps across that boundary; none adds a mnemonic enum, importer whitelist
entry or instruction-kind dispatch branch.

## Provenance and exit

Every TargetIR fact retains artifact identity, source object, source hash and
origin class. Normative, derived, comparison and differential sources remain
distinguishable. The first useful backend gate is a real object emitted from a
small fixed machine witness and checked against an independent encoder or
execution oracle. No ISA payload is committed to the production repository.

E0127 is accepted as `R000235` at `fortback-new` commit
`fbeedd4c8c232116bdf6e9389f6a698ba7f787b0`. It adds a bounded table for
normalized TargetIR encoding records from both existing source families,
preserving order and provenance while reusing the generic validator and
codec. It adds no mnemonic dispatch, ISA-specific branches, ABI/MIR wiring or
new shared contract; the independent mixed-family table oracle and
warning-free full `fo` gate passed.

E0131 is accepted as `R000239` at `fortback-new` commit
`576c7a4b55aa772e0723b274333dcf411f35071d`. It batches existing RISC-V and
AArch64 source records into the generic normalized TargetIR table while
preserving order, provenance and transactional failure. It remains bounded to
the existing RISC-V I-format and AArch64 record families and table capacity.
It adds no mnemonic dispatch, importer whitelists, ISA-specific codec
branches, ABI/MIR wiring, serialization or a new contract; the independent
mixed-source oracle and warning-free full `fo` gate passed.
