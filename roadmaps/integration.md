# Integration lane

Owner: the central laboratory coordinator. This lane does not own compiler
code. It owns contract revisions, dependency-ready waves, production commit
pins, experiment/run records and cleanup.

## Wave protocol

1. inspect the target checkout and worktree. Require a clean exact base.
2. assign one vertical slice with explicit paths, contract revisions and gates.
3. run independent slices concurrently only when repositories and file scopes
   do not overlap.
4. while agents work, execute the coordinator's independent laboratory slice
   immediately; do not wait idle for reports or poll detached processes.
5. verify each report, diff, oracle and production gate.
6. merge verified slices promptly into the target main integration line.
7. append the run record, update the lane and central roadmap, then remove the
   local worktree/branch and any published remote task branch.

The coordinator never calls an unverified commit integrated. A failed or
abandoned slice remains in the run ledger with its last commit and failure
state before cleanup. A later slice starts from the newly integrated commit,
not from a stale long-lived task branch.

Wave H is complete for three bounded slices: frontend typed-program-unit SX,
program-declaration-SX-to-MIR lowering, and the RISC-V instruction-to-ELF
witness. E0102 is recorded separately as the first strict Luna semantic
escalation. Wave I is complete for warning cleanup in StandardIR, the
frontend, and the backend, plus the E0103 deterministic relation audit. The
Wave J is complete for the frontend semantic-table consumer, the program-unit
structural bridge, and E0104's bounded multi-line search. E0104 produced no
unique resolutions, so the coordinator pauses at the documented semantic
escalation gate. D0046 now authorizes one bounded document-structure
extraction slice; no new wave should add unjustified document-specific
heuristics or promote semantic facts before its measurement.

Wave K integrated the frontend diagnostic SX, AArch64 ELF64, and bounded
StandardIR structure-index slices. E0106 measured the latter against the
E0100/E0104 residue and found candidate evidence for 126 of 127 rows without
semantic promotion. The next M3 gate is a stricter laboratory-only definition
measurement. Production work may proceed concurrently only in disjoint
backend codec/decoder and contract-first middle-end scopes.

Wave L integrated the AArch64 ADD/SUB decoder and frontend StandardIR
syntax-item SX slices. The coordinator completed E0106 concurrently. Their
exact commits and gates are recorded in the run ledger; all task worktrees and
branches were removed after merge.

Wave X has integrated the indexed frontend program-declaration query and the
source-backed RV64 SRLI codec. Both passed coordinator-side full `fo` gates;
their task branches were deleted and their production mains are clean and
pushed. The MIR instruction result-type query also passed its coordinator-side
full `fo` gate and was merged and pushed. These additive boundaries do not
redefine a contract, promote semantic facts, or close M3.

Wave Y has integrated the indexed frontend program-declaration-count query.
It passed the coordinator-side full `fo` gate and its task branch was deleted
after push. The source-backed RV64 SRAI slice also passed the full `fo` gate,
was merged and pushed, and its task branch was deleted. The M4 generation
experiment E0119 is reported separately as `R000192` for its first AST/wiring
slice. These boundaries do not redefine a contract, promote semantic facts,
or close M3/M4.

Wave Z has integrated the source-preserving `frontend-ast-v0` SX handoff into
`ffc-new`. It passed coordinator-side full `fo`, retained source spans and
hashes, and its task branch was deleted after push. Wave AA subsequently
integrated the deterministic generator consuming that handoff; neither wave
redefines `mir-v0`, promotes semantic facts, or closes M3/M4.

Wave AA has integrated the deterministic `frontend-ast-v0` generator and its
checked-in generated Fortran records in `fortfront-new`. The generator,
canonical SX witness, malformed/unsupported schema controls, negative
provenance/span/count cases and full `fo` gate passed; the task branch was
deleted after push. E0119 is reported accepted as `R000192` for this first
AST/wiring slice; complete M4 still requires the lexer, parser, semantic and
lowering gates.

