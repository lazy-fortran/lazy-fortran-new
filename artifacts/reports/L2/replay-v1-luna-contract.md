# L2 review v1 — contract and interface

Reviewed commit: `1c23fff`

Verdict: FAIL

Findings: `mir-v0.sxs` did not declare the `instructions` list consumed by FFC
and fortback. The trace claimed serialized `targetir-v0` and `emission-v0`
crossings that the implementation did not perform. TargetIR origin vocabulary
also lacked the component's imported provenance class.

Required correction: declare the actual MIR instruction list, narrow the
central L2 boundary to the observed frontend-v0 → mir-v0 → bounded emission
path, and reserve serialized TargetIR/emission contracts for a later slice.

Disposition: corrected through D0122 and the central contract update; this
report is retained as immutable review evidence.
