# lazy-fortran-new

Research repository for a Fortran compiler generated from the language
standard. It holds the architecture, experiment records, decisions and papers,
and wires together the component repositories. It contains no compiler code.

Status: research project; the generated toolchain covers only a small bounded
slice of Fortran.

## Idea

Much of a compiler is a mechanical elaboration of information that is already
in the language standard. The project therefore treats the standard as the
maintained artifact and generates the compiler from it: deterministic
generation where the specification determines the answer, search and synthesis
where it only constrains it, and language models only for the remaining local
tasks. Nothing generated is trusted until it has been checked against
independent constraints, tests, differential oracles or formal properties.

```text
normative standard -> StandardIR -> generation or synthesis -> ImplIR
  -> verification and benchmarking -> generated Fortran -> generated compiler
```

## Current state

The pinned components provide a bounded path from raw Fortran source through
StandardIR, a generated frontend AST, MIR and RISC-V ELF output, executed under
qemu. The accepted slice is a named main program with scalar integer
declarations, simple assignments and arithmetic, `STOP` and list-directed
`PRINT`. The current goal is to replace this bounded path with a generic
implementation that preserves its behaviour. See [ROADMAP.md](ROADMAP.md) and
[STATUS.md](STATUS.md).

## Repositories

| Repository | Role |
|---|---|
| `lazy-fortran-new` | This repository: research records, wiring, papers |
| `standard-new` | Standard document to StandardIR and derived grammars |
| `fortfront-new` | Generated frontend: lexer, parser, AST, semantics |
| `ffc-new` | Driver and middle end: MIR, optimisation, command line |
| `fortback-new` | Target description to generated backend |

The existing repositories (`standard`, `fortfront`, `ffc`, `fluff`, `lfortran`,
`liric`, `gcc` and others) serve only as oracles, corpora and historical
evidence. The `-new` suffix will be dropped at version 1.0.

[repos.toml](repos.toml) lists all repositories with pinned commits.
`scripts/bootstrap.sh` clones missing sibling checkouts and `scripts/status.sh`
reports their state.

## Getting the sources

No external material is committed. Standards documents, grammars, ISA
specifications and corpora are pinned by URL and SHA-256 in `artifacts/` and
fetched into an ignored cache:

```sh
scripts/fetch.sh --list        # list pinned artifacts and whether they are cached
scripts/fetch.sh j3-24-007     # fetch and verify one artifact
scripts/fetch.sh --all
```

A hash mismatch is an error.

## Checking the pipeline

With the component repositories checked out next to this one:

```sh
scripts/check_pins.sh
scripts/check-contracts.sh
bash tests/e2e/check-generated-chain.sh
```

## Documentation

- [WHITEPAPER.md](WHITEPAPER.md): thesis and method
- [LESSONS.md](LESSONS.md): what the history of the existing Lazy Fortran
  toolchain shows, including where it contradicts the thesis
- [DESIGN.md](DESIGN.md): repository hierarchy, StandardIR, ImplIR and contracts
- [ROADMAP.md](ROADMAP.md), [STATUS.md](STATUS.md),
  [MILESTONES.md](MILESTONES.md): plan and current state
- [RESEARCH.md](RESEARCH.md): how experiments and decisions are recorded
- [docs/glossary.md](docs/glossary.md): terms used across the project
- [docs/provenance.md](docs/provenance.md): external sources consulted and
  their terms

## Licence

MIT for new Lazy Fortran software and specifications where legally applicable;
see [LICENSE](LICENSE). External sources keep their own licences and are never
vendored.
