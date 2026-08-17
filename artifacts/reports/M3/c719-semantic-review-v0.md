# C719 semantic/source review v0

Status: `PASS` for the semantic/source scope; paired review did not authorize promotion.
Origin: `LLM`
Functional snapshot: `150430738e080f04947f381b7949446e135d6070`
Control-plane snapshot: `1a5c272`
Replay: `tests/e2e/run-m3-c719.sh --fresh` (authoritative result `R000002` / `R000048`)

The candidate binds C719 to canonical-text line 3297 and page 80, with the
R709 StandardIR metadata and source hashes checked by the validator. The typed
kind-param presence/value oracle computes outcomes before comparing expected
labels. Its four cases produce two accepted, one rejected and one unresolved
outcome; all five source/provenance mutation controls fail closed. The slice
does not parse numeric literals, evaluate constant expressions, inspect
processor representation methods, consume model output or promote a semantic
fact.

This semantic/source scope passed. The reproducibility scope found a
control-plane reference defect in the same review wave; the retained review
therefore did not authorize promotion.
