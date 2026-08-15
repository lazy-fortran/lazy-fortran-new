# Literature

The prior art this project must be positioned against, and the sources it builds
on. Each entry states what it is used for here. Where a copy exists on disk, the
path is given.

This file is maintained from the first commit rather than assembled before
publication. An idea that turns out to have been published in 1996 is cheaper to
discover now.

**Verification status.** Entries marked ✓ have had their bibliographic details
checked against the publisher or author page. Unmarked entries are recorded from
knowledge and need a verification pass before any of them appears in a paper.
Nothing in this file is a substitute for reading the work.

**Zotero.** `~/Zotero/zotero.sqlite` is a plasma-physics library and contains
almost nothing relevant; the three exceptions are noted below. Check it before
adding anything anyway.

---

## 1. Grammar recovery from specifications, the direct prior art for E1

This is the closest existing work to the first phase of this project, and E1's
contribution has to be stated relative to it.

- ✓ **Lämmel, R. and Verhoef, C. "Semi-automatic grammar recovery."** *Software:
  Practice and Experience* 31(15), 1395-1438, 2001.
  <https://doi.org/10.1002/spe.423>. PDF at <https://www.cs.vu.nl/~x/ge/ge.pdf>.
  Extracts grammars from compilers and language reference manuals through raw
  extraction, static error resolution, test-driven correction, then
  modularization and beautification. **The method this project automates.** Our
  claim must be about what changes when the correction loop is mechanical and
  the provenance is preserved per rule, not about having had the idea.
- ✓ **Lämmel, R. and Verhoef, C. "Cracking the 500-Language Problem."** *IEEE
  Software*, Nov/Dec 2001. <https://www.cs.vu.nl/grammarware/500/500.pdf>
  The economic argument for grammar recovery at scale.
- **Lämmel, R. and Zaytsev, V. "An Introduction to Grammar Convergence."** IFM
  2009. <https://doi.org/10.1007/978-3-642-00255-7_17> Establishing that
  independently produced grammars for one language agree, by transformation to a
  common form. **Directly applicable to the four-corpus comparison** between our
  generated grammar, the old `.g4` corpus, the kaby76 corpus, LFortran and
  Flang.
- **Lämmel, R. and Zaytsev, V. "Recovering Grammar Relationships for the Java
  Language Specification."** SCAM 2009 / SQJ 2011. The same exercise on a real
  standards document.
- **Zaytsev, V. "Grammar Zoo: A corpus of experimental grammarware."** *Science
  of Computer Programming* 98, 2015. A corpus of recovered grammars; useful as a
  model for how to publish ours.
- **Engineering of Grammarware.** <https://www.cs.vu.nl/grammarware/>, the
  group's collected work. Read before writing E1's related-work section.
- **"Kajal: Extracting Grammar of a Source Code Using Large Language Models."**
  arXiv:2412.08842, 2024. <https://arxiv.org/abs/2412.08842> LLM-based grammar
  extraction. Recent and adjacent; check what it measures before claiming
  novelty for the model-assisted parts of E1.

### Generated-runtime parsing algorithms

These are the implementation references for the deterministic runtime gate,
not sources from which grammar productions may be copied.

- ✓ **Earley, J. “An Efficient Context-Free Parsing Algorithm.”**
  *Communications of the ACM* 13(2), 94–102, 1970.
  <https://doi.org/10.1145/362007.362035>. Predictor, scanner and completer
  chart operations over a finite set of items; the reference general parser
  for the E0170 recognizer fix.
- ✓ **Scott, E. and Johnstone, A. “GLL parse-tree generation.”**
  *Science of Computer Programming* 78(10), 1828–1844, 2013.
  <https://doi.org/10.1016/j.scico.2012.03.005>. Generalized LL descriptors,
  graph-structured stacks and shared packed forests for ambiguity and left
  recursion. The worklist and deduplication guidance applies even though E0170
  initially requires outcomes rather than forests.
- ✓ **GNU Bison Manual, “GLR Parsers.”**
  <https://www.gnu.org/software/bison/manual/html_node/GLR-Parsers.html>.
  Operational reference for retaining unresolved alternatives and merging
  equivalent parser states; it is an oracle-policy comparison, not an input
  grammar source.
