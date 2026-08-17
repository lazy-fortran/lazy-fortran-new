# M3 C748 focused review v0

Review status: `NEEDS FIX`; v0 is not promotable.

Frozen review commit: `87e4b2855d535246f3efffc5ac0bacf673d7e5f4`.

The semantic reviewer found that C748 says “no component-attr-spec shall
appear more than once”. The v0 oracle treated present/zero in a
component-definition context as `REJECTED`, which imposes an unsupported
exact-once requirement. Zero occurrences are valid under the source rule.
Source binding, page-index containment, the R737 StandardIR witness, the
36-state product and twelve mutation controls otherwise passed review.

The reproducibility reviewer independently verified the clean E0214 replay,
committed trace and environment, component pins, active verifier and zero
model calls/promotions. That reproducibility pass does not override the
semantic defect. R000577 remains a failed candidate replay and is retained
as evidence; no semantic fact was promoted.
