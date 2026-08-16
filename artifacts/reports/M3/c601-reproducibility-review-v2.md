# M3 C601 reproducibility review v2

Verdict: NEEDS FIX

Packet: central commit `09b9113`, functional pin `7b9987a`, corrected replay
`tests/e2e/run-m3-c601.sh .cache/runs/E0177/R000002`.

First fatal issue: the append-only R000019 record reported the stale oracle
hash `9aba2901081dc449b8d1c02aebea48f41ce03521b480f8f5decbfafd51aabe28`,
while the replay environment and pinned validator hash are
`b9e4a6ace15fd5622cc2496b51f80d23ad9db282251c38215b4c2ed5156a045c`. The
experiment manifest also still named R000001. The required correction is a
fresh replay with the actual hash and a manifest pointing to that replay.
