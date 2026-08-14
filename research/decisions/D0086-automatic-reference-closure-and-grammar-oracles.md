# D0086. Make StandardIR closure and grammar validation fully automatic

Date: 2026-08-14
Status: amended by D0087
Amends: D0084

## Context

The E0147 source-span audit at `standard-new` commit
`17525dbef6ec7a44ee701bc400841e8a907708df` passes its extraction controls, but
the first downstream oracle run rejected all three generated parser grammars.
ANTLR4, Bison and tree-sitter independently report unresolved names such as
`xyz`, `letter`, `r_xyz`, and the assumed `*-list` families. The exports were
therefore not usable parser inputs even though their source spans were valid.

The source document explicitly defines assumed syntax families R401--R403 and
lexical classes in clause 6. It also contains repeated productions and
left-recursive expression families. These are normal inputs to a generic
projection step, not permission for R-number-specific edits. The historical
E0098/E0056 runs used target-specific rewrites and hard-coded residues; they are
retained as evidence but are not an acceptable correctness procedure.

## Decision

1. Treat source validity, reference closure and target-parser validation as
   separate mandatory gates. A source-valid StandardIR artifact is not an
   exportable grammar until every nonterminal-looking reference has a
   source-backed classification and ANTLR4, Bison and tree-sitter all accept
   the generated target grammar.

2. Resolve references by one deterministic, generic closure pass over the
   source-backed records. It may apply only declared source rules and facts:
   R402 name aliases, R401 list expansion, R403 scalar aliases, lexical facts,
   fixed errata under D0025, and explicit semantic-only or unresolved states.
   The closure must reach a fixed point, preserve the original source records,
   emit derived-record provenance, and fail on an unclassified residue.

3. Generate all target grammars from that closure. No manual `sed`, target
   grammar patch, R-number special case, hand-maintained conflict list, or
   copied production is part of a valid run. Target projections may use only
   generic transformations that are derived from the grammar graph, such as
   duplicate-alternative removal, nullable-wrapper simplification and a
   standard left-recursion transformation. Each transformed output must retain
   a mapping to its source-backed input nodes.

4. Run the three external validators in the same reproducible procedure that
   creates the exports. Record executable versions, complete logs, exit codes,
   warning counts and unresolved-symbol counts. A validator error, undefined
   symbol, dropped source mapping or unclassified reference is a hard failure.
   Warnings that are intrinsic to an intentionally all-productions projection
   may remain only when the report names them and an independent check proves
   that no source rule or parser symbol was lost; they do not silently become
   success.

5. Keep the E0147 source-validity result `R000267` as an accepted subgate, but
   do not call E0147 terminal or resume model/semantic work until the closure
   and validator gates pass in a new append-only run record. Luna review remains
   a later diagnostic lane under D0085 and cannot substitute for these gates.

## Rejected

* Treating a generated file as valid because its emitter exited successfully.
  The external parser generators are independent behavioral oracles.
* Dropping unresolved names, pruning inconvenient productions, or adding broad
  catch-all rules merely to make a target tool compile.
* Repeating the historical E0098/E0056 target rewrites. They are useful failure
  evidence but are not source-generated closure.
* Asking an LLM to repair the grammar or choose the wiring. A later bounded
  model lane may propose a typed residual classification only after the
  deterministic closure has passed; it cannot override this gate.

## Reversal condition

Write a successor if the complete selected profile contains a source construct
that cannot be represented by the generic closure or standard target
transformation while preserving source mapping. The successor must retain the
failing witness and decide whether the correct representation is a compact
source-backed erratum, a new generic transformation, or an explicit
semantic-only boundary.
