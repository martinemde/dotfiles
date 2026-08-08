---
name: work-on
description: Ship a GitHub issue end to end by assessing complexity and composing the available research, planning, implementation, review, commit, and pull-request workflows.
---

# Work On

Orchestrate a GitHub issue from understanding through pull request. Preserve existing work, follow the active repository instructions, and adapt to the task and workflow facilities supplied by the current harness.

## Supporting files

- Read [TIERS.md](TIERS.md) for the complexity decision matrix.
- Read [EPIC-WORKFLOW.md](EPIC-WORKFLOW.md) before decomposing an epic.

## Constraints

- Always assess the tier before starting implementation.
- Use only skills and agents available in the current harness. Perform an equivalent step inline when no matching capability exists.
- Proceed autonomously except for genuine blockers or decisions that materially change scope.
- Use the `commit` skill, when available, for each logical change.
- Preserve any task list created by the current harness. Do not overwrite unrelated user work.

## Workflow

### 1. Fetch and assess

Fetch the issue and read its discussion:

```bash
gh issue view <id-or-url> --json number,title,body,labels,comments,assignees,milestone
```

Classify it as Quick fix, Small, Medium, Large, or Epic using [TIERS.md](TIERS.md). State the tier and the evidence for it.

### 2. Build a tailored runbook

Use the following sequences as defaults. Skill names are shown without harness-specific invocation syntax.

- **Quick fix:** checkout, edit, commit, pull request.
- **Small:** checkout, gather-context at light scope, edit, commit, pull request.
- **Medium:** checkout, gather-context, think, plan, review-plan, share-plan, implement, simplify, commit, pull request.
- **Large:** the Medium flow with parallel workstreams where useful, incremental commits, and reflect after the pull request.
- **Epic:** gather-context, think about decomposition, split into independently verifiable units, run the appropriate tier flow for each unit, coordinate integration, and reflect.

Tell the user the selected sequence, key dependencies, and any human checkpoints. Then continue unless a checkpoint is required by repository policy.

### 3. Track and execute

Create a task list using the current harness's native task or plan facility when one exists. Each task must be a specific skill invocation or scoped imperative action, with dependencies represented explicitly.

For each task:

1. Mark it in progress.
2. Invoke the named skill or agent, or perform the work inline.
3. Verify the result in proportion to its risk.
4. Mark it complete and continue with newly unblocked tasks.

Treat `think` and retrospectives as interactive. Research and planning may surface findings while continuing. Implementation, simplification, commits, and pull-request preparation should normally proceed autonomously.

### 4. Adapt

Update the remaining runbook when discoveries invalidate the plan, add work, or change the tier. Keep completed evidence and dependency relationships intact.

### 5. Close out

- Confirm every task is completed or explicitly removed as unnecessary.
- Confirm the pull request links or closes the issue when appropriate.
- Run `reflect` for Large or Epic work when available.
- Report verification results, residual risks, and the pull-request link.
