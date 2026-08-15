# E0157 plan

This is the successor to the historical E0152/E0153 inventories. It will use
the first E0154 replay that passes E0156, not the old `c8ebb22`, `dc75e7f` or
`83f055d` outputs. The reproducible command will be:

```text
research/experiments/E0157-current-cross-format-and-llvm-reference-audit/analyse.sh \
  <current-post-E0156-run> \
  /home/ert/code/standard/grammars/src/Fortran2023Parser.g4 \
  /home/ert/code/kaby76-fortran/comp/Fortran2023Parser.g4 \
  /tmp/lfortran-pinned-parser.yy \
  /home/ert/code/llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  <E0156-lexical-report> \
  <report-dir>
```

The script checks the existing source-expression and grammar-oracle reports,
then inventories each generated format and each pinned reference. It also
records a fixed feature matrix for modern Fortran constructs and Flang's
source rule-comment inventory. It never copies reference productions.

The expected comparison is deliberately two-sided. StandardIR can be better
on source lineage, exact cross-format identity, source-root disposition and
normative feature coverage. The references can be better on executable lexer
integration, parser factoring, actions, precedence, conflict policy and
implementation-oriented runtime behavior. A lower or higher head count alone
does not establish either result.

## R000319: current deterministic comparison

The report was generated from E0154/R000318 after its source, identity and
lexical gates passed:

```text
research/experiments/E0157-current-cross-format-and-llvm-reference-audit/analyse.sh \
  .cache/runs/E0154/R000318 \
  /home/ert/code/standard/grammars/src/Fortran2023Parser.g4 \
  /home/ert/code/kaby76-fortran/comp/Fortran2023Parser.g4 \
  /tmp/lfortran-pinned-parser.yy \
  /home/ert/code/llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  .cache/runs/E0154/R000318/lexical-witnesses.tsv \
  .cache/runs/E0157/R000319
```

The independent report passes source identity, lexical witnesses, all three
target parser validators, reference hashes and exact equality of the four
generated lineage sets. The generated inventories are 659 EBNF heads, 659
ANTLR4 heads, 1,337 Bison heads, 669 tree-sitter heads and 1,111 common
source-lineage values. The Bison excess is generated helper/lowering
structure; the tree-sitter excess is its lexical rule layer. These counts are
not language-equivalence metrics.

The pinned comparison inventories are 57 house ANTLR4 heads, 646 kaby76
ANTLR4 heads, 237 LFortran Bison heads and 195 distinct `R<number>` comments
in Flang's parser source. The selected `program` profile intentionally omits
unreachable bodies for FAIL IMAGE, NOTIFY WAIT, SELECT RANK and FORM TEAM;
their source-backed witnesses remain in all four outputs. This is a
`selected_profile_gap`, not evidence that StandardIR lost those source rules.
The next all-root/profile gate must exercise those bodies before claiming
feature coverage at parser level.

The genuine StandardIR advantages observed here are normative document,
clause, page, byte-range, source hash and alternative lineage on every
generated format; exact 1,068-source-alternative identity; one source
projection producing four validator-accepted formats; and explicit
source-root disposition. The genuine reference advantages are executable
lexer/runtime integration, parser factoring, typed semantic values, actions,
precedence and declared conflict policy. LFortran's pinned Bison file also
regenerates with its declared 238 shift/reduce and 180 reduce/reduce conflict
budget, whereas the current generated Bison output reports 427 and 2,266.
No reference production was copied and no equivalence claim is made.

## R000322: historical corrected audit and Luna adjudication

R000319 is retained as the first inventory result, but its report directory was
superseded after the audit checker itself was reviewed. R000322 is the
immutable corrected replay at lab `207a3a4` and `standard-new`
`bedd9abc7210fc7fc16607d275ea4fa7b24144f8`.

The corrected detector normalizes target quoting and token wrappers before
testing fixed feature witnesses. FAIL IMAGE, NOTIFY WAIT, SELECT RANK and FORM
TEAM are present in all four generated bodies; no false selected-profile gap
remains. The summary separately reports 1,068/1,068 identity coverage and
1,061/1,068 emitted bodies with seven explicit selected-root omissions. The
feature matrix remains a lexical presence inventory: `both` means present in
at least one generated and at least one reference body, not universal support.

Luna's earlier minimal independent review is
`reviews/R000322-luna.md`. Its adjudication is accepted: E0157 is strong
source/provenance evidence for the selected profile, but it is not a semantic,
behavioral or language-equivalence proof. It also identified a remaining audit
boundary: source-projection and lexical status are consumed as upstream gate
reports, not independently re-derived by E0157. Those checks remain explicit
earlier gates; E0157 does not promote them into a second authority.

## R000324: source-lineage replay (preliminary record)

R000324 reruns the audit after correcting two independent counting/derivation
defects in the checker itself. The tree-sitter head parser now accepts only
`r_*: $ =>` declarations. It therefore reports 664 grammar heads; the five
uppercase lexer definitions (`LETTER`, `DIGIT`, `REP_CHAR`, `EN_DASH` and
`RIGHT_SINGLE_QUOTE`) are not counted as grammar rules. The report keeps
1,111 all-metadata lineage values and 1,107 emitted-body lineage values
separate.

