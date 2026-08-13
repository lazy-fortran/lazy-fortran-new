# Backend source manifests

This directory will contain manifests for the processor, ABI, relocation and
object-format sources consumed by `fortback-new`. It contains no downloaded
payloads. The verified cache remains under `.cache/` and is populated only by
`scripts/fetch.sh`.

Each manifest names the source class, license or access restriction, exact
version or retrieval date, byte hash when a concrete payload is available, and
the TargetIR fields for which it is used. Authoritative machine-readable data,
authoritative prose, derived models and differential oracles remain separate.
