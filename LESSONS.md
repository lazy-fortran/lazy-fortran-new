# Lessons from the existing Lazy Fortran toolchain

This document is the empirical case for the architecture in `WHITEPAPER.md`.
Every claim cites commits or files in repositories that exist on disk. Where the
evidence cuts the other way, that is recorded too. Several of the problems this
program proposes to solve are already partly solved in the old repositories, and
those solutions should be imported rather than reinvented.

The repositories examined are `standard`, `fortfront`, `ffc`, `fluff`, `fortad`,
`lfortran` and `liric`, all under `~/code/lazy-fortran/`. Hashes were verified
with `git -C <repo> cat-file -t <hash>` at the time of writing. Counts were
produced by the commands given beside them. Rerun the command rather than trust
the number.

This document has two jobs, and the second is easy to forget. It records what to
do differently: the new repositories inherit no API contract, module boundary
or implementation shape from the old ones. It also records what to take
unchanged, which is the table at the end. A lessons document that only lists
failures produces a project that reinvents the working parts.

A note on how to read this. None of these repositories was carelessly built.
The failure modes below are what competent, sustained work produces when the
architecture requires information to be transcribed by hand from one place to
another. That is the point. The argument is not that the work was bad, but that it should not have been
necessary.

---

## 1. A transcribed specification becomes a software project of its own

**Claim.** Maintaining a machine-readable grammar by hand, separately from the
document it describes, generates a permanent stream of defects whose only cause
is the separation.

**Evidence.** In `lazy-fortran/standard`:

- Tokens defined in a lexer and never connected to any parser rule, found and
  removed one at a time: `eecd178` (C interoperability intrinsics, "previously
  defined as lexer tokens but never wired to the parser grammar", +109 lines to
  `Fortran2018Parser.g4`), `58ba27d` (five tokens appearing "0 times" in the
  parser), `4b7b480`, `f1d58e7`, `08f0f3c`, `ea54165`, `78e0a76`, `de54c3d`,
  `90dc1bd`, `f4bfb63`.
- Parser rules never referenced by any other rule: `a3b54a6` and `e90102e`
  remove four each from `Fortran2023Parser.g4`. They landed about an hour apart
  on the same file. The first audit did not find what the second one did.
- Features attributed to the wrong language revision: `4bc225a` moves `BLOCK`
  from Fortran 2003 to Fortran 2008; `eae8fc0` removes type-declaration tokens
  from FORTRAN 1957, where types were determined by naming convention, and
  records that the removal cascaded down the inheritance chain so that `COLON`
  had to be restored to `Fortran90Lexer.g4`.
- Inheritance overrides silently dropping inherited coverage: `f8a62df`
  (F90 duplicating and shadowing F77 rules), and `eecd178`, where an F2008
  override of `identifier_or_keyword` removed tokens the F2003 version provided.
- Semantics that the grammar could not express, implemented elsewhere: `tools/`
  holds 24 Python validators, about 11,100 lines, imported only by tests, never
  by a grammar or a driver. Alongside them runs a documentation-only track where
  restrictions were written down and not checked at all (`d988931`, `98ff011`,
  `55b9f0b`).
- Documentation duplicating information available elsewhere and then rotting:
  `19a3537` deletes twelve audit files totalling roughly 7,000 lines, with the
  message "Documentation now reflects reality instead of bureaucratic process
  requirements". `4a09a03` deletes another 985 lines. The deleted audit files
  were being edited by the very fix commits above, right up to the deletion.

**Counter-evidence.** This is an audit working, not an audit absent. The dead
tokens and unreachable rules were found systematically over four days in
December 2025, each fix citing a specific ISO rule number. The repository
already cross-validates against the kaby76 reference grammars and against the
standard's own text (`make test-cross-validation`, `make ocr-standards`,
`validation/tools/`), carries 1,205 R-number citations across its grammars, and
its expected-failure registry `tests/xpass_fixtures.py` is empty rather than
quietly growing. The suite is 1,400 test functions over 561 fixtures. In one
case the grammar was right and the fixtures were wrong (`3ce7ea2`: F90 fixtures
using F95 and F2003 syntax), which is the more uncomfortable finding: the test
corpus was not itself validated against a revision.

