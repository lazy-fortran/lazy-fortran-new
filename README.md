# lazy-fortran-new

The laboratory for a specification-generated Fortran compiler.

The premise: a compiler is mostly the mechanical elaboration of information that
already exists in a language standard. If that is true, the standard should be
the maintained artifact and the compiler should be generated from it, with
deterministic generation wherever the specification determines the answer,
search and synthesis where it constrains without determining, and language
models only for the residue. Nothing generated is trusted until it is checked
against independent constraints, tests, differential oracles or formal
properties.

```
normative standard → StandardIR → generation or synthesis → ImplIR
  → verification and benchmarking → generated modern Fortran → generated compiler
```

This repository holds the architecture, the historical evidence, the
experiments, the runs, the decisions and the papers. It contains no compiler
code.

## Start here

- **`WHITEPAPER.md`**: the thesis and the method. Read this first.
- **`LESSONS.md`**: what the existing Lazy Fortran toolchain's history
  demonstrates, at commit level, including where it contradicts the argument.
- **`DESIGN.md`**: repository hierarchy, StandardIR, ImplIR, contracts.
- **`ROADMAP.md`**: phases, current position, what blocks what.
- **`RESEARCH.md`**: how experiments, runs and decisions are recorded.
- **`AGENTS.md`**: how to work in this repository. `CLAUDE.md` is a symlink to
  it.

## Repositories

| Repository | Role |
|---|---|
| `lazy-fortran-new` | This one. Laboratory: research, wiring, papers. |
| `standard-new` | Normative document to StandardIR and derived artifacts. |
| `fortfront-new` | Generated frontend: lexer, parser, AST, semantics, emitter. |
| `ffc-new` | Driver and middle end: MIR, optimization, command line. |
| `fortback-new` | Target description to generated backend. |

Existing repositories, `standard`, `fortfront`, `ffc`, `fortad`, `fluff`,
`lfortran`, `liric`, `gcc`, are oracles, corpora and historical evidence. They
constrain nothing here. The `-new` suffix is temporary and goes away at 1.0.

`repos.toml` lists all of them; `scripts/bootstrap.sh` clones what is missing and
`scripts/status.sh` reports where each checkout stands.

## Getting the sources

Nothing external is committed here. Standards documents, grammars, ISA
specifications and corpora are pinned by URL and SHA-256 in `artifacts/` and
fetched into a gitignored cache:

```sh
scripts/fetch.sh --list        # what is pinned, and whether it is cached
scripts/fetch.sh j3-24-007     # fetch and verify one artifact
scripts/fetch.sh --all
```

A hash mismatch is a hard failure. `git status` stays clean after a fetch.

## Current state

Phase 0 is complete and Phase 1 is in progress. `standard-new` now performs
layout-aware PDF extraction, canonical text projection, complete numbered syntax
extraction for the selected J3/24-007 span, canonical StandardIR SX emission,
dependency closure and deterministic EBNF, ANTLR4, Bison and tree-sitter
projections. The current extraction gate reports 522/522 numbered production
starts with zero model calls. The byte/span text layer, canonical SX reader and
writer, flat SX arena, schema parser and first deterministic Fortran schema type
emitter also exist. The accepted composite projection contains 519 generated
records from 522 source records and zero unresolved target names. E0056 makes
ANTLR4 and Bison generation succeed and records a tree-sitter conflict
boundary. D0029 selects the specialized direct parser as the production target.
Regenerate these figures with `papers/standard-to-grammar/analyse.sh` and
`research/index.md` with `scripts/index.sh`. The StandardIR schema and
composite parser input remain the next major Phase 1 boundaries.

## Licence

MIT for new Lazy Fortran software and specifications where legally applicable.
See `LICENSE`. External sources keep their own licences and are never vendored;
`docs/provenance.md` records what was consulted and under what terms.
