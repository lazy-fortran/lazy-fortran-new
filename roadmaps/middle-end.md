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

The current additive MIR boundary is `ffc-new` commit
`31a2b5df3d5de3486b5614a041d272e1daa6b3b1`; its behavioral tests cover
whitespace- or delimiter-containing SX atoms and validated typed opcode
and result ID/kind/type queries at the instruction boundary, plus a typed
frontend handoff, function-block-count, block-instruction, and generated
frontend-AST handoff boundaries. It also exposes a target-independent opcode
count analysis over validated function bodies, with all ten `mir-v0` opcodes
and malformed/boundary controls covered.
It also exposes a validated instruction-count query with explicit malformed,
index-boundary, output-clearing and diagnostic controls. This remains an
additive consumer API; it does not change `mir-v0` or define target behavior.

E0128 is accepted as `R000237` at `ffc-new` commit
`7691adc1a7b96fef171f9fd0059c89401ad1c4f1`. It provides a complete
deterministic opcode histogram over a validated function body, including all
opcode bins and the total instruction count. It remains target-independent,
rejects malformed input with cleared output, and preserves `mir-v0`; the
independent oracle and warning-free full `fo` gate passed.

E0132 is accepted as `R000242` at `ffc-new` commit
`998ab62d180b4f2940e25d2f987f4f99317c5771`. It exercises the canonical
function-body SX importer/exporter over an independent witness matrix,
including typed results and source-linked instructions, and fixes failure
output clearing. Current `mir-v0` has one representable block, so the gate does
not claim multi-block support; it adds no target details or new contract.

## Exit and handoff

Every emitted operation carries source-rule identity where available. The lane
must provide independent semantic checks for transformations and a small fixed
MIR witness for backend development. Performance choices are benchmarked after
correctness and do not alter the contract's meaning.
