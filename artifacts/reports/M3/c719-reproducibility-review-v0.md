# C719 reproducibility/control-plane review v0

Status: `NEEDS FIX`
Origin: `LLM`
Functional snapshot: `150430738e080f04947f381b7949446e135d6070`
Control-plane snapshot: `1a5c272`
Replay: `tests/e2e/run-m3-c719.sh --fresh` (authoritative result `R000002` / `R000048`)

The functional pin, clean standard-new checkout, fresh replay, source/schema
and negative-control gates, result/trace hashes, final cleanup, zero model
calls and zero semantic promotions all passed. The review found that
`STATUS.md` and `ROADMAP.md` still described superseded `R000047` as the
authoritative C719 replay, while `R000048` was the current authoritative
record. Promotion was not authorized.

The required correction is to update those references to R000048 and rerun
the affected reproducibility review against the corrected pushed revision.
This report remains as retained failure evidence.
