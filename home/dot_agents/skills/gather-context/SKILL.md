---
name: gather-context
description: Build comprehensive understanding of a problem by gathering context from GitHub issues, codebase exploration, git history, and linked references. Use when starting work on an issue or investigating a problem.
---

# Gather Context: Build Understanding Before Acting

Gather comprehensive context about a problem before proposing solutions. Practice Chesterton's Fence: understand why things exist before changing them.

## Arguments

```
$ARGUMENTS
```

## Gather Repository Context

Locate the repository root, inspect the origin remote, and confirm whether
`gh` is available. Treat missing Git metadata or GitHub access as a supported
local-only case rather than a fatal error.

## Constraints

- Avoid `git -C <path>` when changing the working directory directly is clearer.
- This skill is read-only. Do not modify files, create branches, or make commits.
- Gather context proportional to the problem size. A typo fix doesn't need 3 Explore agents.

## Instructions

### 1. Determine Context Scope

Assess what kind of investigation is needed based on `$ARGUMENTS`:

| Input                                                | Scope                                                   |
| ---------------------------------------------------- | ------------------------------------------------------- |
| Issue ref (`#123`) with clear, narrow body           | **Light** — fetch issue, quick codebase scan            |
| Issue ref with broad/vague body or multiple comments | **Full** — fetch issue + parallel exploration + history |
| Problem description (no issue)                       | **Full** — explore codebase, search history             |

### 2. Fetch the Issue (if applicable)

If `$ARGUMENTS` is an issue reference:

```bash
gh issue view <number> --json number,title,body,labels,comments,assignees,milestone,projectItems
```

Extract:

- **Goal**: What needs to change and why
- **Labels**: What labels are applied and what they indicate about priority, readiness, type, and scope
- **Comments**: Additional requirements, discussion, decisions
- **Linked references**: Other issues, PRs, URLs mentioned in body/comments

If comments reference other issues, fetch those too:

```bash
gh issue view <linked-number> --json number,title,body,labels
```

### 3. Explore in Parallel

Spawn Explore agents based on scope. Each agent gets a specific focus — don't duplicate work across agents.

**Light scope** (1 agent):

- Find files and functions relevant to the issue using keywords from the title/body

**Full scope** (up to 3 agents):

| Agent        | Focus                 | Approach                                                                                                                                                                                                                            |
| ------------ | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Codebase** | Find relevant code    | Use issue keywords, file paths from body, area labels. Search for related functions, types, tests. Trace call paths if the issue mentions specific behavior.                                                                        |
| **History**  | Understand prior work | `git log --all --grep="<keywords>"` for related commits. `git log --follow <file>` for files mentioned in the issue. Check for reverted commits or abandoned PRs. Look at who last touched the relevant code and what they changed. |
| **Related**  | Gather linked context | Fetch linked issues/PRs. If the issue references external docs or URLs, use `WebFetch` to gather them. Check if similar issues were filed and closed before.                                                                        |

Only spawn the Related agent if there are actual linked references to follow.

### 4. Synthesize Findings

Produce a structured summary. This is the output other skills such as `think` and `plan` will consume.

**Problem Statement**

- What needs to change (from issue body + comments)
- Why it needs to change (motivation, who's affected)
- What "done" looks like (acceptance criteria, if stated)

**Relevant Code**

- File paths and line ranges
- Key functions, types, or patterns involved
- How the current code works (trace the relevant path)

**Prior Art**

- Previous attempts (commits, PRs, reverted changes)
- Related issues (open or closed)
- Relevant discussion or decisions from comments

**Constraints**

- Project conventions from the active repository instruction file
- Testing requirements (test suite location, patterns)
- Platform considerations (OS-specific behavior, templates)

**Open Questions**

- Gaps in the issue specification
- Ambiguities that need human clarification
- Assumptions that should be validated

Present findings concisely. Link to specific files and line numbers so the next phase can act on them directly.
