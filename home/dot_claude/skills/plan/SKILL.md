---
name: plan
description: Create a parallelized implementation plan with task dependencies, sequencing, and agent team topology. Use after gathering context and reaching agreement on approach.
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

# Plan: Parallelized Implementation Design

Create an implementation plan that maximizes throughput by identifying what work is independent, what depends on what, and how to structure agent teams for parallel execution.

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

- **Always call `EnterPlanMode` before designing the plan.** This skill is plan-first.
- Never use `git -C <path>` — it rewrites the command prefix, breaking `allowed-tools` pattern matching.
- Focus on **parallelization and dependencies** — this is the skill's core value. Claude Code doesn't naturally optimize for these.

## Parallelization Mandate

**Linear plans are a failure mode.** This skill exists because sequential A → B → C wastes time when B and C are independent.

Before presenting any plan, verify each of these holds:

1. Does every independent task have **no** `blockedBy`? It should be ready to run immediately.
2. Does every `blockedBy` reflect a **real data dependency** — task B genuinely needs task A's output, not just ordering preference?
3. Does at least one phase contain **multiple parallel tasks**? If not, state the specific reason all work is serialized — do not silently omit this.
4. Are parallel phases **explicitly labeled** as `(parallel)` in the plan output?

A plan where every task blocks the next is wrong. Find the parallelism before presenting.

## Instructions

### 1. Enter Plan Mode

Call `EnterPlanMode` immediately. All remaining work happens in plan mode.

### 2. Understand the Work

If `$ARGUMENTS` provides context from `/gather-context` or `/think`, use it. Otherwise, explore the codebase to understand:
- What files need to change
- What the current code does and why
- What tests exist and what testing patterns to follow

### 3. Decompose into Tasks

Break the work into discrete, well-defined tasks. For each task, determine:

| Property | Question |
|----------|----------|
| **Independence** | Can this task be done without waiting for another task's output? |
| **Dependencies** | What must complete before this task can start? |
| **Agent type** | What kind of agent is best suited? (Explore, general-purpose, reviewer, project-specific) |
| **Isolation** | Does this task benefit from worktree isolation? (yes if it touches files another task also touches) |
| **Checkpoint** | Should human review the output before downstream tasks proceed? |

After listing all tasks, do an explicit **parallelization pass**. Start from the assumption that all tasks are independent — add `blockedBy` only when the test below fails:

1. Group tasks by the files they touch. Tasks in different file groups are candidates for parallel execution.
2. For each pair, ask: does task B need task A's *output* to start, or just task A to *exist*? Only the former is a real dependency.
3. Tasks that survive this test keep no `blockedBy`. Tasks that fail get `blockedBy` with a one-line reason why.

### 4. Design the Task Graph

Structure tasks with explicit dependencies. Use this format:

```
Phase 1 (parallel):
  Task A — [agent: general-purpose] implement feature X in src/foo.ts
  Task B — [agent: general-purpose] implement feature Y in src/bar.ts

Phase 2 (sequential, blocked by Phase 1):
  Task C — [agent: general-purpose] integrate A and B in src/index.ts
    blockedBy: [A, B]

Phase 3 (parallel):
  Task D — [agent: reviewer] review changes
  Task E — [agent: general-purpose] write tests
    blockedBy: [C]
```

**Parallelization principles**:
- Tasks touching different files are usually independent
- Tests can often be written in parallel with implementation (test the interface, not the implementation)
- Review can start as soon as there's code to review — don't wait for everything
- If two tasks must touch the same file, make one block the other or use worktree isolation

**Agent type selection**:
- `Explore` — read-only research, validation, finding code patterns
- `general-purpose` — implementation, writing code, running commands
- `reviewer` — code review, plan review, validation
- Project-specific agents — check pre-computed context for available agents

### 5. Define Team Topology (if applicable)

For work with 3+ parallel tasks, propose a team:

| Role | Agent type | Responsibilities |
|------|-----------|-----------------|
| Lead | (main session) | Coordinates, reviews, merges |
| Worker 1 | general-purpose | Implements workstream A |
| Worker 2 | general-purpose | Implements workstream B |
| Reviewer | reviewer | Reviews completed work |

Specify isolation strategy:
- `isolation: "worktree"` for workers touching overlapping files
- No isolation needed for workers on completely separate files

### 6. Define Commit Strategy

Plan the commit sequence:
- What gets committed together (one logical change per commit)
- Commit order (infrastructure before features, features before tests if tests depend on impl)
- Whether to squash into one PR or keep granular commits

### 7. Present the Plan

Write the plan with:

1. **Overview** — one paragraph summary of what the plan achieves
2. **Task graph** — tasks with dependencies, agents, and phases (as in step 4)
3. **Parallelization summary** — a concise table listing each parallel group, the tasks in it, and why they are independent:
   ```
   | Phase | Tasks | Why parallel |
   |-------|-------|-------------|
   | 1     | A, B  | Touch different files (src/foo.ts, src/bar.ts) |
   | 3     | D, E  | Review and test are independent of each other |
   ```
4. **Team topology** — agents, roles, isolation (if applicable)
5. **Checkpoints** — where human review is needed before proceeding
6. **Commit strategy** — what gets committed when
7. **Risk flags** — assumptions that might be wrong, areas that might need adjustment

### 8. Verify Before Presenting

Before calling `ExitPlanMode`, run through the [Parallelization Mandate](#parallelization-mandate) checklist. If any item fails:
- Find the independent work and move it out of the serial chain
- Remove `blockedBy` from tasks that don't have real data dependencies
- Re-label phases to reflect the corrected structure

A plan that fails the mandate should not be presented.

### 9. Exit Plan Mode

Call `ExitPlanMode` and await approval. The user's approval of the plan is the execution signal. Your next action after approval is Step 10 — not a summary, not "shall I proceed?", not a pause.

### 10. Create Tasks (append, never replace)

Once the plan is approved, instantiate the task graph as tasks. **If tasks already exist** (e.g., workflow tasks from `/work-on`), append implementation tasks — never clear or replace the existing list.

1. Call `TaskList` to discover existing tasks
2. Create each implementation task via `TaskCreate` with proper `addBlockedBy`/`addBlocks` relationships
3. If an existing task is a placeholder for plan work (e.g., "Implement per plan"), call `TaskUpdate` to mark it `completed` and wire your first implementation task with `addBlockedBy` pointing to that placeholder's upstream dependencies