**Requirement.** The grammar is generated from the pinned normative document.
A token that no rule references cannot exist, because there is no hand to write
one. Rule-to-revision attribution comes from the document, not from a
maintainer's memory. Semantic restrictions live in the same representation as
the syntax, so "the grammar cannot express it" stops being a reason to write a
separate validator that nothing calls.

---

## 2. Semantic knowledge gets reconstructed by every consumer

**Claim.** When a frontend does not expose resolved semantic facts, every
downstream tool rebuilds them, and the frontend's query surface then grows by
accretion in whatever shape the consumers asked for.

**Evidence.** In `fortfront`, `src/frontend/frontend_compiler_queries.f90` is
9,960 lines with 95 public exports, touched by 65 commits;
`frontend_compiler_select_type_queries.f90` is a further 4,477 lines. Roughly 85
commits have "expose" in the subject, 49 of them in ten days of August 2026,
each adding one query plus a test. The facts added are exactly the ones a
compiler cannot proceed without: generic and type-bound resolution (`93fb7dc1`,
`64cb4e8e`), formal procedure interfaces (`8da49474`), SELECT TYPE and SELECT
RANK arm facts (`78d3badb`, `57367e12`, `c48c3e8b`), ownership and lifetime
(`06f6d678`, `488c49e1`, `bf335f50`), allocation source and mold (`840ef4a6`),
callback signatures (`9b337845`, `1b19fcd0`), procedure-pointer targets
(`77008167`), dispatch provenance (`86eb2ba8`, `4420e3d0`).

The consumers are named in the commit messages: `ffc` 35 times, `fluff` 27,
`fortrun` 19. One commit is `809aa921 feat: expose call boundary facts for AD`.
Another, `18fbccee`, re-adds symbol-table queries explicitly "to enable fluff to
implement F006 unused variables, F007 undefined variables, F009 intent
analysis".

The downstream side is documented even more plainly. `fortad/ROADMAP.md:198-207`
states what it needs: "The upstream query contract must expose complete type
hierarchies, deferred and inherited bindings, generic and PASS resolution,
allocatable and pointer attributes, component paths, array bounds and section
properties, actual-to-formal mappings, procedure-pointer targets, and reads or
writes of global state." And at `:231-235`: "FortAD can then implement
allocation and polymorphism against facts rather than source-text heuristics."
Until those facts existed, it was on source-text heuristics;
`src/fortad_lower_statements.f90:3682` carries the comment naming the
anti-pattern directly.

**Counter-evidence.** In several cases the fact was delivered upstream rather
than faked downstream. `fortad`'s roadmap pins the specific `fortfront`
commits that supplied them. The system was converging on the right answer. It
converged by hand, one query at a time, over about a year.

**Requirement.** The semantic contract is part of the generated frontend,
derived from the same specification as the syntax, and complete by construction
rather than by request. No consumer should ever have to ask which procedure a
call refers to, what the actual rank is, which dynamic type a branch has
narrowed to, or who owns an allocation.

---

## 3. Rank, type and representation combinatorics defeat conventions

**Claim.** Specialization across rank and type is mechanical work whose volume
grows multiplicatively, and no coding standard survives contact with it.

**Evidence.** In `ffc`, 124 of 1,187 commits mention rank, accounting for 793
file-touches and about 13% of all insertions in the repository's history. The
shape is explicit ladders: `2483ff3` rank-three count, `c598f19` rank-four sum
and product, `f08a9f0` logical reductions through rank four, `de36ba8` through
`fd3b5e8` for the four assumed-rank SELECT RANK arms, `f0f4396` through
`080f8e2` for allocatable components rank one to four. The same ladder recurs
for runtime arrays, automatic arrays, broadcasts, sections and derived-type
storage.

