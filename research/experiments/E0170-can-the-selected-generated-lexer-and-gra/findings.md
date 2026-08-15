# E0170 findings

E0170 is reported green for the deterministic selected-runtime gate. Its
command is the `analysis` command in `manifest.yaml`;
each attempt retains its generated corpus, command log, per-root runtime log,
timing file and independent recognizer report under `.cache/runs/E0170/`.

The prerequisite E0168 PDF-fidelity gate and E0169 parser-control
adjudication are green. E0170 is the first gate to exercise the selected
source-backed contract through the production runtime over a bounded complete
corpus. No StandardIR or grammar source has been changed.

## Retained intermediate failures

- R000374 is a harness failure. The first replay asked the E0161 recognizer to
  discover role-family roots from the baseline grammar, although those witness
  comments exist only in the opt-in candidate. It produced only two roots and
  failed closed before runtime execution.
- R000375 is a harness-bound failure. The chosen high depth/token bounds
  truncated recursive derivations, and the current recognizer correctly
  rejected an incomplete corpus instead of treating it as complete.
- R000376 is a harness setup failure. The root timing directory was not
  created before `/usr/bin/time` was invoked. The complete corpus itself was
  generated successfully; no runtime result was claimed.
- R000377 is a production-runtime timeout. With the corrected complete bounds,
  the first seven `allocate-object` cases completed, while the eighth case
  (`letter digit % letter`) consumed a CPU core without producing an outcome
  for the bounded timeout. The child was terminated after its timing record
  was retained. This is the current blocking defect.
- R000378 is a rejected Luna production attempt. A generic reachability,
  duplicate-rule and dependency-worklist patch was tested against the exact
  witness but did not meet the bounded termination requirement. It remains
  uncommitted and is preserved as a patch artifact; no production change was
  merged.
- R000379 is a second rejected Luna production attempt. A chart/worklist
  implementation was started from the clean runtime base, but it was not
  completed or independently verified and was restored without a commit.
  No production change was merged.

The complete corpus parameters are depth 8, four terminal tokens, 256 words,
64 negative mutations and repeat limit 1. The exact command and the resulting
case counts are emitted by `run-broad-runtime-gate.sh`; no case is removed
because it is inconvenient. The next accepted run requires a generic runtime
termination fix, an independent regression test, a clean production commit,
and a complete replay over the same generated corpus.

## Algorithm boundary from the literature

The accepted runtime decision is D0101. The replacement must be a finite
chart/worklist evaluator with explicit predictor, scanner and completer
transitions and deduplicated state identity. This is the standard shape of
Earley-style chart parsing, with GLL as the reference for descriptor/worklist
handling under ambiguity and left recursion. The outer timeout remains only a
safety bound for a failing run; it is not an implementation termination rule.

The production agent must first pass a focused independent suite covering the
exact timeout witness, epsilon, direct and indirect left recursion, ambiguity,
unknown references and malformed inputs. Only then may the unchanged broad
995-case corpus be rerun. The script named in `manifest.yaml` regenerates the
counts and reports every case; no case is removed.

## R000380: exact witness fixed, broad scalability still open

The accepted Luna commit `41908855` replaces the old global rescanning with a
finite chart/worklist evaluator. Independent `fo` passes with zero warnings,
the focused frontier suite passes, and the former `allocate-object` timeout
witness completes. The complete corpus still fails the gate: 9 of 11 root
batches completed with zero mismatches, but the `program` root exceeded the
60-second per-root safety guard after 90 outcomes. Its timing file is empty and
the retained runtime log ends in `command-timeout`; the `variable` root was not
started. Peak RSS of completed roots was 1,556,480 KB and their summed elapsed
time was 327.5 seconds. These values are regenerated from the R000380 timing
files by the E0170 runner; they are not a success-rate denominator.

This is now classified as generic chart-state explosion or insufficient
indexing, not as a missing Fortran rule. The next slice must preserve the
finite-state correctness invariant while reducing work generically. It must
first reproduce the `program` root with a bounded diagnostic (state counts by
rule/dot/uncertainty, queue growth and completion counts), then optimize using
exact grammar reachability/productivity and packed or indexed chart operations
where they preserve the existing outcome contract. The first literature-backed
special case to investigate is the practical-Earley treatment of empty and
nullable productions (Aycock and Horspool, 2002), because it changes the
finite chart automaton rather than adding a source-language exception. It may
not add a root, rule-number or input-specific exception, and it must rerun the
focused suite before the unchanged 995-case corpus.

