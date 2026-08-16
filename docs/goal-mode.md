# Central Goal Mode instructions

Advance the Lazy Fortran compiler program from this repository. This is the
sole Goal Mode control plane.

At the start of every cycle read `AGENTS.md`, `STATUS.md`, `MILESTONES.md`,
`repos.toml`, the active contracts, `docs/cross-repo-protocol.md`,
`docs/oracle-policy.md`, `docs/reproducibility.md`, `docs/vertical-slice.md`
and `research/decision-log.md`.

Work on one active central milestone and one unchecked checkbox. A change
counts only when the central clean end-to-end command moves that checkbox to
PASS with an independent oracle.

Do not count component-local success, a new contract, provenance or trace
fields, generated code compiling, an artifact hash, or architecture prose as
delivery progress unless the central fixture consumes it.

For cross-repository work, use only the components declared in `repos.toml`.
Pin every consumed revision, make code changes in the correct component,
commit there first, then update the central pin, trace, fixture evidence and
milestone state here.

If blocked after two materially different technical attempts, record the
minimized fixture and exact trace, then ask GPT-Sol only one bounded
compiler-design or specification question. Turn any proposal into an
independent end-to-end test before accepting it.

Commit only verified PASS results. Do not start a second fixture family until
the first reaches its declared final observable.
