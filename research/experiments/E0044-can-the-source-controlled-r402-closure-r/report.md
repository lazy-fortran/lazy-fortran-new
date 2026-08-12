# E0044. Source-controlled R402 suffix-name closure

## Question

Can the source-controlled R402 closure resolve every absent suffix-name term
without overriding an explicit StandardIR definition?

## Method

The analysis command consumes the pinned complete-core StandardIR SX, canonical
text, E0022 unresolved-reference audit, the E0043 witness seed, and one
source-controlled R402 pattern:

```text
research/experiments/E0044-can-the-source-controlled-r402-closure-r/analyse.sh
```

The pattern selects every unresolved audit term whose spelling ends in
`-name`. R402 states that `xyz-name` is `name` when `xyz` stands for a
syntactic class phrase. The analysis independently extracts StandardIR
left-hand sides and rejects the closure if any selected term already has an
explicit definition. The original semantic role is retained in each alias
record. The comparison grammars are not used as resolution sources.

## Result

The command produced 182 typed resolution records. The records contain 49
R402 aliases, 4 lexical classes, 1 metavariable, 128 unresolved records, and 0
semantic-role or disputed records. All 182 rows carry the pinned J3/24-007
source hash. The explicit-definition conflict count is 0.

The independent closure difference is 0. The alias projection contains 49
records and 94 syntax witnesses. The controlled `module-name` mutation
observed the expected validation failure. The generated ANTLR4 projection is a
partial artifact because the remaining 128 unresolved terms and lexical
details have not been adjudicated.

## Boundary

R402 supplies a source-controlled structural rule for absent suffix-name
terms. It does not establish the semantic role of a name, scope resolution, or
the remaining composite grammar. The next slice must address lexical tokens,
assumed list and scalar rules, punctuation references, and any disputed source
extractions before a complete parser input can be claimed.