- ✓ **Aycock, J. and Horspool, R. N. “Practical Earley Parsing.”**
  *The Computer Journal* 45(6), 620–630, 2002.
  <https://doi.org/10.1093/comjnl/45.6.620>. A practical Earley variant that
  treats empty right-hand sides with a dedicated finite automaton. This is the
  next performance hypothesis for E0170 because the generated Fortran grammar
  contains extensive nullable structure; it does not justify changing the
  source grammar or hiding ambiguity.

### Grammar comparison and projection validation

- ✓ **Lämmel, R. and Zaytsev, V. “An Introduction to Grammar Convergence.”**
  IFM 2009, <https://doi.org/10.1007/978-3-642-00255-7_17>. Compare grammars
  through explicit normalization and transformations, and state which form of
  equivalence the transformations establish. This is the rule for interpreting
  E0171's head inventories: they are structural evidence until a separate
  language witness exists.
- ✓ **GNU Bison Manual, “Generation of Counterexamples.”**
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>.
  Counterexamples are evidence for understanding and classifying conflicts;
  conflict totals and `%expect` declarations are not correctness proofs. The
  manual also distinguishes genuine ambiguity from a grammar that needs more
  lookahead, and recommends counterexample generation during development
  rather than as an unconditional CI cost.
- ✓ **GNU Bison Manual, “Output Files.”**
  <https://www.gnu.org/software/bison/manual/html_node/Output-Files.html>.
  The generated parser's start symbol and target-specific output conventions
  are part of the parser interface; our profile must record them instead of
  inferring an entry point from file order.
- ✓ **ANTLR 4 documentation.** <https://www.antlr.org/>. Generated parser
  acceptance and ambiguity reports are target-tool evidence, not proof that a
  grammar is faithful to its source specification.
- ✓ **Tree-sitter, “The Grammar DSL” and “Writing the Grammar.”**
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>
  and
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
  Lexical precedence, parse precedence and intentional runtime conflicts are
  distinct contracts; exports must record them separately. A `conflicts` entry
  is an intentional GLR ambiguity contract, not a warning suppressor. The
  first grammar rule is also a target-level entry choice, so a generated
  grammar must place an explicit profile wrapper there rather than allowing a
  lexical rule to become the implicit start rule.

## 2. Formalizing prose standards

The general problem of turning a natural-language standard into something
executable. Every one of these is a data point on how much effort it takes by
hand, which is the baseline our mechanical fraction is measured against.

- **Memarian, K. et al. "Into the depths of C: elaborating the de facto
  standards."** PLDI 2016 (Cerberus). The most honest account of what a prose
  standard actually leaves undetermined, and of the gap between the standard and
  what compilers do.
- **Ellison, C. and Roșu, G. "An executable formal semantics of C with
  applications."** POPL 2012. The K framework applied to a full language.
- **Watt, C. "Mechanising and verifying the WebAssembly specification."** CPP
  2018. WebAssembly is the counter-example worth citing: a modern standard
  designed with a formal semantics from the start. Useful for arguing what
  Fortran's standard could have been.
- **Milner, R., Tofte, M., Harper, R., MacQueen, D. *The Definition of Standard
  ML (Revised).*** MIT Press, 1997. The canonical fully formal language
  definition.
- **Mosses, P. D.** Action semantics and semantics-directed compiler generation.
  The older tradition this project sits in; worth citing to show the idea is not
  new and to say precisely what is.

## 3. Machine-readable instruction set specifications, the basis for `fortback-new`

- ✓ **Armstrong, A., Bauereiss, T., Campbell, B., Reid, A., Gray, K. E., Norton,
  R. M., Mundkur, P., Wassell, M., French, J., Pulte, C., Flur, S., Stark, I.,
  Krishnaswami, N., Sewell, P. "ISA Semantics for ARMv8-A, RISC-V, and
  CHERI-MIPS."** *Proc. ACM Program. Lang.* 3, POPL, Article 71, January 2019,
  31 pages. <https://doi.org/10.1145/3290384>. PDF at
  <https://www.cl.cam.ac.uk/~pes20/sail/sail-popl2019.pdf>, tool at
  <https://github.com/rems-project/sail>.
  Sail models are complete enough to boot Linux, and generate emulators in C and
  OCaml plus definitions for Isabelle, HOL4 and Coq. **This is why RISC-V is the
  first backend target**: an official, executable formal semantics makes
  translation validation of generated machine code achievable.
