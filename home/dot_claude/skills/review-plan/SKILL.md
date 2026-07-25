---
name: review-plan
description: Validate an implementation plan by checking for gaps, ambiguity, incorrect assumptions, and missing dependencies. Use after creating a plan and before execution.
argument-hint: "[focus areas for review]"
context: fork
agent: reviewer
metadata:
  author: @ivy
---

# Review Plan: Validate Before Executing

You are reviewing an implementation plan. Your job is to find problems before they waste execution time. Be direct about issues — a false positive costs a re-read, a missed problem costs a rework cycle.

## Arguments

```
$ARGUMENTS
```

## Instructions

### 1. Find the Plan

Read the active plan file. Check these locations in order:

- `~/.claude/plans/` — most recent `.md` file
- Plan content in recent conversation context

If no plan is found, report this and stop.

### 2. Cross-Reference with Codebase

For every concrete claim the plan makes, verify it:

| Claim type              | Verification                                                           |
| ----------------------- | ---------------------------------------------------------------------- |
| "Modify `src/foo.ts`"   | Does `src/foo.ts` exist?                                               |
| "Call `functionName()`" | Does `functionName` exist? Is the signature correct?                   |
| "Import from `package`" | Is `package` in dependencies?                                          |
| "Tests are in `test/`"  | Does the test directory exist? What patterns do existing tests follow? |
| "Convention is X"       | Does CLAUDE.md or the codebase confirm this?                           |

Use `Glob`, `Grep`, and `Read` to verify. Don't trust the plan's claims about the codebase — check them.

### 3. Check Task Graph Integrity

Review the dependency structure:

- **Missing dependencies**: Does Task C use output from Task A without declaring `blockedBy: [A]`?
- **Circular dependencies**: Are there cycles that would deadlock execution?
- **Over-serialization**: Are tasks marked sequential that could actually run in parallel?
- **Under-serialization**: Are tasks marked parallel that actually depend on each other (e.g., both touch the same file)?
- **Orphan tasks**: Are there tasks with no downstream consumer? (Might be intentional, might be a gap.)

### 4. Assess Instruction Clarity

For each task, ask: could an agent execute this without further clarification?

Flag as ambiguous:

- "Update the config" — which config? What change?
- "Fix the tests" — which tests? What's wrong?
- "Follow the existing pattern" — which pattern? Where is it?

Good task descriptions name specific files, functions, and expected behavior.

### 5. Check for Missing Work

Common gaps:

- Tests not included for new functionality
- Missing error handling for new code paths
- No commit strategy defined
- No verification step after changes
- Edge cases mentioned in the issue but not addressed in tasks
- Platform-specific behavior not handled (check for `.tmpl` files, OS conditionals)

### 6. Report Findings

Categorize findings by severity:

**Blocking** — must fix before execution:

- Wrong file paths or function names
- Missing critical dependencies between tasks
- Incorrect API usage or assumptions about tool behavior
- Tasks that would fail because prerequisites don't exist

**Warning** — should address but can proceed:

- Vague task descriptions that might cause agent confusion
- Untested assumptions that are probably correct but not verified
- Missing test tasks for new code
- Suboptimal parallelization (could be faster)

**Note** — improvements, not blockers:

- Style suggestions
- Alternative approaches worth considering
- Minor optimizations

If `$ARGUMENTS` specifies focus areas, weight your review toward those concerns — but check task
graph integrity either way, since a dependency error invalidates the plan regardless of what the
review was asked to focus on.

### 7. Verdict

End with a clear verdict:

- **Approve** — no blocking issues, proceed to execution
- **Revise** — blocking issues found, list what needs to change before proceeding
