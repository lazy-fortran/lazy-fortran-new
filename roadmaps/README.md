# Lane roadmaps

`ROADMAP.md` is the program authority. These files are its concise lane views,
not independent plans. Their contract revisions, dependencies and gates are
checked centrally with `scripts/check-contracts.sh`. Milestone status remains
in `ROADMAP.md` and is changed only after an experiment or an independently
checked production result.

Agents receive one vertical slice from one lane. The coordinator launches a
new wave only when the slice's input contracts and source pins exist. After a
verified result, the coordinator merges it promptly, records the exact commit
and removes the task worktree and branches as specified by D0044.

| Lane | Repository | Roadmap |
|---|---|---|
| StandardIR | `standard-new` | `standardir.md` |
| Frontend | `fortfront-new` | `frontend.md` |
| Middle end | `ffc-new` | `middle-end.md` |
| Backend | `fortback-new` | `backend.md` |
| Integration | laboratory and all production repositories | `integration.md` |
