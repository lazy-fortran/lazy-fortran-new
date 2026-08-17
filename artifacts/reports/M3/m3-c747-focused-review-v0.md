# M3 C747 focused review v0

Review status: `NEEDS_FIX`. This review did not promote C747.

The reproducibility reviewer passed the frozen `53ff572adcc8f9f3710ed855b88525263a299614` packet: the recorded replay, trace, environment, pins, validator, mutation controls and zero model/promotion counts agreed.

The semantic reviewer independently recomputed the 36-state oracle and agreed with its 5 `ACCEPTED`, 2 `REJECTED` and 29 `UNRESOLVED` outcomes, but found a provenance defect. The fixture bound source span `237572:183` to page-index record 77 (`start 195782`, `length 2519`), although the span is contained by record 91 (`start 235554`, `length 2214`). Printed page 77 and canonical page-index page 91 had been conflated, and the validator did not assert containment.

Required correction: bind the canonical span to page-index record 91 and add an independent containment assertion. The corrected slice must be replayed before review or promotion.

The failed review is retained as evidence; no semantic fact was promoted.
