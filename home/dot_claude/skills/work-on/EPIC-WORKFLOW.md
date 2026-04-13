# Epic Workflow

How to handle epic-tier issues that span multiple PRs, issues, or sessions.

## Identifying Epics

An issue is an epic when:
- It contains multiple checkboxes or sub-tasks
- It links to other implementation issues
- It uses phased language ("Phase 1", "Step 1", "First we need to...")
- The scope is too large for a single PR without becoming unwieldy
- It would benefit from multiple independent PRs that can be reviewed separately

## Decomposition Strategy

### Step 1: Slice the Epic

Break the epic into deliverable units. Each unit should be:
- **Independently shippable** — produces a working state when merged
- **Independently reviewable** — a reviewer can understand the change without context from other units
- **Small enough for one session** — fits in a single `/work-on` cycle (Small/Medium/Large tier)

Good slicing patterns:
- **Vertical slices**: Each unit delivers end-to-end functionality for one aspect
- **Layer slices**: Infrastructure first, then features that use it
- **Dependency order**: Foundation pieces before things that build on them

Bad slicing patterns:
- **Horizontal slices**: "All the models", "all the tests" — creates integration risk
- **Arbitrary splits**: Splitting a cohesive change just to reduce PR size

### Step 2: Decide on Tracking

Choose based on team visibility needs:

| Approach | When to use | How |
|----------|------------|-----|
| **GitHub sub-issues** | Other people need to see the work breakdown; units will span sessions | `gh issue create --title "..." --body "..." --label "..." --milestone "..."` and link to parent |
| **Internal tasks** | Solo work, single session, decomposition is just for execution | Use `TaskCreate` with dependencies |
| **Hybrid** | Some units are significant enough to track, others are small | Create issues for significant units, internal tasks for small ones |

When creating sub-issues:
- Reference the parent issue in the body
- Copy relevant labels from the parent
- Set appropriate priority (usually same as parent)
- Add a task list to the parent linking to sub-issues

### Step 3: Order the Work

Map dependencies between units:
1. Which units are independent (can run in parallel)?
2. Which units block others (must complete first)?
3. Which units should be reviewed before others proceed?

Create a task list reflecting this order. Use `addBlockedBy` to enforce sequencing.

### Step 4: Execute Each Unit

For each unit, run the appropriate tier workflow:
- Assess the unit's complexity independently (most epic sub-units are Small or Medium)
- Use `/checkout` to create a branch per unit (or per logical group)
- Execute the workflow for that tier
- `/commit` and `/pr` for each unit

### Step 5: Coordinate Across Units

Between units:
- Check if earlier PRs have been merged — rebase if needed
- Verify assumptions from earlier units still hold
- Update the parent issue with progress
- If a unit reveals that the plan for later units needs to change, update the remaining tasks

### Step 6: Close Out

After all units are complete:
- Verify the parent issue's criteria are met
- Close sub-issues that are done
- Close the parent issue
- `/reflect` on the full epic — what worked, what didn't

## PR Strategy for Epics

| Pattern | When |
|---------|------|
| **One PR per unit** | Units are independent, each is reviewable alone |
| **Stacked PRs** | Units build on each other, want incremental review |
| **Single PR** | Units are tightly coupled, splitting would make review harder |

Default to one PR per unit. Only consolidate if splitting genuinely hurts comprehension.
