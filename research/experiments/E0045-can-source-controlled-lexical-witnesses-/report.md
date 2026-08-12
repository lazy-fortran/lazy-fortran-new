# E0045. Source-controlled lexical operator and literal-marker witnesses

## Question

Can source-controlled lexical witnesses close the unresolved operator and
literal-marker references without normalizing Unicode or punctuation by
guesswork?

## Method

The analysis command consumes the pinned complete-core StandardIR SX, canonical
text, E0022 unresolved-reference audit, the E0043 witness seed, and a
source-controlled lexical seed:

```text
research/experiments/E0045-can-source-controlled-lexical-witnesses-/analyse.sh
```

The seed covers the special-character references `%`, `.`, and `..`, intrinsic
operator spellings, logical literal spellings, and the `.NIL.` token. The
analysis checks the normative table or rule for each group, projects the
selected references to lexical tokens, and leaves the extracted en dash and
right single quotation mark unresolved. No Unicode normalization is introduced.

## Result

The command produced 182 typed resolution records. The records contain 3
aliases, 25 lexical classes, 1 metavariable, 153 unresolved records, and 0
semantic-role or disputed records. All 182 rows carry the pinned J3/24-007
source hash. The lexical projection contains 21 selected records and 34 syntax
witnesses. The independent difference is 0 and the controlled `.AND.` mutation
observed the expected validation failure.

The generated projection maps the selected source spellings to token forms in
the partial SX input. The two excluded Unicode terms remain unresolved. They
need an explicit source representation decision before they can enter a
normative token projection.

## Boundary

This result closes direct lexical witnesses for the selected operators and
literal markers. It does not resolve assumed list and scalar expansions,
punctuation whose extracted glyph needs adjudication, semantic roles, or the
remaining composite grammar.
