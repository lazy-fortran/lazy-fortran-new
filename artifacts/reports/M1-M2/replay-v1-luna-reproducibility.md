# M1-M2 focused Luna review — reproducibility

Snapshot: `fca7fda2986d9d70b95dd392c87da2896be1d31d`

Origin: `LLM`

Verdict: `NEEDS FIX`

The committed trace embedded absolute component/tool paths and host-specific
metadata in the byte-compared payload, so an equivalent fresh checkout could
not reproduce it across paths or hosts.

Required correction: remove path and host fields from the compared trace while
retaining them as non-compared environment evidence.
