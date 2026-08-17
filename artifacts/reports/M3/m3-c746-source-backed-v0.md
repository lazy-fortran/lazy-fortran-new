# M3 C746 bounded type-parameter-name membership oracle

Bounded-slice status: `PASS`; C746 is promoted only as this bounded oracle
leaf. Full M3 remains `OPEN`. This artifact does not claim a Fortran parser,
name resolver or general semantic analysis.

## Contract and result

The contract binds J3-24-007 C746 to canonical lines 3764--3765, printed page
77 and UTF-8 byte span `237401:171`, over existing StandardIR witnesses R727
(`derived-type-stmt`), R732 (`type-param-def-stmt`) and R733
(`type-param-decl`). Its typed candidate product is:

```text
definition-name presence: absent | present | unknown
declared-name relation: member | not-member | unknown
context: derived-type-def | other | unknown
```

The deterministic oracle accepts an absent definition name in a derived-type
definition, accepts a present name whose relation is `member`, rejects a
present name whose relation is `not-member`, and returns `UNRESOLVED`
otherwise. D0152 records this bounded contract and its exclusions.

The separately authored expected-outcome table
`tests/fixtures/m3-c746-expected-outcomes-v0.json`, SHA-256
`b755d1d52fee369dda6e57cf26d0ae1c676f233207c8611911342d5f218dd581`, is the
independent behavioral oracle. The central validator reports 27 typed states:
4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`; its 12 source, page, StandardIR
and contract-identity mutations are all rejected. The replay performs zero
model calls and zero semantic promotions. Reproduce these counts with:

```text
python3 tests/e2e/validate_m3_c746.py --self-test
jq '{outcome_counts,mutation_controls,model_calls,semantic_promotions}' .cache/runs/E0210/R000001/result.json
```

## Authoritative evidence

The clean central verifier is:

```text
tests/e2e/run-m3-c746.sh --fresh
```

It passed in E0210/R000002 at control-plane revision
`6f9bb1653b862a24fb97a477950bf264a8f78253`, with the functional implementation
at `eafe398` and `standard-new` at
`f94c4c51b51fce22b533b7eeda08741970320913`. The recorded result and committed
trace both have SHA-256
`caad123d7aa0a3f30b5d6962e0b15928b8032fba2207fa23cf06105953aa6f66`; the run
environment has SHA-256
`cfee8a4161f9e3be25a4b2b82c7e1d64ff392323a1fbdcae1e56a9113cf648df`.

The validator has SHA-256
`6b7fd1171c0c798c84476574214f354c6b8587cde56a88e067e75865ee91cc66`; the
source fixture has SHA-256
`28fb8bd236b71fdc3b958cd6329d17599492623aefb8b5e479b2ecec359fc402`.
The normative PDF, canonical text, page index and StandardIR hashes are
recorded in the committed trace and run environment.

The final focused review has two passing independent scopes in
`artifacts/reports/M3/m3-c746-focused-review-v0.md`. The post-C746 residual
partition is 145 rows, 84 disputed and 61 unwitnessed, with C747@1 first; its
selection is the next task. Regenerate that partition with the promoted list
in `TASK_POOL.yaml`.

## Non-claims

This leaf does not parse a derived-type definition, compare real identifier
spellings, perform case folding or name resolution, check C747's exactly-once
cardinality, diagnose arbitrary Fortran, restart E0172, or close full M3. It
is a source-backed typed relation oracle, not an end-user compiler frontend.
