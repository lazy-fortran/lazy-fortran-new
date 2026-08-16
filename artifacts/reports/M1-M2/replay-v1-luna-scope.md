# M1-M2 focused Luna review — regression scope

Snapshot: `fca7fda2986d9d70b95dd392c87da2896be1d31d`

Origin: `LLM`

Verdict: `NEEDS FIX`

The milestone definition of done still lacked a declared M1-M2 regression
corpus entry and status, and the fixture did not record one for the oracle
policy's regression-status requirement.

Required correction: add a versioned `research/corpora/` entry, bind its
fixture hash and status in the verifier, and regenerate the trace.
