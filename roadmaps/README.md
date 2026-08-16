# Lane roadmaps

`ROADMAP.md` is the program authority. These files are its concise lane views,
not independent plans. Their contract revisions, dependencies and gates are
checked centrally with `scripts/check-contracts.sh`. Milestone status remains
in `ROADMAP.md` and is changed only after an experiment or an independently
checked production result. The mutable active delivery state is in
`STATUS.md`; `MILESTONES.md` contains its definitions of done.

`lazy-fortran-new` is the only Goal Mode control plane. Component lane views
assign implementation slices; they do not create local status files,
milestone ledgers or project-management loops.

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
