# Middle-end lane

Owner: `ffc-new`. Input: `frontend-v0`. Output: `mir-v0` for `fortback-new`.
The middle end is target-independent and must not import ISA or ABI details.

## Dependency order

- define the minimum typed value, instruction, block and function boundary.
- implement lowering from the frontend result into that boundary.
- add optimization and analysis passes that preserve the same contract.
- provide a stable MIR importer/exporter for differential backend tests.

The contract is central and additive. A backend worker may consume a pinned MIR
fixture before the full middle end exists, but it must not redefine MIR in the
backend repository. Target-specific legalization begins only after the MIR
contract revision is integrated.

## Exit and handoff

Every emitted operation carries source-rule identity where available. The lane
must provide independent semantic checks for transformations and a small fixed
MIR witness for backend development. Performance choices are benchmarked after
correctness and do not alter the contract's meaning.
