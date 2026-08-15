# E0154 current state

The historical baseline remains intentionally failing. Its exports carry
source rule, location and lineage comments, but not an independently
recomputable identity for the exact RHS alternative. The current replay is
run with:

```text
research/experiments/E0154-can-exact-source-expression-identity-and/run-selected.sh \
  .cache/runs/E0154/R000314 program
```

`run-selected.sh` first runs the source-only preflight, then regenerates all
four projections, then invokes the independent checker, and invokes parser
oracles only after that checker passes. `analyse.sh` remains the checker-only
entry point for an existing run directory.

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

## R000313: raw witnesses close the source identity gate

The generic repair is `standard-new` `83f055d`. It captures the raw RHS
fingerprint before lexical target normalization, seeds a typed source witness at
the raw-to-target boundary, carries those witnesses through deduplication,
reference substitution and generated left-recursion helpers, and emits an
explicit witness for omitted selected-root declarations. The focused
independent check reports 1,068/1,068 source alternatives in each of the four
formats, zero missing/wrong rows, and a passing negative mutation control.

R000313 initially exposed a validator defect: EBNF's seven annotation-only
witnesses for six intentionally omitted declared roots were counted as
body-loss. The parser generators themselves all accepted the output. The audit
was corrected generically to distinguish `omitted-before-target-lowering`
witnesses from missing bodies.

## R000314: clean replay after the gate-order and audit fixes

The clean replay pins lab `65c7b69` and `standard-new` `83f055d`. The source
preflight passes before `fo` or any grammar generator is invoked. The independent
identity report then passes in all four formats: 1,068 expected, 1,068 covered,
zero missing/wrong rows, positive identity PASS and negative mutation PASS.
ANTLR4 4.13.2, Bison 3.8.2 and tree-sitter 0.26.9 all accept their generated
formats; the source-projection audit and its negative control pass. Bison still
reports 427 shift/reduce and 2,266 reduce/reduce conflicts. That is an open
parser-quality gate, not a source-identity failure.

No LLM or semantic experiment is resumed by this result. The next comparison is
E0155, which records the corrected bidirectional LFortran Bison comparison and
keeps executable-parser, conflict-policy and language-equivalence work open.

## R000318: raw-witness and canonical-lexical gates close

The replay uses `standard-new` `bedd9abc7210fc7fc16607d275ea4fa7b24144f8` and
lab `9618213`. Source preflight passed before `fo` or any grammar generator.
After the four projections were generated, exact source-expression identity
and the E0156 lexical-witness checker passed before ANTLR4, Bison and
tree-sitter were invoked.

The selected profile has 1,068 source alternatives and all four formats cover
1,068 with zero missing or wrong rows. Both positive identity and negative
mutation controls pass. The EBNF body contains zero U+2013/U+2019 occurrences;
all four formats retain source glyphs in provenance and emit their canonical
ASCII spellings. ANTLR4, Bison and tree-sitter accept the outputs. Bison still
reports 427 shift/reduce and 2,266 reduce/reduce conflicts; those are the next
parser-quality gate, not a source-identity failure.

This is a deterministic subgate only. It does not establish language
equivalence, executable lexer/runtime behavior, precedence/actions, conflict
policy, or quality relative to LFortran, Flang, GNU or the comparison ANTLR
grammars.

## R000323: first trusted all-root replay after PDF fidelity

The all-root replay uses `standard-new` `bedd9abc7210fc7fc16607d275ea4fa7b24144f8`
and lab `47a38c0`, with E0158/R000321 already accepted. Source preflight ran
before `fo` or any grammar generator. The four generated formats then passed
the independent source-expression identity gate and E0156's canonical lexical
witness gate before ANTLR4, Bison and tree-sitter were invoked.

The complete source denominator is 1,068 alternatives. EBNF, ANTLR4, Bison and
tree-sitter each cover all 1,068 with zero missing or wrong rows; positive
identity and negative mutation controls pass. The generated parsers are
accepted by ANTLR4 4.13.2, Bison 3.8.2 and tree-sitter 0.26.9. The all-root
Bison diagnostics are 758 shift/reduce and 3,885 reduce/reduce conflicts,
with no useless nonterminals, useless rules or undefined-symbol diagnostics.

This closes the post-fidelity source/projection replay, not parser quality.
The conflict diagnostics remain the next deterministic slice. Lexer/runtime,
precedence/actions, language preservation and positive/negative corpus
behavior remain open and are not inferred from parser-generator acceptance.

## R000353: fresh post-fidelity regeneration

R000353 repeats the all-root four-format generation after the authoritative
E0158/R000352 gate, using the current lab commit and standard-new
`bedd9abc7210fc7fc16607d275ea4fa7b24144f8`. Source preflight passes before
`fo`, and all four generators then complete. The independent identity and
lexical gates pass with their negative mutations; ANTLR4 4.13.2, Bison 3.8.2
and tree-sitter 0.26.9 accept the generated outputs.

The fresh output covers all 1,068 source alternatives in EBNF, ANTLR4, Bison
and tree-sitter, with zero missing/wrong identity rows and zero raw U+2013 or
U+2019 in executable grammar bodies. The fresh Bison diagnostics are 758
shift/reduce and 3,885 reduce/reduce conflicts; they are inventory evidence
for E0159, not a source-fidelity failure. Lexer/runtime behavior, conflict
resolution, language preservation and semantic/model work remain closed.

## R000365: current selected post-fidelity replay

R000365 repeats the four-format generation against the E0154/R000353 source
evidence after the current E0158/R000364 fidelity gate. Source preflight,
identity, lexical mutation and all three parser-generator oracles pass. The
selected profile covers 1,068/1,068 source alternatives in EBNF, ANTLR4,
Bison and tree-sitter. Its Bison diagnostics are 427 shift/reduce and 2,266
reduce/reduce conflicts, with zero undefined-symbol, useless-symbol or
useless-rule diagnostics. This is the current source/projection input for the
E0164 generated-runtime gate; it does not by itself establish language
equivalence.
