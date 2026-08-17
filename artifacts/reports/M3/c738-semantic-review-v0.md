# C738 semantic/source review v0

Status: `NEEDS FIX`
Origin: `LLM`
Functional snapshot: `20c55cf206ee7822a5ca2c29bfc05bd8051d0ce0`
Control-plane snapshot: `398d7e4cff3c270ddafc68ca4b59b82d44b13ccd`
Replay: `tests/e2e/run-m3-c738.sh --fresh` (cache replay `R000004`)

The source binding, typed oracle truth function, six mutation controls, and
zero model/promotion counters passed. The review found that the declared
state space was not fully witnessed: the fixture lacked no-deferred with
`ABSTRACT` present, inherited-deferred without `ABSTRACT`, and unknown
`ABSTRACT` controls. The review therefore did not authorize promotion.

This failed review is retained. The correction expands the fixture and
self-test to cover all declared branches and replays the corrected packet.
