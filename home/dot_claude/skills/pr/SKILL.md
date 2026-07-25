---
name: pr
description: Create a draft or ready pull request with gh for a jj revision — pushes the bookmark, reviews the full changeset, and drafts a title and body explaining why the change was made. Use when asked to open a PR.
argument-hint: '[revision] [ready]'
---

# Create Pull Request

- `/pr` — draft PR for the current diff from trunk
- `/pr [revision]` — draft PR for that revision
- `/pr [revision] ready` — ready for review rather than draft

## Push and get the bookmark

The command depends on what the revision already has:

```bash
jj git push --bookmark <name>                                     # remote-tracked bookmark
jj bookmark track <name>@origin && jj git push --bookmark <name>  # local-only bookmark
jj git push -c <revision>                                         # no bookmark: creates one
```

Take the bookmark name from the output.

## Review the whole changeset

```bash
jj log -r 'trunk()..<bookmark>'                 # commits going in
jj diff --from trunk() --to <bookmark> --stat    # everything changing
```

A PR is easier to review as several focused commits than one large one. If the changeset is mixed,
reorganize with `jj split` or `jj squash` before opening it.

Check `.github/` for a PR template and follow it if one exists.

## Draft the title and body

The title summarizes the whole changeset, not just the most recent commit.

The body explains why the change was made and what it affects — context and motivation, not
implementation. Don't restate what the diff already shows: "added function X" and "modified file
Y" earn their place only when the reasoning behind them isn't obvious. Cover user-facing impact,
architectural decisions, and trade-offs, following whatever conventions the repository already
uses.

Two skills help here when they're available in the session. Invoke
`elements-of-style:writing-clearly-and-concisely` before drafting prose. Search
`episodic-memory:search` for conversations touching the changed files, looking for design
decisions and their rationale, alternatives that were considered and rejected, trade-offs, and
constraints that shaped the solution — surface what you find as a "Design Decisions" section.

Attribution gets an "Assisted-by" footer, not a "Generated with Claude Code" one.

## Self-review before opening

Read the changes as a reviewer would: code smells, missing tests for new behavior, repetition that
wants refactoring, modules that grew too long or too undocumented. Report what you find and
address it before opening the PR rather than after.

## Open it

```bash
gh pr create --head <bookmark-name> --title "<title>"   # body via heredoc; --draft unless `ready`
```

If the workspace name or bookmark contains a Jira key (`PROJ-123`, e.g. `LDE-488`), move the card:
`acli jira workitem transition --key <KEY> --status "In Review"`. No key, no step — skip it
silently.

Return the PR URL.
