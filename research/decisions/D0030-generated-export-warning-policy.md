# D0030. Generated export warnings are retained evidence

Date: 2026-08-12
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0056 mechanically normalizes the accepted composite input. ANTLR4 and Bison
then generate with zero unresolved names and zero fatal errors, while their
generators report 18 and 206 warnings. D0029 makes both formats derived
exports and selects the specialized direct parser as the production target.
The warning counts therefore describe target projections, not the
authoritative StandardIR or the production parser.

## Decision

Do not require ANTLR4 or Bison exports to be warning-free before the direct
parser path advances. Accept a target export only when its generated input has
zero unresolved target names, the generator reports no fatal error, and the
warning count and target status are recorded in the run. Keep the warnings as
derived target diagnostics. Do not add target-specific exceptions to
StandardIR or spend production-path complexity removing warnings whose only
consumer is a differential export.

A warning becomes blocking evidence when an independent parser-behavior check
shows that it changes acceptance, loses source structure, or hides an
unclassified generation failure. Such a case starts a target-specific
normalization experiment and does not alter the authoritative representation.

## Rejected

Requiring warning-free ANTLR4 and Bison output is rejected because it would
make secondary exports gate the selected direct parser and would encourage
target-specific grammar edits. Silently discarding warnings is rejected
because it destroys evidence about the limits of the export projection.

## Reversal condition

Write a successor if a warning-free export can be obtained by a compact,
general normalization that also improves differential correctness, or if an
independent behavior comparison shows that the retained warnings hide a
correctness failure. A lower warning count alone is insufficient.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