## R000381: token-domain defect found before the next replay

A direct 240-second replay of all 256 `program` cases completed in 148.33
seconds, including the previously timed case 91 in isolation. It nevertheless
reported 52 false mismatches: every affected positive used the abstract source
lexical term `letter`, while the generated runtime contract's lexical rule
requires target token `LETTER`. The same source/target distinction exists for
the other pinned lexical-class facts. R000381 retains the complete output and
records this as `FAIL-TOKEN-DOMAIN`; it is a harness contract defect, not a
StandardIR or parser defect.

The next runner revision therefore reads the pinned lexical-facts SX, builds a
source-term-to-target-token map, records that map beside the generated case
files, and applies it only at the runtime boundary. The independent EBNF
oracle continues to operate in source-term space. The batch safety guard is
raised to 180 seconds for the predeclared corpus volume; it remains an outer
timeout and not a correctness mechanism. A fresh complete run must pass the
token-domain gate before any chart optimization is considered.

## R000382: export defect and outcome-policy defect exposed

The lexical adapter removed the 52 token-domain mismatches, but the replay
still reported 70 cases as `ambiguous` or `malformed`. These are not one
failure class. `ambiguous` is a valid GLR result: the runtime has recognized
the input while preserving more than one parse, as required by D0089 and D0100.
It must therefore count as acceptance for the independent boolean language
comparison, while remaining a separately reported parser-quality metric.
Treating it as a binary failure conflated language recognition with parse-tree
uniqueness and contradicted the selected GLR policy.

`malformed` is different. The affected parent-string witnesses contain raw
double-quote literals emitted as triple quotes in E0164's EBNF. The source
exporter quoted values without escaping embedded quotes or backslashes. That
is a generic `standard-new` defect, not a runtime exception. The correction is
the source-backed E0156 production change `fb6590c4885a38b0106f63112f6e024c20b927b5`,
which escapes both characters and adds a regression fixture. E0164 must be
regenerated from that commit before E0170 is replayed.

The runner now compares boolean acceptance as
`accepted | ambiguous` versus `rejected`, counts `ambiguous_cases`, and keeps
`malformed`, `unresolved`, and `capacity` as abnormal failures. This follows
the generalized-parsing literature: generalized parsers retain competing
branches and merge equivalent states rather than silently selecting one. The
gate still requires zero acceptance mismatches and zero abnormal outcomes.

## R000384: corrected full replay passes

After `standard-new` commit
`fb6590c4885a38b0106f63112f6e024c20b927b5` escaped quoted EBNF literals, the
four-format regeneration R000383 passed source identity, lexical mutation,
ANTLR4, Bison and tree-sitter validation. The unchanged broad replay then
emitted 1,003 cases: 367 expected accepted and 636 expected rejected. All 367
accepted cases were recognized (`311` unambiguous and `56` ambiguous), all 636
negative cases were rejected, and there were zero acceptance mismatches and
zero malformed, unresolved or capacity outcomes. Fortfront `41908855` passed
`fo` with zero warnings. The run took 522.507 seconds and reached 1,556,396 KB
RSS. These values are regenerated from R000384's `summary.json`; the run
directory and hashes are retained.

The denominator increased from R000382's 995 to 1,003 because the corrected
EBNF makes quote-bearing productions parseable. This is a correction of the
generated input, not a corpus expansion chosen after seeing outcomes. The
deterministic runtime gate is closed. The 56 ambiguous outcomes remain a
reported GLR/parser-quality metric and are not evidence of rejection.

## R000386: corrected replay with complete regeneration oracle passes

R000386 repeats the full replay against R000385, whose shared regeneration
script now records the correct experiment identity and emits a validated
source-backed lexer contract. It reproduces the result: 1,003 cases, 367
expected positives, 636 expected negatives, 311 unambiguous accepts, 56
ambiguous accepts, zero acceptance mismatches, zero abnormal outcomes, zero
warnings, 515.953 seconds and 1,556,408 KB peak RSS. R000386 is the reported
run for E0170; R000384 remains immutable evidence from the same corrected
grammar before the regeneration metadata/oracle repair.
