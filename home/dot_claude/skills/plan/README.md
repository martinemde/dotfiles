# `/plan` — Parallelized Implementation Plan

Structure a complex implementation as a task graph — identifying what can run in parallel, what must be sequential, and how to assign work across agent teams.

```
/plan
/plan focus on the authentication refactor
```

## Why this exists

Claude Code plans linearly by default. Given a complex task, it will naturally sequence A → B → C even when B and C are completely independent — different files, different concerns, no shared state. The result is correct but slow: workstreams that could run concurrently are queued behind each other.

The deeper problem is that Claude doesn't naturally *ask* the parallelization question. It's not in the default planning prompt. Without an explicit forcing function, you end up re-prompting the same parallelization instructions every time you tackle a large task.

[`/plan`](../plan/README.md) is that forcing function. It enters structured planning mode, decomposes the work, and explicitly asks: *what is the minimal set of sequential constraints, and what can run in parallel?*

## How to use it

**Standard usage** — after [`/think`](../think/README.md) has converged on an approach:
```
/plan
```
The agent reads the context from the conversation and builds the task graph.

**With focus** — when only part of the work needs planning:
```
/plan the database migration, not the API layer
```

## What a plan contains

- **Task graph** — discrete tasks with explicit `blockedBy` / `blocks` relationships
- **Parallelization summary** — table of parallel groups with justification for why they are independent
- **Agent assignments** — which agent type handles each task (`Explore`, `general-purpose`, `reviewer`, or project-specific agents)
- **Isolation decisions** — which tasks need worktree isolation (two agents touching the same file)
- **Checkpoints** — where human review is needed before downstream tasks can proceed
- **Commit strategy** — what gets committed when, in what order

The plan requires your approval before execution begins. This is the last checkpoint before the agent goes autonomous.

## The EnterPlanMode contract

[`/plan`](../plan/README.md) uses `EnterPlanMode`, which means it presents the plan and waits for explicit sign-off. Approval is the execution signal — the agent proceeds immediately to `TaskCreate` calls with proper `addBlockedBy` relationships. No pause, no "shall I proceed?".

Changing your mind after approval is fine: the task list is a living document. Tasks can be updated, deleted, or added as the implementation reveals new information.

## In the [`/work-on`](../work-on/README.md) workflow

[`/plan`](../plan/README.md) runs after [`/think`](../think/README.md) settles the *what*, and before [`/review-plan`](../review-plan/README.md) validates the *how*. The sequence is:

```
/think (decide approach)  →  /plan (structure execution)  →  /review-plan (validate plan)  →  execute
```

[`/review-plan`](../review-plan/README.md) catches issues with the plan before any code runs. Fixing a wrong file path in a plan costs a sentence; fixing it mid-execution costs a branch reset.
