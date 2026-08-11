# corpora

Manifests for the source corpora used as inputs and comparisons. Contents are
never committed; see `artifacts/README.md` for the mechanism.

A corpus manifest records where the corpus comes from, which commit or release
it is pinned to, how large it is, what licence it carries, and the part that
is easiest to omit and most expensive to omit: **what may be done with it**.

That last field matters because corpora and implementations carry different
permissions. `gfortran.dg` is GPL-licensed test input. Running those files
through our compiler and comparing observable behaviour is behavioural
comparison and is fine. It is not permission to read gfortran's implementation
while writing the corresponding component, and the files are not vendored here.

## Candidates, in rough order of value

| Corpus | Source | Size | Use |
|---|---|---|---|
| `gfortran.dg` | `gcc/gcc/testsuite/gfortran.dg` | ~8,600 files | Conformance, with per-file expected outcomes from DejaGnu directives |
| LFortran integration tests | `lfortran/integration_tests` | ~4,300 `.f90` | Run-and-compare behavioural corpus |
| `standard` fixtures | `standard/tests/fixtures` | 561 files | Per-revision parse fixtures across 12 dialects |
| `ffc` behavioural suite | `ffc/test` | ~450 programs | Compile-run-check |
| `fortfront` examples | `fortfront/examples` | ~900 files | Curated transformation pairs |

Pin each one when the phase that needs it starts, not before. A manifest written before anyone runs the corpus is a claim about the future.

## Reporting rule

Any rate computed over a corpus states its denominator, and reports skipped
cases separately from passed ones. `ffc`'s gfortran-dg row reads 32.4%
evaluated and 19.8% strict because skipped files are 39% of the suite. A single
number would have been misleading in a way nobody intended.
