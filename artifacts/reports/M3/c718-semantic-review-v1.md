# C718 semantic/source review v1

Status: `PASS` for semantic/source scope; the review wave was not promotable
because the paired reproducibility review failed.
Origin: `LLM`
Candidate functional snapshot: `a0a8da40e712068502a0dc5c7487e9b1ecacdbe1`
Replay: `tests/e2e/run-m3-c718.sh .cache/runs/E0182/R000001`

C718 binds canonical line 3296 and StandardIR R709 occurrence 59 with the
matching source hashes. The typed candidate carries named-constant and
value-type states. The independent validator computes two `ACCEPTED`, one
`REJECTED` and one `UNRESOLVED` outcome; it does not use expected labels as
the decision procedure. Five source/provenance mutations fail closed.

The boundary is explicit: no general parsing, name resolution, type inference,
constant evaluation, compiler wiring, model calls or semantic promotions.
The paired control-plane review found that R000033 was recorded before the
final E0182 pin, so this report does not authorize promotion.

Commands: `python3 tests/e2e/validate_m3_c718.py --self-test`,
`scripts/check-contracts.sh`, `scripts/check_pins.sh`, and
`bash -n tests/e2e/run-m3-c718.sh`.