The structural consequence is visible in the source layout.
`src/session_program_lowering.f90` is 7,176 lines against the repository's own
stated cap of 500 lines with a hard limit of 1,000. `src/` contains 51 `.inc`
fragments totalling 69,902 lines (58% of source by line count), while
`ffc/CLAUDE.md` says not to add production include fragments. There are 13
separate `session_program_lowering_reject_*.f90` modules, because the rejection
surface became combinatorial too.

**Counter-evidence.** `ffc` diagnosed this itself, about 600 commits in, and
started converging: the `[arraydesc-NN]`, `[chardesc-NN]` and `[poly-NN]` series
(`7ce03da`, `452455d`, `8f2c1a5`, `dfc37b1`, `0a7d649`) retrofit one canonical
descriptor, and `docs/SUPPORT_CONTRACT.md` names it as an explicit architectural
gate. The lesson is not that nobody saw it. It is that seeing it at commit 600
means paying for it twice.

Also worth stating: rank is not the whole story. The other 87% of the repository
is I/O formatting, module handling, character work and diagnostics, which have
their own combinatorics.

**Requirement.** Rank and type families are specification, and the
specializations are generated. Duplication in generated source costs disk;
duplication in maintained source costs the project.

---

## 4. Declaring the representation lattice is not enough

**Claim.** This is the lesson most easily got wrong, so it is stated carefully.
Making physical representations explicit in the IR is necessary and does not
suffice. The cost is not in naming the representations. It is in the hand-written
lowering that every consumer needs for every representation.

**Evidence.** `lfortran/src/libasr/ASR.asdl` already does the thing a naive
version of this lesson would recommend. Line 261 declares nine
`array_physical_type` values (`DescriptorArray`, `PointerArray`,
`UnboundedPointerArray`, `FixedSizeArray`, `StringArraySinglePointer`,
`NumPyArray`, `ISODescriptorArray`, `SIMDArray`, `AssumedRankArray`), line 262
declares two `string_physical_type` values, and lines 156 and 188 declare
explicit `ArrayPhysicalCast` and `StringPhysicalCast` nodes so that every
transition between representations is visible in the IR. This is a deliberate,
well-formed design.

It still produced 394 commits mentioning descriptors, 52 touching
`ArrayPhysicalCast`, 116 on assumed rank and 130 on BIND(C), over nine years,
including hard internal compiler errors: `f65df6e92` (ICE in `ArrayPhysicalCast`
for ENTRY with an array argument), `1516cebac` (procedure-pointer array argument
physical-type mismatch), `3d753b1a5` (descriptor out-of-bounds write in sequence
association), `094eb2f3e` (lost lower bound when forwarding assumed-shape
arrays), `797a61212` (typed pointer mismatch in a BIND(C) descriptor fixup).

The cost is legible in the commit shape. Adding one representation takes three
commits: `99f0a4427` introduces `UnboundedPointerToDataArray`, `0dcc629a7`
handles it in the frontend, `be726b63e` handles it at the backend. Every new
representation is a pass over every consumer.

**Requirement.** Physical representations are specified once and the lowering
between them is *generated*, not written. The measure of success is that adding
a representation is one specification change with no consumer edits: the exact
opposite of the three-commit shape above.

---

## 5. Text handling and accidental quadratic behaviour dominate real cost

**Claim.** Compiler internals that manipulate strings and copy arrays acquire
quadratic behaviour repeatedly, in the same places, for years.

**Evidence.** In `fortfront`, with the measurements the commits themselves
report: `553a1935` makes arena initialization lazy and takes simple programs
from 1.7 s to about 0.01 s, removing 379 million instructions at startup;
`b0e82abe` copies only used arena elements for a 27% instruction reduction,
found with callgrind; `20edbffb` finds token churn at 40-45% of instructions and
replaces deep string copies with interned handles, and replaces an O(n²)
declaration lookup with a hash table; `259ff03c` fixes quadratic array growth
that made files with many statement-IFs take "minutes" to parse.

