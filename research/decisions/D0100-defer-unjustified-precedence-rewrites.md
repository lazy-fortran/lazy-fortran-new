# D0100. Keep GLR and defer unjustified precedence rewrites

Date: 2026-08-15
Status: accepted

## Context

The trusted selected `program` export reports 427 shift/reduce and 2,266
reduce/reduce conflicts. The pinned LFortran parser is also GLR and declares
238 and 180 conflicts, but it additionally has typed semantic actions, parser
factoring and 11 precedence directives. The generated StandardIR grammar has
the normative precedence-shaped nonterminals, yet it does not currently have
target precedence annotations or semantic actions.

The first generic role-family projection is independently behavior-preserving
on a bounded corpus and reduces the selected inventory to 425/2,135, but it
worsens the all-roots inventory to 760/3,894. A precedence-only target probe
left the selected conflict totals unchanged and produced useless-precedence
diagnostics.

## Decision

Keep the source-backed GLR Bison export as the default. Retain role-family
factoring as an opt-in selected-profile projection only. Do not add precedence
declarations, `%expect` budgets, or semantic actions until a generic
source-derived transformation identifies the affected productions and passes
source-lineage, parser-generator, all-root/selected and independent positive /
negative language gates.

The next parser-quality work is therefore to improve the executable lexer and
runtime contract and broaden the independent corpus. A lower conflict count
alone is not a promotion criterion.

## Rejected

* Copying LFortran's precedence declarations, actions or conflict numbers.
* Adding precedence declarations that do not affect a conflict state.
* Hiding unresolved conflicts with `%expect` declarations.
* Promoting selected-only role factoring to all roots.
* Treating GLR generator acceptance as language equivalence.

## Evidence

* E0159/R000368: current conflict-state inventory and LFortran `%expect`
  comparison.
* The current E0155 target-control replay: generated versus LFortran
  inventory, including 0 versus 11 precedence directives and 0 versus 1,902
  action braces. The exact current report is
  `.cache/runs/E0169-lfortran-comparison.tsv`.
* E0163/R000347: generic role-family factoring and independent 359-positive /
  636-negative language gate.

## Reversal condition

Write a successor if a source-derived, production-specific precedence or
factoring projection changes the relevant parser states, preserves the
complete source lineage and passes independent all-root and selected language
witnesses without introducing useless diagnostics or a broad conflict increase.
