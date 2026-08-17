# M3 C749 focused independent review v1

Review status: `PASS`; promote C749 only as a bounded oracle leaf. Full M3
remains `OPEN`.

Frozen review revision:
`a64c2a73e293345bea35fbd7dac2ca94511f98ad`. Both independent reviewers
checked the same pushed revision and returned PASS.

## Semantic and adversarial review

The source binding independently matches J3-24-007 C749 at canonical lines
3835--3837, printed page 79, byte span `240824:234`, uniquely contained by
page-index record 93 (`start 239957`, `length 2451`). StandardIR R703 and
R737 match the pinned source hash and expected grammar shapes.

The typed product is complete: 3 attribute states × 6 declaration-type
categories × 3 contexts = 54 unique states. The independently recomputed
partition is 4 `ACCEPTED`, 1 `REJECTED`, and 49 `UNRESOLVED`; all twelve
declared mutations reject. The relation remains limited to C749 and does not
parse arbitrary Fortran, resolve names, inspect C750/C751 or claim full M3.

## Reproducibility and integration review

E0216 is `reported` with a result block. Durable R000589 records the passing
E0216/R000006 replay. The result and committed trace are byte-identical with
SHA-256 `4ad1c0d77479c7904cebfb9da2153d118dcd29370394c359c0805618e1890aa3`.
The pinned component revisions, source hashes, expected-table hash, run
environment, registry, executable runner and remote `origin/main` all agree.
The worktree is clean. Model calls and semantic promotions are zero.

## Retained review corrections

R000590 retains the first focused review failure: the replay had passed but
the successful run was not yet durable in the central ledger. R000591 retains
the second focused review failure: the manifest input section still named the
pre-normalization expected-table hash. The manifest, ledger and result linkage
were corrected before the final review. R000592 is the final focused review
PASS.

## Evidence-gate lifecycle

```text
leaf_id: T-M3-c749-component-type-eligibility-oracle
claim_id: M3-C749-bounded-oracle
parent_id: M3
leaf_status: PASS
claim_status: CLOSED
parent_status: OPEN
evidence_gate_verdict: PASS
review_verdict: PASS
```

This review promotes only the bounded C749 oracle leaf; it does not promote a
semantic fact or close the parent M3 milestone.
