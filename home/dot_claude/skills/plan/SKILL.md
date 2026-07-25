---
name: plan
description: Design an implementation as a task graph with explicit dependencies, parallel phases, and agent team topology. Use after gathering context and agreeing on an approach, when the work is large enough that sequencing it badly costs real time.
argument-hint: "[context summary or focus area]"
effort: high
metadata:
  author: @ivy
allowed-tools:
  - Bash(echo:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git rev-parse:*)
  - Bash(git status:*)
  - Bash(head:*)
  - Bash(ls:*)
  - Bash(test:*)
  - Glob
  - Grep
  - Read
  - TaskCreate
  - TaskList
  - TaskUpdate
---

# Plan

Turn work into a task graph that maximizes throughput — what's independent, what genuinely
depends on what, and how to structure agents around it.

This skill exists because planning drifts linear by default. A → B → C is the natural shape to
write down even when B and C touch different files and share no state, and the result is correct
but slower than it needs to be. So the question this skill keeps asking is: what is the minimal
set of sequential constraints here?

## Arguments

```
$ARGUMENTS
```

## Pre-computed Context

```
Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "NOT A GIT REPO"`
Test suite: !`test -d test/ && echo "yes" || echo "no"`
CLAUDE.md exists: !`test -f CLAUDE.md && echo "yes" || echo "no"`
```

## Constraints

- Call `EnterPlanMode` before designing the plan. This skill is plan-first.
- Never use `git -C <path>` — it rewrites the command prefix and breaks `allowed-tools` matching.

## 1. Enter plan mode

Call `EnterPlanMode` immediately. Everything below happens inside it.

## 2. Understand the work

If `$ARGUMENTS` carries context from `/gather-context` or `/think`, use it. Otherwise explore:
what files change, what the current code does and why, what tests exist and what patterns they
follow.

## 3. Decompose, then find the parallelism

Break the work into discrete tasks. For each, establish what must complete before it can start,
what kind of agent suits it, whether it benefits from worktree isolation (it does if another task
touches the same files), and whether a human should review before downstream work proceeds.

Then make a deliberate pass over dependencies, starting from the assumption that everything is
independent. Group tasks by the files they touch — different groups are parallel candidates. For
each pair, ask whether task B needs task A's _output_, or merely needs A to _exist_. Only the
first is a real dependency. Add `blockedBy` only where that test fails, with a one-line reason.

Two rules of thumb worth applying: tests can often be written in parallel with implementation
when they test the interface rather than the implementation, and review can start as soon as
there's something to review rather than waiting for everything.

A plan where every task blocks the next is almost always wrong. If this one genuinely is serial,
say specifically why rather than leaving it unexplained.

## 4. Structure the graph

```
Phase 1 (parallel):
  Task A — [agent: general-purpose] implement feature X in src/foo.ts
  Task B — [agent: general-purpose] implement feature Y in src/bar.ts

Phase 2 (blocked by Phase 1):
  Task C — [agent: general-purpose] integrate A and B in src/index.ts
    blockedBy: [A, B]

Phase 3 (parallel):
  Task D — [agent: reviewer] review changes
  Task E — [agent: general-purpose] write tests
    blockedBy: [C]
```

Label parallel phases as `(parallel)` so the structure is legible at a glance.

Agent selection: `Explore` for read-only research and finding patterns, `general-purpose` for
implementation, `reviewer` for code and plan review, plus any project-specific agents in the
pre-computed context.

## 5. Team topology, for 3+ parallel tasks

Propose roles — the main session leads, coordinating and merging; workers take a workstream each;
a reviewer covers completed work. Specify `isolation: "worktree"` for workers whose files
overlap, and no isolation when they're fully separate.

## 6. Commit strategy

What gets committed together (one logical change per commit), in what order (infrastructure
before features), and whether this lands as one PR or granular commits.

## 7. Present it

Include an overview paragraph, the task graph, a table of parallel groups with why each group is
independent, the team topology if applicable, the checkpoints where a human reviews, the commit
strategy, and the assumptions that might be wrong.

```
| Phase | Tasks | Why parallel |
|-------|-------|-------------|
| 1     | A, B  | Touch different files (src/foo.ts, src/bar.ts) |
| 3     | D, E  | Review and test are independent of each other |
```

Before calling `ExitPlanMode`, re-check the dependency pass from step 3 against what you're about
to present. Independent work sitting in a serial chain, or `blockedBy` without a real data
dependency behind it, means the plan needs another pass first.

## 8. Exit and instantiate

Call `ExitPlanMode` and await approval. Approval is the execution signal — your next action is
creating the tasks, not a summary or a "shall I proceed?"

Then build the task graph. Call `TaskList` first: tasks may already exist (workflow tasks from
`/work-on`, for instance), and implementation tasks get **appended** to those rather than
replacing them. Create each via `TaskCreate` with its `addBlockedBy`/`addBlocks` relationships.
Where an existing task is a placeholder for this plan's work ("Implement per plan"), mark it
completed with `TaskUpdate` and wire your first real task to that placeholder's upstream
dependencies.
