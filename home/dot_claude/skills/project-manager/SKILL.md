---
name: project-manager
description: Use when creating, updating, or triaging GitHub issues. Writes issues from a product perspective — user stories, acceptance criteria, context, and dependencies — without prescribing implementation.
argument-hint: "[create | update #NNN | triage] [description or context]"
metadata:
  author: @ivy
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(gh issue view:*)
  - Bash(gh issue list:*)
  - Bash(gh milestone list:*)
  - Bash(gh label list:*)
---

# Project Manager

Write GitHub issues like a product manager. Focus on the user story, acceptance criteria, and context. Leave implementation notes when useful but never prescribe the solution.

## Arguments

```
$ARGUMENTS
```

## Instructions

### 1. Determine the Action

Parse arguments for intent:

- **`create`** or a description with no issue number → create a new issue
- **`update #NNN`** or **`#NNN`** with modification context → update an existing issue
- **`triage`** → review recent issues for gaps, duplicates, or missing context
- **Ambiguous** → infer from conversation context; ask only if genuinely unclear

### 2. Learn the Repo's Voice

Before writing, fetch 3–5 recent issues from the same milestone (or repo if no milestone):

```bash
gh issue list --milestone "..." --json number,title,body --limit 5
```

Adapt to the conventions you observe:
- **User story format** ("As an X, I can Y") vs. problem/solution format
- **Section headings** (Use-case, Context, Acceptance criteria, Depends on, Future scope, etc.)
- **Tone** (terse vs. explanatory)
- **Labeling and milestone conventions**

If the repo has no issues yet, use a sensible default: user story + acceptance criteria + context.

### 3. Draft the Issue

**Think like a PM, not an engineer:**

- **Title:** Conventional commit prefix if the repo uses them. Concise — under 70 chars.
- **User story or problem statement:** Who benefits and what they can do. One sentence.
- **Use-case:** Numbered walkthrough of the happy path. 3–5 steps max.
- **Context:** Why this matters now. What's the alternative without it. What it builds on.
- **Acceptance criteria:** Observable behaviors, not implementation steps. Testable.
- **Future scope:** Things explicitly NOT in this issue. Reduces scope creep.
- **Depends on:** Link upstream issues. Use `#NNN` format.
- **Notes:** Non-obvious constraints, gotchas, or pointers for whoever picks it up. Not a design doc.

**What to leave out:**
- File paths, function names, or code snippets (that's implementation)
- "How to build it" sections (let the implementer decide)
- Over-specified acceptance criteria that constrain the solution

### 4. Assign Metadata

- **Milestone:** Match the milestone of related issues, or ask if multiple candidates exist
- **Labels:** Match existing label conventions; don't invent new ones

### 5. Publish

Write the body to a temp file to avoid shell escaping issues:

```bash
cat > /tmp/issue-body.md << 'ISSUE'
...formatted body...
ISSUE
```

**Create:**
```bash
gh issue create --title "..." --body-file /tmp/issue-body.md --milestone "..."
```

**Update:**
```bash
gh issue edit NNN --body-file /tmp/issue-body.md
```

Report the issue URL when done.

### Triage Mode

When `triage` is specified:

1. Fetch open issues for the active milestone
2. Flag: missing acceptance criteria, vague scope, no dependencies listed, duplicates
3. Suggest edits — don't apply them without confirmation

## Examples

```
/project-manager create auto-generate PR body from agent session context
/project-manager #64 add a note about graceful fallback
/project-manager create --all flag for multi-repo PR creation, depends on #64 and #65
/project-manager triage milestone "1. Crew Ships Code"
/project-manager                          → infer from conversation context
```

## Anti-patterns

- Writing implementation plans disguised as issues
- Listing file paths or function signatures in acceptance criteria
- Creating issues with no user story or problem statement
- Skipping the format-learning step and using a generic template
- Over-specifying: "use a map[string]bool" is implementation, not acceptance criteria
