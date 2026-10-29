---
name: plan
description: Create a parallelized implementation plan with task dependencies, sequencing, and agent team topology. Use after gathering context and reaching agreement on approach.
---

# Plan: Parallelized Implementation Design

Produce a plan whose value is its dependency graph: what can run at once, what genuinely waits
on what, and who does each piece.

```
$ARGUMENTS
```

Use the harness's planning mode when it has one; otherwise stay read-only until approval. Build
on `gather-context` / `think` output when supplied; otherwise read the code, the tests, and the
repository instructions first.

## Find the parallelism

Linear plans are the failure mode this skill exists to prevent. Start from the assumption that
every task is independent, and add a dependency only when task B needs task A's _output_ (not
merely its existence). Tasks touching different files are usually independent; tests can be
written against the interface alongside the implementation; review can start as soon as there
is code. Two tasks that touch the same file either depend on each other or run in separate
worktrees. If nothing can run in parallel, say why.

## Present

1. **Overview** — one paragraph.
2. **Task graph** — phases labelled `(parallel)` or `(sequential)`; each task names its agent
   (`Explore`, `general-purpose`, `plan-reviewer`, or a project agent), files, and `blockedBy`
   with a one-line reason.
3. **Parallelization table** — each parallel group and why its tasks are independent.
4. **Team and isolation** — for 3+ parallel tasks: roles, and `worktree` isolation where files
   overlap.
5. **Checkpoints** — where a human reviews before downstream work.
6. **Commit strategy** — one logical change per commit, in dependency order.
7. **Risks** — assumptions that may be wrong.

After approval, go straight to creating tasks with the harness's task facility. If tasks already
exist (e.g. from `work-on`), append — never clear or replace them — and hand a placeholder
"plan" task's upstream dependencies to the first implementation task.
