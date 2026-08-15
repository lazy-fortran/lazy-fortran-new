# E0160 result

E0159 identified the selected role/name-family conflict family as the largest
structural reduce/reduce category, but it did not justify a grammar rewrite.
E0160 tests the already accepted generic role-family mechanism as an explicit,
opt-in target projection. The default source-backed export remains unchanged.

The deterministic production hook is merged and pinned at
`standard-new` `7d011f49e0e74e95b88a90c5894ea3358fc5ee82`. It accepts a
source-level StandardIR role-family representative such as `data-ref`; an
emitted target symbol such as `r_data_x2D_ref` is intentionally rejected by
the typed interface. The runner now places the role-family witness gate after
source identity and before ANTLR4, Bison and tree-sitter.

Two early failures remain as immutable evidence. R000332 used the emitted
target symbol and failed before generation. R000335 used the correct source
role but exposed a harness defect: the negative identity mutation selected a
role-family witness hash instead of the target-source-preservation hash. The
generic mutation selector was repaired; neither failure was deleted or
reclassified.

R000336 is the all-roots replay with `data-ref`. The source identity, lexical
witness, role-family lineage/consistency and negative mutation gates pass for
all four formats, followed by ANTLR4, Bison and tree-sitter. The role-family
witness has seven rows. Its Bison inventory is 760 shift/reduce and 3,894
reduce/reduce conflicts, compared with the baseline R000323 inventory of
758/3,885; this projection is therefore not an all-roots improvement.

R000337 is the selected-program replay with the same typed representative.
The same four-format and parser gates pass, with seven role-family witness
rows. Its Bison inventory is 425 shift/reduce and 2,135 reduce/reduce
conflicts, compared with E0159/R000329's 427/2,266 selected baseline. The
earlier exploratory factor probe reported ten useless nonterminals and 514
useless rules; the typed production path reports none. This is a promising
selected-profile projection, not yet a production policy: the full-profile
language and positive/negative corpus oracle has not run.

The next bounded experiment is E0161: compare baseline and opt-in selected
exports on an independently enumerated positive/negative parser corpus,
then add lexer/runtime behavior only after that language gate is green. No
semantic extraction, model comparison, plots or backend work is unlocked by
E0160.