Two commits show the pattern rather than the instance. `6e688073` introduces a
reusable string builder, fixes two hotspots, and states in its own message that
"219+ additional concatenation sites remain (lower priority)", and `96dc3314`
fixes the same defect class again seven months later. `aee215ca` is titled
"restore move_alloc performance optimizations": the optimizations had existed
before and been lost.

Character handling specifically: `7b25ccef` padding, `6979ec44` substring length
inference, `eb327721` substring out of bounds, `11cbab17` and `f5e1cdec` two
attempts at the same deferred-length issue, and `d03f21ce`, `ee5caf7b`,
`3f99a4cb`, the same nested-substring fix appearing three times.

**Requirement.** Internally the compiler holds one immutable source buffer,
integer offsets, interned identifiers and typed nodes. Text appears at the
boundaries. Benchmarking is part of synthesis rather than an activity that
happens after a profile becomes embarrassing, because a defect class that is
fixed twice was never fixed.

---

## 6. Tests are evidence, and evidence can be forged

**Claim.** A test suite reports what it was built to report. Green means the
suite did not object, which is a much weaker statement than it appears, and the
gap is not hypothetical.

**Evidence, tests that could not fail.** `fluff` `5d581c5` is the clearest
case in the house. Its own message: `fo lint` found 30 test programs that tally
their own assertions, print a summary and exit zero regardless; 21 of them, 9,246
lines, genuinely could not fail. Fourteen were deleted, 6,208 lines. Among the
five with no oracle to restore: one assigned `formatted_code = input_code` and
then scored its own input, two printed formatter output with no expectation, one
stated in a comment that it could not test the thing it was named for. Three
suites used `len(formatted_code) > 0` as the per-case verdict, which no output a
formatter can produce violates.

**Evidence, tests measuring nothing real.** `fortfront` `aef6d6c7` names its
own defect "PERFORMANCE MEASUREMENT FRAUD": a division by zero in `system_clock`
reporting infinite operations per second. `499a80e3` finds the performance
baseline stale, meaning the perf gate had been comparing against nothing.
`96941cc2` re-enables a test disabled with a comment claiming the semantic
pipeline types were unavailable. They were in fact re-exported, so the
placeholder body had always been reachable and the test had been green on a
false premise for months. `93e856ba` replaces shipped public API functions that
were silent no-ops or always returned true. As a static check on the current
tree, 25 of 756 test programs contain no failure path at all.

**Evidence, gates that do not gate.** `a9de7d46` states it directly: "#2910
made this gate blocking in CI, and a violation landed anyway three weeks later,
because PRs here are squash-merged with `--admin` without waiting for CI.
'Blocking in CI' therefore does not mean 'cannot reach main'."

**Evidence, silence as success.** `cdca8721` and `f3ab76ba` describe a defect
class where a scanner that computes a construct's extent wrongly does not reject
the program: it produces a shorter AST. "The program parses, compiles and runs,
and does less than its source says."

**Evidence, denominators.** `ffc`'s `scripts/conformance_check.sh:147` prints
`SKIP` and continues when a corpus is absent. Only all corpora missing is fatal.
`test/conformance/` holds 8,862 lines of xfail and skip manifests, and the
largest of them has moved up as often as down across 119 commits. In
`docs/PARITY_STATUS.md` the gfortran-dg suite reads 32.4%, computed as passes
over total-minus-skipped, where skipped is 39% of the suite. The strict rate is
19.8%.

**Counter-evidence, and it is substantial.**

- All 448 `ffc` test programs have a nonzero-exit path. The vacuous-test lesson
  belongs to `fluff`, not to `ffc`, and a naive scan for `error stop` gives a
  false signal because 367 tests route assertions through
  `src/ffc_test_support.f90` and then `stop 1`. `ffc`'s failing is denominators,
  not vacuity. Do not merge the two.
- `ffc`'s parity dashboard prints both the evaluated and the strict rate and
  labels the no-reference cases as such. That is deliberately honest
  instrumentation, added by `112eecd` and `b5e9511`.
