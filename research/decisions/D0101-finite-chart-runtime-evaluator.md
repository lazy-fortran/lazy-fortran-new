# D0101. Use a finite chart evaluator for the generated grammar runtime

Date: 2026-08-15
Status: accepted

## Context

E0170's first complete bounded corpus reached a production-runtime timeout on
the finite `allocate-object` witness `letter digit % letter`. The existing
frontier evaluator repeatedly rescans the complete grammar and has no useful
finite work bound for that input. Two attempted repairs were rejected: one
added reachability and dependency heuristics without meeting the witness, and
the next chart attempt was incomplete and unverified. Neither changed a
production repository.

The relevant parsing literature uses a different invariant. Earley's chart
algorithm uses predictor, scanner and completer operations over deduplicated
items; its general worst-case bound is cubic in input length. GLL uses a
deduplicated descriptor/worklist model and a graph-structured stack for
ambiguity and left recursion. Both make progress by adding a finite state only
once, not by imposing an arbitrary iteration limit. Bison's GLR documentation
likewise treats unresolved alternatives as branches to retain and merge, not
as conflicts to hide.

## Decision

Replace the repeated global rescanning in the generated runtime with a generic
finite chart/worklist evaluator for the existing frontier contract.

The state identity must include at least the grammar rule, RHS position, input
start, input end/current position and the existing certainty state. The
implementation shall maintain indexed waiting and completed states, process
each newly admitted state through predictor/scanner/completer transitions, and
deduplicate before enqueueing. It must preserve epsilon rules, direct and
indirect left recursion, ambiguity, unresolved references and the existing
provenance/result categories. The root result must remain an independent
behavioral outcome, not a self-consistency check.

The implementation may prune states only with a correctness-preserving,
source-independent condition whose witness is tested. It must not use an
iteration cap, depth cap, arbitrary state cap or timeout as a correctness
mechanism. A process timeout remains an outer experiment safety limit and is
reported as a failure.

The first implementation is recognition/outcome-only. Parse-forest storage is
not added until the frontier contract requires it; if it is later needed, an
SPPF or equivalent shared representation is a separate decision.

## Rejected

* Increasing the global rescanning iteration formula or adding a larger fixed
  cutoff.
* Reachability, duplicate removal or FIRST-set heuristics presented as a
  termination fix without a finite-state proof and the exact witness.
* Copying LFortran, Bison or another parser's runtime or conflict policy.
* Rewriting StandardIR productions to suit this runtime.
* Treating successful contract loading or parser-generator acceptance as proof
  of runtime language behavior.

## Reversal condition

Write a successor if the chart evaluator fails the exact timeout witness or a
focused grammar suite, or if a different generic evaluator gives the same
contract and independent outcomes with a smaller, demonstrably bounded state
space. Any change that adds parse trees, semantic actions or language-specific
lookahead requires a separate decision.

## Evidence

* E0170/R000377: exact finite-corpus production timeout.
* E0170/R000378 and R000379: retained rejected production attempts.
* J. Earley, “An Efficient Context-Free Parsing Algorithm,” *Communications
  of the ACM* 13(2), 94–102, 1970,
  <https://doi.org/10.1145/362007.362035>.
* E. Scott and A. Johnstone, “GLL parse-tree generation,” *Science of
  Computer Programming* 78(10), 1828–1844, 2013,
  <https://doi.org/10.1016/j.scico.2012.03.005>.
* GNU Bison Manual, “GLR Parsers,”
  <https://www.gnu.org/software/bison/manual/html_node/GLR-Parsers.html>.
