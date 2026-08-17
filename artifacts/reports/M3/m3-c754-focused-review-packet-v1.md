# C754 focused review packet v1

Frozen implementation revision: `3fb7c98585859f22a833a78734769ea577061351`.

Functional-tree pin in the E0224 manifest: `d59bfad`. The replay revision is
the metadata commit above; `run-m3-c754.sh` checks that every functional path
matches the manifest pin and records both revisions. The exact replay is
`.cache/runs/E0224/R000001` and the command is:

```text
M3_C754_EXPECTED_CENTRAL_COMMIT=3fb7c98585859f22a833a78734769ea577061351 tests/e2e/run-m3-c754.sh --fresh
```

## Review target

Decide whether this is sufficient evidence for the bounded C754 oracle leaf,
not whether C754 is a promoted semantic fact and not whether the compiler can
parse Fortran.

## Required checks

The reviewers must independently check:

* source identity J3-24-007 clause 7 rule C754, canonical lines 3847--3848,
  printed page 79, span `241715:150`, and page record `93:239957:2451`;
* canonical source hash
  `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, PDF
  hash `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`,
  page-index hash
  `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`, and
  StandardIR hash
  `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`;
* StandardIR rows R737/R738/R739/R740 and their referenced component shape;
* the typed 3 x 3 x 3 candidate product and independent expected table;
* the rule: definite POINTER or ALLOCATABLE makes the restriction vacuous,
  explicit shape is compliant, definite absent/absent/deferred shape is the
  sole rejection, and remaining insufficient information is unresolved;
* all 13 mutation controls, result/trace equality, semantic canonicalization,
  clean trees, zero model calls, zero semantic promotions, and bounded-only
  promotion status;
* the distinction between the functional-tree pin and the later metadata
  revision.

## Evidence

* result and trace SHA-256:
  `8051938e0c1771034c78e3a3f10844d423badb1da9b0f32f1c4e24ae145d69eb`;
* run-environment SHA-256:
  `8a40e8414ebb8cf9c7d21108de446b2e8b5c47b8a8b3e2d8abcd649a3529fec4`;
* validator SHA-256:
  `911c676483526ce87fe076ac330bdd800debc56ef490495a93477173b416212f`;
* result partition: 19 ACCEPTED, 1 REJECTED, 7 UNRESOLVED, 27 states;
* model calls: 0; semantic promotions: 0; mutation controls: 13.

The review result must preserve any finding and may promote only the bounded
oracle leaf. Full M3 remains open.
