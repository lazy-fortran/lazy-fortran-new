You are the larger-model subject of E0105. Work in the supplied repository and
read:

- .cache/runs/E0101/R000002/residue.jsonl
- .cache/runs/E0100/R000001/candidate-spans.tsv
- .cache/runs/E0001/R000003/j3-24-007.canonical.txt

For every one of the 127 residue records in residue.jsonl, emit exactly one
JSON object, in JSONL, and emit nothing else: no Markdown, no code fence, no
explanation. The only permitted keys are name, decision, relation, target,
citation. For a row whose retained normative span supports a precise relation,
use decision relation, a short relation name, a target, and citation with
exactly line, page, source_hash, and span copied from one retained candidate
span for that same name. For any row not established by the retained evidence,
use exactly {"name":"...","decision":"unresolved"} with no other keys.

Reason over the normative evidence, not model memory. Do not invent citations,
rules, aliases, targets, or facts. Do not use comparison grammars. The strict
harness will reject unsupported fields, missing rows, duplicate rows, and
citations not present in the retained spans. No answer is better than an
unsupported relation.
