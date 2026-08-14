# Middle-end lane

Owner: `ffc-new`. Input: `frontend-v0`. Output: `mir-v0` for `fortback-new`.
The middle end is target-independent and must not import ISA or ABI details.

## Dependency order

- define the minimum typed value, instruction, block and function boundary.
- implement lowering from the frontend result into that boundary.
- add optimization and analysis passes that preserve the same contract.
- provide a stable MIR importer/exporter for differential backend tests.

The program-declaration and program-unit SX bridges into the existing MIR
witness are integrated and reuse the program-root boundary; they do not
redefine `mir-v0`.

The first target-independent function boundary, witness-bounded canonical MIR
SX handoff, canonical frontend-v0 SX-to-MIR lowering, explicit program-root
lowering, and canonical program-root-SX bridge are integrated and remain
additive. The bounded frontend result lowers into that boundary. A backend
worker may consume a pinned MIR fixture before the full middle end exists, but
it must not redefine MIR in the backend repository. Target-specific
legalization begins only after the MIR contract revision is integrated.

The current additive boundary guard is in `ffc-new` commit
`471dade524580543b14b8f25f424643ad29bcff3`; its behavioral test rejects
whitespace- or delimiter-containing SX atoms at the typed MIR boundary.

## Exit and handoff

Every emitted operation carries source-rule identity where available. The lane
must provide independent semantic checks for transformations and a small fixed
MIR witness for backend development. Performance choices are benchmarked after
correctness and do not alter the contract's meaning.
