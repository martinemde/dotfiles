---
name: work-on
description: End-to-end workflow for shipping a GitHub issue. Assesses complexity, builds a tailored workflow, and orchestrates skills from research through PR.
argument-hint: "[#issue | issue URL | issue number]"
effort: max
disable-model-invocation: true
metadata:
  author: @ivy
allowed-tools:
  - Bash(gh issue view:*)
  - Bash(git branch --show-current:*)
  - Bash(git status:*)
  - Bash(head:*)
  - Bash(ls:*)
  - Read
  - Skill(checkout)
  - Skill(commit)
  - Skill(gather-context)
  - Skill(plan)
  - Skill(pr)
  - Skill(reflect)
  - Skill(review-plan)
  - Skill(share-plan)
  - Skill(simplify)
  - Skill(think)
---

# Work On: Ship an Issue End-to-End

Orchestrate the full lifecycle of a GitHub issue — from understanding through PR — by composing skills, agents, and tasks into a tailored workflow based on issue complexity.

## Arguments

```
$ARGUMENTS
```

## Pre-computed Context

```
Current branch: !`git branch --show-current 2>/dev/null`
Dirty worktree: !`git status --porcelain 2>/dev/null | head -5`
```

## Supporting Files

- For decision matrix details and tier examples, see [TIERS.md](TIERS.md)
- For epic decomposition guidance, see [EPIC-WORKFLOW.md](EPIC-WORKFLOW.md)

## Constraints

- Classify the issue's tier before starting work — the whole workflow branches off it.
- Only invoke skills that appear in the pre-computed context. When one is missing, do the
  equivalent work inline or skip that step rather than calling a skill that doesn't exist.
- Drive autonomously. Assess, plan, and execute without pausing for confirmation, and interrupt
  only for genuine blockers: ambiguous requirements, or failing tests with no clear fix.
- Commit incrementally with `/commit` for each logical change, rather than batching everything
  into one commit at the end.

## Instructions

### Step 0: Fetch & Assess

Fetch the issue:

```bash
gh issue view [id or url] --json number,title,body,labels,comments,assignees,milestone
```

Read the [TIERS.md](TIERS.md) decision matrix. Assess the issue's complexity tier based on signals: labels, body content, comment count, linked issues, design decisions.

**Tiers**: Quick fix · Small · Medium · Large · Epic

### Step 1: Propose Workflow

Based on the assessed tier and available skills, propose a workflow to the user. Use only skills that appear in the pre-computed context. When a skill isn't available, either skip the step or do the equivalent work inline.

Each tier below shows the skill sequence. When proposing the workflow, use exact skill names with arguments — these become the task subjects in Step 2.

#### Quick Fix

```
1. /checkout <branch-name>
2. Edit the file(s) directly
3. /commit
4. /pr
```

#### Small

```
1. /checkout <branch-name>
2. /gather-context <issue-ref> (light scope)
3. Edit file(s) per findings
4. /commit
5. /pr
```

#### Medium

```
1. /checkout <branch-name>
2. /gather-context <issue-ref> (full scope)
3. /think — <key decisions from context>
4. /plan — <context summary>
5. /review-plan
6. /share-plan <issue-ref>
7. Implement per plan (one task per distinct change)
8. /simplify
9. /commit
10. /pr
```

#### Large

```
1-6. Same as Medium
7. TeamCreate for parallel execution
8. Multiple /commit cycles as workstreams complete
9. /simplify
10. /pr
11. /reflect
```

#### Epic

```
1. /gather-context <issue-ref> (full scope)
2. /think — epic decomposition strategy
3. Decompose into sub-units (see EPIC-WORKFLOW.md)
4. For each sub-unit: run appropriate tier workflow
5. Coordinate across units (rebase, verify assumptions)
6. /reflect
```

Present the proposed workflow with:

- The assessed tier and reasoning
- The specific steps (naming which skills will be invoked)
- Where human checkpoints occur

Then proceed immediately to building the task list — do not wait for user confirmation.

### Step 2: Build Task List

