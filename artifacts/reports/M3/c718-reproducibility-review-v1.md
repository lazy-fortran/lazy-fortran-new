# C718 reproducibility/control-plane review v1

Status: `FAIL`
Origin: `LLM`
Candidate functional snapshot: `a0a8da40e712068502a0dc5c7487e9b1ecacdbe1`
Recorded replay: `tests/e2e/run-m3-c718.sh .cache/runs/E0182/R000001`

The bounded result is internally green: the result equals the committed trace,
all source/input hashes pass, the replay records four outcomes, five mutation
failures, zero model calls and zero semantic promotions, and standard-new is
clean at `f94c4c51b51fce22b533b7eeda08741970320913`.

The control-plane gate fails because E0182 was pinned to `8e99c516` while the
review snapshot was `a0a8da4`; R000033 therefore recorded a valid functional
replay but not the exact declared candidate pin. The next executable repair
was to repin E0182 to `a0a8da4` and replay as R000002. No promotion was made.
