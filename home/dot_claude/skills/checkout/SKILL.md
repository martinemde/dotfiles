---
name: checkout
description: Start work on a new issue or feature by creating a jj change on the up-to-date default branch with an optional named bookmark.
argument-hint: "[#issue | bookmark-name]"
metadata:
  author: @ivy
allowed-tools:
  - Bash(echo:*)
  - Bash(gh issue view:*)
  - Bash(head:*)
  - Bash(jj bookmark:*)
  - Bash(jj describe:*)
  - Bash(jj diff:*)
  - Bash(jj git fetch:*)
  - Bash(jj log:*)
  - Bash(jj new:*)
  - Bash(jj st:*)
  - Bash(sed:*)
  - Skill(EnterWorktree:*)
---

# Checkout: Start a New Change for an Issue

## Arguments
```
$ARGUMENTS
```

## Pre-computed Context

```
Working copy: !`jj log -r @ --no-graph -T 'change_id.shortest() ++ " " ++ if(description, description.first_line(), "(no description)")' 2>/dev/null`
Working copy empty: !`jj diff --stat 2>/dev/null | head -1`
Log: !`jj log -r 'ancestors(@, 5)' --no-graph -T 'change_id.shortest() ++ " " ++ bookmarks ++ " " ++ if(description, description.first_line(), "(empty)") ++ "\n"' 2>/dev/null`
```

## Constraints

- Use `jj` for all version control operations, never `git`.
- Do not abandon changes or discard work without user confirmation.

## Instructions

### 1. Parse Arguments

Determine what `$ARGUMENTS` contains:

| Pattern | Action |
|---------|--------|
| `#123` or issue URL | Fetch issue title, derive bookmark name |
| Bookmark name (e.g., `feat/dark-mode`) | Use directly |
| Empty | Ask what to work on |

### 2. Derive Bookmark Name (from issue)

If `$ARGUMENTS` is an issue reference:

1. Fetch: `gh issue view <number> --json number,title,labels`
2. Derive bookmark name from issue metadata:
   - Check labels for conventional commit type hints (bug/fix labels → `fix/`, feature labels → `feat/`, chore/maintenance labels → `chore/`, default → `feat/`)
   - Format: `<prefix><number>-<kebab-case-title>` (e.g., `feat/123-add-dark-mode`)
   - Truncate to 60 characters max

### 3. Handle Existing Work

Check pre-computed context for the current working copy state.

In jj, the working copy `@` is always a change being edited. Before starting new work, assess:

| Situation | Action |
|-----------|--------|
| Working copy is empty (no diff) | Safe to proceed — `jj new` will leave an empty change behind (auto-abandoned) |
| Working copy has changes with a description | Suggest `jj commit` first to finalize, then proceed |
| Working copy has changes without a description | Suggest `jj commit -m "..."` or `jj describe -m "..."` first |
| Conflicts exist (`jj st` shows conflicts) | Inform user and wait for guidance |

Do not silently abandon or squash work.

### 4. Create the Change

1. `jj git fetch` — ensure we have latest from remote
2. Create a new change on top of main:

```bash
jj new main -m "<issue title or description>"
```

3. Create a named bookmark on the new change (for later pushing/PR):

```bash
jj bookmark create <bookmark-name> -r @
```

### 5. Report and Continue

Report the change ID, bookmark name, and parent (e.g., `Created change xyz on bookmark feat/123-add-dark-mode from main`), then immediately mark this task complete and execute the next task in the workflow.
