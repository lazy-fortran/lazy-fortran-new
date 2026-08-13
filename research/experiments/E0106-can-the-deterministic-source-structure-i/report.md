# E0106. Deterministic source-structure index

Command:

```sh
research/experiments/E0106-can-the-deterministic-source-structure-i/analyse.sh
```

The run used `lazy-fortran-new` at `767807e` and `standard-new` at
`ae2ee71c42d2da4cfea28c0093408e375317987b`. The canonical text hash was
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`.

The production indexer emitted 6,707 source-backed structural records:

```text
section-heading              5573
rule-block-start              522
rule-continuation             609
cross-reference-block           3
```

Against the strict 127-row E0100/E0104 residue, matching structural evidence
was found for 126 rows:

```text
unique candidate              60
ambiguous candidate            66
no candidate                    1
```

These are candidate counts, not semantic resolutions. No alias, relation,
resolution, or semantic fact was promoted. The structure records retain exact
source spans, page numbers, source hash and `MECHANICAL` origin.

The independent traversal agreed on the candidate-name set. The independent
validator recomputed record text from canonical bytes and checked page
containment and provenance. A malformed page index and a same-length tampered
canonical source were both rejected. Model calls: zero.

The result is useful but does not close M3. The extractor has reduced the
residue to a bounded evidence set; the next step is to inspect the 60 unique
candidate rows with a stricter source-backed definition recognizer, while
keeping all ambiguous and unsupported rows unresolved.
