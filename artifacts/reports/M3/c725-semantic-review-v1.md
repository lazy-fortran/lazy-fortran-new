# C725 semantic/source review v1

Status: `PASS`
Candidate revision: `d202da29ff4fa8b2914ca6e44add89a2ca323442`
Replay: `tests/e2e/run-m3-c725.sh .cache/runs/E0180/R000001`

The C725 fixture and D0130 bind the same normative source identity: canonical
line 3452, printed page 83, PDF SHA-256
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.
StandardIR metadata matches exactly for R723 (`char-length`, page 84,
byte-start 217536, byte-length 70, occurrence 73) and R708
(`int-literal-constant`, page 80, byte-start 207585, byte-length 61,
occurrence 58).

The independent validator computes the typed kind-parameter property as two
`ACCEPTED`, one `REJECTED` and one `UNRESOLVED` outcome. All five source and
identity mutations fail. Canonicalization and committed-trace comparison pass.
The boundary is explicit: no parsing, value evaluation, processor facts, model
calls or semantic promotions.

Commands and inputs: the replay above, `scripts/check-contracts.sh`, its
`--self-test`, `scripts/check_pins.sh`, `bash -n tests/e2e/run-m3-c725.sh`,
`python3 tests/e2e/validate_m3_c725.py --self-test`, and the pinned artifacts
under `.cache/runs/E0180/R000001/`.