The next production backend slice is integrated at `fortback-new`
`dcbae9882850efbe246b8faf22394306589ce530`: a source-backed RV64I `SLTIU`
codec with canonical encoding, malformed/unsupported/wrong-target controls,
and preserved source provenance. Coordinator-side full `fo` passed, the task
branch was removed, and no MIR or AArch64 files changed.

The following backend slice is integrated at `fortback-new`
`205fe1c2cf994274b87f676f07c57fddb911da23`: a source-backed RV64I `XORI`
codec with canonical encoding/decoding, malformed/unsupported/invalid-operand/
wrong-target controls, and preserved source provenance. Coordinator-side full
`fo` passed; the task branch was removed and no MIR or AArch64 files changed.

The first post-D0072 backend slice is integrated at `fortback-new`
`c48922d5dd9ebc9b0524a1f6eb14c3697c5e7327`: a generic source-record-driven
RV64I I-format encoder/decoder. It adds no mnemonic dispatch branch and checks
XORI, shift-shaped and JALR-shaped records through independent metadata,
operand, target and provenance controls. Coordinator-side full `fo` passed,
the task branch was removed, and no MIR or AArch64 files changed.

The second post-D0072 backend slice is integrated at `fortback-new`
`600457fb60eb74ee99cd2d647c6382bcf21f1afe`: a generic AArch64 fixed-record
validator/matcher over imported ADD, SUB and NOP records. It checks mask/match
selection, name independence, malformed metadata, unsupported words, target
identity and source provenance. Coordinator-side full `fo` passed, the task
branch was removed, and no mnemonic dispatch, ABI or MIR behavior changed.

The parallel middle-end slice is integrated at `ffc-new`
`1d356b42dd7821cfebea9fec78291a2c37e456e8`: a generic instruction result-ID
query reusing the validated MIR accessor, with independent valid, malformed,
index-boundary, output-clearing and diagnostic controls. Coordinator-side full
`fo` passed, the task branch was removed, and `mir-v0`, frontend lowering and
backend-specific details were unchanged.

The third post-D0072 backend slice is integrated at `fortback-new`
`02837b1387315929545b6d33bc03e38a6bfc90e8`: AARCHMRS variable bit ranges are
now retained as bounded generic source-record metadata, with fixed fields
preserved and malformed, overlapping and out-of-range controls. Coordinator-
side full `fo` passed, the task branch was removed, and no mnemonic dispatch,
encoder/decoder, ABI or MIR behavior changed.

The parallel frontend slice is integrated at `fortfront-new`
`7bb9eae735c21f94bb123c3c6c4048f29b6bcb7e`: a bounded
program/module/subroutine/function
source-witness parser with exact terminator/name matching, span checks and
rejection controls. Coordinator-side full `fo` passed, the task branch was
removed, and no frontend-ast-v0 or mir-v0 contract changed.

The next parallel wave is integrated at `fortfront-new`
`bd6436e532aa75e664b4967c4d95b810fc9ab59b` and `fortback-new`
`19bd36aa272115dd8f2029a89fb17761b291c649`. The frontend slice adds
schema-generated AST preorder traversal with optional callbacks; the backend
slice adds generic ordinal extraction of retained AARCHMRS variable ranges.
Both passed coordinator-side full `fo` with zero warnings and their local and
remote task branches were removed. Neither changes parser semantics,
instruction dispatch, ABI behavior or MIR.

The backend continuation is integrated at `fortback-new`
`70e3e39e32258df01034ad85eedb40f57da4596d`: generic ordinal field insertion
now complements extraction and preserves fixed bits while validating source
metadata. Coordinator-side full `fo` passed with zero warnings; the task
branch was removed and no separate task worktree existed. No instruction
dispatch, ABI or MIR behavior changed. The parallel frontend AST-query task
is integrated at `fortfront-new`
`f931acfd99640eeda95a89b8dd56df89581ad97e`: the schema-generated kind-count
query covers nested records, empty input and invalid query types. Its
coordinator-side full `fo` passed with zero warnings, the task branch was
removed and no separate task worktree existed. No parser, lowering or
`mir-v0` behavior changed.