- `fortfront` has a negative-control gate, `check-duplication-gate`, whose
  entire purpose is to prove the duplication gate can still fail; a committed
  785-entry accept/reject corpus baseline so no change can silently narrow the
  accepted language; and CI-verified documentation examples.
- `liric/ROADMAP.md:5-20` refuses to convert infrastructure failures into
  semantic passes: the red runs "are not evidence for or against the serializer
  defect and must not be reported as semantic passes."
- `fortad` has 104 of 104 failable tests, each bounded claim paired with an
  oracle checking finite differences *and* the adjoint identity, and explicit
  named refusals for everything outside the bound.

**Requirement.** Every gate has a negative control proving it can fail. Skipped
is reported separately from passed, and any headline rate states its
denominator. Expected-failure lists are dated and expire. Test corpora and
binaries are content-addressed so a stale artifact cannot be mistaken for a
current one. Mutation testing decides whether a suite distinguishes a correct
implementation from a nearly correct one.

---

## 7. Self-reported status rots, in both directions

**Claim.** Documentation of a repository's own health decays as fast as the
health does, and it decays optimistically and pessimistically alike, so it
cannot be trusted in either direction.

**Evidence.** `fluff/README.md:56` still says "28 of its 94 programs exit zero
no matter what they find". After `5d581c5` deleted fourteen programs and
repaired seven, the actual count is 11 of 87. The README understates its own
improvement. Meanwhile `fortfront/CLAUDE.md` stated the duplication gate
reported zero violations while `make check-duplication` was failing on main
(`a9de7d46`), and `fortfront/ROADMAP.md` reports 483 of 483 tests green against
756 test programs on disk. `liric/TODO.md` is dated February 2026 at an August
HEAD and still gives a path on a different machine. `fortfront` needed
`499a80e3` to update a stale performance baseline and `7c177ba5` to correct a
stale test-deduplication status. `ffc` needed `112eecd` and `abb2496` to fix
stale conformance dispositions and pass rates.

**Requirement.** A number in a document names the command that regenerates it,
or it is not written down. Status is generated from run records, not typed.

---

## Practices to import rather than reinvent

The following already exist and work, and the new repositories should adopt them
directly rather than rediscovering the need:

| Practice | Where it exists |
|---|---|
| Negative-control gate proving a gate can fail | `fortfront` `check-duplication-gate` |
| Committed accept/reject corpus baseline | `fortfront` `check-rejection-gate`, 785 entries |
| SHA-pinned corpora with a tested verifier | `ffc` `scripts/fetch_corpora.sh`, `test/test_fetch_corpora.sh` |
| Reporting evaluated and strict rates separately | `ffc` `docs/PARITY_STATUS.md` |
| Full provenance table pinning source, binary and oracle tree hashes | `ffc` `docs/PARITY_STATUS.md` |
| Refusing to report infrastructure failure as semantic success | `liric/ROADMAP.md` |
| Bounded capability claims with named refusals and dual oracles | `fortad/ROADMAP.md`, its test suite |
| Cross-validation against independent grammars and the standard text | `standard` `make test-cross-validation` |
| Issues carrying normative rule numbers instead of in-repo limitation docs | `standard/CLAUDE.md` |

---

## From lessons to architecture

| Lesson | Architectural consequence |
|---|---|
| 1. Transcription becomes a project | Document is the source; grammar and constraints are generated with provenance |
| 2. Semantics get reconstructed | The semantic contract is generated and complete, not extruded by consumers |
| 3. Combinatorics defeat conventions | Rank and type families are specifications; specializations are generated |
| 4. Declaring the lattice is not enough | Representation lowering is generated, so adding one costs no consumer edits |
| 5. Text and quadratic cost | Immutable buffers, offsets, interned IDs; benchmarking inside synthesis |
| 6. Tests can be forged | Negative controls, explicit denominators, mutation, differential oracles |
| 7. Status rots | Every reported number is generated from append-only run records |
