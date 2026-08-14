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
| 2026-08-12 | `kaby76/fortran` | MIT | `comp/Fortran2023Parser.g4` at the pinned commit | E0020 structural grammar comparison adapter |
| 2026-08-12 | `llvm/llvm-project` | Apache-2.0 WITH LLVM-exception | Flang `lib/Parser/Fortran-parsers.cpp` rule comments at the pinned commit | E0020 StandardIR rule-ID comparison; no implementation is imported |
| 2026-08-12 | `lfortran/lfortran` | BSD-3-Clause | `src/lfortran/parser/parser.yy` at the pinned commit | E0020 structural Bison-rule comparison adapter |
| 2026-08-13 | `riscv/riscv-opcodes` | BSD-3-Clause | Pinned machine-readable opcode tables at `6bf30f5d` | RISC-V TargetIR encoding and decoding source manifest |
| 2026-08-13 | `riscv/sail-riscv` | BSD-2-Clause | Pinned Sail RISC-V model at `aec19f42` | RISC-V executable semantics and differential oracle manifest |
| 2026-08-13 | `rems-project/sail` | BSD-2-Clause with stated exceptions | Pinned Sail tooling and language source at `23f85b1b` | RISC-V formal-model build source manifest |
| 2026-08-13 | `riscv/riscv-isa-manual` | CC-BY-4.0 | Pinned ISA manual source at `846efd1c` | RISC-V encoding/version classification manifest |
| 2026-08-13 | `riscv-non-isa/riscv-elf-psabi-doc` | CC-BY-4.0 | Pinned ELF psABI source at `76b837ec` | RISC-V ABI and object-writer source manifest |
| 2026-08-13 | `AARCHMRS` mirror | Arm package terms | Pinned A-profile machine-readable package at `47b5446` | AArch64 instruction, register and feature source manifest |
| 2026-08-13 | `ARM-software/abi-aa` | CC-BY-SA-4.0 with Arm ABI patent licence | Pinned ABI source at `ee4b3c12` | AArch64 ABI and object-writer source manifest |
| 2026-08-13 | `intelxed/xed` | Apache-2.0 | Pinned XED source at `519c843c` | x86-64 encoding comparison source manifest |
| 2026-08-13 | `zyantific/zydis` | MIT | Pinned Zydis source at `a95bb710` | Independent x86-64 encoding comparison source manifest |
| 2026-08-13 | `x86-psABIs/x86-64-ABI` | No explicit licence declaration found | Pinned System V x86-64 psABI archive | x86-64 ABI source manifest |
| 2026-08-13 | Intel SDM | Intel proprietary documentation | Combined Intel 64 and IA-32 SDM, version 092, retrieved from Intel | x86-64 vendor specification manifest |
| 2026-08-14 | `ggml-org/llama.cpp` | MIT | Official function-calling and server API documentation, including named `tool_choice`, bounded `max_tokens`, `chat_template_kwargs`, and timing fields | E0116 local Qwen semantic runner protocol |

---

## Artifact pins

Every external artifact has a manifest under `artifacts/` recording URL,
SHA-256, byte size, licence, retrieval date and purpose. `scripts/fetch.sh`
verifies. No payload is committed.

| Artifact | Manifest | Status |
|---|---|---|
| J3/24-007, Fortran 2023 working draft | `artifacts/standards/j3-24-007.toml` | pinned, verified 2026-08-11 |

The current ISA/ABI manifest inventory is generated by `scripts/index.sh` and
verified or fetched with `scripts/fetch.sh --list`, `scripts/fetch.sh
--verify <name>` or `scripts/fetch.sh <name>`. It includes the AARCHMRS
features, instructions and registers; Arm ABI; Intel SDM and XED; RISC-V
ELF psABI, ISA manual, opcodes and Sail sources; and the x86-64 ABI and Zydis.
The payloads remain outside git under the ignored cache. This table is not a
second pin list: `artifacts/isa/*.toml` is authoritative.

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