The parallel middle-end continuation is integrated at `ffc-new`
`555eb09bfb17329517176f967a3d1fda36c3159e`: a target-independent opcode-count
analysis over validated MIR bodies covers all ten `mir-v0` opcodes, repeated
instructions, malformed bodies, invalid opcode values and output clearing.
Coordinator-side full `fo` passed with zero warnings; the task branch was
removed and no separate task worktree existed. No contract, frontend lowering,
ISA or ABI details changed.

The StandardIR lexical continuation is integrated at `standard-new`
`985d684a2c8e5f4394b3473c8bdc3a9de7453ab9`: generic source-backed scalar
lookup returns the matching target/class/provenance and reports processor-
defined, invalid, duplicate and overlapping cases explicitly. Text-policy and
coordinator-side full `fo` passed with zero warnings; the task branch was
removed and no separate task worktree existed. No frontend token wiring was
added.

The backend codec continuation is integrated at `fortback-new`
`9baabf418280812b43181330b67d10d4078e88ae`: generic whole-record encode and
decode compose the source-record matcher with ordinal field operations,
preserving fixed bits and clearing outputs on failure. Coordinator-side full
`fo` passed with zero warnings; the task branch was removed and no separate
task worktree existed. No mnemonic dispatch, ABI or MIR behavior changed.

The frontend lexical continuation is integrated at `fortfront-new`
`c704f047fadc64b771279111becff78ed2c835f3`: a caller-supplied,
source-provenance-validated scalar classifier reports match, no-match,
ambiguity, processor-defined and invalid-input states. Coordinator-side full
`fo` passed with zero warnings; the task branch was removed and no separate
task worktree existed. No keyword dispatch, grammar, parser or `mir-v0`
behavior changed.

The next lexical/codec continuation is integrated in parallel at
`fortback-new` `3a1b38e84af54f70ff6baaff231d84deed31a353` and `fortfront-new`
`2bb1bdd1fe0f75164b8de4bfd1c1c6db9d710cca`. The backend composes the source-record RISC-V I-format matcher with
a generic operand-array whole-record codec. The frontend iterates UTF-8
scalars by byte span and classifies source spans through caller-supplied
lexical facts, with distinct no-match, unsupported, ambiguous and invalid-fact
statuses. Both passed coordinator-side full `fo` with zero warnings and their
output-clearing controls; no task branches or separate task worktrees remain.
These are recorded as `R000218` and `R000219`. Neither changes grammar/parser
dispatch, ABI, MIR or instruction selection.

The backend normalization continuation is integrated at `fortback-new`
`8c4c71e33beb94a4891e3cffe17c29c54b716709`: existing RISC-V I-format and
AArch64 source records normalize into one provenance-bearing generic encoding
record with fixed bits and variable fields. Coordinator-side full `fo` passed
with zero warnings and explicit malformed, unsupported, wrong-target and
output-clearing controls; it is recorded as `R000220`. The parallel frontend
scanner is now integrated at `fortfront-new`
`e98bc27d1ad275001df5c040931213b0da34c4c7`: it coalesces maximal same-fact
UTF-8 spans and retains provenance while reporting unmatched, unsupported,
ambiguous, malformed and capacity states explicitly. Full `fo` passed with
zero warnings and it is recorded as `R000221`. Together these slices add no
grammar/parser dispatch, ABI, MIR or instruction selection.

Wave AM is integrated in parallel at `fortfront-new`
`f75e7091798eed10e2aef2ab60dae2ba3698b6ce` and `fortback-new`
`5a44f9c5906068433bf616c1687dc2f486fa5abc`. The frontend now stores and
queries caller-supplied source-provenanced grammar rules by LHS in insertion
order. The backend now encodes and decodes normalized TargetIR records without
ISA source-module imports. Both passed coordinator-side full `fo` with zero
warnings and explicit malformed, capacity, provenance, fixed-bit, field-range,
unsupported-word and output-clearing controls; they are recorded as `R000222`
and `R000223`. No Fortran parser dispatch, ABI, MIR or instruction selection
was added.

