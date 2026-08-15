# E0154 current state

The historical baseline remains intentionally failing. Its exports carry
source rule, location and lineage comments, but not an independently
recomputable identity for the exact RHS alternative. The current replay is
run with:

```text
research/experiments/E0154-can-exact-source-expression-identity-and/run-selected.sh \
  .cache/runs/E0154/R000002 program
```

`run-selected.sh` regenerates all four projections from the pinned
source-backed input and invokes the independent checker. `analyse.sh` remains
the checker-only entry point for an existing run directory.

## R000308: the first real identity replay failed for useful reasons

The replay generated all four target files, but the exact identity gate failed:

- 1,068 source alternatives were the denominator; each format independently
  covered 1,052 before errors were counted.
- The independent negative mutation failed as required.
- The target files passed ANTLR4, Bison and tree-sitter, and the older
  body-bound source projection passed. Those are subordinate checks, not an
  identity pass.
- Non-ASCII source expressions such as the en dash in R1010/R712 receive a
  different SHA-256 from the independent UTF-8 oracle.
- A fixed 256-character annotation buffer truncates one hash in long merged
  lineages such as the R901 helper.
- Synthetic assumed-expansion records derived from R401/R402/R403 have no
  normative RHS expression. Giving those records a field named
  `source-expression-sha256` is a typed-provenance error, even though the
  hash is internally reproducible from the generated target expression.

These are generic production defects, not defects adjudicated by rule number
and not evidence about any LLM. The next repair must correct the canonical
UTF-8 byte path, make merged witness serialization capacity-safe, and make
source-versus-generated expression identity explicit. The failed run and the
post-failure target-oracle run are retained as R000308 and R000309.

The comparison is bidirectional. StandardIR already does something the
reference parser does not: it retains source document/clause/page/byte
provenance and can emit the same source-backed structure to four target
formats. LFortran currently does something our export does not: it supplies a
working lexer/runtime interface, typed semantic values, precedence/actions and
a declared Bison conflict budget. Neither side is treated as automatically
correct; a future case where the source-backed projection is more faithful or
more auditable than the reference is recorded as a `standardir_advantage`,
with the reference body and an independent witness beside it.

The checker recomputes SHA-256 over the canonical SX serialization of each
source RHS alternative, distinguishes repeated rule occurrences by byte span,
checks all four generated formats, and requires a mutation to fail. It is an
independent identity witness, not yet a language-equivalence or parser-runtime
witness. The baseline is expected to report missing expression fields until
the corresponding generic production slice is merged.

The required Luna review is `reviews/R000310-luna.md`. It independently
confirmed the three identity defects and found a fourth projection gap: the
generic nullable-reference normalization removes source optionality from
R1404/R1416. That transformation may be language-preserving, but this replay
does not prove it. It must either be retained for the exact-source gate or
receive a generic target-body/language-preservation witness.

## R000311: the first repair still hashes after lexical normalization

The replay used `standard-new` `cdec3fa` and the updated independent checker.
All four exports were present; ANTLR4, Bison and tree-sitter accepted them; the
negative mutation was rejected. The exact source gate nevertheless failed:

* 1,068 source alternatives were the denominator and 1,053 were covered in
  each format;
* eight Unicode-bearing alternatives still had wrong source hashes in the
  emitted target annotations because the closure pipeline had already applied
  lexical canonicalization before the typed adapter computed its hash;
* seven source alternatives were absent from the target lineage, including
  R401--R403 generated-helper cases and four additional transformed cases
  (R1028 and R1323, plus both R1221 alternatives);
* target-expression hashes were now emitted separately and the merged-lineage
  buffers were no longer truncated;
* Bison still reported 427 shift/reduce and 2,266 reduce/reduce conflicts.

This is a more precise failure than R000308. The standalone UTF-8 path and
capacity tests pass, but they do not cover the actual pre-adapter lexical
rewrite. D0096 therefore makes the next production boundary explicit: capture
the raw source witness before any target normalization, preserve every source
alternative through merged/factored targets, and emit a typed source-
preservation witness for alternatives without a one-to-one target body. The
parser-generator PASS results remain subordinate and do not close E0154.

The required Luna review is `reviews/R000312-luna.md`. It confirms the raw
source/target diagnosis and the bidirectional comparison: provenance and
four-format projection are genuine StandardIR advantages, while executable
lexer/runtime behavior, typed values, precedence/actions, factoring and
conflict policy remain genuine reference advantages. It also caught a lab
bookkeeping label in `run-selected.sh`; the 522 count is now named
`source-syntax-records`, while the independent denominator remains 1,068
source alternatives.
