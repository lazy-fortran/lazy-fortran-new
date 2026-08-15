# E0148 adjudication: StandardIR against pinned LFortran Bison

Run the deterministic inventory with:

```text
research/experiments/E0148-compare-source-backed-standardir-grammar/analyse.sh \
  .cache/runs/E0148/R000001
```

The command writes the counts and replay logs. The exact inputs are the
source-backed E0147/R000016 exports and the BSD-3-Clause LFortran
`src/lfortran/parser/parser.yy` blob at commit
`caf87b660f803148f000046392a5da803f9fc630`. LFortran is an independent
comparison implementation. Its productions are not copied into StandardIR.

The deterministic inventory is exhaustive over every syntax record and token
atom in the selected StandardIR input, every identical duplicate-body group,
the pinned LFortran terminal declarations, and both the all-roots and selected
`r_program` Bison replays. It is not a claim that two independently designed
Fortran parsers have pairwise-equivalent rule names: LFortran intentionally
accepts partial sources and extensions and factors the language differently.

For a direct PDF witness, regenerate the relevant pages with:

```text
pdftotext -f 69 -l 69 -layout .cache/j3-24-007.pdf -
pdftotext -f 81 -l 81 -layout .cache/j3-24-007.pdf -
pdftotext -f 85 -l 85 -layout .cache/j3-24-007.pdf -
pdftotext -f 114 -l 114 -layout .cache/j3-24-007.pdf -
pdftotext -f 141 -l 141 -layout .cache/j3-24-007.pdf -
pdftotext -f 170 -l 170 -layout .cache/j3-24-007.pdf -
```

For the pinned comparison line numbers, regenerate with:

```text
git -C ../lfortran-12385 show \
  caf87b660f803148f000046392a5da803f9fc630:src/lfortran/parser/parser.yy \
  | nl -ba
```

## Defects still present

### F001: typographic en dash has no canonical source-token alias

The current StandardIR contains U+2013 EN DASH as a `(token ...)` in R1010,
R712 and R868. The generated Bison target declares and emits `EN_DASH`; the
tree-sitter target emits a U+2013 terminal as well. Fortran source uses the
ASCII minus character. The pinned LFortran grammar declares `TK_MINUS "-"`
and uses `-` in its precedence and expression rules.

This is a real target-lexical defect, not a disagreement about the normative
production. The PDF glyph must remain in source provenance, but the canonical
syntax projection needs a deterministic alias to `-`. The alias must be
represented in typed lexical metadata so a future source audit can distinguish
the PDF glyph from the source spelling.

The inventory reports the exact occurrence count and source locations in
`glyphs.tsv`; regenerate it with the command above.

### F002: typographic right quote has no canonical character-literal alias

The current StandardIR contains U+2019 RIGHT SINGLE QUOTATION MARK as the
delimiter in R724, R773, R774 and R775. The generated projections therefore
accept the typographic code point rather than the ASCII apostrophe used in
Fortran character and BOZ constants. LFortran represents character literals
through its `TK_STRING` tokenizer token and does not use U+2019 as a source
delimiter.

This is a real target-lexical defect. Preserve the PDF glyph in provenance,
but project it to the canonical ASCII apostrophe delimiter (or an explicitly
named canonical delimiter whose lexer spelling is ASCII apostrophe). The
mapping must be generic and source-position independent.

The inventory reports all occurrences in `glyphs.tsv`; regenerate it with the
command above.

## Projection gaps exposed by the comparison

### F003: repeated source occurrences are emitted as repeated alternatives

The source contains repeated, identical rule occurrences. The current target
normalizer preserves them because their source spans differ. That is correct
for occurrence provenance, but the generated Bison output repeats the same
alternative instead of merging the target alternative and carrying both source
occurrences in one explicit merged-lineage record. This is output hygiene and
provenance design, not evidence that the PDF has two different productions;
the current output does retain each separate source lineage.

The complete duplicate inventory is `duplicate-occurrences.tsv`; regenerate it
with the command above. The production fix should merge only structurally
identical target alternatives and retain every source occurrence in the merged
provenance. It must not deduplicate conflicting bodies.

### F004: the default Bison start symbol is a closure validator

The E0147 export starts at `standardir_start` and lists every profile root so
that all source-backed records are reachable for validator and provenance
checks. LFortran starts at one full-program entry, `units`. A separate replay
with `r_program` demonstrates the behavior of a selected production root.

The all-roots grammar must remain available as a validation artifact, but it
must not be presented as the production parser export. The generator needs an
explicit selected-root mode, with root completeness and reachability reported
separately. The selected root is a configuration choice, not an LLM decision.

### F005: unreachable normalized helpers remain in a selected-root export

When the generated grammar is replayed with `r_program` as its start symbol,
Bison reports unreachable normalized helpers and their retained source
productions. Some are intermediate records introduced for generic left
recursion normalization. They are not necessarily source defects, but the
output is not clean: a selected-root export should either emit only its
reachable closure or emit explicit deterministic suppression records for
unreachable normalized records.

The exact Bison warning and conflict inventory is in
`standardir-program-root.stderr`; regenerate it with the command above.

### F006: parser-generator acceptance is not language equivalence

E0147's body-bound witness proves that retained target bodies have source
lineage and that a mutation is detected. It does not prove that generic
normalization such as left-recursion removal, inlining or nullable-wrapper
simplification preserves the accepted language. The LFortran comparison makes
this boundary visible, but LFortran itself cannot serve as the normative
language-equivalence oracle because it has a different decomposition and
deliberate extensions.

The next production gate therefore needs generic witness cases for each
normalization class: a source expression, its target expression, and a bounded
accept/reject corpus or equivalent derivation witness. No Fortran rule number
may be hard-coded into that gate.

## Expected differences, not defects

The following disagreements are real differences but must not be “fixed” by
copying LFortran into StandardIR:

* LFortran's `units`/`script_unit` accepts isolated declarations, statements
  and expressions because it is also an interactive and partial-source parser.
  StandardIR R501/R502 define a complete program-unit structure, including an
  optional main-program statement.
* LFortran's module, submodule and block-data rules use implementation
  nonterminals such as `decl_star`, `contains_block_opt` and `sep`; StandardIR
  names the normative parts and their exact optionality. The shapes are not
  interchangeable.
* LFortran accepts extensions such as `:=`, templates, unions and additional
  parser conveniences. These are comparison-only extensions.
* LFortran factors expressions into one precedence-directed `expr` rule with
  Bison declarations. StandardIR retains the numbered precedence ladder.
  The target generator may lower the ladder generically, but the lowering
  needs a language-equivalence witness.
* LFortran's `designator` combines array, function, substring and coarray
  cases for AST construction. StandardIR separates normative categories such
  as array-element, array-section, coindexed object and substring.
* LFortran uses a tokenizer-level string token and does not reproduce every
  lexical fact as a Bison production. That is an architectural difference,
  not evidence that StandardIR may discard its source-backed lexical facts.

## Prior critique items checked and now stale

The earlier independent critique was based on an older E0013 extraction. In
E0147/R000016, R741, R843, R1103, R1307 and R1417 contain their complete
source-backed bodies. The previously reported malformed token examples for
R721, R760, R808, R870, R1044, R1048, R1123, R1179, R1222, R1302 and R1315
are also corrected there. The old critique must remain historical evidence,
but those items are not current defects.

The current blockers are therefore the two lexical alias defects and the
three generic projection/gate gaps above. The Bison conflict counts are
diagnostics, not a reason to alter normative StandardIR or to hand-tune
Fortran-specific conflict resolutions.
