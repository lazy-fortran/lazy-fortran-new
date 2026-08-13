# Cross-repository contracts

This directory is the central authority for interfaces that cross production
repository boundaries. The `.sxs` files are versioned schema inputs. The `.sx`
files under `fixtures/` are small canonical witnesses. Production repositories
implement against a pinned contract revision and do not copy the contract into
their research history.

The registry is `registry.sx`. A contract revision is identified by its file
stem, for example `standardir-v0`. The validator is
`scripts/check-contracts.sh`. It checks schema/fixture pairing, registry
coverage, balanced SX structure and a deliberate malformed-input failure.

The current contract set is deliberately a boundary, not a complete compiler
schema:

| Contract | Producer | Consumers | Boundary |
|---|---|---|---|
| `standardir-v0` | `standard-new` | `fortfront-new`, `ffc-new` | source-backed language facts and syntax |
| `frontend-v0` | `fortfront-new` | `ffc-new`, tools | typed frontend results and diagnostics |
| `mir-v0` | `ffc-new` | `fortback-new` | target-independent compiler operations |
| `targetir-v0` | `fortback-new` | backend generators | target facts, encodings and semantics |
| `emission-v0` | `fortback-new` | `ffc-new`, driver | object and executable emission |

Every record that came from an external specification carries source identity,
source hash and an origin label. The provenance chain is:

```text
external manifest and verified cache object
  -> importer/generator commit
  -> contract or TargetIR record
  -> generated production source
```

The laboratory owns the contract revision and compatibility decision. A
production repository owns the implementation and behavioral tests. Contract
changes are additive by default. A breaking change requires a new revision, a
central decision and a migration slice. Validate the contract set with:

```sh
scripts/check-contracts.sh
```
