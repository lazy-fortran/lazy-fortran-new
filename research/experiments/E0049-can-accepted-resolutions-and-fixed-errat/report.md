# E0049. Unified partial composite input and resolution-overlap audit

## Question

Can the accepted D0019 resolutions and fixed D0025 errata compose into one
partial parser input while retaining the D0024 expansion boundary?

## Method

The analysis command reruns the accepted E0046 resolution composition and the
E0048 errata and expansion inventory, checks their pinned output hashes, and
attaches the eight errata IDs to the 182 resolution records. It then applies
the 70 accepted R402 and lexical projections and the eight punctuation repairs
to all 522 StandardIR syntax records. R401 and R403 terms are not projected by
this experiment.

The candidate is passed through the deterministic `standard-new` SX-to-ANTLR
emitter. Independent traversals reconstruct the overlap set and check source
occurrences, projected references, retained expansion references and the
controlled family mutation.

## Result

Pending the first run.

## Boundary

The generated files are a candidate partial input and evidence for the
representation decision. They do not establish target-parser acceptance or
semantic correctness. The next decision must define compositional resolution
facts or retain the three overlaps unresolved until the parser and semantic
schemas can carry both relationships.
