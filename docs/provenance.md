# Provenance

Two records live here. What external material has been consulted, and under what
terms it may be used. The rules are in `AGENTS.md`. This file is the log.

---

## The problem this solves

New Lazy Fortran work is MIT. The oracles are not. Downloading a source and
pinning its hash solves redistribution, nothing external is committed to this
repository. It does not solve contamination, which is about what an author read
while writing something. The two problems need separate handling and are often
confused.

There is a third thing this file is *not* for. It does not track what anyone
knows. The project's goal is to demonstrate that a specification-generated
compiler works, not to prove it was built in isolation, and any model used here
was trained on Fortran compilers regardless. See `WHITEPAPER.md` §4.1.

---

## Licence classes

| Class | Sources | Rule |
|---|---|---|
| **GPL** | gfortran, the GCC tree | **Behavioural comparison only.** Run the binary; compare accept and reject decisions, diagnostics, runtime output. Do not read the implementation source while authoring the corresponding component. Absolute, no research exception. |
| **Permissive** | LFortran (BSD), Flang (Apache-2.0), kaby76 grammars, Intel XED (Apache-2.0), Zydis (MIT), riscv-opcodes (BSD), Sail (BSD) | Source may be read. Log each instance below. |
| **House** | `standard`, `fortfront`, `ffc`, `fortad`, `fluff`, `liric` | Ours. Read freely. Nothing is inherited: not the APIs, the module boundaries, or the naming. Proven gates are imported deliberately, see `LESSONS.md`. |
| **Normative documents** | J3/24-007, J3/26-007, ISO/IEC 1539-1 | Read and formalize. Never redistribute. Pin by hash. |

One derivation rule cuts across all of these: **grammar productions are not
copied into StandardIR from any existing grammar.** They are derived from the
normative document. Existing grammars are comparisons that may themselves be
wrong. Reading them to understand the problem or to adjudicate a disagreement is
expected. Lifting a production is not.

---

## Consultation log

Append-only. One row per instance of reading a permissively licensed source
while authoring something here. Recording an entry costs nothing. Omitting one costs the record its value.

| Date | Source | Licence | What was read | What it informed |
|---|---|---|---|---|
| 2026-08-11 | `lazy-fortran/*` | house | Git history of `standard`, `fortfront`, `ffc`, `fluff`, `fortad`, `lfortran`, `liric` | `LESSONS.md` |
| 2026-08-11 | `lfortran` | BSD | `src/libasr/ASR.asdl` (physical type declarations) | `LESSONS.md` §4, `WHITEPAPER.md` §2.4 |
| 2026-08-11 | `liric` | house | `README.md`, `ROADMAP.md`, `TODO.md`, source inventory | `WHITEPAPER.md` §18, backend decision |

---

## Artifact pins

Every external artifact has a manifest under `artifacts/` recording URL,
SHA-256, byte size, licence, retrieval date and purpose. `scripts/fetch.sh`
verifies. No payload is committed.

| Artifact | Manifest | Status |
|---|---|---|
| J3/24-007, Fortran 2023 working draft | `artifacts/standards/j3-24-007.toml` | pinned, verified 2026-08-11 |

Additional pins are added as phases need them: J3/26-007, the kaby76 grammar
corpus, riscv-opcodes, the ARM Machine Readable Architecture, Intel XED,
gfortran.dg, the LFortran integration tests.

Note on gfortran.dg: the corpus is GPL-licensed test *inputs*. Running them
through our compiler and comparing behaviour is behavioural comparison and is
fine. It is not a licence to read gfortran's implementation, and the test
sources are not vendored.

---

## Origin labels

Distinct from this log, and recorded per artifact rather than per reading. Every
generated artifact carries exactly one of `MECHANICAL`, `SEARCH`, `SMT`, `LLM`,
`LLM_REPAIR`, `HUMAN`, `IMPORTED`, `DIFFERENTIAL`. `RESEARCH.md` defines them.

`IMPORTED` is the label that connects the two records: an imported artifact must
have a row in the consultation log above, or its provenance is incomplete and it
cannot be published about.
