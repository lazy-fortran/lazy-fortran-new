# D0029. Specialized direct parser is the production target

Date: 2026-08-12
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0056 removes the compact target-export failures from the accepted composite
projection. ANTLR4 and Bison generate with zero unresolved names. tree-sitter
still requires an expanding target-specific ambiguity table after thirteen
explicit conflict groups. D0018 already defines the four grammar formats as
derived exports and makes the composite parser input the authoritative parser
source.

## Decision

Use a specialized direct parser generator as the production parser target. Its
input is the accepted composite projection of StandardIR, lexical facts,
constraints, prose restrictions and resolution states. The generator emits
direct parser structure and deterministic wiring from those records.

Keep EBNF, ANTLR4, Bison and tree-sitter as generated export formats for
documentation, interoperability and differential comparison. Their target
normalization metadata is derived output. It must not become a second semantic
source or a collection of hand-maintained Fortran exceptions. tree-sitter
generation status and its conflict inventory remain reported evidence while
the direct parser path advances.

## Rejected

Blocking the production parser on a conflict-free tree-sitter grammar is
rejected because E0056 shows that the remaining work is target-specific and
does not add source facts. Adding the conflict list to StandardIR is rejected
because it would make a backend projection part of the authoritative
representation. Asking a model to adjudicate the conflicts is rejected because
the issue is deterministic target composition, not a local semantic hole.

## Reversal condition

Write a successor if a general, mechanically derived tree-sitter conflict
projection becomes compact and stable, or if differential measurements show
that tree-sitter is required for correctness or materially outperforms the
specialized direct parser. A warning or conflict count alone is insufficient.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