The feature matrix is now derived from parsed StandardIR `syntax` records:
each feature has explicit normative `lhs` families and source rule IDs, and a
generated format is present only when one of those IDs occurs in emitted
source-lineage metadata. It no longer searches generated or source text for
terminal words. Reference columns remain structural rule-head witnesses and
are not normative claims. The replay passes source identity, all four target
validators, reference hashes, and the source-derived feature inventory. It
reports 1,068/1,068 source alternatives, 1,061/1,068 emitted bodies and seven
explicit omissions.

Luna's independent adjudication is recorded in
`reviews/R000324-luna.md`; the replay is accepted as a deterministic audit
correction, not as parser behavior or language-equivalence evidence.

The authoritative append-only run record for this replay is R000350. R000324
is retained as the preliminary record from before the run-ID correction; the
report and adjudication are unchanged.

## R000396: explicit reference-anchor replay

The audit no longer stores reference-name aliases in the Python checker. They
are now the reviewed experiment input
`reference-feature-anchors.tsv`, and its SHA-256 is recorded in the replay
summary and `hashes.tsv`. The input contains only observed grammar-head names
from the pinned reference files; it does not add productions to StandardIR.

The replay writes `reference-feature-anchors.tsv` in its report directory with
one row for every feature/reference pair. `MATCH` means that a declared
structural anchor was found. `NO_ANCHOR_DECLARED` means that this comparison
file has no mapped anchor; it does not mean that the reference lacks the
feature. The Flang column remains a separate source-rule-comment intersection.
The former `both` classification is now `source-and-reference-anchor`, which
states the actual evidence level.

The deterministic gates remain green: source identity 1,068/1,068, emitted
body coverage 1,061/1,068 with seven explicit profile omissions, equal
generated lineage sets, and ANTLR4, Bison, tree-sitter and source-projection
validators passing. This replay repairs audit transparency only; it does not
change the generated grammar or establish language equivalence.

Reproduce it with:

```text
research/experiments/E0157-current-cross-format-and-llvm-reference-audit/analyse.sh \
  .cache/runs/E0164/R000385-four-format-regeneration \
  ../standard/grammars/src/Fortran2023Parser.g4 \
  ../kaby76-fortran/comp/Fortran2023Parser.g4 \
  .cache/runs/E0162/reference/parser.yy \
  ../llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  .cache/runs/E0164/R000385-four-format-regeneration/lexical-witnesses.tsv \
  .cache/runs/E0157/R000396-anchor-input-replay
```

## R000354: fresh regenerated-output replay

R000354 repeats the corrected inventory against the fresh post-fidelity
E0154/R000353 output. It again reports 1,068/1,068 source alternatives and
equal generated lineage sets; the all-root EBNF and ANTLR4 projections have
665 canonical heads, Bison has 1,346 including generated helpers, and
tree-sitter has 670 `r_*` grammar heads with five uppercase lexer definitions
excluded. All four validators, the lexical gate, source projection and pinned
reference hashes pass. The feature matrix is still derived from StandardIR
rule IDs intersected with emitted source lineage.

Luna's minimal independent review is recorded in
`reviews/R000354-luna.md`. It accepts this as a bounded structural audit and
keeps full Fortran 2023 representation, language equivalence, and Flang
feature absence open.

## R000371: current post-fidelity replay and corrected Flang witness

The current replay uses the fresh E0154/R000365 four-format output and the
corrected `analyse.sh`. The tree-sitter inventory is 664 `r_*` grammar heads;
uppercase lexer declarations are excluded. EBNF and ANTLR4 each have 659
heads, and Bison has 1,337 including target helpers. All generated formats
cover 1,061/1,068 source alternatives with seven explicit unreachable skips and
zero missing alternatives. Their emitted source-lineage sets are equal, and
the four parser-generator/source-projection validators pass.

The generated feature matrix is source-derived: each feature's StandardIR
rule IDs are intersected with emitted lineage IDs. The Flang column is labelled
`flang_source_rule_comment_present` and intersects the same source rule IDs
with Flang's 195 retained `R####` comments. Two of 11 feature rows intersect.
That is a rule-comment witness, not a claim that the other features are absent
from Flang's implementation. Reference grammar columns remain structural head
witnesses because those files do not carry StandardIR lineage.

Luna's independent review is `reviews/R000371-luna.md`. It adjudicates the
corrected audit as a structural PASS and leaves parser behavior, semantics,
diagnostics, runtime behavior and language equivalence OPEN. The exact replay
command is:

```text
research/experiments/E0157-current-cross-format-and-llvm-reference-audit/analyse.sh \
  .cache/runs/E0164/R000365-four-format-regeneration \
  .cache/runs/E0152/R000001/references/house-antlr4 \
  .cache/runs/E0152/R000001/references/kaby76-antlr4 \
  .cache/runs/E0152/R000001/references/lfortran-bison \
  /home/ert/code/llvm-project/flang/lib/Parser/Fortran-parsers.cpp \
  .cache/runs/E0164/R000365-four-format-regeneration/lexical-witnesses.tsv \
  .cache/runs/E0167-audit-replay-v2
```