Wave AN is integrated in parallel at `fortfront-new`
`b657fad20cccb2a2166c11d1faf48d8b0d69314f` and `fortback-new`
`e72467d97fbd8978d29c8cc69719e343a687a992`. The frontend now performs
deterministic ordered RHS matching over caller-supplied grammar symbols while
preserving rule provenance. The backend now looks up matching normalized
TargetIR records in insertion order and reports ambiguity, no-match,
malformed, unsupported-word, invalid-target and capacity states. Both passed
coordinator-side full `fo` with zero warnings and are recorded as `R000224`
and `R000225`. No parser state/backtracking, ISA dispatch, ABI, MIR or
instruction selection was added.

Wave AO is integrated in parallel at `fortfront-new`
`199c383ede97fe78f91a738d16c28e946c15f072` and `fortback-new`
`b533414aae80052308434fc725500cf2d028a1ac`. The frontend composes LHS
lookup and exact RHS matching into deterministic unique/ambiguous candidate
collection with preserved identity and provenance. The backend composes
candidate lookup and generic record decode for exactly one matching record,
leaving ambiguity explicit. Both passed coordinator-side full `fo` with zero
warnings and are recorded as `R000226` and `R000227`. No parser state,
backtracking, ISA dispatch, ABI, MIR or instruction selection was added.

The StandardIR half of D0076 is now integrated at `standard-new`
`071acf5cc23200441b28309b50a6c8ccd5922e0e` and recorded as `R000229`. The
typed producer validates and canonically reads/writes all six normalized node
kinds, nested optional/repeat/choice/group structure, alternative order and
source provenance. It does not apply the contract to PDF text, invent aliases
or choose parser dispatch. The producer-to-consumer pipeline remains the next
frontend handoff gate.

The parallel backend serialization slice is integrated at `fortback-new`
`c68bf54844fbdbb79f012c5e5e977dacc6301ce2` and recorded as `R000230`. It
round-trips normalized TargetIR encoding records through a private generic SX
boundary, retaining target/operation identity, fixed and ordered variable
fields and both provenance records. It passed coordinator-side full `fo` with
zero warnings and malformed, range, overlap/order, unsupported-version,
capacity and output-clearing controls. D0077 keeps this internal until a
second production consumer requires a versioned cross-repository contract.

The parallel middle-end slice is integrated at `ffc-new`
`31a2b5df3d5de3486b5614a041d272e1daa6b3b1` and recorded as `R000231`. It
exposes a validated target-independent instruction-count query with
independent valid, malformed, index-boundary, output-clearing and diagnostic
controls. It does not change `mir-v0`, opcodes, lowering, backend, ISA or ABI
behavior.

The current bounded production pins are `standard-new`
`071acf5cc23200441b28309b50a6c8ccd5922e0e`, `fortfront-new`
`49dd337728df9bbcc451042ed11a26842f92341b`, `ffc-new`
`31a2b5df3d5de3486b5614a041d272e1daa6b3b1`, and `fortback-new`
`c68bf54844fbdbb79f012c5e5e977dacc6301ce2`, all on clean `main` branches
tracking `origin/main`. Verify any pin with `git -C ../<repo> cat-file -t`
and the branch state with `git -C ../<repo> status --short --branch`.
Use the full commit argument for an immutable pin when checking a recorded
result.

The cleanup sequence is explicit:

```sh
git worktree remove /path/to/task-worktree
git branch -d task-branch
git ls-remote --exit-code --heads origin task-branch
git push origin --delete task-branch
git fetch origin --prune
```

Run the remote deletion only when the preceding lookup finds the branch. An
absent remote branch is already clean. A dirty worktree, an unmerged branch or
a network/authentication error stops cleanup for review.

## Cross-lane gates

- StandardIR output is source-backed before frontend acceptance claims.
- frontend output satisfies `frontend-v0` before middle-end lowering claims.
- MIR is stable before backend legalization or instruction-selection claims.
- TargetIR source classes and emission records are present before machine-code
  performance claims.
- every cross-repository result names the contract revisions and exact commits
  used to produce it.
