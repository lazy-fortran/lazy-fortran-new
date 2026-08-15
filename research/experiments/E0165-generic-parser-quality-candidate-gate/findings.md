# E0165 findings

The trusted E0158 PDF-fidelity gate, fresh E0154/R000353 regeneration, fresh
E0157/R000354 inventory and E0159/R000356 conflict classification were green
before this candidate was attempted. The baseline all-root Bison inventory is
758 shift/reduce and 3,885 reduce/reduce conflicts; the selected profile is
427/2,266 and the pinned LFortran policy is 238/180.

## Candidate: generic common-prefix factoring

The candidate was implemented in `standard-new` as a grammar-structural
transformation with merged source lineage and generated helper witnesses. It
also made the Bison ambiguity policy explicit with GLR/IELR declarations. No
Fortran rule number, mnemonic or source production was special-cased.

The first run exposed an allocation bug in the generic factoring loop. The
coordinator corrected that one generic allocation lifetime issue; focused and
full `fo` then passed. The corrected candidate generated all four formats and
passed E0154 source identity, lexical and parser-generator gates, but its
Bison inventory worsened to 948 shift/reduce and 4,572 reduce/reduce conflicts.

The selected-program follow-up did not produce a valid conflict inventory. It
reported 12 useless nonterminals and 516 useless rules, then Bison aborted in
`AnnotationList__compute_from_inadequacies` before the analyzer could compute
selected totals. This is a target-projection failure, not evidence that any
StandardIR rule is wrong.

The candidate is rejected and `standard-new` returned to the baseline
projection in revert commit `8d5ee41`. The accepted generic choices remain
D0089's GLR export policy and D0092/E0163's opt-in role-family specialization;
this global common-prefix transformation is not promoted. No precedence
rewrite is justified. The next parser-quality work must use an independently
witnessed transformation with the same source/lineage and behavior gates.

Reproducible evidence is retained in `.cache/runs/E0154/R000357`,
`.cache/runs/E0159/R000358` and `.cache/runs/E0159/R000359`; the append-only
adjudication is R000360.