Create tasks via `TaskCreate` with dependencies.

Name each task by the exact skill or command it invokes, arguments included. That turns the task
list into a runbook someone can read and execute.

- **Skill tasks**: Use the exact invocation as the subject (e.g., `/checkout feat/123-add-dark-mode`)
- **Implementation tasks**: Use a scoped imperative verb phrase naming the specific file or module (e.g., "Add dark-mode toggle to `theme.ts`"). Never use catch-all subjects like "Implement the feature" or "Make the changes."

Each task should include:

- Subject: exact skill invocation or scoped action
- Description with enough context for the step
- `addBlockedBy` for tasks that must complete first

Example for a Medium tier:

```
Task 1: /checkout feat/123-add-dark-mode
Task 2: /gather-context #123                          (blockedBy: [1])
Task 3: /think — key decisions from gather-context     (blockedBy: [2])
Task 4: /plan — implement dark mode                    (blockedBy: [3])
Task 5: /review-plan                                   (blockedBy: [4])
Task 6: /share-plan #123                               (blockedBy: [5])
Task 7: Add dark-mode toggle to theme.ts               (blockedBy: [6])
Task 8: Update CSS variables in globals.css             (blockedBy: [6])
Task 9: /simplify                                      (blockedBy: [7, 8])
Task 10: /commit                                       (blockedBy: [9])
Task 11: /pr                                           (blockedBy: [10])
```

### Step 3: Execute the Workflow

**Preserve the task list across skill invocations.** Sub-skills (e.g., `/gather-context`, `/plan`) may create their own tasks — that is fine. But they must never delete or overwrite the `/work-on` tasks created in Step 2. After each skill invocation, call `TaskList` and verify the workflow tasks still exist. If any were removed, re-create them with the same subjects and dependencies.

(You, the `/work-on` orchestrator, may still update, add, or delete tasks as part of Step 4 adaptation — the rule above applies only to sub-skill side effects.)

Work through the task list in order. For each task:

1. Mark as `in_progress` via `TaskUpdate`
2. Execute (invoke skill, spawn agent, or do work directly)
3. Mark as `completed`
4. Check `TaskList` for newly unblocked tasks

**Autonomy boundary**:

| Phase                                     | Mode            | Behavior                                                                                                                                               |
| ----------------------------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Research (`/checkout`, `/gather-context`) | Semi-autonomous | Agent works, surfaces findings to user                                                                                                                 |
| Discussion (`/think`)                     | **Interactive** | Agent and user converge on approach together. Pass specific framing via args: the key decisions, tradeoffs, and open questions from `/gather-context`. |
| Planning (`/plan`, `/review-plan`)        | Semi-autonomous | Agent drafts, user approves via `ExitPlanMode`                                                                                                         |
| Execution                                 | **Autonomous**  | Agent implements, commits incrementally                                                                                                                |
| Review (`/simplify`, `/pr`)               | Autonomous      | Agent reviews and opens PR                                                                                                                             |
| Retrospective (`/reflect`)                | Interactive     | Agent and user reflect on what worked                                                                                                                  |

**Escape hatch**: If the agent encounters a blocking issue it can't resolve during autonomous phases (unexpected test failures, missing dependencies, ambiguous requirements), it should flag the user and wait for guidance rather than guessing.

### Step 4: Adapt During Execution

Plans don't survive contact with reality. During execution:

- If a task reveals the plan is wrong, update remaining tasks via `TaskUpdate`
- If new work is discovered, create new tasks with appropriate dependencies
- If a task turns out to be unnecessary, delete it
- If the tier assessment was wrong (e.g., "Small" issue turns out to be "Medium"), adjust the workflow — add `/think` and `/plan` steps if needed

The task list is a living document, not a contract.

### Step 5: Close Out

After the PR is open:

1. Verify all tasks are marked completed (or deleted if unnecessary)
2. If `/reflect` is available and the tier is Large or Epic, invoke it
3. If the issue should be closed by the PR, confirm the PR description includes "Closes #N" or "Fixes #N"
