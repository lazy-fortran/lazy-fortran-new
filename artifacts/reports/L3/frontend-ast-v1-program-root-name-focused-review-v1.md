# L3 frontend AST v1 program-root-name focused review

Status: PASS-BOUNDED-ONLY

Frozen executable revision: `d8d61d8fe9df29cf42593d93a315e9a73727839d`

Technical replay: `research/runs/2026-08.jsonl#R000698`

Component revision: `fortfront-new` `04ca10b9d191366f328a39d0133375fd6aa62e4e`

The clean replay command was:

```text
AST_EXPECTED_CENTRAL_COMMIT=d8d61d8fe9df29cf42593d93a315e9a73727839d tests/e2e/run-frontend-ast-v1-program-root-name.sh --fresh
```

The independent review runs are `R000699` and `R000700`. They confirm the
source-derived `main` and `unit` root and declaration names, preservation of
the `integer :: x` record, identical repeated output, rejection of the
mismatched `END PROGRAM`, committed trace/hash closure, clean component pins,
zero model calls and zero semantic promotions. The claim is limited to the
pinned typed-AST shape; it does not establish general identifier parsing,
general program-unit parsing, semantic analysis, full L3, or full M3.
