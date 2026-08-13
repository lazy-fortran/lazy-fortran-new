# Standard to grammar

This directory contains the first-paper package accepted by D0038.

The manuscript is generated from the pinned run set. Rebuild it with:

```sh
papers/standard-to-grammar/analyse.sh
papers/standard-to-grammar/render.sh
```

The resulting PDF is written to the ignored cache. The paper claims the
standard-to-StandardIR extraction boundary, provenance-preserving grammar
projections, deterministic parser wiring, generated local operations and
bounded semantic evaluation. It does not claim a complete Fortran parser,
complete semantic coverage, compiler performance or production
`fortfront-new` integration.

Build a handoff bundle, including the PDF hash manifest and the pinned paper
sources, with:

```sh
papers/standard-to-grammar/submission.sh
```

The bundle is written to the ignored cache unless an output directory is
provided as the first argument. The manifest records the SHA-256 and byte
size of every payload file. The manifest itself is excluded because it would
otherwise hash itself.

The remaining publication actions are external: choose the author list and
venue, then submit the regenerated PDF and its repository commit.
