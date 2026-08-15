# E0162 findings

## Scope

This experiment is a structural adjudication after the corrected E0157 audit.
It compares the selected `program` baseline from E0161 with the opt-in
`data-ref` role-family projection from E0160. It does not copy productions from
the comparison grammars and it does not claim language equivalence.

The corrected E0157 audit was rerun against the exact pinned LFortran commit,
not the newer working checkout:

```text
git -C /home/ert/code/lfortran-12385 show \
  caf87b660f803148f000046392a5da803f9fc630:src/lfortran/parser/parser.yy \
  > .cache/runs/E0162/reference/parser.yy

research/experiments/E0157-current-cross-format-and-llvm-reference-audit/analyse.sh \
  .cache/runs/E0161/R000338 ... .cache/runs/E0162/reference/parser.yy ... \
  .cache/runs/E0162/R000344
```

The candidate replay is identical except for the E0160 role-family run and is
`R000345`. Both corrected upstream audits pass source identity, lexical gate,
source projection, ANTLR4, Bison and tree-sitter validation. Each covers
1,068/1,068 source alternatives and retains equal lineage sets across all four
formats, with seven explicit selected-root omissions.

## Four generated formats

The independent E0162 analyser is:

```text
research/experiments/E0162-can-all-four-standardir-grammar-projecti/analyse.py \
  .cache/runs/E0161/R000338 .cache/runs/E0162/R000344 \
  .cache/runs/E0160/R000337 .cache/runs/E0162/R000345 \
  /home/ert/code/standard/grammars/src/Fortran2023Parser.g4 \
  /home/ert/code/kaby76-fortran/comp/Fortran2023Parser.g4 \
  .cache/runs/E0162/reference/parser.yy \
  /home/ert/code/llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  .cache/runs/E0162/R000346
```

The results are:

| variant | EBNF | ANTLR4 | Bison | tree-sitter |
| --- | ---: | ---: | ---: | ---: |
| baseline raw heads | 659 | 659 | 1,337 | 669 |
| role-family raw heads | 655 | 655 | 1,333 | 665 |
| baseline canonical heads | 659 | 659 | 1,337 | 666 |
| role-family canonical heads | 655 | 655 | 1,333 | 662 |

The canonical EBNF and ANTLR4 head sets are exactly equal in both variants.
Bison adds 672 deterministic `h_*` lowering helpers plus six target wrapper
heads. Tree-sitter adds seven lexical wrapper heads. These are target
projection scaffolding, not missing or extra normative productions. The
role-family candidate removes four canonical source heads consistently in all
four formats while retaining all source alternatives and lineage; that is an
opt-in target projection choice, not a correction to StandardIR.

The full rows and hashes are in
`.cache/runs/E0162/R000346/head-inventory.tsv` and
`.cache/runs/E0162/R000346/internal-comparison.tsv`.

## Pinned references

The exact reference hashes used by R000346 are:

```text
house ANTLR4  d8bb1b600e30be245a2d8c87e32660a3b4ad83aa94728cf50cebf37c1e8b67ce
kaby76 ANTLR4 8f1f55ee4f61f82d732d41bd9452917bc1ce293f64e19615649a5170fb2705a8
LFortran Bison 112ef0ce5078ccec630a893bc51b92232348c37742b1451c833928a422907936
Flang parser abb4126d6c0c4e516628ba9836c428f83f0ccf883439e67cbfdd061aa42d83b9
```

The structural inventories are 57 house heads, 646 kaby76 heads, 237 pinned
LFortran Bison heads and 195 Flang `R<number>` comment occurrences. Exact head
names are a useful first correspondence only:

| reference | shared canonical names with baseline | interpretation |
| --- | ---: | --- |
| house ANTLR4 | 5 | F2023 extension/inheritance and a narrow local file; not a full denominator |
| kaby76 ANTLR4 | 638 | closest head inventory, but still factors names and list forms differently |
| pinned LFortran Bison | 34 | parser-oriented factoring, actions and implementation categories dominate |
| Flang rule comments | 194 unique rule IDs | source-rule anchors; comments are not production heads |

The candidate changes only the source-side head count: the same references are
still structural comparisons, not an oracle for StandardIR. The E0149 matrix
remains the manual adjudication layer for genuine advantages on either side.

## Adjudication

E0157's required minimal Luna review is already recorded as
`research/experiments/E0157-current-cross-format-and-llvm-reference-audit/reviews/R000322-luna.md`.
It accepted the corrected inventory as strong
selected-profile provenance evidence while rejecting any language-equivalence,
semantic or behavioral claim. E0162 preserves that boundary and adds the
explicit target-scaffolding classification above.

E0162 is therefore reported. The next gate is parser quality: classify the
selected Bison conflict states against LFortran's declared policy, then test a
generic factoring/precedence transformation with an independent language
corpus. No semantic extraction, LLM experiment, model comparison or backend
work is resumed by this result.