- **Reid, A. "Trustworthy specifications of ARM v8-A and v8-M system level
  architecture."** FMCAD 2016. How ARM's machine-readable architecture was
  produced and validated.
- **Reid, A. et al. "Who guards the guards? Formal validation of the ARM v8-M
  processor specification."** OOPSLA 2017.
- **riscv-opcodes**. <https://github.com/riscv/riscv-opcodes>. Machine-readable
  encodings, BSD.
- **ARM Machine Readable Architecture**, official A64 encodings plus ASL
  semantics.
- **Intel XED**. <https://github.com/intelxed/xed>, Apache-2.0. Data files are
  the practical encoding source for x86-64, in the absence of an official
  machine-readable specification.
- **Zydis**. MIT. A second independent x86-64 encoding table, therefore a
  comparison rather than a source.
- **uops.info**, measured latency and throughput; the input for cost modelling
  where no vendor data exists.

## 4. Verified and validated compilation

- **Leroy, X. "Formal verification of a realistic compiler."** *CACM* 52(7),
  2009 (CompCert). The reference point for what "verified compiler" means, and
  the reason §19 of the whitepaper states the trusted base explicitly rather
  than implying a stronger claim.
- **Pnueli, A., Siegel, M., Singerman, E. "Translation validation."** TACAS
  1998. Validating one compilation rather than the compiler, the right shape
  for a generated backend.
- **Necula, G. "Translation validation for an optimizing compiler."** PLDI 2000.
- **Lopes, N. et al. "Alive2: bounded translation validation for LLVM."** PLDI
  2021. The practical modern version, and the model for what `fortback-new`
  should attempt against Sail.

## 5. Synthesis, search and superoptimization

- **Solar-Lezama, A.** Program synthesis by sketching (PhD, 2008) and the CEGIS
  loop. The method for whitepaper category 2, "searchable".
- **Bansal, S. and Aiken, A. "Automatic generation of peephole
  superoptimizers."** ASPLOS 2006. Generating instruction-selection patterns by
  search rather than by hand.
- **Souper**. <https://github.com/google/souper>. A working superoptimizer over
  LLVM IR; useful as a comparison for generated peephole quality.
- **Torlak, E. and Bodik, R.** Rosette. Solver-aided languages; relevant if
  ImplIR ever needs a symbolic backend.

## 6. Separating correctness from performance

- **Ragan-Kelley, J. et al. "Halide: a language and compiler for optimizing
  parallelism, locality, and recomputation in image processing pipelines."**
  PLDI 2013. **The strongest citation for whitepaper §21**: algorithm and
  schedule as separate artifacts, with the schedule searched. The direct
  analogue of specification-determines-correctness, generator-searches-for-speed.
- **Frigo, M. and Johnson, S. G. "The design and implementation of FFTW3."**
  *Proc. IEEE* 93(2), 2005. Generated code plus empirical selection, in
  production, for two decades.
- **Whaley, R. C. and Dongarra, J. ATLAS.** Autotuning as the standard method in
  numerical libraries.

## 7. Test adequacy, mutation and differential testing

The evidence base for `LESSONS.md` §6 and for E7.

- **DeMillo, R., Lipton, R., Sayward, F. "Hints on test data selection: help for
  the practicing programmer."** *IEEE Computer* 11(4), 1978. The origin of
  mutation testing.
- **Papadakis, M. et al. "Mutation testing advances: an analysis and survey."**
  *Advances in Computers*, 2019. What is known about mutation's effectiveness
  and cost.
- **Yang, X., Chen, Y., Eide, E., Regehr, J. "Finding and understanding bugs in
  C compilers."** PLDI 2011 (Csmith). Random differential testing of compilers,
  and the canonical demonstration that mature compilers are full of bugs.
- **Le, V., Afshari, M., Su, Z. "Compiler validation via equivalence modulo
  inputs."** PLDI 2014 (EMI). Metamorphic testing for compilers; directly
  applicable and cheap.
- **Chen, J. et al.** Surveys of compiler testing. For E7's related work.

## 8. Constrained generation and model scale, the ImplIR hypothesis

The literature that makes "a smaller output language needs a smaller model"
testable rather than merely plausible.

- **Poesia, G. et al. "Synchromesh: reliable code generation from pre-trained
  language models."** ICLR 2022. Constrained decoding into a restricted target.
