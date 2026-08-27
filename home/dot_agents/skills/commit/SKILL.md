---
name: commit
description: Finalize one completed logical change with Jujutsu (jj) and leave a clean working copy. Use when asked to commit or when a finished unit of work needs recording; do not invoke merely to begin a task.
---

# Commit a Completed Change

Record the current unit of work without absorbing unrelated changes or rewriting existing history. Repository instructions take precedence when they define a more specific commit workflow.

## Inspect

Run these concurrently before changing history:

- `jj diff`
- `jj log -r "ancestors(@, 10)" --template builtin_log_oneline`
- `jj status`

Use the diff to identify the task-owned changes, the log to match the repository's description style, and status to catch conflicts, unrelated work, or an existing description. Confirm the relevant checks have passed and scan the changed paths for likely secrets.

If the working copy is empty, report that there is nothing to commit. If task-owned and unrelated changes are mixed, split only when the ownership boundary is exact and the active jj guidance provides a safe non-interactive procedure; otherwise stop and identify what needs separating.

## Finalize

Choose a concise description that explains why the completed change exists and matches local history. Do not impose Conventional Commits unless the repository uses them.

- If `@` already has an accurate description, run `jj new`.
- Otherwise run `jj commit -m "<description>"`.

Never launch an editor, publish changes, or rewrite an earlier commit as part of this skill.

## Verify

Run `jj status`. Success means the new `@` is empty and the completed change is its accurately described parent. Report the description and the checks that passed; distinguish checks not run from checks that passed.
