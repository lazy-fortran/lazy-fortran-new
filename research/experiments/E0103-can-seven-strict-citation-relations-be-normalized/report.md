# E0103 report

The analysis command is
`research/experiments/E0103-can-seven-strict-citation-relations-be-normalized/analyse.sh`.
It reads the ignored E0102 response and residue package, then writes the
ignored run tables under `.cache/runs/E0103/R000001`.

The independent negative-control command is:

```sh
research/experiments/E0103-can-seven-strict-citation-relations-be-normalized/test.sh
```

It changes one retained citation line in a temporary model-output copy,
requires `analyse.sh` to fail, and compares two positive summaries.

## Question

Can the seven relation rows accepted by the strict E0102 Luna citation gate be
normalized and classified from committed evidence without promoting any row
into StandardIR?

## Method

The denominator is the seven JSONL objects with `decision: relation` in the
ignored E0102 response. The audit reads those objects directly. E0102 summary
fields do not supply the denominator. Each relation name is retained exactly,
including a trailing comma. Explicit normalization removes only that final
comma for the StandardIR comparison.

Citation validation independently checks the canonical text line, page derived
from form-feed boundaries, source hash, and cited span. A separate traversal
re-extracts the relation rows and compares their name, normalized name, line,
and relation keys with the primary table. StandardIR `lhs` tokens are scanned
from the committed E0013 SX.

## Result

| Metric | Value |
|---|---:|
| Accepted relation rows | 7 |
| Exact source citations valid | 7 |
| Trailing-comma name artifacts retained | 6 |
| StandardIR lhs matches after normalization | 5 |
| Semantic/non-parser targets | 2 |
| Parser targets | 5 |
| StandardIR promotions | 0 |
| Model calls | 0 |
| Independent traversal difference | 0 |
| Negative control | passed |

| Name as accepted | Normalized name | Relation | Target class | Citation | Normalized StandardIR lhs |
|---|---|---|---|---|---|
| `assumed-implied-spec,` | `assumed-implied-spec` | definition | parser-target | valid | yes |
| `explicit-shape-spec-list` | `explicit-shape-spec-list` | rank | semantic/non-parser | valid | no |
| `explicit-shape-spec-list,` | `explicit-shape-spec-list` | rank | semantic/non-parser | valid | no |
| `format-items,` | `format-items` | definition | parser-target | valid | yes |
| `integer-type-spec,` | `integer-type-spec` | definition | parser-target | valid | yes |
| `team-number,` | `team-number` | definition | parser-target | valid | yes |
| `upper-cobound,` | `upper-cobound` | definition | parser-target | valid | yes |

The five definition targets match existing StandardIR `lhs` names after the
explicit comma normalization. The two `rank` targets describe a semantic
property. `explicit-shape-spec-list` has no committed StandardIR `lhs` entry,
so both rows remain unmatched even after normalization. The audit therefore
classifies all seven rows and promotes none.

## Limitations

The audit establishes citation and name-coverage properties. It does not prove
that the five definition targets should become new StandardIR facts, or that
the two rank statements have a complete semantic representation. The ignored
model response and package remain external run inputs. Their hashes are not
copied into git, and this commit contains no generated payload or model output.