- **Scholak, T., Schucher, N., Bahdanau, D. "PICARD: parsing incrementally for
  constrained auto-regressive decoding from language models."** EMNLP 2021.
- **Geng, S. et al. "Grammar-constrained decoding for structured NLP tasks."**
  EMNLP 2023. The general mechanism; relevant to whether ImplIR generation
  should be grammar-constrained at decode time rather than repaired afterwards.
- **Chen, M. et al. "Evaluating large language models trained on code."** arXiv
  2107.03374, 2021 (Codex/HumanEval). The measurement conventions E3 and E4
  should follow or explicitly depart from.
- **Hoffmann, J. et al. "Training compute-optimal large language models."** 2022
  (Chinchilla). Needed to talk about "model scale" precisely rather than by
  parameter count alone.
- **Austin, J. et al. "Program synthesis with large language models."** arXiv
  2108.07732, 2021.

## 9. Fortran context

- ✓ **Kedward, L. J. et al. "The State of Fortran."** *Computing in Science &
  Engineering* 24(2), 63-72, 2022.
  <https://doi.org/10.1109/MCSE.2022.3159862>. On disk:
  `~/Zotero/storage/7MPHMESD/Kedward et al. - 2022 - The State of Fortran.pdf`.
  The survey to cite when motivating the work.
- **ISO/IEC 1539-1:2023**, the published standard. Not freely available; not
  vendored.
- **J3/24-007**, the Fortran 2023 final working draft, freely available,
  technically near-identical to the published standard. **The normative source
  for this project.** Pinned in `artifacts/standards/j3-24-007.toml`.
- **J3/26-007**, the Fortran 2028 working draft. On disk at
  `~/code/standard/validation/pdfs/Fortran2028_J3_26-007.pdf`. A moving target;
  used to test that the pipeline generalizes across revisions, not as the
  primary source.
- **Metcalf, M., Reid, J., Cohen, M., Bader, R. *Modern Fortran Explained:
  Incorporating Fortran 2023.*** Oxford University Press, 2023. On disk in
  `~/Nextcloud/` (note the leading space in the filename). The standard's
  intent in readable form; useful when adjudicating an ambiguity.
- **Markus, A. "Design patterns and Fortran 90/95."** 2006. On disk:
  `~/Zotero/storage/M8WRJ3VH/`.
- **kaby76/fortran**. <https://github.com/kaby76/fortran>. Third-party ANTLR
  grammars for multiple Fortran revisions. One of the three independent
  comparisons in E1. Already fetched by `standard/validation/tools/`.

## 10. Provenance and reproducibility

- **Wilkinson, M. D. et al. "The FAIR Guiding Principles for scientific data
  management and stewardship."** *Scientific Data* 3, 2016.
- **RO-Crate**. <https://www.researchobject.org/ro-crate/>. The export format
  for a publication snapshot. Deliberately not part of daily work.
- **ACM Artifact Review and Badging.** The bar a paper from this project should
  clear without extra effort, because the run records already exist.

## 11. Schemas, meta-languages and specification-driven implementation

The prior art behind `docs/self-hosting.md`. Each entry states what we take and
what we deliberately leave.

- **Wang, D. C., Appel, A. W., Korn, J. L., Serra, C. S. "The Zephyr Abstract
  Syntax Description Language."** USENIX DSL 1997.
  <https://www.usenix.org/conference/dsl-97/zephyr-abstract-syntax-description-language>
  Built to describe compiler IRs and generate data structures and serialization
  for C, C++, Java and ML. **We take the data model** — sum types, product
  types, lists, optional and primitive fields — **and not the toolchain**
  (D0006).
- **WebAssembly text format.**
  <https://webassembly.github.io/spec/core/text/conventions.html> The
  specification renders abstract syntax into S-expressions with the text
  grammar kept close to the abstract syntax. The precedent for SX being a tree
  serialization rather than a language.
- **LLVM TableGen.** <https://llvm.org/docs/TableGen/ProgRef.html> Declarative
  records generating instruction descriptions, register information, selection
  patterns and Clang AST definitions. Right direction, and a warning: classes,
  inheritance, template arguments, multiclasses, loops and conditionals are what
  our representation must not become.
- **MLIR Operation Definition Specification.**
  <https://mlir.llvm.org/docs/DefiningDialects/Operations/> The same pattern for
  dialect operations.
