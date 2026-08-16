# Component contracts

The authoritative cross-repository interfaces are the versioned SX schemas in
`contracts/` and their fixtures. The registry is `contracts/registry.sx`.

| Component | Consumes | Produces |
|---|---|---|
| `standard-new` | pinned normative source and StandardIR specs | StandardIR and derived artifacts |
| `fortfront-new` | `standardir-v0`, `standardir-grammar-v0` and lexical-layout contracts | frontend and AST artifacts |
| `ffc-new` | frontend, MIR and emission contracts | target-independent compiler artifacts |
| `fortback-new` | MIR, TargetIR and emission contracts | target artifacts |

## Current L0 boundary audit

L0 consumes `standard-new/specs/lexical-facts-v0.sx` and the component's
`specs/schema-v0.sxs` generator fixture. It is explicitly a component-local
generator slice and does not claim to consume central
`contracts/standardir-v0.sxs`. D0022 records that the component schema is a
generator contract fixture, not the complete StandardIR data model; D0027
records lexical facts as a separate target-independent projection. The
central StandardIR contract becomes applicable only when a later fixture
actually crosses that boundary.

The laboratory records contract revisions and fixtures. A production slice may
add implementation detail only when the central fixture consumes it. Breaking
changes require a new central revision and a migration slice; additive fields
remain compatible only when old fixtures retain their declared meaning.
