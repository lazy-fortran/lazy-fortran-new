# E0161 plan

E0160 established that the typed role-family projection can preserve source
lineage and pass all four format generators, but it did not establish parser
language preservation. E0161 is the narrow successor: selected-program
baseline and `data-ref` opt-in outputs will be compared on the same
independently enumerated positive and negative corpus.

The corpus generator must be independent of the role-family transformation.
The run is not authorized until its source commit, corpus manifest, and
positive/negative denominator are pinned. The existing E0154 source,
lexical, identity and mutation gates remain prerequisites. Bison conflict
counts are diagnostic only. A lower count cannot close this experiment.

No lexer/runtime, precedence, semantic, model, plot or backend work is part of
this experiment. Those are later slices after the language gate is green.

## Result

R000338 is the fresh selected-program baseline. Its source, lexical, identity,
four-format and parser-generator gates pass. R000340 compares it with the
typed `data-ref` projection in R000337 using the independent EBNF parser and
recognizer in `compare_language.py`. The runner discovers the role-family
source names from the generated witness comments and selects every common
production that references one of them; no Fortran rule number is named in the
oracle.

The complete bounded corpus contains 359 positive derivations and 636
negative mutations. All baseline positives are accepted by the candidate, all
candidate positives are accepted by the baseline, and no candidate accepts a
baseline-rejected negative. The bounds are depth 8, four terminal tokens,
repeat limit 1, and at most 256 derivations per context; the report confirms
that no context was truncated. The lexical terminals left without EBNF
productions are reported explicitly (`letter`, `digit`, `rep-char`, `-` and
the apostrophe), rather than silently treated as missing grammar rules.

R000339 is retained as a timeout: the first broad sweep used depth 20 and 16
tokens and was stopped after the recognizer became impractically slow. This
prompted the bounded complete-corpus limits above; it is not an accepted
language result.

This closes the E0161 selected-profile bounded language gate. It does not
prove complete Fortran equivalence, lexer/runtime behavior, or parity with
LFortran's conflict policy. Those require the next differential and runtime
slices.
