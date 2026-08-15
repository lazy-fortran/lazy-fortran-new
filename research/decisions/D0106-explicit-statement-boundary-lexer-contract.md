# D0106. Make statement boundaries an explicit target lexer contract

Date: 2026-08-15
Status: accepted

## Context

The clean selected-profile replay reaches the parser generators with source
identity, lexical spelling, profile and transformation witnesses green. The
same abstract case then appears in Tree-sitter as `SAVE` followed by `LETTER`
and in the selected Bison counterexample inventory as a `LETTER` reduce/reduce
witness involving source R859. The retained Bison derivations prove two parses
for the current token stream, but the current normalized lexer contract has
only five lexical rows and no statement-termination event.

Fortran keywords are not a sufficient token-domain boundary by themselves:
the source position and statement structure affect whether a word begins a
statement or is a name in the following statement. A parser-generator conflict
therefore cannot be adjudicated until the lexer/profile contract states how
statement termination, continuation and keyword/name reclassification are
represented.

## Decision

Keep StandardIR's source-backed syntax productions unchanged. Represent
statement termination and related line/continuation behavior in a versioned
target lexer contract consumed by generated parsers. The contract must expose
the event or equivalent parser-visible fact needed to distinguish a statement
ending after `SAVE` from a following statement beginning with a name, and it
must state how keyword-shaped names are handled.

The contract and its tests are generated or checked from source-backed lexical
facts and source layout evidence; they are not copied from LFortran, Flang or a
reference grammar. Every target projection records the contract revision.
Until independent positive and negative behavior witnesses cover statement
boundaries, continuation and keyword/name cases, a Tree-sitter `conflicts`
entry, precedence declaration or Bison `%expect` is not a resolution. The
current conflict remains `lexer/profile-interaction-candidate`.

## Rejected

* Adding a Tree-sitter conflict declaration for `r_save_stmt` as a substitute
  for statement-boundary behavior.
* Adding an `EOS` production to StandardIR merely because one target needs a
  parser-visible boundary.
* Treating the current five-row lexical contract as complete Fortran lexer
  behavior.
* Copying a reference parser's lexer actions or token names into StandardIR.

## Reversal condition

Write a successor if an independent source-backed lexer model demonstrates that
statement termination is fully represented by an existing contract revision,
or if a target-independent recognizer proves the conflict classification and
behavior without exposing a boundary event to the generated parser.

## Evidence

* E0171/R000404: all source/target witness gates pass; Tree-sitter reports
  `SAVE` / `LETTER` unresolved conflict.
* E0171/R000406: normalized selected Bison and Tree-sitter evidence maps the
  conflict to R859 and the derived R401 list; classification remains
  unaccepted pending lexer behavior.
* Tree-sitter, “Writing the Grammar,” on lexical versus parse precedence and
  context-aware lexing,
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
* GNU Bison Manual, “Generation of Counterexamples,” on ambiguity versus
  insufficient lookahead,
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>.
