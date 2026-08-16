# Component contracts

The authoritative cross-repository interfaces are the versioned SX schemas in
`contracts/` and their fixtures. The registry is `contracts/registry.sx`.

| Component | Consumes | Produces |
|---|---|---|
| `standard-new` | pinned normative source and StandardIR specs | StandardIR and derived artifacts |
| `fortfront-new` | `standardir-v0`, `standardir-grammar-v0` and lexical-layout contracts | frontend and AST artifacts |
| `ffc-new` | frontend, MIR and emission contracts | target-independent compiler artifacts |
| `fortback-new` | MIR, TargetIR and emission contracts | target artifacts |

The laboratory records contract revisions and fixtures. A production slice may
add implementation detail only when the central fixture consumes it. Breaking
changes require a new central revision and a migration slice; additive fields
remain compatible only when old fixtures retain their declared meaning.
