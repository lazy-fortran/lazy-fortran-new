# Focused review: source-derived typed AST v1 name boundary

The bounded L3 source-derived-name slice is promotable only under D0181,
D0182 and D0183. The evidence packet is central revision
`b7da3ee569fc3c3f0183f8fd64e2014822cc7e1a`; its frozen executable revision is
`0ac0e88e2add068b7ac434c46473657a66438f6e`, and the producer is fortfront
`157236b11540d6a55676e159062e6f9423577a0d`.

R000693 is the authoritative no-bootstrap replay. It executes `beta`, `q7`
and `theta_2` through the same `fortfront-source-ast-v1` producer, preserves
declaration spans 10 through 27, 10 through 25 and 10 through 30, repeats
each output identically, rejects the malformed `integer ::` neighbour and
passes the independent output oracle and committed trace. The contract oracle
also checks the full J3-24-007 source hash ending `9979f9e`, all source rules
and pages, every positive/mutation witness and the negative witness identity.

The exact authoritative command is:

```text
AST_EXPECTED_CENTRAL_COMMIT=0ac0e88e2add068b7ac434c46473657a66438f6e \
tests/e2e/run-frontend-ast-v1-name-derived.sh --fresh
```

Independent final focused reviews R000694 and R000695 both pass contract
oracle independence, source provenance, behavioral replay, lineage,
reproducibility, bounded scope and promotion safety. R000689 and R000690 are
retained failures: the former is the pre-implementation rejection of `beta`,
and the latter is the oracle catch of the incorrect source-hash-label
expectation. R000691 and R000692 remain retained earlier successful replays;
R000693 is authoritative.

This promotes only source-derived variable names and declaration spans for the
fixed `program p` / `integer :: name` AST-v1 shape. It does not establish
general identifier parsing, arbitrary Fortran parsing, semantic analysis, MIR
or full M3. The contract and expected table remain labelled `LLM` because
Luna generated them; deterministic replay and independent review, not model
output, authorize the bounded promotion. Every recorded run reports zero model
calls and zero semantic promotions.