- **K Framework.** <https://kframework.org/> Language semantics, type systems
  and analysis tools as executable rewrite rules. The model for expressing
  dynamic semantics relationally if we need them.
- **Sewell, P. et al. Ott.**
  <https://www.cl.cam.ac.uk/~pes20/ott/> Motivated explicitly by the difficulty
  of maintaining full-scale semantic definitions; generates proof-assistant
  definitions and documentation from one specification.
- **Spoofax.** <https://spoofax.dev/> Declarative meta-languages for syntax,
  static semantics and transformation, generating parsers, type checkers and
  editor services. Demonstrates the reach of the approach, and the size of
  system it takes.

## 12. Scope graphs and Statix — the specialization precedent

The closest published analogue to this project's declarative-plus-specialized
split, and the direct prior art for D0007.

- **Néron, P., Tolmach, A., Visser, E., Wachsmuth, G. "A Theory of Name
  Resolution."** ESOP 2015.
  <https://research.tudelft.nl/en/publications/a-theory-of-name-resolution/>
  Splits name resolution into language-specific scope construction and a
  language-independent resolution calculus. **The hypothesis E12 tests against
  Fortran's modules, host association and USE renaming.**
- **Konat, G., Kats, L., Wachsmuth, G., Visser, E. "Declarative Name Binding
  for Type System Specifications."** SLE 2012.
  <https://research.tudelft.nl/en/publications/declarative-name-binding-for-type-system-specifications/>
- **Antwerpen, H. van, Poulsen, C. B., Rouvoet, A., Visser, E. "Scopes as
  Types."** OOPSLA 2018.
  <https://research.tudelft.nl/en/publications/scopes-as-types/> Statix: static
  semantics as declarative constraints over scope graphs, with executable type
  checking derived from them.
- **"Specializing Scope Graph Resolution Queries."** SLE 2022.
  <https://research.tudelft.nl/en/publications/specializing-scope-graph-resolution-queries/>
  **The single most relevant citation in this file.** Specializes declarative
  resolution queries into a procedural intermediate query language, reporting
  query resolution up to 7.7× faster and total type-checking time reduced by
  roughly 38 to 48 per cent. It is the published demonstration that keeping
  semantics declarative and specializing for speed are compatible, which is the
  premise of D0007 and of `WHITEPAPER.md` §21.

## 13. Bootstrapping and self-hosting

- **Konat, G., Erdweg, S., Visser, E. "Bootstrapping Domain-Specific
  Meta-Languages in Language Workbenches."** GPCE 2016.
  <https://research.tudelft.nl/en/publications/bootstrapping-domain-specific-meta-languages-in-language-workbenc/>
  Fixpoint compilation for systems whose compilers depend on their own DSLs and
  generators. **The precedent for the meta-language fixpoint criterion in
  D0010**, and the reason that criterion exists separately from the compiler
  one.
- **CakeML.** <https://cakeml.org/> A formally verified compiler that
  bootstraps itself; the stronger compiler self-hosting example.
- **Pottier, F. Menhir reference manual.**
  <https://gallium.inria.fr/~fpottier/menhir/manual.html> Generates a parser
  together with a proof of correctness and completeness with respect to its
  grammar, used in CompCert. Named as future work in `docs/self-hosting.md`
  §21, not planned.
- **Wheeler, D. A. "Fully Countering Trusting Trust through Diverse
  Double-Compiling."** PhD dissertation, 2009.
  <https://dwheeler.com/trusting-trust/dissertation/html/wheeler-trusting-trust-ddc.html>
  The actual answer to trusting trust, which stage-2/stage-3 equality is not.
  Also named as future work, not planned.

---

## Gaps to close

Things that should be here and are not yet. Each is a search someone owes.

- Prior work on generating a compiler frontend from a standards document
  specifically, as opposed to grammar recovery in general. If it exists, E1's
  framing changes.
- Fortran-specific compiler testing and conformance-suite literature.
- Empirical work on how much of a compiler is boilerplate, anyone who has
  measured this before, in any language.
- Attribute grammars and semantics-directed compiler generation, treated
  properly rather than by gesture at Knuth 1968.
- Recent work on LLM-assisted formalization of standards in other domains
  (protocols, hardware, legal text), which likely has the closest methodology
  even though the subject differs.
