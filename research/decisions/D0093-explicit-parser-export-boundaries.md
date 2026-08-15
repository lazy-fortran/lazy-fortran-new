# D0093. Make parser export boundaries and lexer contracts explicit

Date: 2026-08-15
Status: accepted

## Context

E0149 and Luna's review distinguish three things that were previously easy to
confuse: a closure grammar containing every declared root, a selected parser
grammar for one entry point, and a lexer contract that maps source characters
to parser terminals. The current Bison output passes Bison and preserves source
lineage, but its all-root conflict counts are not a production parser quality
measure and the `.y` file alone does not define `yylex`.

## Decision

StandardIR exports name their target mode explicitly. A closure export is a
validation artifact and reports every declared root and its disposition. A
selected-root export is the production-parser input, performs deterministic
reachability pruning, and records every omitted helper or root with a reason.
The default mode must not be presented as a production parser entry point.

Each parser export has a companion lexer-contract projection containing token
names, canonical source spellings, lexical facts, and provenance. Lexer actions
remain outside normative StandardIR. Bison conflict and reachability data are
reported as target metrics; a target policy or budget is generated only for a
selected parser mode and is never copied from LFortran's `%expect` values.

## Rejected

* Calling the all-root closure grammar the compiler's parser.
* Treating Bison's terminal declarations as a complete lexer implementation.
* Comparing raw conflict counts across differently factored grammars as a
  conformance result.
* Silently dropping unreachable roots or helpers without a disposition.

## Reversal condition

Write a successor if a selected export cannot be generated from the same
source-backed records as the closure export, if a lexer-contract witness
disagrees with canonical source behavior, or if explicit reachability
dispositions fail to preserve the selected language.
